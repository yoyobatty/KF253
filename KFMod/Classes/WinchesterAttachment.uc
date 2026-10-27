class WinchesterAttachment extends KFWeaponAttachment;

defaultproperties
{
     mMuzFlashClass=Class'KFMod.KFFlashWinchester'
     mTracerClass=Class'KFMod.KFRoundRifle'
     HitEffectType=Class'KFMod.KFHitEffectLarge' //it's a powerful round, why shouldn't it be a big boy?
     TPAnims(0)="WinchFire"
     WeaponIdleMovementAnim="WinchIdle"
     bHeavy=True
     SplashEffect=Class'XGame.BulletSplash'
     CullDistance=5000.000000
     Mesh=SkeletalMesh'KFWeaponModels.Winchester3P'
     DrawScale=0.300000
     SmokeHeat=0.120000
}
