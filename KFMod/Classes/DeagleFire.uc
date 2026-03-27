//=============================================================================
// Deagle Fire
//=============================================================================
class DeagleFire extends KFFire;

var float ClickTime;

var() int					PenetrateForce;	// The penetrating power of these bullets.
var() bool					bPenetrate;		// Bullets can go though enemies
var() float					PDamageFactor;	// Damage multiplied by this with each penetration
var() float				WallPDamageFactor;	// Damage multiplied by this for each wall penetration

struct TraceInfo					// This holds info about a trace
{
	var() Vector 	Start, End, HitNormal, HitLocation, Extent;
	var() Actor		HitActor;
};

var() int						TraceCount;		// Number of fire traces to use

// Check if bullet should go through enemy
function bool CanPenetrate (Actor Other, vector HitLocation, vector Dir, int PenCount)
{
    local float Resistance;
    local actor TargetActor;
    local pawn TargetPawn;

    // If this is an ExtendedZCollision, operate on its Owner instead
    if ( Other != None && ExtendedZCollision(Other) != None && ExtendedZCollision(Other).Owner != None )
        TargetActor = ExtendedZCollision(Other).Owner;
    else
        TargetActor = Other;

    if (!bPenetrate || TargetActor == None || TargetActor.bWorldGeometry || Mover(TargetActor) != None)
        return false;

    TargetPawn = Pawn(TargetActor);

    // Resistance is random between 0 and enemy max health
    if (TargetPawn != None)
        Resistance = FRand() * TargetPawn.HealthMax * 0.5;
    // Add target shield to resistance
    if (xPawn(TargetActor) != None)
        Resistance += xPawn(TargetActor).ShieldStrength;
    // Half resistance for legs
    if (Vehicle(TargetActor) == None && HitLocation.Z < TargetActor.Location.Z)
        Resistance *= 0.5;
    // half resistance for head
    else if (Vehicle(TargetActor) == None && Normal(Dir).Z > -0.5 && (HitLocation.Z > TargetActor.Location.Z + TargetActor.CollisionHeight*0.8) )
        Resistance *= 0.5;

    if (PenetrateForce/(PenCount+1) > Resistance)
    {
        //log(TargetActor.GetHumanReadableName()$ " CanPenetrated at " $HitLocation$ " PenCount " $PenCount$ " with Resistance " $Resistance);
        return true;
    }
    return false;
}
/*
// Do the trace to find out where bullet really goes
function DoTrace (Vector InitialStart, Rotator Dir)
{
    local int						PenCount, WallCount, HitSameCount;
    local Vector					End, X, HitLocation, HitNormal, Start, WaterHitLoc, LastHitLoc, ExitNormal;
    local Material					HitMaterial;
    local float						Dist;
    local Actor						Other, LastOther;
    local Actor						HitOwner; // <-- normalize ExtendedZCollision owner
    //local bool						bHitWall;

    // Work out the range
    Dist = TraceRange;

    Start = InitialStart;
    X = Normal(Vector(Dir));
    End = Start + X * Dist;
    LastHitLoc = End;
    Weapon.bTraceWater=true;
    while (Dist > 0 && HitSameCount < 10)		// Loop traces in case we need to go through stuff
    {
        // Do the trace
        Other = Trace (HitLocation, HitNormal, End, Start, true, , HitMaterial);
        Dist -= VSize(HitLocation - Start);
        if (Level.NetMode == NM_Client && (Other.Role != Role_Authority || Other.bWorldGeometry))
            continue;
        if (Other != None)
        {
            // If this is an ExtendedZCollision, treat its Owner as the logical hit pawn
            if ( ExtendedZCollision(Other) != None && ExtendedZCollision(Other).Owner != None )
                HitOwner = ExtendedZCollision(Other).Owner;
            else
                HitOwner = Other;

            // Water
            if ( (FluidSurfaceInfo(Other) != None) || ((PhysicsVolume(Other) != None) && PhysicsVolume(Other).bWaterVolume) )
            {
                if (VSize(HitLocation - Start) > 1)
                    WaterHitLoc=HitLocation;
                Start = HitLocation;
                End = Start + X * Dist;
                Weapon.bTraceWater=false;
                continue;
            }
            else
                LastHitLoc=HitLocation;
            // Got something interesting
            // Use HitOwner for comparisons that are intended to operate on the pawn/actor owning the collision proxy.
            if (!Other.bWorldGeometry && HitOwner != LastOther)
            {
                // Apply damage to the owner pawn so that ExtendedZCollision will forward it anyway.
                HitOwner.TakeDamage(Lerp(FRand(), DamageMin, DamageMax), Instigator, HitLocation, Momentum*X, DamageType);
                //log(HitOwner.GetHumanReadableName()$ " was penetrated at " $HitLocation$ " PenCount " $PenCount);
                LastOther = HitOwner;
                HitSameCount = 0;

                //if (Vehicle(HitOwner) != None)
                //	ImpactEffect (HitLocation, HitNormal, HitMaterial, HitOwner, WaterHitLoc);

                if (CanPenetrate(HitOwner, HitLocation, X, PenCount))
                {
                    PenCount++;
                    Start = HitLocation + (X * FMax(HitOwner.CollisionRadius * 2, 8.0));
                    End = Start + X * Dist;
                    //log(HitOwner.GetHumanReadableName()$ " was penetrated at " $HitLocation$ " PenCount " $PenCount);
                    continue;
                }
                else if (Mover(HitOwner) == None)
                    break;
            }
            // Do impact effect
            if (Other.bWorldGeometry || Mover(Other) != None)
            {
                WallCount++;
                ExitNormal = X;
                if (WallCount <= 2 && GoThroughWall(Other, HitLocation, HitNormal, 200, X, Start, ExitNormal))
                {
                    //End = Start + X * Dist;
                    if( KFWeaponAttachment(Weapon.ThirdPersonActor)!=None )
                    {
                        End = Start + X * Dist;
                        KFWeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other,HitLocation,HitNormal);
                        Weapon.IncrementFlashCount(ThisModeNum);
                        KFWeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other,Start,ExitNormal);
                        Weapon.IncrementFlashCount(ThisModeNum);
                    }
                    continue;
                }
                if( KFWeaponAttachment(Weapon.ThirdPersonActor)!=None )
                {
                        KFWeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other,HitLocation,HitNormal);
                        Weapon.IncrementFlashCount(ThisModeNum);
                }
                //bHitWall = ImpactEffect (HitLocation, HitNormal, HitMaterial, Other, WaterHitLoc);
                break;
            }
            else if(Vehicle(Other)==None)
            {
                if( KFWeaponAttachment(Weapon.ThirdPersonActor)!=None )
                {
                    KFWeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other,HitLocation,HitNormal);
                    Weapon.IncrementFlashCount(ThisModeNum);
                }
            }
            // Still in the same guy - compare against owner normalized actor
            if (HitOwner == Instigator || HitOwner == LastOther)
            {
                HitSameCount++;
                Start = HitLocation + (X * FMax(HitOwner.CollisionRadius * 2, 16.0) * 2);
                End = Start + X * Dist;
                continue;
            }
            break;
        }
        else
        {
            LastHitLoc = End;
            break;
        }
    }
    Weapon.bTraceWater=false;
}
*/
// Do the trace to find out where bullet really goes
function DoTrace (Vector InitialStart, Rotator Dir)
{
    local int						PenCount, WallCount, HitSameCount;
    local Vector					End, X, HitLocation, HitNormal, Start, WaterHitLoc, LastHitLoc, ExitNormal;
    local Material					HitMaterial;
    local float						Dist;
    local Actor						Other, LastOther;
    local Actor						HitOwner; // <-- normalize ExtendedZCollision owner
    local vector					FinalHitLocation, FinalHitNormal;
    local Actor						FinalHitActor;
    //local bool					bHitWall;

    // Work out the range
    Dist = TraceRange;

    Start = InitialStart;
    X = Normal(Vector(Dir));
    End = Start + X * Dist;
    LastHitLoc = End;
    FinalHitLocation = End;
    Weapon.bTraceWater=true;
    while (Dist > 0 && HitSameCount < 10)		// Loop traces in case we need to go through stuff
    {
        // Do the trace
        Other = Trace (HitLocation, HitNormal, End, Start, true, , HitMaterial);
        Dist -= VSize(HitLocation - Start);
        if (Level.NetMode == NM_Client && (Other.Role != Role_Authority || Other.bWorldGeometry))
            continue;
        if (Other != None)
        {
            // If this is an ExtendedZCollision, treat its Owner as the logical hit pawn
            if ( ExtendedZCollision(Other) != None && ExtendedZCollision(Other).Owner != None )
                HitOwner = ExtendedZCollision(Other).Owner;
            else
                HitOwner = Other;

            // Water
            if ( (FluidSurfaceInfo(Other) != None) || ((PhysicsVolume(Other) != None) && PhysicsVolume(Other).bWaterVolume) )
            {
                if (VSize(HitLocation - Start) > 1)
                    WaterHitLoc=HitLocation;
                Start = HitLocation;
                End = Start + X * Dist;
                Weapon.bTraceWater=false;
                continue;
            }
            else
                LastHitLoc=HitLocation;
            // Got something interesting
            // Use HitOwner for comparisons that are intended to operate on the pawn/actor owning the collision proxy.
            if (!Other.bWorldGeometry && HitOwner != LastOther)
            {
                // Apply damage to the owner pawn so that ExtendedZCollision will forward it anyway.
                HitOwner.TakeDamage(Lerp(FRand(), DamageMin, DamageMax), Instigator, HitLocation, Momentum*X, DamageType);
                //log(HitOwner.GetHumanReadableName()$ " was penetrated at " $HitLocation$ " PenCount " $PenCount);
                LastOther = HitOwner;
                HitSameCount = 0;

                //if (Vehicle(HitOwner) != None)
                //	ImpactEffect (HitLocation, HitNormal, HitMaterial, HitOwner, WaterHitLoc);

                if (CanPenetrate(HitOwner, HitLocation, X, PenCount))
                {
                    PenCount++;
                    Start = HitLocation + (X * FMax(HitOwner.CollisionRadius * 2, 8.0));
                    End = Start + X * Dist;
                    //log(HitOwner.GetHumanReadableName()$ " was penetrated at " $HitLocation$ " PenCount " $PenCount);
                    continue;
                }
                else if (Mover(HitOwner) == None)
                {
                    FinalHitActor = Other;
                    FinalHitLocation = HitLocation;
                    FinalHitNormal = HitNormal;
                    break;
                }
            }
            // Do impact effect
            if (Other.bWorldGeometry || Mover(Other) != None)
            {
                WallCount++;
                ExitNormal = X;
                if (WallCount <= 2 && GoThroughWall(Other, HitLocation, HitNormal, 200, X, Start, ExitNormal))
                {
                    // Show hit effects on wall entry and exit points
                    if (KFWeaponAttachment(Weapon.ThirdPersonActor) != None)
                    {
                        Spawn(KFWeaponAttachment(Weapon.ThirdPersonActor).HitEffectType, Other, , HitLocation, Rotator(HitNormal));
                        Spawn(KFWeaponAttachment(Weapon.ThirdPersonActor).HitEffectType, Other, , Start, Rotator(ExitNormal));
                    }
                    End = Start + X * Dist;
                    continue;
                }
                FinalHitActor = Other;
                FinalHitLocation = HitLocation;
                FinalHitNormal = HitNormal;
                //bHitWall = ImpactEffect (HitLocation, HitNormal, HitMaterial, Other, WaterHitLoc);
                break;
            }
            else if(Vehicle(Other)==None)
            {
                // Non-vehicle, non-world actor already handled or same as instigator
            }
            // Still in the same guy - compare against owner normalized actor
            if (HitOwner == Instigator || HitOwner == LastOther)
            {
                HitSameCount++;
                Start = HitLocation + (X * FMax(HitOwner.CollisionRadius * 2, 16.0) * 2);
                End = Start + X * Dist;
                continue;
            }
            FinalHitActor = Other;
            FinalHitLocation = HitLocation;
            FinalHitNormal = HitNormal;
            break;
        }
        else
        {
            LastHitLoc = End;
            FinalHitLocation = End;
            break;
        }
    }

    if( KFWeaponAttachment(Weapon.ThirdPersonActor) != None )
    {
        KFWeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(FinalHitActor, FinalHitLocation, FinalHitNormal);
        //Weapon.IncrementFlashCount(ThisModeNum);
    }

    Weapon.bTraceWater=false;
}

