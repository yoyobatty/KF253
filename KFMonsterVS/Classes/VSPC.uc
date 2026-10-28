Class VSPC extends KFPlayerController;

// A specimen player (on the server)
var class<KFMonster> LastSpecimen;	// what they last rose as (not given again straight away)
var float NextSpawnTime;			// when they may rise again
var float DeathTime;				// when their last specimen died
var bool bHeavy;					// their specimen is the wave's heavy
var float LastHurtTime;				// when their heavy last hurt a survivor
var int HeavyCount;					// heavies they have had this half

// Rising (both machines: the player's HUD shows whether the spot will do)
var float MinSpawnDist;				// no nearer a survivor than this
var float SightDist;				// a survivor sees a spot this near if nothing is in the way
var transient float NextRiseTry;
var transient Pawn WarpTarget;

var transient string RedStr, GreenStr, BlueStr;
var transient bool bInitColors;

replication
{
	reliable if( Role<ROLE_Authority )
		ServerRise, ServerGhostWarp;
	reliable if( Role==ROLE_Authority )
		ClientDeathMessage;
}

// As a specimen: the AI takes it over and the player is a ghost again
exec function Suicide()
{
	if( KFMonster(Pawn)!=None && VSGame(Level.Game)!=None )
	{
		if( Pawn.Health>0 && Level.TimeSeconds-Pawn.LastStartTime>1 )
			VSGame(Level.Game).ReleaseSpecimen(self);
		return;
	}
	Super.Suicide();
}

function ServerChangeTeam( int N )
{
	if( VSGame(Level.Game)!=None )
		VSGame(Level.Game).SwitchSquad(Self);
}
function ServerRise();
function ServerGhostWarp();

// Why the specimen could not rise here (0: it can), and where it would: 2 no floor below, 3 a survivor can see the spot,
// 4 too near a survivor, 5 no specimen to rise as (VSInfoMessage's numbers)
simulated function byte SpawnProblem( class<KFMonster> M, out vector Spot )
{
	local vector HitL, HitN, Eye, Top;
	local KFHumanPawn P;

	if( M==None )
		return 5;
	if( Trace(HitL,HitN,Location-vect(0,0,3000),Location,false)==None || HitN.Z<0.7 )
		return 2;
	Spot = HitL + vect(0,0,1)*(M.Default.CollisionHeight+5);
	Top = Spot + vect(0,0,0.8)*M.Default.CollisionHeight;
	foreach DynamicActors(class'KFHumanPawn',P)
	{
		if( P.Health<=0 )
			continue;
		if( VSize(P.Location-Spot)<MinSpawnDist )
			return 4;
		Eye = P.Location + P.EyePosition();
		if( VSize(Eye-Spot)<SightDist && (FastTrace(Spot,Eye) || FastTrace(Top,Eye)) )
			return 3;
	}
	return 0;
}

simulated final function ClientDeathMessage( PlayerReplicationInfo Victim, Class<DamageType> DamType,
	 optional PlayerReplicationInfo Killer, optional class<Monster> KillerPawn )
{
	local string S,V;
	local byte T;

	if( Viewport(Player)==None || Victim==None )
		return;
	if( !bInitColors )
	{
		bInitColors = true;
		RedStr = Class'GameInfo'.Static.MakeColorCode(class'HUD'.Default.RedColor);
		GreenStr = Class'GameInfo'.Static.MakeColorCode(class'HUD'.Default.GreenColor);
		BlueStr = Class'GameInfo'.Static.MakeColorCode(class'HUD'.Default.BlueColor);
	}

	if( DamType==None )
		DamType = Class'DamageType';
	if( (Killer==None && KillerPawn==None) || Killer==Victim )
	{
		S = DamType.Static.SuicideMessage(Victim);
		S = Class'GameInfo'.Static.ParseKillMessage(Class'xDeathMessage'.Default.SomeoneString,
			Eval((Victim.Team==None || Victim.Team.TeamIndex==0),RedStr,BlueStr)$Victim.PlayerName$GreenStr,S);
	}
	else
	{
		S = DamType.Static.DeathMessage(Killer,Victim);
		if( Killer!=None )
		{
			if( Killer.Team!=None && Killer.Team.TeamIndex!=0 )
				T = 1;
			V = Killer.PlayerName;
			if( KillerPawn!=None )
				V = V@"("$KillerPawn.Default.MenuName$")";
		}
		else if( KillerPawn!=None )
		{
			T = 1;
			V = Class'KFInvasionMessage'.Static.GetNameOf(KillerPawn);
		}
		S = Class'GameInfo'.Static.ParseKillMessage(Eval(T==0,RedStr,BlueStr)$V$GreenStr,
			Eval((Victim.Team==None || Victim.Team.TeamIndex==0),RedStr,BlueStr)$Victim.PlayerName$GreenStr,S);
	}
	ClientMessage(S,'DeathMessage');
}

