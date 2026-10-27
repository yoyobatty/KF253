//=============================================================================
// KFRoundTracer
// A round's tracer: a hot thin core inside a soft glow, both drawn along their flight. Its calibre's length, width
// and colour (Dress) set it apart; the attachment sends each round down the line to where it struck
// (KFWeaponAttachment.AddHitFX). A miss close by still whizzes past the one it missed (KFNewTracer).
//=============================================================================
class KFRoundTracer extends KFNewTracer;

var() float	CoreLen, CoreWidth;	// the core's length at the attachment's tracer speed, and width
var() float	GlowLen, GlowWidth;	// ...and the glow's
var() color	CoreTint, GlowTint;
var() float	RefSpeed;			// the speed the lengths are made for (KFWeaponAttachment.mTracerSpeed)

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	Dress(0, CoreLen, CoreWidth, CoreTint);
	Dress(1, GlowLen, GlowWidth, GlowTint);
}

// A layer's length is its size times its speed times ScaleSizeByVelocityMultiplier
simulated function Dress( int i, float Len, float Width, color Tint )
{
	if ( i >= Emitters.Length )
		return;
	Emitters[i].StartSizeRange.X.Min = Len / (RefSpeed * Emitters[i].ScaleSizeByVelocityMultiplier.X);
	Emitters[i].StartSizeRange.X.Max = Emitters[i].StartSizeRange.X.Min;
	Emitters[i].StartSizeRange.Y.Min = Width;
	Emitters[i].StartSizeRange.Y.Max = Width;
	Emitters[i].ColorMultiplierRange.X.Min = Tint.R / 255.0;
	Emitters[i].ColorMultiplierRange.X.Max = Tint.R / 255.0;
	Emitters[i].ColorMultiplierRange.Y.Min = Tint.G / 255.0;
	Emitters[i].ColorMultiplierRange.Y.Max = Tint.G / 255.0;
	Emitters[i].ColorMultiplierRange.Z.Min = Tint.B / 255.0;
	Emitters[i].ColorMultiplierRange.Z.Max = Tint.B / 255.0;
}

defaultproperties
{
	CoreLen=60.000000
	CoreWidth=1.400000
	GlowLen=90.000000
	GlowWidth=5.000000
	CoreTint=(B=200,G=240,R=255)
	GlowTint=(B=40,G=110,R=200)
	RefSpeed=7500.000000

	Begin Object Class=SpriteEmitter Name=RoundCore
		UseDirectionAs=PTDU_Right
		RespawnDeadParticles=False
		UseAbsoluteTimeForSizeScale=True
		UseRegularSizeScale=False
		ScaleSizeXByVelocity=True
		AutomaticInitialSpawning=False
		ExtentMultiplier=(X=0.200000)
		MaxParticles=100
		StartSizeRange=(X=(Min=8.000000,Max=8.000000),Y=(Min=1.400000,Max=1.400000))
		ScaleSizeByVelocityMultiplier=(X=0.001000)
		DrawStyle=PTDS_Brighten
		Texture=Texture'AW-2004Particles.Weapons.TracerShot'
		LifetimeRange=(Min=0.100000,Max=0.100000)
		StartVelocityRange=(X=(Min=10000.000000,Max=10000.000000))
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFRoundTracer.RoundCore'

	Begin Object Class=SpriteEmitter Name=RoundGlow
		UseDirectionAs=PTDU_Right
		RespawnDeadParticles=False
		UseAbsoluteTimeForSizeScale=True
		UseRegularSizeScale=False
		ScaleSizeXByVelocity=True
		AutomaticInitialSpawning=False
		ExtentMultiplier=(X=0.200000)
		MaxParticles=100
		StartSizeRange=(X=(Min=12.000000,Max=12.000000),Y=(Min=5.000000,Max=5.000000))
		ScaleSizeByVelocityMultiplier=(X=0.001000)
		DrawStyle=PTDS_Brighten
		Texture=Texture'AW-2004Particles.Weapons.TracerShot'
		LifetimeRange=(Min=0.100000,Max=0.100000)
		StartVelocityRange=(X=(Min=10000.000000,Max=10000.000000))
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFRoundTracer.RoundGlow'
}
