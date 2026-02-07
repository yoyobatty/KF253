//=============================================================================
// THIS IS     MAH     BOOMSTICK!
//=============================================================================
class BoomStickSuperBullet extends BoomStickBullet;

simulated function PostBeginPlay()
{
     local int RandProperty;
     Super.PostBeginPlay();
     RandProperty = Rand(3);
     if ( RandProperty == 0 )
          MyDamageType = Class'KFMod.DamTypeFlamethrower';
     else if ( RandProperty == 1 )
          MyDamageType = Class'KFMod.DamTypeDBShotgun';
     else
          MyDamageType = Class'KFMod.DamTypeFrag';
}

defaultproperties
{
     MaxPenetrations=100
     PenDamageReductionPerked=1.000000
     PenDamageReduction=1.000000
     Damage=100.000000
     //MyDamageType=Class'KFMod.DamTypeFrag'
}
