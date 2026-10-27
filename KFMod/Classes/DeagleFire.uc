//=============================================================================
// Deagle Fire
// The bullet goes on through up to four bodies past the first, its damage halved after each, as retail Killing
// Floor's Deagle does (KFFire.PenetratingTrace). Walls stop it.
//=============================================================================
class DeagleFire extends KFFire;

defaultproperties
{
	MechSound=Sound'KFWeaponSound.DeagleCock'
	MechVolume=0.280000
	MechPitch=1.500000
     FlashFXClass=Class'KFMod.KFFlashDeagle'
    MaxPenetrations=4
    PenDamageScale=0.500000
    DamageType=Class'KFMod.DamTypeDeagle'
    DamageMin=115
    DamageMax=125
    Momentum=10000.000000
    bPawnRapidFireAnim=True
    bAttachSmokeEmitter=True
    bWaitForRelease=True
    TransientSoundVolume=100.000000
    FireLoopAnim=
    FireEndAnim=
    FireAnimRate=0.900000
    FireSound=Sound'KFWeaponSound.50CalFire'
    AmmoClass=Class'KFMod.DeagleAmmo'
    AmmoPerFire=1
    ShakeRotMag=(X=90.000000,Y=90.000000,Z=90.000000)
    ShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
    ShakeRotTime=2.000000
    ShakeOffsetMag=(X=19.000000,Y=19.000000,Z=19.000000)
    ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
    ShakeOffsetTime=2.000000
    BotRefireRate=0.800000
    FireRate=0.400000
    FlashEmitterClass=None
    aimerror=0.000000
    SpreadStyle=SS_Random
}
