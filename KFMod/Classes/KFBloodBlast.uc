//=============================================================================
// KFBloodBlast
// A body blown apart bursts in one great wet explosion of blood: a dark spatter that pops out at once, a thick crimson
// cloud that bursts out and hangs, streams and globs of blood flung out in every way and falling, a fine spray, and a
// haze that lingers after. The blood lands on the walls and floor round it as it would arrive there, and on the
// screen of a player close in front, where it runs down and fades (HUDKillingFloor.AddScreenBlood). Made of the game's
// own blood pictures (KFX). Each drawing machine makes its own (Make), in its first update (what is thrown before an
// emitter's first update is lost); Size 1 is a clot blown apart.
//=============================================================================
class KFBloodBlast extends Emitter;

#exec OBJ LOAD FILE=KFX.utx
#exec OBJ LOAD FILE=PlayerSounds.uax
#exec OBJ LOAD FILE=KFPawnDamageSound.uax

var float	Size;
var vector	Dir;					// which way the blast throws it, if any
var bool	bThrown;
var() int	Counts[6];				// each layer's particles at Size 1
var() float	StainReach;				// how far its blood reaches the walls and floor, at Size 1
var() int	Stains;					// ...how many splashes, at Size 1
var() float	StainSpeed;				// ...how fast it gets there
var() float	ScreenReach;			// a player's eye this near, and the blast in front of it, gets blood on the screen
var() int	MaxBlasts;
var() float	CloseRange;				// a burst nearer the player's eye than this has less of its cloud and haze				// at most this many at once: past it the small are not made and the large are less
var array<vector>	StainAt, StainNormal;
var array<float>	StainTime;
var array<byte>		StainBig;

// A blast of blood of Size at Spot, thrown a little along Dir
static function KFBloodBlast Make( Actor Maker, vector Spot, float Size, optional vector Dir )
{
	local KFBloodBlast B;
	local int n;

	if ( Maker == None || Maker.Level.NetMode == NM_DedicatedServer || Size <= 0.0 || class'GameInfo'.static.UseLowGore() )
		return None;
	foreach Maker.DynamicActors(class'KFBloodBlast', B)
		n++;
	if ( n >= default.MaxBlasts )
	{
		if ( Size < 0.5 )
			return None;
		Size *= 0.6;
	}
	if ( Maker.Level.bDropDetail || Maker.Level.DetailMode == DM_Low )
		Size *= 0.7;
	B = Maker.Spawn(class'KFBloodBlast',,, Spot, rotator(vect(0,0,1)));
	if ( B == None )
		return None;
	B.Size = Size;
	B.Dir = Dir;
	return B;
}

simulated function Tick( float DT )
{
	local int i;

	if ( !bThrown )
	{
		bThrown = true;
		Throw();
	}
	// the blood reaches the walls and floor
	for ( i = StainTime.Length - 1; i >= 0; i-- )
		if ( Level.TimeSeconds >= StainTime[i] )
		{
			if ( StainBig[i] != 0 )
				Spawn(class'KFBloodBlastStain',,, StainAt[i] + StainNormal[i] * 20.0, rotator(-StainNormal[i]));
			else
				Spawn(class'KFBloodSplatterBig',,, StainAt[i] + StainNormal[i] * 20.0, rotator(-StainNormal[i]));
			StainAt.Remove(i, 1);
			StainNormal.Remove(i, 1);
			StainTime.Remove(i, 1);
			StainBig.Remove(i, 1);
		}
}

