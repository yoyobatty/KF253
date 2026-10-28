//=============================================================================
// KFNoBloodHit - a round going into a body with no gore at all (Gore Level None, KFGoreLevel; the gib groups' no-blood
// hit and emit, which must be xEmitters): a faint grey puff of dust off it, no blood and no stain.
//=============================================================================
class KFNoBloodHit extends KFBloodPuff;

defaultproperties
{
	FXSize=0.000000
     BloodDecalClass=None
     mMaxParticles=2
     mLifeRange(0)=0.400000
     mLifeRange(1)=0.600000
     mSizeRange(0)=5.000000
     mSizeRange(1)=8.000000
     mGrowthRate=16.000000
     mNumTileColumns=1
     mNumTileRows=1
     mColorRange(0)=(B=96,G=102,R=108,A=255)
     mColorRange(1)=(B=80,G=86,R=92,A=255)
     Skins(0)=Texture'AW-2004Particles.Weapons.DustSmoke'
     Style=STY_Alpha
}
