//=============================================================================
// RevolverFire
// The magnum revolver's shot: heavier than the Deagle's, slower, with more kick, through more bodies.
//=============================================================================
class RevolverFire extends DeagleFire;

defaultproperties
{
     DamageType=Class'KFMod.DamTypeRevolver'
     DamageMin=165
     DamageMax=185
     MaxPenetrations=5
     PenDamageScale=0.600000
     Momentum=16000.000000
     FireRate=0.500000
     FireAnimRate=1.000000
     AmmoClass=Class'KFMod.RevolverAmmo'
     ShakeRotMag=(X=130.000000,Y=130.000000,Z=130.000000)
     ShakeOffsetMag=(X=26.000000,Y=26.000000,Z=26.000000)
}
