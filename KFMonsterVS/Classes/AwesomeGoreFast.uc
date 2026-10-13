class AwesomeGoreFast extends ZombieGorefast;

var transient float NextChargeTimer;
var byte ClientFire[2];
var bool bFreezeMovement,bClientAllowAnim,bClientRunningNow;
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
simulated function PostNetReceive()
{
	if( bClientRunningNow==bRunning )
		return;
	NextChargeTimer = Level.TimeSeconds+10.f;
	bClientRunningNow = bRunning;
	if (bRunning)
		MovementAnims[0]='ZombieRun';
	else MovementAnims[0]=default.MovementAnims[0];
}

simulated function DrawHUD(Canvas Canvas)
{
	if( bDecapitated )
		Class'AwesomeBloat'.Static.DrawChargeBar(Canvas,0);
	else if( bRunning )
		Class'AwesomeBloat'.Static.DrawChargeBar(Canvas,(NextChargeTimer-Level.TimeSeconds)/10.f);
	else Class'AwesomeBloat'.Static.DrawChargeBar(Canvas,1.f-(NextChargeTimer-Level.TimeSeconds)/10.f);
}

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
	if( PlayerController(Controller)!=None && Class'AwesomeBloat'.Static.IsHitAnim(NewAction,Self) )
		bFreezeMovement = true;
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
		SetAnimAction('ClawAndMove');
	else if( ClientFire[1]==1 && !bDecapitated && NextChargeTimer<Level.TimeSeconds && !IsInState('PlayerRunning') )
	{
		GoToState('PlayerRunning');
		return;
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
	if( ExpectingChannel==Channel )
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

state PlayerRunning
{
	// Don't override speed in this state
	function bool CanSpeedAdjust()
	{
		return false;
	}
	function BeginState()
	{
		NextChargeTimer = Level.TimeSeconds+10.f;
		GroundSpeed = OriginalGroundSpeed * 1.875;
		bRunning = true;
		if( Level.NetMode!=NM_DedicatedServer )
			PostNetReceive();

		NetUpdateTime = Level.TimeSeconds - 1;
	}

	function EndState()
	{
		NextChargeTimer = Level.TimeSeconds+10.f;
		GroundSpeed = OriginalGroundSpeed;
		bRunning = False;
		if( Level.NetMode!=NM_DedicatedServer )
			PostNetReceive();

		NetUpdateTime = Level.TimeSeconds - 1;
	}

	function RemoveHead()
	{
		GoToState('');
		Global.RemoveHead();
	}

	function Tick(float DeltaTime)
	{
		global.Tick(DeltaTime);
		if( PlayerController(Controller)==None || NextChargeTimer<Level.TimeSeconds )
			GoToState('');
	}
}
state RunningState
{
	function Tick(float DeltaTime)
	{
		if( PlayerController(Controller)!=None )
			GoToState('');
		else Super.Tick(DeltaTime);
	}
}

defaultproperties
{
     MeleeDamage=10
     bSpecialHUD=True
     bSpecialCalcView=True
     HeadScale=1.000000
     ControllerClass=Class'KFMonsterVS.ControllerGoreFast'
}
