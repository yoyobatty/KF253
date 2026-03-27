class BullpupAttachment extends KFWeaponAttachment;

defaultproperties
{
     mMuzFlashClass=Class'KFMod.KFNormal3PMuzzFlash'
     mTracerClass=Class'KFMod.KFNewTracer'
     mTracerIntervalPrimary=0.110000
     mTracerIntervalSecondary=0.140000
     mShellCaseEmitterClass=Class'KFMod.KFShellSpewer'
     TPAnims(0)="BullpupFire"
     WeaponIdleMovementAnim="BullpupIdle"
     bRapidFire=True
     bAltRapidFire=True
     SplashEffect=Class'XGame.BulletSplash'
     CullDistance=5000.000000
     Mesh=SkeletalMesh'KFWeaponModels.L853P'
}
