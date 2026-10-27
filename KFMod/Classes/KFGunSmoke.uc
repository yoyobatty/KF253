//=============================================================================
// KFGunSmoke
// A gun's smoke, after Ballistic Weapons: each shot leaves a faint puff that hangs where the muzzle was (a long burst
// fills a room with it), and a hot barrel trails thin smoke from its muzzle once the shooting stops, on through a
// reload. The shots heat it (KFWeaponAttachment.SmokeHeat each) and it cools. It sits at the muzzle the viewer sees:
// the drawn first-person gun's for its shooter (KFWeapon.DrawnMuzzle), else the attachment's. Each machine has its own.
//=============================================================================
class KFGunSmoke extends Emitter;

var KFWeaponAttachment	Gun;
var float	Heat;
var float	LastShot;
var float	WispRate;
var bool	bKilled;
var() float	CoolRate;		// heat lost a second
var() float	MaxHeat;
var() float	WispStart;		// the heat the barrel smokes above
var() float	WispPerHeat;	// wisps a second for each unit of heat above that

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	Gun = KFWeaponAttachment(Owner);
}

// Shots fired since the last, each heating it by HeatPerShot; a bigger gun's puffs are bigger
simulated function Shot( int Count, float HeatPerShot )
{
	local float K;

	Heat = FMin(Heat + Count * HeatPerShot, MaxHeat);
	LastShot = Level.TimeSeconds;
	PlaceAtMuzzle();
	K = FMin(0.8 + 1.5 * HeatPerShot, 1.6);
	Emitters[0].StartSizeRange.X.Min = default.Emitters[0].StartSizeRange.X.Min * K;
	Emitters[0].StartSizeRange.X.Max = default.Emitters[0].StartSizeRange.X.Max * K;
	Emitters[0].SpawnParticle(Count);
}

simulated function PlaceAtMuzzle()
{
	local Pawn P;
	local KFWeapon W;

	P = Gun.Instigator;
	if ( P == None )
		return;
	W = KFWeapon(P.Weapon);
	if ( W != None && W.ThirdPersonActor == Gun && P.IsFirstPerson() && Level.TimeSeconds - W.DrawnMuzzleTime < 0.1 )
		SetLocation(W.DrawnMuzzle);
	else if ( Level.TimeSeconds - Gun.LastRenderTime < 0.5 )
		SetLocation(Gun.GetBoneCoords('tip').Origin);
	else
		SetLocation(P.Location + P.EyePosition());
	SetRotation(P.GetViewRotation());
}

simulated function Tick( float DT )
{
	local float R;

	if ( bKilled )
		return;
	if ( Gun == None || Gun.bDeleteMe )
	{
		GunGone();
		return;
	}
	Heat = FMax(0.0, Heat - DT * CoolRate);
	if ( Heat > WispStart && Level.TimeSeconds - LastShot > 0.25 && !Gun.bHidden )
	{
		PlaceAtMuzzle();
		R = WispPerHeat * (Heat - WispStart);
	}
	if ( R != WispRate )
	{
		WispRate = R;
		Emitters[1].ParticlesPerSecond = R;
		Emitters[1].InitialParticlesPerSecond = R;
		// (an emitter whose particles have all died with no rate is no longer ticked: woken here)
		if ( R > 0 )
			Emitters[1].AllParticlesDead = false;
	}
}

// Its gun is gone: what smoke there is drifts off, and then it goes
simulated function GunGone()
{
	bKilled = true;
	Kill();
}

defaultproperties
{
	CoolRate=0.120000
	MaxHeat=1.200000
	WispStart=0.180000
	WispPerHeat=40.000000

	Begin Object Class=SpriteEmitter Name=GunPuffs
		UseRotationFrom=PTRS_Actor
		UseColorScale=True
		FadeOut=True
		FadeIn=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseRandomSubdivision=True
		Acceleration=(Z=4.000000)
		ColorScale(0)=(Color=(B=112,G=108,R=105,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=96,G=93,R=90,A=255))
		Opacity=0.200000
		FadeOutStartTime=1.000000
		FadeInEndTime=0.150000
		MaxParticles=48
		SpinsPerSecondRange=(X=(Min=-0.060000,Max=0.060000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=1.000000)
		SizeScale(1)=(RelativeTime=0.200000,RelativeSize=3.000000)
		SizeScale(2)=(RelativeTime=1.000000,RelativeSize=5.000000)
		StartSizeRange=(X=(Min=3.000000,Max=4.500000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'AW-2004Particles.Fire.MuchSmoke1'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=3.000000,Max=4.000000)
		StartVelocityRange=(X=(Min=40.000000,Max=80.000000),Y=(Min=-10.000000,Max=10.000000),Z=(Min=-6.000000,Max=10.000000))
		VelocityLossRange=(X=(Min=1.500000,Max=2.000000),Y=(Min=1.500000,Max=2.000000),Z=(Min=1.500000,Max=2.000000))
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFGunSmoke.GunPuffs'

	Begin Object Class=SpriteEmitter Name=GunWisps
		UseColorScale=True
		FadeOut=True
		FadeIn=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseRandomSubdivision=True
		Acceleration=(Z=3.000000)
		ColorScale(0)=(Color=(B=212,G=210,R=208,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=172,G=170,R=168,A=255))
		Opacity=0.450000
		FadeOutStartTime=1.000000
		FadeInEndTime=0.150000
		MaxParticles=140
		SpinsPerSecondRange=(X=(Min=-0.150000,Max=0.150000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=1.000000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=4.000000)
		StartSizeRange=(X=(Min=1.200000,Max=1.800000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'AW-2004Particles.Weapons.DustSmoke'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=1.800000,Max=2.600000)
		StartVelocityRange=(X=(Min=-2.500000,Max=2.500000),Y=(Min=-2.500000,Max=2.500000),Z=(Min=6.000000,Max=11.000000))
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFGunSmoke.GunWisps'

	bNoDelete=False
}
