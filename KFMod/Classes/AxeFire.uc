// Axe Fire //
class AxeFire extends KFMeleeFire;

// Down from the right shoulder, with the width of a two-handed swing
defaultproperties
{
     bSweep=True
     Swings(0)=(Anim="Fire",From=0.650000,To=0.790000,StartYaw=14.000000,StartPitch=38.000000,EndYaw=-8.000000,EndPitch=-26.000000,Across=36.000000,DamageScale=1.000000)
     HitPunch=150.000000
     HitPause=0.070000
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
}