// Returns true if the trace hit the back of a surface, i.e. the surface normal and trace normal
// are pointed in the same direction...
function bool IsBackface(vector Norm, vector Dir)	{	return (Normal(Dir) Dot Normal(Norm) > 0.0);	}
// Returns true if point is in a solid, i.e. FastTrace() fails at the point
function bool PointInSolid(vector V)				{	return !Weapon.FastTrace(V, V+vect(1,1,1));		}

function TraceInfo GetTraceInfo (Vector End, Vector Start, optional bool bTraceActors, optional Vector Extent)
{
	local TraceInfo TI;
	TI.Start = Start;	TI.End = End;	TI.Extent = Extent;
	TI.HitActor = Trace(TI.HitLocation, TI.HitNormal, TI.End, TI.Start, bTraceActors, TI.Extent);
	if (TI.HitActor == None)
		TI.HitLocation = TI.End;
	return TI;
}
function bool GoThroughWall(actor Other, vector FirstLoc, vector FirstNorm, float MaxWallDepth, vector Dir, out vector ExitLocation, out vector ExitNormal)
{
	local TraceInfo TBack, TFore;
	local float CheckDist;
	local Vector Test, HLoc, HNorm;
	local Pawn A;

	if (MaxWallDepth <= 0)
		return false;
	// First, try shorcut method...
	foreach Weapon.CollidingActors ( class'pawn', A, MaxWallDepth, FirstLoc)
	{
		if (A == None || A == Instigator || A.TraceThisActor(HLoc, HNorm, FirstLoc + Dir * MaxWallDepth, FirstLoc))
			continue;
		TBack = GetTraceInfo(FirstLoc, HLoc, false);
		if (TBack.HitActor != None)
		{
			if (VSize(TBack.HitLocation - FirstLoc) <= MaxWallDepth)
			{
				ExitLocation = TBack.HitLocation + Dir * 1;
				ExitNormal = TBack.HitNormal;
				return true;
			}
		}
		else
		{
			ExitLocation = FirstLoc + Dir * 48;
			ExitNormal = Dir;
			return true;
		}
	}
	// Start testing as far in as possible, then move closer until we're back at the start
	for (CheckDist=MaxWallDepth;CheckDist>0;CheckDist-=48)
	{
		Test = FirstLoc + Dir * CheckDist;
		// Test point is in a solid, try again
		if (PointInSolid(Test))
			continue;
		// Found space, check to make sure its open space and not just inside a static
		else
		{
			// First, Trace back and see whats there...
			TBack = GetTraceInfo(Test-Dir*CheckDist, Test, true);
			// We're probably in thick terrain, otherwise we'd have found something
			if (TBack.HitActor == None)	{
				return false;	}
			// A non world actor! Must be in valid space
			if (!TBack.HitActor.bWorldGeometry && Mover(TBack.HitActor) == None)	{
				ExitLocation = TBack.HitLocation - Dir * TBack.HitActor.CollisionRadius;
				ExitNormal = Dir;
				return true;
			}
			// Found the front face of a surface(normal parallel to Fire Dir, Opposite to Back Trace dir)
			if (VSize(TBack.HitLocation - TBack.Start) > 0.5 && IsbackFace(TBack.HitNormal, Dir))	{
				ExitLocation = TBack.HitLocation + Dir * 1;
				ExitNormal = TBack.HitNormal;
				return true;
			}
			// Found a back face,
			else{	// Trace forward(along fire Dir) and see if we're inside a mesh or if the surface was just a plane
				TFore = GetTraceInfo(Test+Dir*2000, Test, true);
				if (VSize(TFore.HitLocation - TFore.Start) > 0.5)	{
					// Hit nothing, we're probably not inside a mesh (hopefully)
					if (TFore.HitActor == None)	{
						ExitLocation = TBack.HitLocation + Dir * 1;
						ExitNormal = -TBack.HitNormal;
						return true;
					}
					// Found backface. Looks like its a mesh bigger than MaxWallDepth
					if (IsBackFace(TFore.HitNormal, Dir))
						return false;
					// Hit a front face...
					else	{
						ExitLocation = TBack.HitLocation + Dir * 1;
						ExitNormal = -TBack.HitNormal;
						return true;
					}
				}
				else
					return false;
			}
			break;
		}
	}
	return false;
}

defaultproperties
{
    PenetrateForce=500
    bPenetrate=True
    TraceCount=1
    DamageType=Class'KFMod.DamTypeDeagle'
    DamageMin=115
    DamageMax=125
    Momentum=10000.000000
    bPawnRapidFireAnim=True
    bAttachSmokeEmitter=True
    bWaitForRelease=True
    TransientSoundVolume=100.000000
    FireLoopAnim=
    FireEndAnim=
    FireAnimRate=0.900000
    FireSound=Sound'KFWeaponSound.50CalFire'
    AmmoClass=Class'KFMod.DeagleAmmo'
    AmmoPerFire=1
    ShakeRotMag=(X=90.000000,Y=90.000000,Z=90.000000)
    ShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
    ShakeRotTime=2.000000
    ShakeOffsetMag=(X=19.000000,Y=19.000000,Z=19.000000)
    ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
    ShakeOffsetTime=2.000000
    BotRefireRate=0.800000
    FireRate=0.400000
    FlashEmitterClass=Class'KFMod.KFMuzzleFlash1PGeneric'
    aimerror=0.000000
    SpreadStyle=SS_Random
}
