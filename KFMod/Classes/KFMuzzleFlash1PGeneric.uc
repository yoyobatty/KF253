class KFMuzzleFlash1PGeneric extends xEmitter;

#exec OBJ LOAD FILE=xGameShaders.utx

var int mNumPerFlash;

simulated function Trigger(Actor Other, Pawn EventInstigator)
{
    mStartParticles += mNumPerFlash;
}

defaultproperties
{
<<<<<<< HEAD
	mNumPerFlash=5
	mParticleType=PT_Mesh
	mStartParticles=0
	mMaxParticles=5
	mLifeRange(0)=0.090000
	mLifeRange(1)=0.120000
	mRegenRange(0)=0.000000
	mRegenRange(1)=0.000000
	mSpawnVecB=(Z=0.000000)
	mSpeedRange(0)=0.000000
	mSpeedRange(1)=0.000000
	mPosRelative=True
	mAirResistance=0.000000
	mSizeRange(0)=0.050000
	mSizeRange(1)=0.080000
	mGrowthRate=5.000000
	mRandTextures=True
	mTileAnimation=True
	mMeshNodes(0)=StaticMesh'PatchStatics.KFMuzzSM'
	DrawScale=0.900000
	Skins(0)=FinalBlend'PatchTex.Common.MuzzFB'
	Style=STY_Translucent
=======
     mNumPerFlash=5
     mParticleType=PT_Mesh
     mStartParticles=0
     mMaxParticles=5
     mLifeRange(0)=0.090000
     mLifeRange(1)=0.120000
     mRegenRange(0)=0.000000
     mRegenRange(1)=0.000000
     mSpawnVecB=(Z=0.000000)
     mSpeedRange(0)=0.000000
     mSpeedRange(1)=0.000000
     mPosRelative=True
     mAirResistance=0.000000
     mSizeRange(0)=0.050000
     mSizeRange(1)=0.080000
     mGrowthRate=5.000000
     mRandTextures=True
     mTileAnimation=True
     mMeshNodes(0)=StaticMesh'PatchStatics.KFMuzzSM'
     DrawScale=0.900000
     Skins(0)=FinalBlend'PatchTex.Common.MuzzFB'
     Style=STY_Translucent
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
