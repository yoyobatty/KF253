//=============================================================================
// KFFlameStreamEnd
// Where the flamethrower's stream (KFFlameStream) gets to: a splash of fire spreading over what it strikes, or where
// it burns out in the air, the last of it slowing, swelling and rising in a billow.
//=============================================================================
class KFFlameStreamEnd extends Emitter;

const E_SPLASH	= 0;
const E_SPRAY	= 1;
const E_BILLOW	= 2;
const E_BSOOT	= 3;

var bool	bHot;			// an upgraded flamethrower's (SetHot)

var float	SplashRate, SprayRate, BillowRate, BillowSootRate;
var byte	Mode;	// 0 nothing, 1 splash, 2 billow
var float	Scale;	// the splash's size: smaller where the stream strikes close in front of the shooter's own eyes

// (an emitter whose particles have all died with no rate is no longer ticked: woken here)
// An upgraded flamethrower's: blue (KFFlameStream.SetHot), the soot as it is
simulated function SetHot( bool bHotter )
{
	local int i;

	if ( bHot == bHotter )
		return;
	bHot = bHotter;
	for ( i = 0; i < Emitters.Length; i++ )
		if ( i != E_BSOOT )
			class'KFFlameStream'.static.BlueFlame(Emitters[i], default.Emitters[i], bHot);
}

simulated function Rate( int i, float PPS )
{
	Emitters[i].ParticlesPerSecond = PPS;
	Emitters[i].InitialParticlesPerSecond = PPS;
	if ( PPS > 0 )
		Emitters[i].AllParticlesDead = false;
}

simulated function SetScale( float K )
{
	if ( Abs(K - Scale) < 0.05 )
		return;
	Scale = K;
	Emitters[E_SPLASH].StartSizeRange.X.Min = default.Emitters[E_SPLASH].StartSizeRange.X.Min * K;
	Emitters[E_SPLASH].StartSizeRange.X.Max = default.Emitters[E_SPLASH].StartSizeRange.X.Max * K;
	Emitters[E_SPLASH].StartVelocityRange.Y.Min = default.Emitters[E_SPLASH].StartVelocityRange.Y.Min * K;
	Emitters[E_SPLASH].StartVelocityRange.Y.Max = default.Emitters[E_SPLASH].StartVelocityRange.Y.Max * K;
	Emitters[E_SPLASH].StartVelocityRange.Z.Min = default.Emitters[E_SPLASH].StartVelocityRange.Z.Min * K;
	Emitters[E_SPLASH].StartVelocityRange.Z.Max = default.Emitters[E_SPLASH].StartVelocityRange.Z.Max * K;
	if ( Mode == 1 )
		Rate(E_SPLASH, SplashRate * (0.4 + 0.6 * Scale));
}

simulated function Show( vector Spot, vector Normal, rotator Aim, bool bHit, optional float Dist, optional bool bFromEyes )
{
	if ( bHit )
	{
		if ( bFromEyes )
			SetScale(FClamp(Dist / 600.0, 0.3, 1.0));
		else
			SetScale(1.0);
		SetLocation(Spot + Normal * 4);
		SetRotation(rotator(Normal));
		if ( Mode != 1 )
		{
			Mode = 1;
			Rate(E_SPLASH, SplashRate * (0.4 + 0.6 * Scale));
			Rate(E_SPRAY, SprayRate);
			Rate(E_BILLOW, 0);
			Rate(E_BSOOT, 0);
		}
	}
	else
	{
		SetLocation(Spot);
		SetRotation(Aim);
		if ( Mode != 2 )
		{
			Mode = 2;
			Rate(E_SPLASH, 0);
			Rate(E_SPRAY, 0);
			Rate(E_BILLOW, BillowRate);
			Rate(E_BSOOT, BillowSootRate);
		}
	}
}

simulated function Hide()
{
	if ( Mode == 0 )
		return;
	Mode = 0;
	Rate(E_SPLASH, 0);
	Rate(E_SPRAY, 0);
	Rate(E_BILLOW, 0);
	Rate(E_BSOOT, 0);
}

