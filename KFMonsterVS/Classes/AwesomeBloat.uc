//=============================================================================
// AwesomeBloat.
//=============================================================================
class AwesomeBloat extends ZombieBloat;

#exec OBJ LOAD FILE=KillingFloorHUD.utx

var byte ClientFire[2];
var bool bLimitMovement,bFreezeMovement,bClientAllowAnim;
var int MeleeDamage;

replication
{
	reliable if( Role<ROLE_Authority )
		ServerStartFire,ServerStopFire;
	reliable if( Role==ROLE_Authority )
		ClientPlayAnim;
}

function bool FlipOver()
{
	if( Physics==PHYS_Falling )
		SetPhysics(PHYS_Walking);
	bShotAnim = true;
	SetAnimAction('KnockDown');
	Acceleration = vect(0, 0, 0);
	if( KFMonsterController(Controller)!=None )
	{
		Controller.GoToState('WaitForAnim');
		KFMonsterController(Controller).bUseFreezeHack = True;
	}
	Return True;
}
function HandleBumpGlass()
{
	if( PlayerController(Controller)==None )
		Super.HandleBumpGlass();
}
simulated function PostNetReceive();
function Setup(xUtil.PlayerRecord rec, optional bool bLoadNow);

simulated final function ClientPlayAnim( name N )
{
	if( Level.NetMode!=NM_Client )
		return;
	bClientAllowAnim = true;
	SetAnimAction(N);
	bClientAllowAnim = false;
}
simulated function SetAnimAction(name NewAction)
{
	if( Level.NetMode==NM_Client && !bClientAllowAnim && Level.GetLocalPlayerController()==Controller )
		return;
	if( PlayerController(Controller)!=None && Class'AwesomeBloat'.Static.IsMeleeAnim(NewAction,Self) )
		bFreezeMovement = true;
	else bLimitMovement = (NewAction=='ZombieBarfMoving');
	Super.SetAnimAction(NewAction);
	if( Level.NetMode!=NM_Client && PlayerController(Controller)!=None && NetConnection(PlayerController(Controller).Player)!=None )
		ClientPlayAnim(AnimAction);
}
simulated function Fire( optional float F )
{
	ClientFire[0] = 1;
	ServerStartFire(0);
}
simulated function AltFire( optional float F )
{
	ClientFire[1] = 1;
	ServerStartFire(1);
}
function SetAttackAnim()
{
	if( ClientFire[0]==1 )
		SetAnimAction('Claw');
	else if( ClientFire[1]==1 )
		SetAnimAction('ZombieBarfMoving');
	else return;
	bShotAnim = true;
}
function ServerStartFire( byte Mode )
{
	ClientFire[Mode] = 1;

	if( !bShotAnim )
		SetAttackAnim();
}
simulated function AnimEnd(int Channel)
{
	if( ExpectingChannel==Channel )
	{
		bLimitMovement = false;
		bFreezeMovement = false;
	}
	Super.AnimEnd(Channel);
	if( Level.NetMode!=NM_Client && PlayerController(Controller)!=None && !bShotAnim )
		SetAttackAnim();
}
function ServerStopFire( byte Mode )
{
	ClientFire[Mode] = 0;
}
simulated function Tick( float Delta )
{
	Super.Tick(Delta);
	if( Health>=0 && PlayerController(Controller)!=None && Viewport(PlayerController(Controller).Player)!=None )
	{
		if( ClientFire[0]!=0 && Controller.bFire==0 )
		{
			ClientFire[0] = 0;
			ServerStopFire(0);
		}
		else if( ClientFire[1]!=0 && Controller.bAltFire==0 )
		{
			ClientFire[1] = 0;
			ServerStopFire(1);
		}
	}
}

