class BullpupAttachment extends KFWeaponAttachment;

defaultproperties
{
     TracerEvery=3
     mMuzFlashClass=Class'KFMod.KFFlashRifle'
     mTracerClass=Class'KFMod.KFRoundAuto'
     mShellCaseEmitterClass=Class'KFMod.KFShellSpewer'
     TPAnims(0)="BullpupFire"
     WeaponIdleMovementAnim="BullpupIdle"
     bRapidFire=True
     bAltRapidFire=True
     SplashEffect=Class'XGame.BulletSplash'
     CullDistance=5000.000000
     Mesh=SkeletalMesh'KFWeaponModels.L853P'
     SmokeHeat=0.035000
}
