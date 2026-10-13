//=============================================================================
// The blood off a heavy hit: more of it than a KFBloodPuff, thrown further, and
// spatters beside the mark it leaves on what is behind.
//=============================================================================
class KFBloodPuffHeavy extends KFBloodPuff;

var() int ExtraSplats;				// spatters beside the main mark
var() float SplatRange;				// how far behind the body a surface is marked
var() float SplatSpread, SplatDrop;	// the spatters: scatter about the line of the hit, and lean toward the floor
var() class<Actor> ExtraDecalClass;
var() bool bBigExtra;				// the first spatter is a full stain
var() bool bAlongSelf;				// marks what is ahead of it, not what is behind it from its owner

simulated function WallSplat()
{
	local vector WallHit, WallNormal, Dir;
	local Actor WallActor;
	local class<Actor> C;
	local int i;

	if ( Level.bDropDetail || BloodDecalClass == None )
		return;
	if ( HitDir == vect(0,0,0) )
	{
		if ( bAlongSelf )
			HitDir = vector(Rotation);
		else if ( Owner != None )
			HitDir = Location - Owner.Location;
		else
			HitDir.Z = -1;
	}
	HitDir = Normal(HitDir);

	WallActor = Trace(WallHit, WallNormal, Location + SplatRange * HitDir, Location, false);
	if ( WallActor != None )
		Spawn(BloodDecalClass,,, WallHit + 20 * (WallNormal + VRand()), rotator(-WallNormal));
	for ( i=0; i<ExtraSplats; i++ )
	{
		Dir = Normal(HitDir + SplatSpread * VRand() - SplatDrop * FRand() * vect(0,0,1));
		WallActor = Trace(WallHit, WallNormal, Location + SplatRange * Dir, Location, false);
		if ( WallActor == None )
			continue;
		C = ExtraDecalClass;
		if ( i == 0 && bBigExtra )
			C = class'KFBloodSplatterDecal';
		Spawn(C,,, WallHit + 20 * WallNormal, rotator(-WallNormal));
	}
}

defaultproperties
{
     ExtraSplats=2
     SplatRange=450.000000
     SplatSpread=0.300000
     SplatDrop=0.700000
     ExtraDecalClass=Class'KFMod.KFBloodDrip'
     mStartParticles=11
     mMaxParticles=11
     mLifeRange(0)=0.600000
     mLifeRange(1)=0.900000
     mPosDev=(X=5.000000,Y=5.000000,Z=5.000000)
     mSpeedRange(0)=15.000000
     mSpeedRange(1)=45.000000
     mSizeRange(0)=13.000000
     mSizeRange(1)=18.000000
     mGrowthRate=60.000000
}
