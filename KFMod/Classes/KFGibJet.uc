//=============================================================================
// KF GibJet.      This streaks after bits of flesh. Yum.
//=============================================================================
class KFGibJet extends BloodJet;

defaultproperties
{
	mGrowthRate=2.000000
	mNumTileRows=4
	mNumTileColumns=4
	mMassRange(1)=2.500000
	mMassRange(0)=1.500000
	mSizeRange(1)=2.000000
	mSizeRange(0)=1.100000
	mRegenRange(1)=16.000000
	mRegenRange(0)=16.000000
     SplatterClass=Class'KFMod.KFBloodSplat'
     mMaxParticles=20
     mLifeRange(0)=0.800000
     mLifeRange(1)=1.200000
     mColorRange(0)=(B=38,G=38,R=92)
     mColorRange(1)=(B=50,G=50,R=118)
     Skins(0)=Texture'KFX.BloodSplash'
     Style=STY_Alpha
     bUnlit=False
}
