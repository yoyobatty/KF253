//=============================================================================
// FlameChucker
//=============================================================================
class FlameThrower extends KFWeapon;

// The nozzle glows while it fires, and with its heat: hot after about six seconds of fire, cooling from four seconds after
var float Heat, ColdFor, LastFlame;
var float GlowR, GlowG, GlowB;		// the glow shown, eased towards what it should be
var Shader GlowShader;				// FTFireShader's look with its glow coloured by GlowColor
var ConstantColor GlowColor;

// Where the nozzle is drawn in first person, on the scene's view (KFFlameStream starts there)
var vector DrawnNozzle;
var float DrawnNozzleTime;

simulated function IncrementFlashCount(int Mode)
{
	Super.IncrementFlashCount(Mode);
	LastFlame = Level.TimeSeconds;
}

simulated event RenderOverlays( Canvas Canvas )
{
	local PlayerController PC;

	Super.RenderOverlays(Canvas);
	if ( Instigator == None )
		return;
	PC = PlayerController(Instigator.Controller);
	if ( PC == None )
		return;
	DrawnNozzle = class'KFFlameStream'.static.OnSceneView(GetBoneCoords('tip').Origin, PC.CalcViewLocation, PC.CalcViewRotation, DisplayFOV, PC.FovAngle, 32.0);
	DrawnNozzleTime = Level.TimeSeconds;
}

// Hot metal: dull red, then orange, then yellow
static function HeatColour( float H, out float R, out float G, out float B )
{
	local float T;

	if ( H < 0.35 )
	{
		T = H / 0.35;
		R = 120 * T;
		G = 25 * T;
		B = 5 * T;
	}
	else if ( H < 0.75 )
	{
		T = (H - 0.35) / 0.4;
		R = 120 + 135 * T;
		G = 25 + 85 * T;
		B = 5 + 20 * T;
	}
	else
	{
		T = (H - 0.75) / 0.25;
		R = 255;
		G = 110 + 90 * T;
		B = 25 + 95 * T;
	}
}

simulated function WeaponTick(float dt)
{
	local bool bFiring;
	local float R, G, B, Lit, Ease;

	Super.WeaponTick(dt);
	if ( Level.NetMode == NM_DedicatedServer || Instigator == None || !Instigator.IsLocallyControlled() )
		return;

	bFiring = Level.TimeSeconds - LastFlame < 0.2;
	if ( bFiring )
	{
		Heat = FMin(1.0, Heat + dt / 6.0);
		ColdFor = 0;
	}
	else
	{
		ColdFor += dt;
		if ( ColdFor > 4.0 )
			Heat = FMax(0.0, Heat - dt / 10.0);
	}
	if ( Instigator.HeadVolume != None && Instigator.HeadVolume.bWaterVolume )
		Heat = FMax(0.0, Heat - dt * 5.0);

	HeatColour(Heat, R, G, B);
	if ( bFiring )
	{
		Lit = 0.8 + 0.2 * Heat;
		R = FMax(R, 255 * Lit);
		G = FMax(G, 225 * Lit);
		B = FMax(B, 190 * Lit);
		Ease = FMin(1.0, dt * 12.0);
	}
	else
		Ease = FMin(1.0, dt * 4.0);
	GlowR += (R - GlowR) * Ease;
	GlowG += (G - GlowG) * Ease;
	GlowB += (B - GlowB) * Ease;
	ShowGlow();
}

simulated function ShowGlow()
{
	local Combiner Mix;
	local Shader Look;

	if ( GlowR + GlowG + GlowB < 3.0 )
	{
		if ( Skins[4] != default.Skins[4] )
			Skins[4] = default.Skins[4];
		return;
	}
	if ( GlowShader == None )
	{
		Look = Shader(default.Skins[4]);
		GlowColor = new(None) class'ConstantColor';
		Mix = new(None) class'Combiner';
		Mix.CombineOperation = CO_Multiply;
		Mix.Material1 = Texture'KillingFloorWeapons.FlameThrower.FTIllumMask';
		Mix.Material2 = GlowColor;
		GlowShader = new(None) class'Shader';
		GlowShader.Diffuse = Look.Diffuse;
		GlowShader.Specular = Look.Specular;
		GlowShader.SpecularityMask = Look.SpecularityMask;
		GlowShader.SelfIllumination = Mix;
		GlowShader.SelfIlluminationMask = Texture'KillingFloorWeapons.FlameThrower.FTIllumMask';
	}
	GlowColor.Color.R = byte(FClamp(GlowR, 0, 255));
	GlowColor.Color.G = byte(FClamp(GlowG, 0, 255));
	GlowColor.Color.B = byte(FClamp(GlowB, 0, 255));
	GlowColor.Color.A = 255;
	Skins[4] = GlowShader;
}

function bool RecommendRangedAttack()
{
	return true;
}

function float SuggestAttackStyle()
{
	return -1.0;
}

defaultproperties
{
	ClipCount=100
	ReloadRate=4.140000
	ReloadAnim="Reload"
	ReloadAnimRate=1.000000
	//MinimumFireRange=100
	bSteadyAim=True
	UpKick=250
	FireModeClass(0)=Class'KFMod.FlameBurstFire'
	FireModeClass(1)=Class'KFMod.NoFire'
	PutDownAnim="PutDown"
	PutDownAnimRate=1.000000
	PutDownTime=1.000000
	SelectSound=Sound'KFPlayerSound.getweaponout'
	AIRating=0.700000
	CurrentRating=0.700000
	OldCenteredOffsetY=0.000000
	OldPlayerViewOffset=(X=-8.000000,Y=5.000000,Z=-6.000000)
	OldSmallViewOffset=(X=4.000000,Y=11.000000,Z=-12.000000)
	OldPlayerViewPivot=(Pitch=400)
	OldCenteredRoll=3000
	Description="A deadly experimental weapon designed by Horzine industries. It can fire streams of burning liquid which ignite on contact."
	EffectOffset=(X=100.000000,Y=25.000000,Z=-10.000000)
	DisplayFOV=80.000000
	Priority=4
	SmallViewOffset=(X=24.000000,Y=20.000000,Z=-20.000000)
	CenteredOffsetY=-5.000000
	CenteredRoll=3000
	CenteredYaw=-1500
	InventoryGroup=3
	GroupOffset=4
	PickupClass=Class'KFMod.FlameThrowerPickup'
	PlayerViewOffset=(X=4.000000,Y=5.500000,Z=-10.000000)
	BobDamping=4.000000
	AttachmentClass=Class'KFMod.FlameThrowerAttachment'
	IconCoords=(X1=245,Y1=39,X2=329,Y2=79)
	ItemName="FlameThrower"
	Mesh=SkeletalMesh'KFWeaponModels.FlameThrower'
	DrawScale=0.900000
	Skins(0)=Texture'KillingFloorWeapons.Deagle.HandSkinNew'
	Skins(1)=Texture'KillingFloorWeapons.Deagle.ArmSkinNew'
	Skins(2)=Shader'KillingFloorWeapons.Welder.FlameShader'
	Skins(3)=Shader'KillingFloorWeapons.FlameThrower.PilotBloomShader'
	Skins(4)=Shader'KillingFloorWeapons.FlameThrower.FlameThrowerShader'
	TransientSoundVolume=1.250000
}
