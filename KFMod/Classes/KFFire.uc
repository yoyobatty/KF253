class KFFire extends InstantFire
    abstract;

var() class<KFFlash> FlashFXClass;	// its muzzle flash (KFFlash), drawn at the gun's muzzle
var() bool bNotAShot;		// a fire mode that is no shot (the 9mm's light): no burst, casing, layers or energy hum
var() Sound MechSound;		// a close, quiet sound of the gun's works under the shooter's own shot (KFWeapon.LocalShotLayers)
var() float MechVolume, MechPitch;

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

// An upgraded gun's burst (KFWeapon.UpgradeBurst): the rest of a pull's shots follow on their own
var() float BurstGap;
var int BurstLeft;
var bool bBurstShot;

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

    Weapon.PlayOwnedSound(FireSound,SLOT_Interact,TransientSoundVolume,,TransientSoundRadius,(1.0 + RandPitch)*UpgradePitch(),false);
    UpgradeLayer();
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
    if ( FlashFXClass != None && KFWeapon(Weapon) != None )
        KFWeapon(Weapon).MuzzleFlashFX(FlashFXClass, FlashFXBone());
    if ( (FlashEmitterClass != None || FlashFXClass != None) && KFWeapon(Weapon) != None )
        KFWeapon(Weapon).ShotLight();
    if ( KFWeapon(Weapon) != None && !bNotAShot )
    {
        KFWeapon(Weapon).LocalShotLayers(MechSound, MechVolume, MechPitch);
        KFWeapon(Weapon).EjectBrass(BrassFXBone());
    }
}

// The port this shot's casing leaves (a pair of pistols takes turns)
simulated function name BrassFXBone()
{
	return KFWeapon(Weapon).BrassBone;
}

// The muzzle this shot leaves (a pair of pistols takes turns)
simulated function name FlashFXBone()
{
	return KFWeapon(Weapon).FlashBoneName;
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
	FireRate = default.FireRate/Rec*KFWeapon(Weapon).UpgradeFireRate();
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

	// the first shot of an upgraded gun's burst: the others follow on their own, the trigger let go or not
	if ( !bBurstShot && !bNotAShot && Upgraded() && KFWeapon(Weapon).UpgradeBurst > 1 )
	{
		BurstLeft = KFWeapon(Weapon).UpgradeBurst - 1;
		SetTimer(BurstGap, true);
	}
}

// The next shot of an upgraded burst
event Timer()
{
	if ( BurstLeft <= 0 || Weapon == None || Instigator == None || Instigator.Weapon != Weapon || KFWeapon(Weapon).bIsReloading )
	{
		BurstLeft = 0;
		SetTimer(0, false);
		return;
	}
	BurstLeft--;
	bBurstShot = true;
	ModeDoFire();
	bBurstShot = false;
	if ( BurstLeft <= 0 )
		SetTimer(0, false);
}

simulated function bool Upgraded()
{
	return KFWeapon(Weapon) != None && KFWeapon(Weapon).bUpgraded;
}

// An upgraded gun sounds heavier
function float UpgradePitch()
{
	if ( Upgraded() )
		return 0.85;
	return 1.0;
}

function ServerPlayFiring()
{
	Weapon.PlayOwnedSound(FireSound,SLOT_Interact,TransientSoundVolume,,TransientSoundRadius,UpgradePitch(),false);
	UpgradeLayer();
}

// What an upgraded gun's shot does to a specimen besides the harm (bWasAlive: it was before this shot)
function UpgradeHit( Actor Target, vector HitLocation, bool bWasAlive )
{
	local KFMonster M, Near;
	local KFWeapon W;

	W = KFWeapon(Weapon);
	M = KFMonster(Target);
	if ( W == None || !W.bUpgraded || M == None )
		return;
	if ( W.bUpgradeIncendiary && M.Health > 0 )
		M.TakeIncendiary(2, Instigator);
	if ( W.bUpgradeStagger && M.Health > 0 && Instigator != None )
		M.BlastStagger(Instigator.Location);
	// a head burst by the shot jolts those around it
	if ( W.bUpgradeHeadShock && bWasAlive && M.Health <= 0 && M.bDecapitated )
		foreach M.VisibleCollidingActors(class'KFMonster', Near, 300, M.Location + vect(0,0,1) * M.CollisionHeight)
			if ( Near != M && Near.Health > 0 )
				Near.BlastStagger(M.Location);
}

