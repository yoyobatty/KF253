class KFFire extends InstantFire
    abstract;

var float LastClickTime;
var float LastFireTime;

var() Name EmptyAnim;
var() float EmptyAnimRate;
var() Name EmptyFireAnim;
var() float EmptyFireAnimRate;
var bool Empty;
var () bool bFiringDoesntAffectMovement;

var()           bool            bRandomPitchFireSound;      // Fire sound randomly change pitch (use this instead of lots of multiple sounds to save memory)
var()           float           RandomPitchAdjustAmt;       // How much to randomly adjust the pitch for firing sounds

var() int MaxFireBurst; // Maximum number of shots in a burst, 0 for unlimited

// A shot that goes on through bodies (see PenetratingTrace)
var() int MaxPenetrations;      // bodies it goes on through after the first; 0, it stops at the first
var() float PenDamageScale;     // share of its damage it keeps after each body

// View punch stuff (the punch itself lives in KFPlayerController)
var() float   ViewPunchDamping;     // Damping factor for smooth return
var() float   ViewPunchSpring;      // Spring force for return
var float     KickScale;            // This shot's share of the weapon's UpKick (crouch, aim, perk)

// Accuracy update based on pawn velocity
var() float RecoilMovePenaltySlow, RecoilMovePenaltyFast;            
var() float BotRecoilMovePenaltySlow, BotRecoilMovePenaltyFast;     

function float GetFireSpeed()
{
	if( KFPawn(Instigator)!=None )
		Return KFPawn(Instigator).GetVeteran().Static.GetFireSpeedMod(Weapon)*KFPawn(Instigator).GetFireSpeedScale();
	Return 1;
}

simulated function bool AllowFire()
{
	if(KFWeapon(Weapon).bIsReloading)
		return false;
	if(FireCount >= MaxFireBurst && MaxFireBurst > 0)
		return false;
	if(KFPawn(Instigator).SecondaryItem!=none)
		return false;
	if(KFPawn(Instigator).bThrowingNade)
		return false;

	if(KFWeapon(Weapon).FireClip(ThisModeNum) < 1)
	{
		if(Level.TimeSeconds - LastClickTime > FireRate)
		{
			LastClickTime = Level.TimeSeconds;
			Weapon.PlayOwnedSound(NoAmmoSound, SLOT_Interact, TransientSoundVolume,,,, false);
			if(Weapon.HasAnim(EmptyAnim))
				weapon.PlayAnim(EmptyAnim, EmptyAnimRate, 0.0);
		}
		if( AIController(Instigator.Controller)!=None )
			KFWeapon(Weapon).ReloadMeNow();
		return false;
	}

	return KFWeapon(Weapon).FireAmmo(ThisModeNum) >= AmmoPerFire;
}

function StopFiring()
{
    FireCount = 0;
}

function PlayFiring()
{
	local float RandPitch;

	if ( Weapon.Mesh != None )
	{
		if ( FireCount > 0 )
		{
			if ( Weapon.HasAnim(FireLoopAnim) )
			{
				Weapon.PlayAnim(FireLoopAnim, FireLoopAnimRate, 0.0);
			}
			else
			{
				Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
			}
		}
		else
		{
			Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
		}
	}

    if( bRandomPitchFireSound )
    {
        RandPitch = FRand() * RandomPitchAdjustAmt;

        if( FRand() < 0.5 )
        {
            RandPitch *= -1.0;
        }
    }

    Weapon.PlayOwnedSound(FireSound,SLOT_Interact,TransientSoundVolume,,TransientSoundRadius,(1.0 + RandPitch),false);
    //Weapon.PlayOwnedSound(FireSound,SLOT_Interact,TransientSoundVolume,,TransientSoundRadius,Default.FireAnimRate/FireAnimRate,false);
    ClientPlayForceFeedback(FireForce);  // jdf

    FireCount++;
}

//function StartBerserk();

//function StopBerserk();

simulated function InitEffects()
{
    Super.InitEffects();
	if ( (Level.NetMode == NM_DedicatedServer) || (AIController(Instigator.Controller) != None) )
		return;
    if ( FlashEmitter != None )
        Weapon.AttachToBone(FlashEmitter, KFWeapon(Weapon).FlashBoneName);
}

function FlashMuzzleFlash()
{
    local rotator r;
    r.Roll = Rand(65536);


    Weapon.SetBoneRotation('Bone_Flash', r, 0, 1.f);


   //log(r);

    Super.FlashMuzzleFlash();
    if ( FlashEmitterClass != None && KFWeapon(Weapon) != None )
        KFWeapon(Weapon).ShotLight();
}

