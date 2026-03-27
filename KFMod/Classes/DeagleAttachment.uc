class DeagleAttachment extends KFWeaponAttachment;

defaultproperties
{
     mMuzFlashClass=Class'KFMod.KFNormal3PMuzzFlash'
     mTracerClass=Class'KFMod.KFLargeTracer'
     mTracerIntervalPrimary=0.110000
     mTracerIntervalSecondary=0.140000
     mShellCaseEmitterClass=Class'KFMod.KFShellSpewer'
     HitEffectType=Class'KFMod.KFHitEffectLarge'
     TPAnims(0)="DeagleBlast"
     WeaponIdleMovementAnim="DeagleHold"
     bHeavy=True
     SplashEffect=Class'XGame.BulletSplash'
     CullDistance=5000.000000
     Mesh=SkeletalMesh'KFWeaponModels.Deagle3P'
}
