// Bat Fire //

class BatFire extends KFMeleeFire;

// Down from the shoulder, then across from the left
defaultproperties
{
     MeleeKind=2
     WeaponRange=80.000000
     bSweep=True
     Swings(0)=(Anim="Fire",From=0.400000,To=0.490000,StartYaw=8.000000,StartPitch=34.000000,EndYaw=-4.000000,EndPitch=-24.000000,Across=20.000000,DamageScale=1.000000,BodyAnim="BatAttack",BodyFrom=0.310000,BodyTo=0.470000,Lunge=8.000000)
     Swings(1)=(Anim="Fire2",From=0.360000,To=0.490000,StartYaw=-36.000000,StartPitch=6.000000,EndYaw=34.000000,EndPitch=-6.000000,Across=20.000000,DamageScale=1.000000,BodyAnim="BatAttack2",BodyFrom=0.330000,BodyTo=0.520000,Lunge=3.000000)
     HitPunch=90.000000
     HitPause=0.018000
     CamSway=3.500000
     damageConst=80
     maxAdditionalDamage=25
     ProxySize=0.120000
     DamagedelayMin=0.500000
     DamagedelayMax=0.500000
     hitDamageClass=Class'KFMod.DamTypeBat'
     WideDamageMinHitAngle=0.750000
     FireRate=0.710000
     BotRefireRate=0.850000
}
