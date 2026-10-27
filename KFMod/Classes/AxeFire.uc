// Axe Fire //
class AxeFire extends KFMeleeFire;

// Down from the right shoulder, with the width of a two-handed swing; then flat across from the right
defaultproperties
{
     MeleeKind=1
     bSweep=True
     Swings(0)=(Anim="Fire",From=0.650000,To=0.790000,StartYaw=14.000000,StartPitch=38.000000,EndYaw=-8.000000,EndPitch=-26.000000,Across=36.000000,DamageScale=1.000000,BodyAnim="AxeAttack",BodyFrom=0.560000,BodyTo=0.720000,Lunge=10.000000)
     Swings(1)=(Anim="Fire2",From=0.650000,To=0.780000,StartYaw=40.000000,StartPitch=14.000000,EndYaw=-40.000000,EndPitch=-2.000000,Across=24.000000,DamageScale=1.000000,BodyAnim="AxeAttack",BodyFrom=0.560000,BodyTo=0.720000,Lunge=4.000000)
     ChainTime=1.500000
     HitPunch=150.000000
     HitPause=0.025000
     CamSway=4.000000
     damageConst=175
     maxAdditionalDamage=50
     ProxySize=0.150000
     weaponRange=100.000000
     DamagedelayMin=0.800000
     DamagedelayMax=0.800000
     hitDamageClass=Class'KFMod.DamTypeAxe'
     WideDamageMinHitAngle=0.500000
     FireRate=1.100000
     BotRefireRate=0.850000
     UpgradeSideDamageScale=1.000000
}