simulated function Throw()
{
	local int i, n;
	local float K, S, R, D, Near, CloseK;
	local vector V, HL, HN;
	local PlayerController PC;
	local vector Eye;

	// (a burst on top of the player is not drawn as a wall of mist in their face: the blood on the screen does that)
	PC = Level.GetLocalPlayerController();
	Near = 100000.0;
	if ( PC != None && PC.ViewTarget != None )
	{
		Eye = PC.ViewTarget.Location;
		if ( Pawn(PC.ViewTarget) != None )
			Eye += Pawn(PC.ViewTarget).EyePosition();
		Near = VSize(Location - Eye);
	}
	CloseK = FClamp(Near / CloseRange, 0.3, 1.0);

	K = Sqrt(FMax(Size, 0.1));
	S = Size ** 0.6;
	if ( VSize(Dir) > 0.1 )
		Dir = Normal(Dir);
	for ( i = 0; i < Emitters.Length && i < ArrayCount(Counts); i++ )
	{
		Emitters[i].StartSizeRange.X.Min *= S;
		Emitters[i].StartSizeRange.X.Max *= S;
		Emitters[i].StartSizeRange.Y.Min *= S;
		Emitters[i].StartSizeRange.Y.Max *= S;
		Emitters[i].StartVelocityRadialRange.Min *= K;
		Emitters[i].StartVelocityRadialRange.Max *= K;
		Emitters[i].StartVelocityRange.X.Min += Dir.X * 220.0 * K;
		Emitters[i].StartVelocityRange.X.Max += Dir.X * 220.0 * K;
		Emitters[i].StartVelocityRange.Y.Min += Dir.Y * 220.0 * K;
		Emitters[i].StartVelocityRange.Y.Max += Dir.Y * 220.0 * K;
		Emitters[i].StartVelocityRange.Z.Min += Dir.Z * 220.0 * K;
		Emitters[i].StartVelocityRange.Z.Max += Dir.Z * 220.0 * K;
		n = Min(int(Counts[i] * Size + FRand()), Emitters[i].MaxParticles);
		if ( i == 1 || i == 5 )
			n = int(n * CloseK + FRand());
		if ( n > 0 )
			Emitters[i].SpawnParticle(n);
	}

	// where it lands: a splash for each line out that meets a wall or the floor near enough, the near ones bigger,
	// and always one under it
	R = StainReach * K;
	n = Clamp(int(Stains * Size + 0.5), 2, 18);
	for ( i = 0; i < n; i++ )
	{
		if ( i == 0 )
			V = vect(0,0,-1);
		else
		{
			V = VRand();
			V.Z = 0.6 * V.Z - 0.3;
			V = Normal(V + Dir * 0.4);
		}
		if ( Trace(HL, HN, Location + V * R, Location, false) != None )
		{
			D = VSize(HL - Location);
			StainAt[StainAt.Length] = HL;
			StainNormal[StainNormal.Length] = HN;
			StainTime[StainTime.Length] = Level.TimeSeconds + D / (StainSpeed * K);
			if ( D < 0.5 * R || i == 0 )
				StainBig[StainBig.Length] = 1;
			else
				StainBig[StainBig.Length] = 0;
		}
	}

	PlaySound(Sound'PlayerSounds.NewGibs.NewGib1', SLOT_None, FMin(1.2 + Size, 3.0),, 1800, 0.95 - 0.12 * FMin(Size, 2.0));
	PlaySound(Sound'PlayerSounds.Final.Giblets3', SLOT_None, FMin(1.0 + Size, 2.5),, 1200, 0.8 + 0.2 * FRand());
	if ( Size >= 0.6 )
		PlaySound(Sound'KFPawnDamageSound.MeleeDamageSounds.axehitflesh', SLOT_None, FMin(1.5 * Size, 2.5),, 1400, 0.55);

	// blood on the screen of the player close in front
	if ( PC == None || PC.ViewTarget == None || HUDKillingFloor(PC.myHUD) == None )
		return;
	R = ScreenReach * K;
	if ( Near < R && (Normal(Location - Eye) dot vector(PC.GetViewRotation())) > 0.25 && FastTrace(Location, Eye) )
		HUDKillingFloor(PC.myHUD).AddScreenBlood((1.0 - Near / R) * FMin(Size, 1.6));
}

