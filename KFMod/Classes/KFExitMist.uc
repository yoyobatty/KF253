//=============================================================================
// KFExitMist
// The small dark mist a round leaves out of the far side of a body (KFMonster.ExitMist): less than a heavy hit's
// burst (KFBloodBurst), and it marks nothing.
//=============================================================================
class KFExitMist extends KFBloodPuffHeavy;

defaultproperties
{
	bFXDrip=False
	bFXHeavy=False
	bFXAlong=True
	FXSize=0.700000
	ExtraSplats=0
	bAlongSelf=True
	BloodDecalClass=None
	mStartParticles=4
	mMaxParticles=4
	mLifeRange(0)=0.300000
	mLifeRange(1)=0.500000
	mDirDev=(X=0.250000,Y=0.250000,Z=0.250000)
	mPosDev=(X=3.000000,Y=3.000000,Z=3.000000)
	mSpeedRange(0)=50.000000
	mSpeedRange(1)=140.000000
	mMassRange(0)=0.400000
	mMassRange(1)=0.800000
	mSizeRange(0)=6.000000
	mSizeRange(1)=11.000000
	mGrowthRate=34.000000
}
