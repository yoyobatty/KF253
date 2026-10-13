class AwesomeFleshPound extends ZombieFleshpound;

var int RageLevel;
var int MeleeDamage;
var byte ClientFire[2];
var bool bLimitMovement,bFreezeMovement,bClientAllowAnim;

replication
{
	reliable if( Role<ROLE_Authority )
		ServerStartFire,ServerStopFire;
	reliable if( Role==ROLE_Authority )
		ClientPlayAnim;
	reliable if( bNetOwner && Role==ROLE_Authority )
		RageLevel;
}

function HandleBumpGlass()
{
	if( PlayerController(Controller)==None )
		Super.HandleBumpGlass();
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
	if( PlayerController(Controller)!=None && Class'AwesomeBloat'.Static.IsMeleeAnim(NewAction,Self) )
		bLimitMovement = true;
	else bFreezeMovement = (NewAction=='PoundRage');
	Super.SetAnimAction(NewAction);
	if( Level.NetMode!=NM_Client && PlayerController(Controller)!=None && NetConnection(PlayerController(Controller).Player)!=None )
		ClientPlayAnim(AnimAction);
}
function PlayHit(float Damage, Pawn InstigatedBy, vector HitLocation, class<DamageType> damageType, vector Momentum)
{
	RageLevel+=Damage;
	Super.PlayHit(Damage,InstigatedBy,HitLocation,damageType,Momentum);
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
	else if( ClientFire[1]==1 && !bDecapitated && RageLevel>RageDamageThreshold && !IsInState('RageCharging') )
	{
		GotoState('RageCharging');
		SetAnimAction('PoundRage');
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
	if( Role==ROLE_Authority && bShotAnim && Controller.Target!=None && PlayerController(Controller)==None )
		Acceleration = AccelRate * Normal(Controller.Target.Location - Location);
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

function StartCharging()
{
	if( PlayerController(Controller)==None )
		Super.StartCharging();
}

simulated function DrawHUD(Canvas Canvas)
{
	if( bDecapitated )
		Class'AwesomeBloat'.Static.DrawChargeBar(Canvas,0);
	else Class'AwesomeBloat'.Static.DrawChargeBar(Canvas,float(RageLevel)/float(RageDamageThreshold));
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

state RageCharging
{
	function EndState()
	{
		RageLevel = 0;
		Super.EndState();
	}

	function Tick( float Delta )
	{
		if( !bShotAnim )
		{
			GroundSpeed = OriginalGroundSpeed * 2.3;//2.0;
			if( !bFrustrated && Level.TimeSeconds>RageStartTime )
				GoToState('');
		}

		// Keep the flesh pound moving toward its target when attacking
		if( bShotAnim && Controller.Target!=None && PlayerController(Controller)==None )
			Acceleration = AccelRate * Normal(Controller.Target.Location - Location);

		global.Tick(Delta);
	}

	// If fleshie hits his target on a charge, then he should settle down for abit.
	function bool MeleeDamageTarget(int hitdamage, vector pushdir)
	{
		local bool RetVal,bWasEnemy;

		bWasEnemy = (PlayerController(Controller)!=None || Controller.Target==Controller.Enemy);
		RetVal = Global.MeleeDamageTarget(hitdamage*1.75, pushdir*3);
		if( RetVal && bWasEnemy )
			GoToState('');
		return RetVal;
	}
}

defaultproperties
{
     MeleeDamage=25
     bSpecialHUD=True
     bSpecialCalcView=True
     HeadScale=1.000000
     ControllerClass=Class'KFMonsterVS.ControllerFP'
}
