//=============================================================================
// The blood that pumps out of the neck of a specimen that has lost its head and
// not yet dropped: a thin dark spurt now and then. Each machine drawing the
// specimen makes its own.
//=============================================================================
class KFNeckJet extends KFBloodJet;

// (no pool on the floor when it starts: what falls is the trail the body leaves)
simulated function PostNetBeginPlay()
{
	SetTimer(LifeSpan - 1.0, false);
	Super(xEmitter).PostNetBeginPlay();
}

defaultproperties
{
     mRegenOnTime(0)=0.150000
     mRegenOnTime(1)=0.300000
     mRegenOffTime(0)=0.500000
     mRegenOffTime(1)=1.000000
     mMaxParticles=24
     mLifeRange(0)=0.600000
     mLifeRange(1)=0.800000
     mRegenRange(0)=26.000000
     mRegenRange(1)=26.000000
     mDirDev=(X=0.100000,Y=0.100000,Z=0.100000)
     mSpeedRange(0)=30.000000
     mSpeedRange(1)=55.000000
     mMassRange(0)=1.500000
     mMassRange(1)=2.500000
     mSizeRange(0)=1.500000
     mSizeRange(1)=2.800000
     mGrowthRate=6.000000
     mColorRange(0)=(B=38,G=38,R=92)
     mColorRange(1)=(B=50,G=50,R=118)
     LifeSpan=8.000000
     RemoteRole=ROLE_None
}
