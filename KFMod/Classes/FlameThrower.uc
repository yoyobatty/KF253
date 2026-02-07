//=============================================================================
// FlameChucker
//=============================================================================
class FlameThrower extends KFWeapon;

// Cool Nozzle Illumination (WARNING -  Artist at play) :P

simulated function WeaponTick(float dt)
{
  Super.WeaponTick(dt);

  if(FireMode[0].bIsFiring)
    Skins[4] = Shader 'KillingFloorWeapons.FlameThrower.FTFireShader';
  else
    Skins[4] = default.Skins[4];
}

function bool RecommendRangedAttack()
{
	return true;
}

function float SuggestAttackStyle()
{
	return -1.0;
}

<<<<<<< HEAD
//TODO: LONG ranged?
function bool RecommendLongRangedAttack()
{
	return true;
}

defaultproperties
{
	ClipCount=100
	ReloadRate=4.140000
	ReloadAnim="Reload"
	ReloadAnimRate=1.000000
	MinimumFireRange=300
	bSteadyAim=True
	UpKick=200
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
	DisplayFOV=70.000000
	Priority=10
	SmallViewOffset=(X=24.000000,Y=20.000000,Z=-20.000000)
	CenteredOffsetY=-5.000000
	CenteredRoll=3000
	CenteredYaw=-1500
	CustomCrosshair=-1
	CustomCrossHairColor=(B=0,G=0,R=0,A=0)
	CustomCrossHairTextureName=
	InventoryGroup=3
	GroupOffset=4
	PickupClass=Class'KFMod.FlameThrowerPickup'
	PlayerViewOffset=(X=4.000000,Y=5.500000,Z=-10.000000)
	PlayerViewPivot=(Pitch=1500)
	BobDamping=6.000000
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
=======
/* 
function float GetAIRating()
{
	if (KFPawn(Instigator).GetVeteran().default.VeterancyName == "Firebug")
	{
    MinimumFireRange = 0; //fuck you bot for thinking you wanna shoot far away
	}	
  MinimumFireRange = default.MinimumFireRange;
	return AIRating;
}
*/
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
     DisplayFOV=65.000000
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
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
