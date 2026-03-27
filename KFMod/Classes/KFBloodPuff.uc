//=============================================================================
// KF Blood Spray (normal shot effect)
//=============================================================================
class KFBloodPuff extends BloodSmallHit;

#exec OBJ LOAD File=KFX.utx

defaultproperties
{
<<<<<<< HEAD
	BloodDecalClass=Class'KFMod.KFBloodSplatterDecal'
	Splats(0)=Texture'KFX.BloodSplat1'
	Splats(1)=Texture'KFX.BloodSplat2'
	Splats(2)=Texture'KFX.BloodSplat3'
	mMaxParticles=6
	mLifeRange(1)=0.700000
	mDirDev=(X=0.000000,Y=15.000000,Z=10.000000)
	mPosDev=(X=0.000000,Y=0.000000,Z=0.000000)
	mSpeedRange(0)=2.000000
	mSpeedRange(1)=4.000000
	mMassRange(0)=1.000000
	mMassRange(1)=2.000000
	mRandOrient=False
	mSpinRange(0)=50.000000
	mSpinRange(1)=100.000000
	mSizeRange(1)=10.000000
	mGrowthRate=45.000000
	mNumTileColumns=4
	mNumTileRows=4
	Skins(0)=Texture'KFX.BloodySpray'
	Style=STY_Modulated
=======
     BloodDecalClass=Class'KFMod.KFBloodSplatterDecal'
     Splats(0)=Texture'KFX.BloodSplat1'
     Splats(1)=Texture'KFX.BloodSplat2'
     Splats(2)=Texture'KFX.BloodSplat3'
     mMaxParticles=6
     mLifeRange(1)=0.700000
     mDirDev=(X=0.000000,Y=15.000000,Z=10.000000)
     mPosDev=(X=0.000000,Y=0.000000,Z=0.000000)
     mSpeedRange(0)=2.000000
     mSpeedRange(1)=4.000000
     mMassRange(0)=1.000000
     mMassRange(1)=2.000000
     mRandOrient=False
     mSpinRange(0)=50.000000
     mSpinRange(1)=100.000000
     mSizeRange(1)=10.000000
     mGrowthRate=45.000000
     mNumTileColumns=4
     mNumTileRows=4
     Skins(0)=Texture'KFX.BloodySpray'
     Style=STY_Modulated
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