// A specimen player waiting to rise: free flight through the map (not through walls), unseen. Fire rises, Alt-Fire goes
// to the next survivor
state Ghost extends BaseSpectating
{
ignores SwitchWeapon, RestartLevel, ThrowWeapon, NotifyPhysicsVolumeChange, NotifyHeadVolumeChange;

	exec function Fire( optional float F )
	{
		if( Level.TimeSeconds>=NextRiseTry )
		{
			NextRiseTry = Level.TimeSeconds + 0.4;
			ServerRise();
		}
	}
	exec function AltFire( optional float F )
	{
		if( Level.TimeSeconds>=NextRiseTry )
		{
			NextRiseTry = Level.TimeSeconds + 0.4;
			ServerGhostWarp();
		}
	}
	function ServerRise()
	{
		if( VSGame(Level.Game)!=None )
			VSGame(Level.Game).RiseSpecimen(self);
	}
	// (above and behind the next living survivor, where there is room)
	function ServerGhostWarp()
	{
		local Controller C;
		local Pawn P, First, Next;
		local bool bPast;
		local vector Spot;
		local rotator R;

		for( C=Level.ControllerList; C!=None; C=C.NextController )
		{
			P = C.Pawn;
			if( KFHumanPawn(P)==None || P.Health<=0 )
				continue;
			if( First==None )
				First = P;
			if( bPast && Next==None )
				Next = P;
			if( P==WarpTarget )
				bPast = true;
		}
		if( Next==None )
			Next = First;
		if( Next==None )
			return;
		WarpTarget = Next;
		R.Yaw = Next.Rotation.Yaw;
		Spot = Next.Location - vector(R)*250 + vect(0,0,150);
		if( !FastTrace(Spot,Next.Location) || !SetLocation(Spot) )
		{
			Spot = Next.Location + vect(0,0,120);
			if( !SetLocation(Spot) )
				return;
		}
		R = rotator(Next.Location-Location);
		SetRotation(R);
		ClientSetLocation(Location,R);
	}
	function BeginState()
	{
		bCollideWorld = true;
		CameraDist = Default.CameraDist;
		bBehindView = false;
		SetViewTarget(self);
	}
	function EndState()
	{
		PlayerReplicationInfo.bIsSpectator = false;
		bCollideWorld = false;
	}
	function ProcessMove( float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot )
	{
		bBehindView = false;
		if( ViewTarget!=Self )
			SetViewTarget(Self);
		Acceleration = NewAccel;
		if( bWantsSprint )
			SpectateSpeed = default.SpectateSpeed * FlySpeedMulti;
		else SpectateSpeed = default.SpectateSpeed;
		MoveSmooth(SpectateSpeed * Normal(Acceleration) * DeltaTime);
	}
	function PlayerMove( float DeltaTime )
	{
		local vector X,Y,Z, NewAccel;

		GetAxes(Rotation,X,Y,Z);
		NewAccel = aForward*X + aStrafe*Y + aUp*vect(0,0,1);
		if( VSize(NewAccel)<1.0 )
			NewAccel = vect(0,0,0);
		UpdateRotation(DeltaTime, 1);
		if( Role<ROLE_Authority )
			ReplicateMove(DeltaTime, NewAccel, DCLICK_None, rot(0,0,0));
		else ProcessMove(DeltaTime, NewAccel, DCLICK_None, rot(0,0,0));
	}
}

