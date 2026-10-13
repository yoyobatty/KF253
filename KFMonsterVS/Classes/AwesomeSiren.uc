//=============================================================================
// AwesomeSiren.
//=============================================================================
class AwesomeSiren extends Zombiesiren;

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
	if( PlayerController(Controller)!=None && (Class'AwesomeBloat'.Static.IsMeleeAnim(NewAction,Self) || NewAction=='Siren_Scream') )
		bLimitMovement = true;
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
		SetAnimAction('Siren_Scream');
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
	Super(KFMonster).Tick(Delta);

	if( Role == ROLE_Authority )
	{
		if( bShotAnim )
		{
			GroundSpeed = OriginalGroundSpeed * 0.65;

			if( PlayerController(Controller)==None && Controller.Target!=None )
				Acceleration = AccelRate * Normal(Controller.Target.Location - Location);
		}
		else GroundSpeed = OriginalGroundSpeed;
	}
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
simulated function SpawnTwoShots()
{
	if( Level.NetMode==NM_Client )
	{
		DoShakeEffect();
		return;
	}
	if( PlayerController(Controller)!=None )
		Controller.Target = None;
	Super.SpawnTwoShots();
}
// Shake nearby players screens
simulated function DoShakeEffect()
{
	local PlayerController LocalPlayer;

	LocalPlayer = Level.GetLocalPlayerController();
	if ( LocalPlayer!=None && LocalPlayer.ViewTarget!=None && (VSize(Location-LocalPlayer.ViewTarget.Location)<ScreamRadius) && FastTrace(Location,LocalPlayer.ViewTarget.Location) )
		LocalPlayer.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);
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

defaultproperties
{
     bSpecialCalcView=True
     ControllerClass=Class'KFMonsterVS.ControllerAIBase'
     bNetNotify=False
     MeleeDamage=10
}
