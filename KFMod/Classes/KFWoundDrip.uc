//=============================================================================
// KFWoundDrip
// After a heavy blow, a few dark drops fall from the wound for a short while, staying with the body as it moves
// (KFBloodPuff.Tick). Made on each drawing machine.
//=============================================================================
class KFWoundDrip extends Emitter;

var Pawn	Victim;
var vector	Offset;			// (the wound, in the body's own terms)
var float	StopAt;
var() float	DripTime;

simulated function Follow( Pawn P, vector Spot )
{
	Victim = P;
	Offset = (Spot - P.Location) << P.Rotation;
	StopAt = Level.TimeSeconds + DripTime * (0.8 + 0.4 * FRand());
	SetLocation(Spot);
}

simulated function Tick( float DT )
{
	if ( Victim == None || Victim.bDeleteMe || Level.TimeSeconds > StopAt )
	{
		Disable('Tick');
		Kill();
		return;
	}
	SetLocation(Victim.Location + (Offset >> Victim.Rotation));
}

defaultproperties
{
	DripTime=2.500000

	Begin Object Class=SpriteEmitter Name=WoundDrops
		UseDirectionAs=PTDU_Up
		FadeOut=True
		FadeOutStartTime=0.400000
		ScaleSizeYByVelocity=True
		AutomaticInitialSpawning=False
		Acceleration=(Z=-950.000000)
		ColorMultiplierRange=(X=(Min=0.550000,Max=0.700000),Y=(Min=0.500000,Max=0.600000),Z=(Min=0.500000,Max=0.600000))
		MaxParticles=12
		ParticlesPerSecond=4.000000
		InitialParticlesPerSecond=4.000000
		StartLocationRange=(X=(Min=-2.000000,Max=2.000000),Y=(Min=-2.000000,Max=2.000000))
		StartSizeRange=(X=(Min=4.500000,Max=6.500000),Y=(Min=4.500000,Max=6.500000))
		ScaleSizeByVelocityMultiplier=(Y=0.003000)
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'KFX.BloodDrops'
		LifetimeRange=(Min=0.500000,Max=0.700000)
		StartVelocityRange=(X=(Min=-10.000000,Max=10.000000),Y=(Min=-10.000000,Max=10.000000),Z=(Min=-30.000000,Max=0.000000))
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFWoundDrip.WoundDrops'

	bNoDelete=False
	RemoteRole=ROLE_None
	LifeSpan=6.000000
}
