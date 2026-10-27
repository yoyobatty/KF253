//=============================================================================
// KFBrassShell
// A pump shotgun's spent shell out of its port (KFBrass)
//=============================================================================
class KFBrassShell extends KFBrass;

defaultproperties
{
	Begin Object Class=MeshEmitter Name=BrassShell
		StaticMesh=StaticMesh'PatchStatics.ShottyCasing'
		UseMeshBlendMode=False
		UseParticleColor=True
		DrawStyle=PTDS_Regular
		ColorMultiplierRange=(X=(Min=0.550000,Max=0.650000),Y=(Min=0.550000,Max=0.650000),Z=(Min=0.550000,Max=0.650000))
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		SpinParticles=True
		UniformSize=True
		Acceleration=(Z=-2600.000000)
		MaxParticles=4
		StartSpinRange=(X=(Max=1.000000),Y=(Max=1.000000),Z=(Max=1.000000))
		SpinsPerSecondRange=(X=(Min=1.000000,Max=2.500000),Y=(Min=1.500000,Max=3.000000),Z=(Min=0.500000,Max=2.000000))
		StartSizeRange=(X=(Min=0.850000,Max=0.900000),Y=(Min=0.850000,Max=0.900000),Z=(Min=0.850000,Max=0.900000))
		LifetimeRange=(Min=0.650000,Max=0.750000)
	End Object
	Emitters(0)=MeshEmitter'KFMod.KFBrassShell.BrassShell'
	Throw=(X=-20.000000,Y=150.000000,Z=500.000000)
	ThrowSpread=40.000000
}
