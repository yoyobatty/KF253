// A player's Wretch. Fire or Alt-Fire: claw
class AwesomeWretch extends ZombieWretch;

var byte HeldFire[2];	// fire buttons held (the server's copy is what the player sent)
var byte MoveLock;		// how much of the player's movement the action playing holds (VSZed.ActionLock)
var bool bServerAnim;	// an animation the server sent, on the player's own machine
var byte PressedFire;	// a press during another action (mode + 1), done once that action ends if soon enough
var float PressTime;

replication
{
	reliable if( Role<ROLE_Authority )
		ServerFire;
	reliable if( Role==ROLE_Authority )
		ClientAnim;
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
	if( !Wants(0) && !Wants(1) )
		return;
	SetAnimAction('Claw');
	bShotAnim = true;
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
}
simulated function RawInput( float DeltaTime, float aBaseX, float aBaseY, float aBaseZ, float aMouseX, float aMouseY,
	float aForward, float aTurn, float aStrafe, float aUp, float aLookUp )
{
	class'VSZed'.static.LockInput(PlayerController(Controller),MoveLock);
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

defaultproperties
{
     bSpecialCalcView=True
}
