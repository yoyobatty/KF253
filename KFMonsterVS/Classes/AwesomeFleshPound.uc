// A player's Fleshpound (a heavy). Fire: pound. Alt-Fire, once hurt enough: rage (he rages on his own too, as ever)
class AwesomeFleshPound extends ZombieFleshPound;

var byte HeldFire[2];	// fire buttons held (the server's copy is what the player sent)
var byte MoveLock;		// how much of the player's movement the action playing holds (VSZed.ActionLock)
var bool bServerAnim;	// an animation the server sent, on the player's own machine
var byte PressedFire;	// a press during another action (mode + 1), done once that action ends if soon enough
var float PressTime;
var byte Charge;		// the rage meter, 0 to 100 (for the player's HUD)
var int RageLevel;		// damage taken since the last rage
var bool bSpinning;		// his spin under way (the AI's controller hurts all about him as he spins; a player's he does it himself)
var float NextSpinHit;

replication
{
	reliable if( Role<ROLE_Authority )
		ServerFire;
	reliable if( Role==ROLE_Authority )
		ClientAnim;
	reliable if( Role==ROLE_Authority && bNetOwner )
		Charge;
}

simulated function Fire( optional float F )
{
	HeldFire[0] = 1;
	ServerFire(0,true);
}
simulated function AltFire( optional float F )
{
	HeldFire[1] = 1;
	ServerFire(1,true);
}
function ServerFire( byte Mode, bool bHeld )
{
	HeldFire[Mode] = byte(bHeld);
	if( !bHeld )
		return;
	PressedFire = Mode+1;
	PressTime = Level.TimeSeconds;
	if( !bShotAnim )
		TryAttack();
}
// The button held, or pressed a moment ago
function bool Wants( byte Mode )
{
	return HeldFire[Mode]!=0 || (PressedFire==Mode+1 && Level.TimeSeconds-PressTime<0.5);
}
function TryAttack()
{
	PlayerAttack();
	if( bShotAnim )
		PressedFire = 0;
}
function PlayerAttack()
{
	if( Wants(0) )
	{
		SetAnimAction('Claw');
		bShotAnim = true;
		bSpinning = (AnimAction=='PoundAttack3');
		NextSpinHit = Level.TimeSeconds + 0.1;
	}
	else if( Wants(1) && !bDecapitated && RageLevel>=RageDamageThreshold && !bChargingPlayer )
		StartCharging();
}

simulated function ClientAnim( name N )
{
	if( Level.NetMode!=NM_Client )
		return;
	bServerAnim = true;
	SetAnimAction(N);
	bServerAnim = false;
}
simulated function SetAnimAction( name NewAction )
{
	local byte Lock;

	if( !class'VSZed'.static.AllowAnim(self,bServerAnim) )
		return;
	Lock = LockFor(NewAction);
	if( Lock>0 || !IsFlinchAnim(NewAction) )
		MoveLock = Lock;
	Super.SetAnimAction(NewAction);
	if( class'VSZed'.static.SendAnim(self) )
		ClientAnim(AnimAction);
}
simulated function byte LockFor( name N )
{
	if( N=='PoundRage' )
		return 2;
	return class'VSZed'.static.ActionLock(self,N);
}
simulated function AnimEnd( int Channel )
{
	if( Channel==ExpectingChannel )
		MoveLock = 0;
	Super.AnimEnd(Channel);
	if( Role==ROLE_Authority && PlayerController(Controller)!=None && !bShotAnim )
		TryAttack();
}
simulated function Tick( float DeltaTime )
{
	Super.Tick(DeltaTime);
	if( class'VSZed'.static.IsMine(self) )
	{
		if( HeldFire[0]!=0 && Controller.bFire==0 )
		{
			HeldFire[0] = 0;
			ServerFire(0,false);
		}
		if( HeldFire[1]!=0 && Controller.bAltFire==0 )
		{
			HeldFire[1] = 0;
			ServerFire(1,false);
		}
	}
	if( Role==ROLE_Authority && PlayerController(Controller)!=None )
		Charge = ChargeNow();
	if( bSpinning && Role==ROLE_Authority )
		SpinTick();
}
simulated function RawInput( float DeltaTime, float aBaseX, float aBaseY, float aBaseZ, float aMouseX, float aMouseY,
	float aForward, float aTurn, float aStrafe, float aUp, float aLookUp )
{
	class'VSZed'.static.LockInput(PlayerController(Controller),MoveLock);
}
simulated function DrawHUD( Canvas C )
{
	class'VSZed'.static.DrawCharge(C,Charge/100.0,"Alt-Fire when full: rage");
}

function ClawDamageTarget()
{
	if( Role<ROLE_Authority )
		return;
	if( PlayerController(Controller)!=None )
		Controller.Target = class'VSZed'.static.MeleeTarget(self);
	Super.ClawDamageTarget();
}
simulated function HandleBumpGlass()
{
	if( PlayerController(Controller)==None )
		Super.HandleBumpGlass();
}
function bool DoJump( bool bUpdating )
{
	if( PlayerController(Controller)==None )
		return Super.DoJump(bUpdating);
	return class'VSZed'.static.Jump(self);
}
simulated function bool SpecialCalcView( out Actor ViewActor, out vector CameraLocation, out rotator CameraRotation )
{
	return class'VSZed'.static.HeadView(self,CameraLocation,CameraRotation);
}
// (as FleshpoundZombieController.SpinAttack does for the AI's)
function SpinTick()
{
	local Actor A;

	if( !bShotAnim || PlayerController(Controller)==None )
	{
		bSpinning = false;
		return;
	}
	if( Level.TimeSeconds<NextSpinHit )
		return;
	NextSpinHit = Level.TimeSeconds + 0.1;
	foreach CollidingActors(class'Actor',A,MeleeRange*1.5+CollisionRadius,Location)
		if( A!=Self && KFMonster(A)==None )
			SpinDamage(A);
}
function byte ChargeNow()
{
	if( bChargingPlayer )
		return 100;
	return byte(100*FClamp(float(RageLevel)/RageDamageThreshold,0,1));
}
function PlayHit( float Damage, Pawn InstigatedBy, vector HitLocation, class<DamageType> damageType, vector Momentum )
{
	RageLevel += Damage;
	Super.PlayHit(Damage,InstigatedBy,HitLocation,damageType,Momentum);
}
function StartCharging()
{
	RageLevel = 0;
	Super.StartCharging();
}

State RageCharging
{
	// (the rage ends on a hit as the AI's does: it counts a blow on its enemy)
	function bool MeleeDamageTarget( int hitdamage, vector pushdir )
	{
		local bool bHit;

		if( PlayerController(Controller)==None )
			return Super.MeleeDamageTarget(hitdamage,pushdir);
		Controller.Enemy = Pawn(Controller.Target);
		bHit = Super.MeleeDamageTarget(hitdamage,pushdir);
		if( Controller!=None )
			Controller.Enemy = None;
		return bHit;
	}
}

defaultproperties
{
     bSpecialHUD=True
     bSpecialCalcView=True
}
