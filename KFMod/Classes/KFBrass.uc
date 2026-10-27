//=============================================================================
// KFBrass
// The casings a first-person gun throws out of its port (KFWeapon.EjectBrass): out to the right and up, tumbling, and
// gone out of the view within a second. Drawn with the gun, at its field of view, so in the gun's own (larger) scale:
// sizes, speeds and the fall are about five times the world's. Each gun keeps one, made on the shooter's machine.
//=============================================================================
class KFBrass extends Emitter;

#exec OBJ LOAD FILE=..\StaticMeshes\PatchStatics.usx

var bool	bReady;			// (a new Emitter loses what it throws before its first update)
var int		Pending;
var float	Size;
var float	LiveUntil;
var() vector	Throw;			// its throw in the gun's own terms: back, right, up
var() float		ThrowSpread;

// This gun's casing against a pistol's (once, after it is made)
simulated function SetSize( float S )
{
	Size = S;
	Emitters[0].StartSizeRange.X.Min *= Size;
	Emitters[0].StartSizeRange.X.Max *= Size;
	Emitters[0].StartSizeRange.Y.Min *= Size;
	Emitters[0].StartSizeRange.Y.Max *= Size;
	Emitters[0].StartSizeRange.Z.Min *= Size;
	Emitters[0].StartSizeRange.Z.Max *= Size;
}

// One casing out of Spot, the gun facing GunRot (an Emitter throws in the world's terms, so the throw is turned to
// the gun's each time)
simulated function Eject( vector Spot, rotator GunRot )
{
	local vector V;

	SetLocation(Spot);
	SetRotation(GunRot);
	V = Throw >> GunRot;
	Emitters[0].StartVelocityRange.X.Min = V.X - ThrowSpread;
	Emitters[0].StartVelocityRange.X.Max = V.X + ThrowSpread;
	Emitters[0].StartVelocityRange.Y.Min = V.Y - ThrowSpread;
	Emitters[0].StartVelocityRange.Y.Max = V.Y + ThrowSpread;
	Emitters[0].StartVelocityRange.Z.Min = V.Z - ThrowSpread;
	Emitters[0].StartVelocityRange.Z.Max = V.Z + ThrowSpread;
	LiveUntil = Level.TimeSeconds + Emitters[0].LifetimeRange.Max + 0.1;
	if ( bReady )
		Emitters[0].SpawnParticle(1);
	else
		Pending++;
}

simulated function bool IsLive()
{
	return Level.TimeSeconds < LiveUntil;
}

simulated function Tick( float DT )
{
	Super.Tick(DT);
	if ( !bReady )
	{
		bReady = true;
		return;
	}
	if ( Pending > 0 )
	{
		Emitters[0].SpawnParticle(Pending);
		Pending = 0;
	}
}

defaultproperties
{
	Begin Object Class=MeshEmitter Name=BrassCasing
		StaticMesh=StaticMesh'PatchStatics.NormalCasing'
		UseMeshBlendMode=False
		UseParticleColor=True
		DrawStyle=PTDS_Regular
		ColorMultiplierRange=(X=(Min=0.550000,Max=0.650000),Y=(Min=0.550000,Max=0.650000),Z=(Min=0.550000,Max=0.650000))
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		SpinParticles=True
		UniformSize=True
		Acceleration=(Z=-2600.000000)
		MaxParticles=8
		StartSpinRange=(X=(Max=1.000000),Y=(Max=1.000000),Z=(Max=1.000000))
		SpinsPerSecondRange=(X=(Min=1.500000,Max=3.500000),Y=(Min=2.000000,Max=5.000000),Z=(Min=1.000000,Max=3.000000))
		StartSizeRange=(X=(Min=0.820000,Max=0.900000),Y=(Min=0.820000,Max=0.900000),Z=(Min=0.820000,Max=0.900000))
		LifetimeRange=(Min=0.550000,Max=0.700000)
	End Object
	Emitters(0)=MeshEmitter'KFMod.KFBrass.BrassCasing'
	Throw=(X=-40.000000,Y=260.000000,Z=280.000000)
	ThrowSpread=50.000000

	bNoDelete=False
	bHidden=True
	RemoteRole=ROLE_None
	bUnlit=True
}
