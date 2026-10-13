Class VSPC extends KFPlayerController;

var transient float NextPossessTimer;
var transient string RedStr,GreenStr,BlueStr;

var transient bool bInitColors,bSeenTeamHint;

replication
{
	reliable if( Role < ROLE_Authority )
		ServerPossessZed;
	reliable if( Role==ROLE_Authority )
		ClientDeathMessage;
}

exec function Suicide()
{
	local float MinSuicideInterval;

	if ( Level.NetMode == NM_Standalone )
		MinSuicideInterval = 1;
	else
		MinSuicideInterval = 10;

	if ( (Pawn != None) && (Level.TimeSeconds - Pawn.LastStartTime > MinSuicideInterval) )
	{
		if( Monster(Pawn)!=None )
		{
			// Repossess the pawn instead.
			UnPossessZed();
		}
		else Pawn.Suicide();
	}
}

final function bool UnPossessZed()
{
	local Monster M;
	local rotator R;

	M = Monster(Pawn);
	if( M==None || M.Health<=0 )
		return false;
	R.Yaw = M.Rotation.Yaw;
	UnPossess();
	ClientSetRotation(R); // Resets Roll/Pitch so crawlers don't screw up view.
	M.Controller = Spawn(M.ControllerClass);
	if( M.Controller!=None )
		M.Controller.Possess(M);
	else M.Suicide();
	return true;
}

function ServerChangeTeam( int N )
{
	bSeenTeamHint = true;
	VSGame(Level.Game).PlayerSwapTeam(Self,N);
}
function ServerPossessZed();

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

state Spectating
{
	function BeginState()
	{
		Super.BeginState();
		if( VSGame(Level.Game)!=None && VSGame(Level.Game).ShouldGoHunt(Self) )
			GoToState('PreySpec');
	}
}

state PreySpec extends BaseSpectating
{
ignores SwitchWeapon, RestartLevel, ClientRestart, Suicide, ThrowWeapon, NotifyPhysicsVolumeChange, NotifyHeadVolumeChange;

	function ServerPossessZed()
	{
		local KFMonster M;
		local vector HL,HN;

		if( NextPossessTimer>Level.TimeSeconds )
			return;
		NextPossessTimer = Level.TimeSeconds+0.4f;

		foreach TraceActors(Class'KFMonster',M,HL,HN,Location+vector(Rotation)*1000.f,Location)
		{
			if( M!=None && M.Health>0 )
			{
				VSGame(Level.Game).PlayerPossess(Self,M);
				return;
			}
		}
		ClientMessage("Can't possess: You must aim at the specimen to possess.");
	}
	exec function Fire( optional float F )
	{
		if( NextPossessTimer<Level.TimeSeconds )
		{
			ServerPossessZed();
			NextPossessTimer = Level.TimeSeconds+0.5f;
		}
	}
	exec function AltFire( optional float F )
	{
	}

	function Timer()
	{
		bFrozen = false;
	}

	function BeginState()
	{
		if ( Pawn != None )
		{
			SetLocation(Pawn.Location);
			UnPossess();
		}
		bCollideWorld = true;
		CameraDist = Default.CameraDist;
	}

	function EndState()
	{
		PlayerReplicationInfo.bIsSpectator = false;
		bCollideWorld = false;
	}
	function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{
		bBehindView = false;
		if( ViewTarget!=Self )
			SetViewTarget(Self);
		Acceleration = NewAccel;
		MoveSmooth(SpectateSpeed * Normal(Acceleration) * DeltaTime);
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

	function UpdateRotation(float DeltaTime, float maxPitch)
	{
		local rotator ViewRotation;
		local vector MyFloor, CrossDir, FwdDir, OldFwdDir, OldX, RealFloor;

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
}
