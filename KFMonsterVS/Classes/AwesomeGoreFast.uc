// A player's Gorefast. Fire: blade. Alt-Fire: sprint
class AwesomeGoreFast extends ZombieGorefast;

var byte HeldFire[2];	// fire buttons held (the server's copy is what the player sent)
var byte MoveLock;		// how much of the player's movement the action playing holds (VSZed.ActionLock)
var bool bServerAnim;	// an animation the server sent, on the player's own machine
var byte PressedFire;	// a press during another action (mode + 1), done once that action ends if soon enough
var float PressTime;
var byte Charge;		// the sprint's readiness, or while sprinting what is left of it, 0 to 100 (for the player's HUD)
var float NextSprint;	// when the next sprint may begin, or while sprinting when it ends
var float SprintTime, SprintRest;

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
	}
	else if( Wants(1) && !bDecapitated && Level.TimeSeconds>=NextSprint && !IsInState('PlayerSprint') )
		GotoState('PlayerSprint');
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
	Lock = class'VSZed'.static.ActionLock(self,NewAction);
	if( Lock>0 || !IsFlinchAnim(NewAction) )
		MoveLock = Lock;
	Super.SetAnimAction(NewAction);
	if( class'VSZed'.static.SendAnim(self) )
		ClientAnim(AnimAction);
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
}
simulated function RawInput( float DeltaTime, float aBaseX, float aBaseY, float aBaseZ, float aMouseX, float aMouseY,
	float aForward, float aTurn, float aStrafe, float aUp, float aLookUp )
{
	class'VSZed'.static.LockInput(PlayerController(Controller),MoveLock);
}
simulated function DrawHUD( Canvas C )
{
	class'VSZed'.static.DrawCharge(C,Charge/100.0,"Alt-Fire: sprint");
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
function byte ChargeNow()
{
	if( IsInState('PlayerSprint') )
		return byte(100*FClamp((NextSprint-Level.TimeSeconds)/SprintTime,0,1));
	return byte(100*FClamp(1.0-(NextSprint-Level.TimeSeconds)/SprintRest,0,1));
}

state PlayerSprint
{
	function bool CanSpeedAdjust()
	{
		return false;
	}
	function BeginState()
	{
		NextSprint = Level.TimeSeconds + SprintTime;
		SetGroundSpeed(OriginalGroundSpeed * 1.7);
		bRunning = true;
		if( Level.NetMode!=NM_DedicatedServer )
			PostNetReceive();
		NetUpdateTime = Level.TimeSeconds - 1;
	}
	function EndState()
	{
		NextSprint = Level.TimeSeconds + SprintRest;
		SetGroundSpeed(OriginalGroundSpeed);
		bRunning = false;
		if( Level.NetMode!=NM_DedicatedServer )
			PostNetReceive();
		NetUpdateTime = Level.TimeSeconds - 1;
	}
	function RemoveHead()
	{
		GotoState('');
		Global.RemoveHead();
	}
	function Tick( float DeltaTime )
	{
		Global.Tick(DeltaTime);
		if( PlayerController(Controller)==None || Level.TimeSeconds>=NextSprint )
			GotoState('');
	}
}

defaultproperties
{
     SprintTime=10.000000
     SprintRest=10.000000
     bSpecialHUD=True
     bSpecialCalcView=True
}
