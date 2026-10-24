//=============================================================================
// The blood a blade throws off as it goes into a body: one short dark spray along the swing, made on the
// machine of the one swinging it (KFMeleeFire.BladeSpray).
//=============================================================================
class KFBladeSpray extends xEmitter;

#exec OBJ LOAD File=KFX.utx

defaultproperties
{
     mRegen=False
     mStartParticles=10
     mMaxParticles=10
     mLifeRange(0)=0.500000
     mLifeRange(1)=0.800000
     mDirDev=(X=0.250000,Y=0.250000,Z=0.250000)
     mSpeedRange(0)=120.000000
     mSpeedRange(1)=250.000000
     mMassRange(0)=1.500000
     mMassRange(1)=2.500000
     mAirResistance=0.600000
     mRandOrient=True
     mSizeRange(0)=1.500000
     mSizeRange(1)=3.000000
     mGrowthRate=3.000000
     mColorRange(0)=(B=38,G=38,R=92)
     mColorRange(1)=(B=50,G=50,R=118)
     mRandTextures=True
     mNumTileColumns=4
     mNumTileRows=4
     LifeSpan=1.200000
     Skins(0)=Texture'KFX.BloodSplash'
     Style=STY_Alpha
     bUnlit=False
     RemoteRole=ROLE_None
}