defaultproperties
{
	Counts(0)=9
	Counts(1)=12
	Counts(2)=70
	Counts(3)=26
	Counts(4)=26
	Counts(5)=5
	StainReach=230.000000
	Stains=10
	StainSpeed=700.000000
	ScreenReach=240.000000
	MaxBlasts=10
	CloseRange=170.000000

	// the spatter that pops out at once
	Begin Object Class=SpriteEmitter Name=BlastPop
		FadeOut=True
		FadeOutStartTime=0.060000
		RespawnDeadParticles=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		AutomaticInitialSpawning=False
		ColorMultiplierRange=(X=(Min=0.850000,Max=1.000000),Y=(Min=0.750000,Max=0.850000),Z=(Min=0.750000,Max=0.850000))
		MaxParticles=20
		StartLocationShape=PTLS_Sphere
		SphereRadiusRange=(Min=2.000000,Max=10.000000)
		StartSpinRange=(X=(Max=1.000000))
		SpinsPerSecondRange=(X=(Min=-0.300000,Max=0.300000))
		SizeScale(0)=(RelativeSize=0.500000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.200000)
		StartSizeRange=(X=(Min=30.000000,Max=80.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'KFX.BloodSplashHuge'
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=0.280000,Max=0.400000)
		StartVelocityRadialRange=(Min=60.000000,Max=140.000000)
		GetVelocityDirectionFrom=PTVD_AddRadial
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFBloodBlast.BlastPop'

	// the thick crimson cloud: bursts out, brakes and hangs
	Begin Object Class=SpriteEmitter Name=BlastCloud
		UseColorScale=True
		FadeOut=True
		FadeIn=True
		FadeOutStartTime=0.350000
		FadeInEndTime=0.040000
		RespawnDeadParticles=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		AutomaticInitialSpawning=False
		Acceleration=(Z=-35.000000)
		ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=255,R=255,A=255))
		ColorMultiplierRange=(X=(Min=0.450000,Max=0.800000),Y=(Min=0.250000,Max=0.420000),Z=(Min=0.250000,Max=0.420000))
		Opacity=0.800000
		MaxParticles=40
		StartLocationShape=PTLS_Sphere
		SphereRadiusRange=(Min=2.000000,Max=12.000000)
		StartSpinRange=(X=(Max=1.000000))
		SpinsPerSecondRange=(X=(Min=-0.120000,Max=0.120000))
		SizeScale(0)=(RelativeSize=1.000000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=3.400000)
		StartSizeRange=(X=(Min=22.000000,Max=50.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'KFX.KFBloodPuff'
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=0.900000,Max=1.400000)
		VelocityLossRange=(X=(Min=3.000000,Max=4.000000),Y=(Min=3.000000,Max=4.000000),Z=(Min=3.000000,Max=4.000000))
		StartVelocityRadialRange=(Min=260.000000,Max=520.000000)
		GetVelocityDirectionFrom=PTVD_AddRadial
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFBloodBlast.BlastCloud'

	// thick streams flung out every way and falling, drawn along their flight
	Begin Object Class=SpriteEmitter Name=BlastStreams
		UseDirectionAs=PTDU_Up
		FadeOut=True
		FadeOutStartTime=0.500000
		RespawnDeadParticles=False
		ScaleSizeYByVelocity=True
		AutomaticInitialSpawning=False
		Acceleration=(Z=-1000.000000)
		ColorMultiplierRange=(X=(Min=0.500000,Max=0.650000),Y=(Min=0.420000,Max=0.520000),Z=(Min=0.420000,Max=0.520000))
		MaxParticles=200
		StartLocationShape=PTLS_Sphere
		SphereRadiusRange=(Min=2.000000,Max=10.000000)
		StartSizeRange=(X=(Min=26.000000,Max=40.000000),Y=(Min=26.000000,Max=40.000000))
		ScaleSizeByVelocityMultiplier=(Y=0.004000)
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'KFX.BloodDrops'
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=0.650000,Max=1.000000)
		StartVelocityRange=(Z=(Min=120.000000,Max=320.000000))
		StartVelocityRadialRange=(Min=480.000000,Max=1100.000000)
		GetVelocityDirectionFrom=PTVD_AddRadial
	End Object
	Emitters(2)=SpriteEmitter'KFMod.KFBloodBlast.BlastStreams'

	// globs, tumbling as they arc and fall
	Begin Object Class=SpriteEmitter Name=BlastGlobs
		FadeOut=True
		FadeOutStartTime=0.750000
		RespawnDeadParticles=False
		SpinParticles=True
		UniformSize=True
		AutomaticInitialSpawning=False
		UseRandomSubdivision=True
		Acceleration=(Z=-950.000000)
		ColorMultiplierRange=(X=(Min=0.500000,Max=0.620000),Y=(Min=0.420000,Max=0.500000),Z=(Min=0.420000,Max=0.500000))
		MaxParticles=80
		StartLocationShape=PTLS_Sphere
		SphereRadiusRange=(Min=2.000000,Max=10.000000)
		StartSpinRange=(X=(Max=1.000000))
		SpinsPerSecondRange=(X=(Min=-2.000000,Max=2.000000))
		StartSizeRange=(X=(Min=14.000000,Max=26.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'KFX.BloodSplash'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=0.900000,Max=1.300000)
		StartVelocityRange=(Z=(Min=150.000000,Max=380.000000))
		StartVelocityRadialRange=(Min=260.000000,Max=650.000000)
		GetVelocityDirectionFrom=PTVD_AddRadial
	End Object
	Emitters(3)=SpriteEmitter'KFMod.KFBloodBlast.BlastGlobs'

	// a fine spray that shoots out and is gone
	Begin Object Class=SpriteEmitter Name=BlastSpray
		FadeOut=True
		FadeOutStartTime=0.080000
		RespawnDeadParticles=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		AutomaticInitialSpawning=False
		UseRandomSubdivision=True
		ColorMultiplierRange=(X=(Min=0.600000,Max=0.750000),Y=(Min=0.450000,Max=0.550000),Z=(Min=0.450000,Max=0.550000))
		MaxParticles=80
		StartLocationShape=PTLS_Sphere
		SphereRadiusRange=(Min=2.000000,Max=10.000000)
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.600000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.600000)
		StartSizeRange=(X=(Min=16.000000,Max=30.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'KFX.BloodySpray'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=0.220000,Max=0.380000)
		VelocityLossRange=(X=(Min=4.000000,Max=5.000000),Y=(Min=4.000000,Max=5.000000),Z=(Min=4.000000,Max=5.000000))
		StartVelocityRadialRange=(Min=650.000000,Max=1300.000000)
		GetVelocityDirectionFrom=PTVD_AddRadial
	End Object
	Emitters(4)=SpriteEmitter'KFMod.KFBloodBlast.BlastSpray'

	// the haze left hanging after
	Begin Object Class=SpriteEmitter Name=BlastHaze
		UseColorScale=True
		FadeOut=True
		FadeIn=True
		FadeOutStartTime=0.350000
		FadeInEndTime=0.250000
		RespawnDeadParticles=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		AutomaticInitialSpawning=False
		Acceleration=(Z=-8.000000)
		ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=255,R=255,A=255))
		ColorMultiplierRange=(X=(Min=0.400000,Max=0.500000),Y=(Min=0.220000,Max=0.280000),Z=(Min=0.220000,Max=0.280000))
		Opacity=0.450000
		MaxParticles=14
		StartLocationShape=PTLS_Sphere
		SphereRadiusRange=(Min=4.000000,Max=20.000000)
		StartSpinRange=(X=(Max=1.000000))
		SpinsPerSecondRange=(X=(Min=-0.040000,Max=0.040000))
		SizeScale(0)=(RelativeSize=1.000000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.200000)
		StartSizeRange=(X=(Min=70.000000,Max=110.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'KFX.KFBloodPuff'
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=2.400000,Max=3.200000)
		VelocityLossRange=(X=(Min=1.000000,Max=1.000000),Y=(Min=1.000000,Max=1.000000),Z=(Min=1.000000,Max=1.000000))
		StartVelocityRadialRange=(Min=40.000000,Max=90.000000)
		GetVelocityDirectionFrom=PTVD_AddRadial
	End Object
	Emitters(5)=SpriteEmitter'KFMod.KFBloodBlast.BlastHaze'

	bNoDelete=False
	RemoteRole=ROLE_None
	LifeSpan=4.000000
}