simulated function RawInput(float DeltaTime,
							float aBaseX, float aBaseY, float aBaseZ, float aMouseX, float aMouseY,
							float aForward, float aTurn, float aStrafe, float aUp, float aLookUp)
{
	Class'AwesomeBloat'.Static.LockMovement(bLimitMovement,bFreezeMovement,PlayerController(Controller));
}
function ClawDamageTarget()
{
	local Actor A;

	if( Level.NetMode==NM_Client )
		return;
	if( PlayerController(Controller)==None )
		Super.ClawDamageTarget();

	A = Class'AwesomeBloat'.Static.GetBestMeleeTarget(Self);
	if( A==None )
		return;
	Controller.Target = A;

	if ( MeleeDamageTarget(MeleeDamage, (damageForce * Normal(A.Location - Location))) )
		PlayZombieAttackHitSound();
}
function SpawnTwoShots()
{
	if( Level.NetMode==NM_Client )
		return;
	if( PlayerController(Controller)!=None )
		Controller.Target = None;
	Super.SpawnTwoShots();
}
function bool DoJump( bool bUpdating )
{
	return Class'AwesomeBloat'.Static.StaticJump(Self,bUpdating);
}
simulated function bool SpecialCalcView(out Actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
{
	return Class'AwesomeBloat'.Static.CalcHeadView(Self,CameraLocation,CameraRotation);
}
function RemoveHead()
{
	Super.RemoveHead();
	SetHeadScale(0.f);
}

State ZombieDying
{
	simulated function BeginState()
	{
		if ( bTearOff && (Level.NetMode == NM_DedicatedServer) || class'GameInfo'.static.UseLowGore() )
			LifeSpan = 1.0;
		else
			SetTimer(2.0, false);

		SetPhysics(PHYS_Falling);
		if ( Controller != None )
		{
			if( PlayerController(Controller)!=None )
				Controller.bIsPlayer = true;
			if ( !Controller.bIsPlayer )
				Controller.Destroy();
			else Controller.PawnDied(self);
		}
 	}
}

static final function Actor GetBestMeleeTarget( KFMonster Start )
{
	local Actor A;
	local Pawn P;
	local float Aim,Dist;
	local vector Dir,HL,HN,StartPos;

	Aim = 0.6f;
	Dir = vector(Start.Controller.Rotation);
	P = Start.Controller.PickTarget(Aim,Dist,vector(Start.Controller.Rotation),Start.Location,100.f);
	if( P!=None && Start.FastTrace(Start.Location,P.Location) )
		return P;
	StartPos = Start.Location+(Dir*Start.CollisionRadius*0.9f);
	A = Start.Trace(HL,HN,StartPos+Dir*50.f,StartPos,true);
	if( Pawn(A)!=None || KFDoorMover(A)!=None )
		return A;
	return None;
}
simulated static final function bool IsMeleeAnim( name N, KFMonster M )
{
	return (N=='Claw' || N==M.meleeAnims[0] || N==M.meleeAnims[1] || N==M.meleeAnims[2]);
}
simulated static final function bool IsHitAnim( name N, KFMonster M )
{
	return (N==M.KFHitFront || N==M.KFHitBack || N==M.KFHitLeft || N==M.KFHitRight || N=='KnockDown');
}
simulated static final function bool CalcHeadView( KFMonster M, out vector CamPos, out rotator CamRot )
{
	local Coords C;

	if( M.Level.NetMode==NM_DedicatedServer || M.Health<=0 || M.Level.GetLocalPlayerController().bBehindView )
		return false;
	M.LastRenderTime = M.Level.TimeSeconds;
	if( M.Controller==None )
		CamRot = M.Rotation;
	else CamRot = M.Controller.Rotation;
	C = M.GetBoneCoords(M.HeadBone);
	CamPos = C.Origin + (M.HeadHeight * M.HeadScale * C.XAxis);

	// Make sure head isn't clipping through world geometry.
	if( M.Trace(C.XAxis,C.YAxis,CamPos,M.Location,false,vect(10,10,10))!=None )
		CamPos = C.XAxis;
	return true;
}
static function bool StaticJump( KFMonster M, bool bUpdating )
{
	if ( (M.Physics == PHYS_Walking) || (M.Physics == PHYS_Ladder) || (M.Physics == PHYS_Spider) )
	{
		M.PlayOwnedSound(M.ZJumpSound, SLOT_Pain, M.GruntVolume,,80);

		if ( M.Physics == PHYS_Spider )
			M.Velocity += (M.JumpZ - (M.Velocity Dot M.Floor)) * M.Floor;
		else if ( M.Physics == PHYS_Ladder )
			M.Velocity.Z = 0;
		else M.Velocity.Z = M.JumpZ;

		if ( (M.Base != None) && !M.Base.bWorldGeometry )
			M.Velocity += M.Base.Velocity;
		M.SetPhysics(PHYS_Falling);
		return true;
	}
	return false;
}
simulated static final function LockMovement( bool bMotion, bool bAll, PlayerController PC )
{
	if( bAll )
	{
		PC.aForward = 0;
		PC.aStrafe = 0;
		PC.bPressedJump = false;
	}
	else if( bMotion )
	{
		PC.bPressedJump = false;
		PC.aStrafe = 0;
	}
}
simulated static final function LockJumping( bool bLock, PlayerController PC )
{
	if( bLock )
		PC.bPressedJump = false;
}
simulated static final function DrawChargeBar( Canvas C, float Val )
{
	local int X,Y,XS,YS;

	C.Style = ERenderStyle.STY_Alpha;
	C.SetDrawColor(255,255,255,200);
	XS = C.ClipX*0.1f;
	X = C.ClipX*0.5f-(XS*0.5);
	Y = C.ClipY*0.05f;
	YS = C.ClipY*0.035f;
	C.SetPos(X,Y);
	C.DrawRect(Texture'Engine.WhiteSquareTexture',XS,YS);
	if( Val<=0 )
		return;
	C.SetPos(X+2,Y+2);
	C.SetDrawColor(255,255,255,255);
	C.DrawTile(Texture'Engine.WhiteSquareTexture',float(XS-4)*FMin(Val,1.f),YS-4, 0, 0, 1, 1);
}

defaultproperties
{
     MeleeDamage=10
     bSpecialCalcView=True
     HeadScale=1.000000
     ControllerClass=Class'KFMonsterVS.ControllerAIBase'
     bNetNotify=False
}
