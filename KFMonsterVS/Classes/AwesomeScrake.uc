//=============================================================================
// AwesomeScrake.
//=============================================================================
class AwesomeScrake extends Zombiescrake;

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

function HandleBumpGlass()
{
	if( PlayerController(Controller)==None )
		Super.HandleBumpGlass();
}
simulated function DrawHUD(Canvas Canvas)
{
	if( bDecapitated )
		Class'AwesomeBloat'.Static.DrawChargeBar(Canvas,0);
	else Class'AwesomeBloat'.Static.DrawChargeBar(Canvas,2.f-(float(Health)/HealthMax)*2.f);
}

simulated function PostNetReceive();
function Setup(xUtil.PlayerRecord rec, optional bool bLoadNow);

simulated function bool AnimNeedsWait(name TestAnim)
{
	return ( TestAnim == 'SawImpaleLoop' || TestAnim == 'DoorBash' || TestAnim=='KnockDown' );
}

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
	else bFreezeMovement = (NewAction=='SawImpaleLoop' || NewAction=='KnockDown');
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
	{
		SetAnimAction(MeleeAnims[Rand(2)]);
		GoToState('PlayerSawingLoop');
	}
	else if( ClientFire[1]==1 && !bDecapitated && Health<(HealthMax*0.5f) )
	{
		GoToState('RunningState');
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

State PlayerSawingLoop
{
	function SetAttackAnim()
	{
		if( ClientFire[0]==1 )
		{
			MeleeDamage = default.MeleeDamage*0.6;
			SetAnimAction('SawImpaleLoop');
		}
		else
		{
			GoToState('');
			return;
		}
		bShotAnim = true;
	}
	function bool CanSpeedAdjust()
	{
		return false;
	}
	function bool CanGetOutOfWay()
	{
		return false;
	}

	function RangedAttack(Actor A)
	{
		GoToState('');
	}

	function BeginState()
	{
		GroundSpeed = OriginalGroundSpeed * 0.75f;
	}
	function EndState()
	{
		AmbientSound =default.AmbientSound;
		MeleeDamage = default.MeleeDamage;
	}
}

defaultproperties
{
     MeleeDamage=14
     bSpecialHUD=True
     bSpecialCalcView=True
     HeadScale=1.000000
     ControllerClass=Class'KFMonsterVS.ControllerScrake'
     bNetNotify=False
}