defaultproperties
{
	SplashRate=45.000000
	Scale=1.000000
	SprayRate=20.000000
	BillowRate=26.000000
	BillowSootRate=6.000000

	Begin Object Class=SpriteEmitter Name=EndSplash
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseRandomSubdivision=True
		UseCollision=True
		ExtentMultiplier=(X=0.300000,Y=0.300000,Z=0.300000)
		DampingFactorRange=(X=(Min=0.200000,Max=0.400000),Y=(Min=0.200000,Max=0.400000),Z=(Min=0.200000,Max=0.400000))
		UseRotationFrom=PTRS_Actor
		Acceleration=(Z=150.000000)
		ColorScale(0)=(Color=(B=200,G=240,R=255))
		ColorScale(1)=(RelativeTime=0.250000,Color=(B=100,G=190,R=255))
		ColorScale(2)=(RelativeTime=0.600000,Color=(B=35,G=110,R=240))
		ColorScale(3)=(RelativeTime=0.850000,Color=(B=6,G=20,R=70))
		ColorScale(4)=(RelativeTime=1.000000)
		ColorMultiplierRange=(Y=(Min=0.900000,Max=1.000000),Z=(Min=0.800000,Max=1.000000))
		MaxParticles=26
		SpinsPerSecondRange=(X=(Min=-0.400000,Max=0.400000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.500000)
		SizeScale(1)=(RelativeTime=0.400000,RelativeSize=1.600000)
		SizeScale(2)=(RelativeTime=1.000000,RelativeSize=2.400000)
		StartSizeRange=(X=(Min=22.000000,Max=34.000000))
		Texture=Texture'EmitterTextures.MultiFrame.LargeFlames'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		LifetimeRange=(Min=0.300000,Max=0.500000)
		StartVelocityRange=(X=(Min=30.000000,Max=120.000000),Y=(Min=-420.000000,Max=420.000000),Z=(Min=-420.000000,Max=420.000000))
		VelocityLossRange=(X=(Min=3.500000,Max=3.500000),Y=(Min=3.500000,Max=3.500000),Z=(Min=3.500000,Max=3.500000))
		SecondsBeforeInactive=0.000000
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFFlameStreamEnd.EndSplash'

	Begin Object Class=SpriteEmitter Name=EndSpray
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		UniformSize=True
		UseCollision=True
		UseMaxCollisions=True
		MaxCollisions=(Min=2.000000,Max=2.000000)
		DampingFactorRange=(X=(Min=0.300000,Max=0.500000),Y=(Min=0.300000,Max=0.500000),Z=(Min=0.300000,Max=0.500000))
		UseRotationFrom=PTRS_Actor
		Acceleration=(Z=-1100.000000)
		ColorScale(0)=(Color=(B=150,G=225,R=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=10,G=60,R=200))
		MaxParticles=14
		StartSizeRange=(X=(Min=2.500000,Max=4.500000))
		Texture=Texture'EmitterTextures.Flares.EFlareOY'
		LifetimeRange=(Min=0.300000,Max=0.600000)
		StartVelocityRange=(X=(Min=150.000000,Max=400.000000),Y=(Min=-300.000000,Max=300.000000),Z=(Min=-300.000000,Max=300.000000))
		DetailMode=DM_High
		SecondsBeforeInactive=0.000000
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFFlameStreamEnd.EndSpray'

	Begin Object Class=SpriteEmitter Name=EndBillow
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseRandomSubdivision=True
		UseCollision=True
		ExtentMultiplier=(X=0.300000,Y=0.300000,Z=0.300000)
		DampingFactorRange=(X=(Min=0.200000,Max=0.300000),Y=(Min=0.200000,Max=0.300000),Z=(Min=0.200000,Max=0.300000))
		UseRotationFrom=PTRS_Actor
		Acceleration=(Z=180.000000)
		ColorScale(0)=(Color=(B=140,G=215,R=255))
		ColorScale(1)=(RelativeTime=0.300000,Color=(B=55,G=140,R=255))
		ColorScale(2)=(RelativeTime=0.700000,Color=(B=15,G=50,R=170))
		ColorScale(3)=(RelativeTime=0.900000,Color=(B=4,G=12,R=40))
		ColorScale(4)=(RelativeTime=1.000000)
		ColorMultiplierRange=(Y=(Min=0.850000,Max=1.000000),Z=(Min=0.700000,Max=1.000000))
		MaxParticles=22
		SpinsPerSecondRange=(X=(Min=-0.300000,Max=0.300000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.800000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.000000)
		StartSizeRange=(X=(Min=55.000000,Max=80.000000))
		Texture=Texture'EmitterTextures.MultiFrame.LargeFlames'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		LifetimeRange=(Min=0.450000,Max=0.750000)
		StartVelocityRange=(X=(Min=180.000000,Max=380.000000),Y=(Min=-160.000000,Max=160.000000),Z=(Min=0.000000,Max=120.000000))
		VelocityLossRange=(X=(Min=1.800000,Max=1.800000),Y=(Min=1.800000,Max=1.800000),Z=(Min=1.800000,Max=1.800000))
		SecondsBeforeInactive=0.000000
	End Object
	Emitters(2)=SpriteEmitter'KFMod.KFFlameStreamEnd.EndBillow'

	Begin Object Class=SpriteEmitter Name=EndBillowSoot
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		FadeOut=True
		FadeIn=True
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseRandomSubdivision=True
		UseRotationFrom=PTRS_Actor
		Acceleration=(Z=60.000000)
		ColorScale(0)=(Color=(B=34,G=36,R=40,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=56,G=58,R=60,A=255))
		Opacity=0.300000
		FadeOutStartTime=0.800000
		FadeInEndTime=0.350000
		MaxParticles=10
		SpinsPerSecondRange=(X=(Min=-0.050000,Max=0.050000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.600000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.400000)
		StartSizeRange=(X=(Min=60.000000,Max=80.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'AW-2004Particles.Fire.MuchSmoke1'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		LifetimeRange=(Min=1.200000,Max=1.600000)
		StartVelocityRange=(X=(Min=100.000000,Max=250.000000),Y=(Min=-60.000000,Max=60.000000),Z=(Min=60.000000,Max=140.000000))
		VelocityLossRange=(X=(Min=1.200000,Max=1.200000),Y=(Min=1.200000,Max=1.200000),Z=(Min=0.600000,Max=0.600000))
		DetailMode=DM_High
		SecondsBeforeInactive=0.000000
	End Object
	Emitters(3)=SpriteEmitter'KFMod.KFFlameStreamEnd.EndBillowSoot'

	bNoDelete=False
	bNotOnDedServer=True
}
