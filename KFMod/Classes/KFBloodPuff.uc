//=============================================================================
// KF Blood Spray (normal shot effect)
//=============================================================================
class KFBloodPuff extends BloodSmallHit;

var() float	FXSize;			// the blood it throws (KFBloodFX), against a plain hit's; 0: none
var() bool	bFXAlong;		// thrown on along the hit (out of the far side), not back the way it came
var() bool	bFXHeavy;		// with a heavy blow's spatter
var() bool	bFXDrip;		// and the wound drips a while after (KFWoundDrip)
var bool	bFXDone;

#exec OBJ LOAD File=KFX.utx

// The blood, in its first update: by then the server has set HitDir, and a client has it from the server
simulated function Tick( float DT )
{
	local KFBloodFX FX;
	local KFWoundDrip Drip;
	local KFMonster M, Best;
	local KFBloodFX Other;
	local PlayerController PC;
	local vector D;
	local int Near;

	if ( bFXDone )
	{
		Disable('Tick');
		return;
	}
	bFXDone = true;
	if ( Level.NetMode == NM_DedicatedServer || FXSize <= 0.0 || class'GameInfo'.static.UseLowGore() )
		return;
	D = HitDir;
	if ( VSize(D) < 0.1 )
		D = vector(Rotation);
	else if ( !bFXAlong )
		D = -D;
	// (a burst of pellets, or of rounds, into one spot: the first's mist serves for all, the rest throw a few drops)
	foreach DynamicActors(class'KFBloodFX', Other)
		if ( Other.LifeSpan > Other.default.LifeSpan - 0.12 && VSize(Other.Location - Location) < 90.0 )
			Near++;
	if ( Near >= 6 )
		return;
	FX = Spawn(class'KFBloodFX',,, Location, rotator(D));
	if ( FX != None )
	{
		FX.Dir = Normal(D);
		FX.Size = FXSize;
		if ( !bMustShow )
			FX.Size *= 0.75;
		FX.bHeavy = bFXHeavy && Near == 0;
		if ( Near > 0 )
		{
			FX.Size *= 0.5;
			FX.bNoMist = true;
		}
		// (at arm's length a mist thrown back fills the view of the one who struck: only a few drops)
		PC = Level.GetLocalPlayerController();
		if ( PC != None && PC.ViewTarget != None && VSize(PC.ViewTarget.Location - Location) < 150.0 && !bFXAlong )
		{
			FX.Size *= 0.6;
			FX.bNoMist = true;
			FX.bHeavy = false;
		}
	}
	if ( bFXDrip && !Level.bDropDetail )
	{
		foreach CollidingActors(class'KFMonster', M, 80.0, Location)
			if ( M.Health > 0 && (Best == None || VSize(M.Location - Location) < VSize(Best.Location - Location)) )
				Best = M;
		if ( Best != None )
		{
			Drip = Spawn(class'KFWoundDrip',,, Location);
			if ( Drip != None )
				Drip.Follow(Best, Location);
		}
	}
}

defaultproperties
{
	bNetTemporary=True
	bOnlyRelevantToOwner=False
	FXSize=1.000000
     BloodDecalClass=Class'KFMod.KFBloodSplatterDecal'
     Splats(0)=Texture'KFX.BloodSplat1'
     Splats(1)=Texture'KFX.BloodSplat2'
     Splats(2)=Texture'KFX.BloodSplat3'
     mMaxParticles=3
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
}
