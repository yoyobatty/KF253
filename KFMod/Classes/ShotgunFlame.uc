// Less ugly than the UT2k4 one, anyway :)

class ShotgunFlame extends HitFlame;

state Ticking
{
    simulated function Tick( float dt )
    {
        if( LifeSpan < 2.0 )
        {
            //mRegenRange[0] *= LifeSpan * 0.5;
            //mRegenRange[1] = mRegenRange[0];
            SoundVolume = byte(float(SoundVolume) * (LifeSpan * 0.5));
            //SetDrawScale(DrawScale / (dt * 2));
        }
    }
}

defaultproperties
{
     mParticleType=PT_Stream
     mSpawningType=ST_Explode
     mLifeRange(0)=1.400000
     mLifeRange(1)=1.500000
     mRegenRange(0)=60.000000
     mRegenRange(1)=60.000000
     mMassRange(0)=0.500000
     mMassRange(1)=1.000000
     mSizeRange(0)=4.000000
     mSizeRange(1)=8.000000
     mGrowthRate=-50.000000
     mRandTextures=True
     mAttraction=100.000000
     Physics=PHYS_Trailer
     AmbientSound=Sound'PatchSounds.OnFire'
     LifeSpan=0.150000
     DrawScale=0.400000
     Skins(0)=Texture'KFX.KFFlames'
     Style=STY_Additive
     SoundVolume=255
     TransientSoundVolume=0.000000
     TransientSoundRadius=50.000000
     bNotOnDedServer=False
}