// An upgraded round that has hit a wall goes on to the nearest specimen in front of the wall it can reach
function Ricochet( vector From, vector WallNormal, float Damage )
{
	local KFMonster M, Best;
	local float D, BestD;
	local vector Aim, HL, HN, Dir;
	local Actor Other, Target;
	local KFRicochet R;
	local bool bWasAlive;

	From += 4 * WallNormal;
	foreach Weapon.VisibleCollidingActors(class'KFMonster', M, 1000, From)
	{
		if ( M.Health <= 0 )
			continue;
		Dir = Normal(M.Location - From);
		if ( (Dir dot WallNormal) < 0.2 )
			continue;
		D = VSize(M.Location - From);
		if ( Best == None || D < BestD )
		{
			Best = M;
			BestD = D;
		}
	}
	if ( Best == None )
		return;
	Aim = Best.Location + vect(0,0,0.3) * Best.CollisionHeight;
	Dir = Normal(Aim - From);
	Other = Weapon.Trace(HL, HN, Aim + 60 * Dir, From, true);
	Target = Other;
	if ( ExtendedZCollision(Other) != None && Other.Owner != None )
		Target = Other.Owner;
	if ( KFMonster(Target) == None || Pawn(Target).Health <= 0 )
		return;
	bWasAlive = true;
	Target.TakeDamage(int(Damage * 0.8), Instigator, HL, Momentum * Dir, DamageType);
	UpgradeHit(Target, HL, bWasAlive);
	R = Weapon.Spawn(class'KFRicochet',,, From);
	if ( R != None )
		R.ShowTo(HL);
}

function bool Ricochets()
{
	return Upgraded() && KFWeapon(Weapon).UpgradeRicochets > 0;
}

function HandleRecoil()
{
	// The kick grows through a burst, up to three times after twelve shots
	KFWeapon(Weapon).ViewKick(KickScale, 1.0 + FClamp(FireCount/6.f,0.0,2.0), ViewPunchDamping, ViewPunchSpring);
}

// Bodies a shot goes on through after the first: its own, its shooter's perk's and an upgrade's on top
function int Penetrations()
{
	local int N;

	N = MaxPenetrations;
	if ( KFPawn(Instigator) != None && KFPawn(Instigator).GetVeteran() != None )
		N += KFPawn(Instigator).GetVeteran().static.ExtraPenetrations(self);
	if ( Upgraded() )
		N += KFWeapon(Weapon).UpgradePenetrations;
	return N;
}

// The share of its damage a shot keeps past each body
function float PenScale()
{
	if ( Upgraded() && KFWeapon(Weapon).UpgradePenDamageScale > 0 )
		return KFWeapon(Weapon).UpgradePenDamageScale;
	return PenDamageScale;
}

function DoTrace(Vector Start, Rotator Dir)
{
    local Vector X, End, HitLocation, HitNormal;
    local Actor Other;
    local Actor DamageTarget;
    local KFWeaponAttachment WeapAttach;
    local bool bWasAlive;

    // (the fire grid) a muzzle flash sets off fuel vapour hanging round the gun
    class'KFFireGrid'.static.Heat(Weapon, Start + vector(Dir) * 70.0, 90, 1.4);

    if ( Penetrations() > 0 )
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
            bWasAlive = Pawn(DamageTarget) != None && Pawn(DamageTarget).Health > 0;
            DamageTarget.TakeDamage(Lerp(FRand(), DamageMin, DamageMax), Instigator, HitLocation, Momentum*X, DamageType);
            UpgradeHit(DamageTarget, HitLocation, bWasAlive);
        }
        else
        {
            HitLocation = HitLocation + 2.0 * HitNormal;
            if ( WeapAttach != None )
                WeapAttach.UpdateHit(Other,HitLocation,HitNormal);
            if ( Ricochets() )
                Ricochet(HitLocation, HitNormal, Lerp(FRand(), DamageMin, DamageMax));
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
	local int i, Passed, Tries, Pens;
	local bool bSeen, bFree, bWasAlive;

	MaxRange();
	Pens = Penetrations();
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
			if ( Ricochets() )
				Ricochet(HitLocation + 2.0 * HitNormal, HitNormal, HitDamage);
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
		bWasAlive = Pawn(Target).Health > 0;
		Target.TakeDamage(int(HitDamage), Instigator, HitLocation, Momentum*X, DamageType);
		UpgradeHit(Target, HitLocation, bWasAlive);
		Hit[Hit.Length] = Target;
		LookThrough(Other, Off);
		if ( Target != Other )
			LookThrough(Target, Off);
		Start = HitLocation;

		if ( !bFree )
		{
			if ( Passed++ >= Pens )
				break;
			HitDamage *= PenScale();
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

// An upgraded gun's shot has a hum of energy under it, pitched by its element (KFElement)
function UpgradeLayer()
{
	local KFWeapon W;

	W = KFWeapon(Weapon);
	if ( W == None || bNotAShot || !W.bUpgraded || !class'KFElement'.static.Has(W.Element) || class'KFElement'.default.FireLayer == None )
		return;
	Weapon.PlayOwnedSound(class'KFElement'.default.FireLayer, SLOT_None, class'KFElement'.default.FireLayerVolume,, TransientSoundRadius,
		class'KFElement'.default.LayerPitches[W.Element] * (0.97 + 0.06 * FRand()), false);
}

defaultproperties
{
	MechVolume=0.300000
	MechPitch=1.000000
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
	BurstGap=0.070000
}
