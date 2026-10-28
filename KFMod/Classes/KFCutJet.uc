//=============================================================================
// Blood pumping out of a fresh cut (KFTrauma): the neck of a head split open or taken off at the top, both halves of a
// body cut in two. A few hard spurts that weaken and stop, dark red. Each machine drawing the body makes its own.
//=============================================================================
class KFCutJet extends KFNeckJet;

defaultproperties
{
     mRegenOnTime(0)=0.250000
     mRegenOnTime(1)=0.450000
     mRegenOffTime(0)=0.250000
     mRegenOffTime(1)=0.500000
     mMaxParticles=40
     mLifeRange(0)=0.700000
     mLifeRange(1)=1.000000
     mRegenRange(0)=55.000000
     mRegenRange(1)=55.000000
     mDirDev=(X=0.200000,Y=0.200000,Z=0.200000)
     mSpeedRange(0)=60.000000
     mSpeedRange(1)=130.000000
     mSizeRange(0)=2.000000
     mSizeRange(1)=3.600000
     LifeSpan=3.200000
}
