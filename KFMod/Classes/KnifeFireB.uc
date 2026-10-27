// Knife Stab //
class KnifeFireB extends KFMeleeFire;

// Down from above
defaultproperties
{
     bSweep=True
     Swings(0)=(Anim="Stab",From=0.360000,To=0.470000,StartYaw=0.000000,StartPitch=28.000000,EndYaw=0.000000,EndPitch=-22.000000,Across=8.000000,DamageScale=1.000000,BodyAnim="KnifeStab",BodyFrom=0.460000,BodyTo=0.620000,Lunge=5.000000)
     HitPunch=60.000000
     HitPause=0.012000
     CamSway=2.500000
     damageConst=50
     maxAdditionalDamage=20
     DamagedelayMin=0.500000
     DamagedelayMax=0.500000
     hitDamageClass=Class'KFMod.DamTypeKnife'
     WideDamageMinHitAngle=0.700000
     FireAnim="Stab"
     FireRate=1.100000
     BotRefireRate=1.100000
}
