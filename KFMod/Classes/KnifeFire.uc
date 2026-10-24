// Knife Fire //

class KnifeFire extends KFMeleeFire;

// A slash to the left, one back to the right, then a harder backhand
defaultproperties
{
     WeaponRange=65.000000
     bSweep=True
     Swings(0)=(Anim="Fire",From=0.020000,To=0.110000,StartYaw=30.000000,StartPitch=4.000000,EndYaw=-30.000000,EndPitch=-4.000000,Across=20.000000,DamageScale=1.000000,BodyAnim="KnifeAttack",BodyFrom=0.380000,BodyTo=0.620000)
     Swings(1)=(Anim="Fire2",From=0.015000,To=0.125000,StartYaw=-30.000000,StartPitch=10.000000,EndYaw=30.000000,EndPitch=-10.000000,Across=20.000000,DamageScale=1.000000,BodyAnim="KnifeAttack2",BodyFrom=0.400000,BodyTo=0.620000)
     Swings(2)=(Anim="fire3",From=0.200000,To=0.315000,StartYaw=-32.000000,StartPitch=-2.000000,EndYaw=28.000000,EndPitch=-8.000000,Across=20.000000,DamageScale=1.500000,BodyAnim="KnifeStab2",BodyFrom=0.360000,BodyTo=0.520000,Lunge=6.000000)
     HitPunch=40.000000
     CamSway=2.500000
     damageConst=40
     maxAdditionalDamage=15
     DamagedelayMin=0.100000
     DamagedelayMax=0.300000
     hitDamageClass=Class'KFMod.DamTypeKnife'
     WideDamageMinHitAngle=0.750000
     FireRate=0.600000
     BotRefireRate=0.900000
}
