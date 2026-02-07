class LAWFireSmoke extends pclLightSmoke;

state Ticking
{
    simulated function Tick( float dt )
    {
        if( LifeSpan < 1.0 )
        {
            mRegenRange[0] *= LifeSpan;
            mRegenRange[1] = mRegenRange[0];
        }
    }
}

simulated function timer()
{
    GotoState('Ticking');
}

simulated function PostNetBeginPlay()
{
    SetTimer(LifeSpan - 1.0,false);
    if ( Level.NetMode != NM_DedicatedServer )
    Super.PostNetBeginPlay();
}

defaultproperties
{
<<<<<<< HEAD
	mRegen=False
	mStartParticles=100
	mMaxParticles=60
	mSizeRange(0)=60.000000
	mSizeRange(1)=76.000000
	mColorRange(0)=(B=5,G=5,R=5,A=225)
	mColorRange(1)=(B=5,G=5,R=5,A=225)
	LifeSpan=5.000000
=======
     mRegen=False
     mStartParticles=100
     mMaxParticles=60
     mSizeRange(0)=60.000000
     mSizeRange(1)=76.000000
     mColorRange(0)=(B=5,G=5,R=5,A=225)
     mColorRange(1)=(B=5,G=5,R=5,A=225)
     LifeSpan=5.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
