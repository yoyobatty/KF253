//=============================================================================
// Tracer Bullet
//=============================================================================
class KFTracer extends pclSmoke;

defaultproperties
{
     mParticleType=PT_Stream
     mStartParticles=0
     mMaxParticles=40
     mLifeRange(0)=0.100000
     mLifeRange(1)=0.100000
     mRegenRange(0)=60.000000
     mRegenRange(1)=60.000000
     mSpawnVecB=(X=20.000000,Z=0.000000)
     mSizeRange(0)=1.500000
     mSizeRange(1)=2.000000
     mGrowthRate=-0.500000
     mColorRange(0)=(B=90,G=180,R=255,A=130)
     mColorRange(1)=(B=60,G=150,R=240,A=130)
     mNumTileColumns=1
     mNumTileRows=1
     Physics=PHYS_Trailer
     LifeSpan=2.900000
     Skins(0)=Texture'KFX.TransTrailT'
}
