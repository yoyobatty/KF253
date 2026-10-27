//=============================================================================
// KFFuelPool
// Fuel lying on the floor in a cell of the fire grid (KFFireGrid): its stain (KFFuelStain) on each machine that draws
// it, as big as the fuel (Amount, sent from the server).
//=============================================================================
class KFFuelPool extends Actor;

var byte		Amount;			// tenths of a second of burning
var byte		ShownAmount;
var KFFuelStain	Stain;
var int			StainRoll;

replication
{
	reliable if ( Role == ROLE_Authority )
		Amount;
}

// (the server)
function SetAmount( float Fuel )
{
	local byte A;

	A = byte(FClamp(Fuel * 10.0, 1.0, 255.0));
	if ( Abs(int(A) - int(Amount)) >= 4 || Amount == 0 )
		Amount = A;
}

simulated function Tick( float DT )
{
	if ( Level.NetMode == NM_DedicatedServer || Amount == 0 )
		return;
	if ( Stain == None || Abs(int(Amount) - int(ShownAmount)) >= 12 )
		Restain();
}

simulated function Restain()
{
	local rotator R;

	ShownAmount = Amount;
	if ( Stain != None )
		Stain.Destroy();
	if ( StainRoll == 0 )
		StainRoll = 1 + Rand(65535);
	R = Rotation;
	R.Roll = StainRoll;
	Stain = Spawn(class'KFFuelStain', self,, Location - vector(Rotation) * 24, R);
	if ( Stain == None )
		return;
	Stain.DetachProjector();
	Stain.SetDrawScale(0.62 + 0.06 * FMin(float(Amount) / 10.0, 8.0));
	Stain.AttachProjector();
}

simulated function Destroyed()
{
	if ( Stain != None )
		Stain.Destroy();
	Super.Destroyed();
}

defaultproperties
{
     DrawType=DT_None
     bHidden=False
     RemoteRole=ROLE_SimulatedProxy
     NetUpdateFrequency=2.000000
     bCollideActors=False
     bBlockActors=False
}
