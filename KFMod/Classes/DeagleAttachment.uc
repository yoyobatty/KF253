class DeagleAttachment extends KFWeaponAttachment;

defaultproperties
{
     mMuzFlashClass=Class'KFMod.KFFlashDeagle'
     mTracerClass=Class'KFMod.KFRoundHeavy'
     mShellCaseEmitterClass=Class'KFMod.KFShellSpewer'
     HitEffectType=Class'KFMod.KFHitEffectLarge'
     TPAnims(0)="DeagleBlast"
     WeaponIdleMovementAnim="DeagleHold"
     bHeavy=True
     SplashEffect=Class'XGame.BulletSplash'
     CullDistance=5000.000000
     Mesh=SkeletalMesh'KFWeaponModels.Deagle3P'
     SmokeHeat=0.120000
}