event ModeDoFire()
{
	local float Rec, PenaltyFactor;

	if (!AllowFire())
		return;

	if( Instigator==None || Instigator.Controller==none )
		return;

	if ( Level.TimeSeconds - LastFireTime > 0.5 )
		Spread = Default.Spread;
	else Spread = FMin(Spread+0.01,0.12);

	KickScale = 1.0;

	// Small spread bonus for firing crouched
    if( Instigator != none && Instigator.bIsCrouched )
    {
        Spread *= 0.85;
		KickScale *= 0.85;
    }

	// Spread bonus for firing aiming
    if( KFWeapon(Weapon).bAimingRifle )
    {
        Spread *= 0.5;
		KickScale *= 0.5;
    }

	Rec = GetFireSpeed();
	FireRate = default.FireRate/Rec;
	FireAnimRate = default.FireAnimRate*Rec;
	ReloadAnimRate = default.ReloadAnimRate*Rec;
	Rec = 1;

	if( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
	{
		Spread*=KFPawn(Instigator).GetVeteran().Static.ModifyRecoilSpread(Self,Rec);
		KickScale*=KFPawn(Instigator).GetVeteran().Static.ModifyRecoilSpread(Self,Rec);
	}

	LastFireTime = Level.TimeSeconds;

    if (Weapon.Owner != none && AllowFire() && !bFiringDoesntAffectMovement && Weapon.Owner.Physics != PHYS_Falling )
    {
        // Determine velocity retention factor based on fire rate and controller type
        if (Bot(Instigator.Controller) != None)
        {
            if (FireRate > 0.25)
                PenaltyFactor = BotRecoilMovePenaltySlow;
            else
                PenaltyFactor = BotRecoilMovePenaltyFast;
        }
        else
        {
            if (FireRate > 0.25)
                PenaltyFactor = RecoilMovePenaltySlow;
            else
                PenaltyFactor = RecoilMovePenaltyFast;
        }

        if (KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none &&
            KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none)
        {
            PenaltyFactor = Lerp(KFPawn(Instigator).GetVeteran().Static.GetRecoilMovementSpeedModifier(), PenaltyFactor, 1.0);
        }

        if ( KFPawn(Weapon.Owner) != None )
            KFPawn(Weapon.Owner).WeaponBrake(PenaltyFactor);
        else
        {
            Weapon.Owner.Velocity.x *= PenaltyFactor;
            Weapon.Owner.Velocity.y *= PenaltyFactor;
        }
    }
	//log("ModeDoFire called on "$Weapon.GetHumanReadableName());
	Super.ModeDoFire();
	KFWeapon(Weapon).ShotDue[ThisModeNum] = 0;

    // Only start a new recoil if not already recoiling
    if (Instigator.IsLocallyControlled())
    {
        HandleRecoil();
    }
}

function HandleRecoil()
{
	// The kick grows through a burst, up to three times after twelve shots
	KFWeapon(Weapon).ViewKick(KickScale, 1.0 + FClamp(FireCount/6.f,0.0,2.0), ViewPunchDamping, ViewPunchSpring);
}

function DoTrace(Vector Start, Rotator Dir)
{
    local Vector X, End, HitLocation, HitNormal;
    local Actor Other;
    local Actor DamageTarget;
    local KFWeaponAttachment WeapAttach;

    if ( MaxPenetrations > 0 )
    {
        PenetratingTrace(Start, Dir);
        return;
    }

    MaxRange();
    X = Normal(Vector(Dir));
    End = Start + TraceRange * X;
    Other = Instigator.Trace(HitLocation, HitNormal, End, Start, true);
    if ( Other != None && Other != Instigator && Other.Base != Instigator )
    {
        WeapAttach = KFWeaponAttachment(Weapon.ThirdPersonActor);

        // Resolve ExtendedZCollision to its owner pawn
        if ( ExtendedZCollision(Other) != None && Other.Owner != None )
            DamageTarget = Other.Owner;
        else
            DamageTarget = Other;

        if ( !Other.bWorldGeometry )
        {
            // Update hit effect except for pawns
            if ( !Other.IsA('Pawn') && !Other.IsA('HitScanBlockingVolume') && !Other.IsA('ExtendedZCollision') )
            {
                if( WeapAttach != None )
                    WeapAttach.UpdateHit(Other, HitLocation, HitNormal);
            }
            // every client keeps a body of its own for a dead specimen, and tries the shot on that
            else if ( WeapAttach != None && KFMonster(DamageTarget) != None && KFMonster(DamageTarget).Health <= 0 )
                WeapAttach.UpdateCorpseHit(HitLocation);
            DamageTarget.TakeDamage(Lerp(FRand(), DamageMin, DamageMax), Instigator, HitLocation, Momentum*X, DamageType);
        }
        else
        {
            HitLocation = HitLocation + 2.0 * HitNormal;
            if ( WeapAttach != None )
                WeapAttach.UpdateHit(Other,HitLocation,HitNormal);
        }
    }
    else
    {
        HitLocation = End;
        HitNormal = Normal(Start - End);
    }
}

// A shot that goes on through bodies, as retail Killing Floor's Deagle does and this mod's Winchester did. Each body
// hit has its collision switched off and the trace goes on from where it was hit, so a specimen pressed right behind
// another is met too. After MaxPenetrations bodies past the first it stops, and the damage is scaled by
// PenDamageScale after each. A dead body takes the shot (for its gore) but costs it nothing, and so does a teammate
// while friendly fire is off. The world, doors, glass and props stop it.
function PenetratingTrace(Vector Start, Rotator Dir)
{
	local Vector X, End, HitLocation, HitNormal;
	local Actor Other, Target;
	local array<Actor> Off, Hit;
	local KFWeaponAttachment WeapAttach;
	local float HitDamage;
	local int i, Passed, Tries;
	local bool bSeen, bFree;

	MaxRange();
	X = Normal(Vector(Dir));
	End = Start + TraceRange * X;
	HitDamage = Lerp(FRand(), DamageMin, DamageMax);
	WeapAttach = KFWeaponAttachment(Weapon.ThirdPersonActor);

	while ( Tries++ < 24 )
	{
		Other = Instigator.Trace(HitLocation, HitNormal, End, Start, true);
		if ( Other == None || HitScanBlockingVolume(Other) != None )
			break;

		// the shooter, and what rides on them, are looked through
		if ( Other == Instigator || Other.Base == Instigator )
		{
			LookThrough(Other, Off);
			Start = HitLocation;
			continue;
		}

		if ( Other.bWorldGeometry || Other == Level )
		{
			if ( WeapAttach != None )
				WeapAttach.UpdateHit(Other, HitLocation + 2.0 * HitNormal, HitNormal);
			break;
		}

		// a specimen's extra collision (big body, head) is the specimen
		Target = Other;
		if ( ExtendedZCollision(Other) != None && Other.Owner != None )
			Target = Other.Owner;

		// a body already hit, met again through another of its parts
		bSeen = false;
		for ( i = 0; i < Hit.Length; i++ )
			if ( Hit[i] == Target )
				bSeen = true;
		if ( bSeen )
		{
			LookThrough(Other, Off);
			Start = HitLocation;
			continue;
		}

		// a door, glass or a prop takes the shot and stops it
		if ( Pawn(Target) == None )
		{
			if ( WeapAttach != None )
				WeapAttach.UpdateHit(Other, HitLocation, HitNormal);
			Target.TakeDamage(int(HitDamage), Instigator, HitLocation, Momentum*X, DamageType);
			break;
		}

		bFree = Pawn(Target).Health <= 0 || FriendlyFireOff(Pawn(Target));
		// every client keeps a body of its own for a dead specimen, and tries the shot on that
		if ( Pawn(Target).Health <= 0 && KFMonster(Target) != None && WeapAttach != None )
			WeapAttach.UpdateCorpseHit(HitLocation);
		Target.TakeDamage(int(HitDamage), Instigator, HitLocation, Momentum*X, DamageType);
		Hit[Hit.Length] = Target;
		LookThrough(Other, Off);
		if ( Target != Other )
			LookThrough(Target, Off);
		Start = HitLocation;

		if ( !bFree )
		{
			if ( Passed++ >= MaxPenetrations )
				break;
			HitDamage *= PenDamageScale;
		}
	}

	// collision back on for what was looked through (a body the shot destroyed is gone)
	for ( i = 0; i < Off.Length; i++ )
		if ( Off[i] != None && !Off[i].bDeleteMe )
			Off[i].SetCollision(true);
}

// One the trace is to pass through from now on
function LookThrough(Actor A, out array<Actor> Off)
{
	if ( A == None || !A.bCollideActors )
		return;
	A.SetCollision(false);
	Off[Off.Length] = A;
}

// A teammate, while friendly fire is off: the shot passes them by
function bool FriendlyFireOff(Pawn P)
{
	return P != None && Monster(P) == None && Instigator != None && P.GetTeamNum() == Instigator.GetTeamNum()
		&& TeamGame(Level.Game) != None && TeamGame(Level.Game).FriendlyFireScale == 0;
}

// Accuracy update based on pawn velocity
simulated function AccuracyUpdate(float Velocity)
{
	if (KFWeapon(Weapon).bSteadyAim)
		return;

	if (Pawn(Weapon.Owner).bIsCrouched)
		Velocity *= 0.6;

	AimError = ((default.AimError * 0.75) + (Velocity * 2 ));   //2
	Spread = ((default.Spread * 0.75) + (Velocity * 0.0005 ));   //.0005
}

defaultproperties
{
	EmptyAnim="Empty"
	EmptyAnimRate=1.000000
	EmptyFireAnim="EmptyFire"
	EmptyFireAnimRate=1.000000
	bRandomPitchFireSound=True
	RandomPitchAdjustAmt=0.100000
	ViewPunchDamping=9.000000
	ViewPunchSpring=65.000000
	KickScale=1.000000
	MaxFireBurst=0
	MaxPenetrations=0
	PenDamageScale=0.500000
    RecoilMovePenaltySlow=0.100000
    RecoilMovePenaltyFast=0.250000
    BotRecoilMovePenaltySlow=0.250000
    BotRecoilMovePenaltyFast=0.500000
}
