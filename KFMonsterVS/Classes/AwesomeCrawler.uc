//=============================================================================
// AwesomeCrawler.
//=============================================================================
class AwesomeCrawler extends ZombieCrawler;

var transient float NextProunceTimer;
var byte ClientFire[2];
var bool bFreezeMovement,bClientAllowAnim;
var int MeleeDamage;
var name MeleeAirAnims[3];

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
simulated function DrawHUD(Canvas Canvas)
{
	Class'AwesomeBloat'.Static.DrawChargeBar(Canvas,1.f-(NextProunceTimer-Level.TimeSeconds)/2.f);
}

simulated function PostNetReceive();
function Setup(xUtil.PlayerRecord rec, optional bool bLoadNow);
function TakeFallingDamage();

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
	if( PlayerController(Controller)!=None && (NewAction==MeleeAnims[0] || NewAction==MeleeAnims[1]
			 || NewAction==MeleeAirAnims[0] || NewAction==MeleeAirAnims[1]) )
		bFreezeMovement = true;
	if( NewAction=='ZombieSpring' )
		NextProunceTimer = Level.TimeSeconds+2.f;
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
simulated function bool AnimNeedsWait(name TestAnim)
{
    return (TestAnim=='ZombieSpring' || TestAnim=='DoorBash' || TestAnim==MeleeAnims[0] || TestAnim==MeleeAnims[1]
	 || TestAnim==MeleeAirAnims[0] || TestAnim==MeleeAirAnims[1]);
}
function SetAttackAnim()
{
	if( ClientFire[0]==1 )
	{
		if( Physics==PHYS_Falling )
			SetAnimAction(MeleeAirAnims[Rand(2)]);
		else SetAnimAction(MeleeAnims[Rand(2)]);
	}
	else if( ClientFire[1]==1 && NextProunceTimer<Level.TimeSeconds && (Physics==PHYS_Walking || Physics==PHYS_Spider) )
	{
		Velocity = vector(Controller.Rotation)*PounceSpeed;
		Velocity.Z += JumpZ;
		SetPhysics(PHYS_Falling);
		SetAnimAction('ZombieSpring');
		bPouncing = true;
		Enable('Bump');
	}
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
	bFreezeMovement = false;
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
	Class'AwesomeBloat'.Static.LockMovement(false,bFreezeMovement,PlayerController(Controller));
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

defaultproperties
{
     MeleeDamage=4
     MeleeAirAnims(0)="InAir_Attack1"
     MeleeAirAnims(1)="InAir_Attack2"
     MeleeAirAnims(2)="InAir_Attack2"
     MeleeAnims(2)="ZombieLeapAttack2"
     bSpecialHUD=True
     bSpecialCalcView=True
     HeadScale=1.000000
     ControllerClass=Class'KFMonsterVS.ControllerCrawler'
     LandMovementState="PlayerSpidering"
     bNetNotify=False
}
