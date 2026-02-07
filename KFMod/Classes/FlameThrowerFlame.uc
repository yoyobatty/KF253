// Less ugly than the UT2k4 one, anyway :)

class FlameThrowerFlame extends HitFlame;

var float LastFlameSpawnTime;
var () float FlameSpawnInterval;

var Emitter SecondaryFlame;

state Ticking
{
    simulated function Tick( float dt )
    {
        if( LifeSpan < 2.0 )
        {
            mRegenRange[0] *= LifeSpan * 0.5;
            mRegenRange[1] = mRegenRange[0];
            SoundVolume = byte(float(SoundVolume) * (LifeSpan * 0.5));
        }
        
        if (Level.TimeSeconds - LastFlameSpawnTime > FlameSpawnInterval)
        {
          SecondaryFlame =  Spawn(class'FlameThrowerFlameB',self);
        }
        

    }
}

defaultproperties
{
<<<<<<< HEAD
	FlameSpawnInterval=0.500000
	mParticleType=PT_Stream
	mLifeRange(0)=1.000000
	mLifeRange(1)=1.500000
	mRegenRange(0)=60.000000
	mRegenRange(1)=60.000000
	mMassRange(0)=0.500000
	mMassRange(1)=1.000000
	mSizeRange(0)=4.000000
	mSizeRange(1)=8.000000
	mGrowthRate=-52.000000
	mAttenKa=0.000000
	mAttenKb=0.000000
	mRandTextures=True
	mAttraction=100.000000
	Physics=PHYS_Trailer
	AmbientSound=Sound'PatchSounds.OnFire'
	Skins(0)=Texture'KFX.KFFlames'
	Style=STY_Additive
	SoundVolume=255
	TransientSoundVolume=0.000000
	TransientSoundRadius=50.000000
	bNotOnDedServer=False
=======
     FlameSpawnInterval=0.500000
     mParticleType=PT_Stream
     mLifeRange(0)=1.000000
     mLifeRange(1)=1.500000
     mRegenRange(0)=60.000000
     mRegenRange(1)=60.000000
     mMassRange(0)=0.500000
     mMassRange(1)=1.000000
     mSizeRange(0)=4.000000
     mSizeRange(1)=8.000000
     mGrowthRate=-52.000000
     mAttenKa=0.000000
     mAttenKb=0.000000
     mRandTextures=True
     mAttraction=100.000000
     Physics=PHYS_Trailer
     AmbientSound=Sound'PatchSounds.OnFire'
     Skins(0)=Texture'KFX.KFFlames'
     Style=STY_Additive
     SoundVolume=255
     TransientSoundVolume=0.000000
     TransientSoundRadius=50.000000
     bNotOnDedServer=False
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