// (specimen code sends its controller into the AI's states; a player's specimen carries on under the player)
state WaitForAnim
{
	function BeginState()
	{
		if( Pawn!=None )
			GotoState(Pawn.LandMovementState);
	}
}
state SpinAttack
{
	function BeginState()
	{
		if( Pawn!=None )
			GotoState(Pawn.LandMovementState);
	}
}

// Make it better able to attach to walls.
state PlayerSpidering
{
	function BeginState()
	{
		MinHitWall += 100;
		Super.BeginState();
	}

	function EndState()
	{
		MinHitWall -= 100;
		Super.EndState();
	}

	// (the specimen gone, as walking does: on a client its death can come before the server's word of it)
	function PlayerMove( float DeltaTime )
	{
		if( Pawn==None )
		{
			GotoState('Dead');
			return;
		}
		Super.PlayerMove(DeltaTime);
	}

	function UpdateRotation(float DeltaTime, float maxPitch)
	{
		local rotator ViewRotation;
		local vector MyFloor, CrossDir, FwdDir, OldFwdDir, OldX, RealFloor;

		if( Pawn==None )
			return;
		if ( bInterpolating || Pawn.bInterpolating )
		{
			ViewShake(deltaTime);
			return;
		}

		TurnTarget = None;
		bRotateToDesired = false;
		bSetTurnRot = false;

		if ( (Pawn.Base == None) || (Pawn.Floor == vect(0,0,0)) )
			MyFloor = vect(0,0,1);
		else MyFloor = Pawn.Floor;

		if ( MyFloor != OldFloor )
		{
			// smoothly change floor
			RealFloor = MyFloor;
			MyFloor = Normal(6*DeltaTime * MyFloor + (1 - 6*DeltaTime) * OldFloor);
			if ( (RealFloor Dot MyFloor) > 0.999 )
				MyFloor = RealFloor;
			else
			{
				// translate view direction
				CrossDir = Normal(RealFloor Cross OldFloor);
				FwdDir = CrossDir Cross MyFloor;
				OldFwdDir = CrossDir Cross OldFloor;
				ViewX = MyFloor * (OldFloor Dot ViewX)
							+ CrossDir * (CrossDir Dot ViewX)
							+ FwdDir * (OldFwdDir Dot ViewX);
				ViewX = Normal(ViewX);

				ViewZ = MyFloor * (OldFloor Dot ViewZ)
							+ CrossDir * (CrossDir Dot ViewZ)
							+ FwdDir * (OldFwdDir Dot ViewZ);
				ViewZ = Normal(ViewZ);
				OldFloor = MyFloor;
				ViewY = Normal(MyFloor Cross ViewX);
			}
		}

		if ( (aTurn != 0) || (aLookUp != 0) )
		{
			// adjust Yaw based on aTurn
			if ( aTurn != 0 )
			{
				ViewX = Normal(ViewX + 2 * ViewY * Sin(0.0005*DeltaTime*aTurn));
				if( aLookUp==0 )
					ViewZ = Normal(ViewX Cross ViewY);
			}

			// adjust Pitch based on aLookUp
			if ( aLookUp != 0 )
			{
				OldX = ViewX;
				ViewX = Normal(ViewX + 2 * ViewZ * Sin(0.0005*DeltaTime*aLookUp));
				ViewZ = Normal(ViewX Cross ViewY);

				// bound max pitch
				if ( (ViewZ Dot MyFloor) < 0.707   )
				{
					OldX = Normal(OldX - MyFloor * (MyFloor Dot OldX));
					if ( (ViewX Dot MyFloor) > 0)
						ViewX = Normal(OldX + MyFloor);
					else ViewX = Normal(OldX - MyFloor);

					ViewZ = Normal(ViewX Cross ViewY);
				}
			}

			// calculate new Y axis
			ViewY = Normal(MyFloor Cross ViewX);
		}
		ViewRotation = OrthoRotation(ViewX,ViewY,ViewZ);
		SetRotation(ViewRotation);
		ViewShake(deltaTime);
		ViewFlash(deltaTime);
		Pawn.FaceRotation(ViewRotation, deltaTime );
	}
}

defaultproperties
{
     MinSpawnDist=600.000000
     SightDist=4000.000000
}
