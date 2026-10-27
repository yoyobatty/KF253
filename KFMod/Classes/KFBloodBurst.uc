//=============================================================================
// What a power weapon, or any one great blow, blows out of the far side of a body.
//=============================================================================
class KFBloodBurst extends KFBloodPuffHeavy;

defaultproperties
{
	bFXDrip=False
	bFXAlong=True
	FXSize=1.300000
     ExtraSplats=4
     SplatRange=650.000000
     SplatSpread=0.350000
     SplatDrop=0.900000
     bBigExtra=True
     bAlongSelf=True
     BloodDecalClass=Class'KFMod.KFBloodSplatterBig'
     mStartParticles=6
     mMaxParticles=6
     mLifeRange(0)=0.700000
     mLifeRange(1)=1.100000
     mDirDev=(X=0.300000,Y=0.300000,Z=0.300000)
     mPosDev=(X=6.000000,Y=6.000000,Z=6.000000)
     mSpeedRange(0)=60.000000
     mSpeedRange(1)=190.000000
     mMassRange(0)=0.600000
     mMassRange(1)=1.200000
     mSizeRange(0)=14.000000
     mSizeRange(1)=24.000000
     mGrowthRate=80.000000
}
