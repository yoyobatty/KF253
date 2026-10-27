//=============================================================================
// RailgunFire
// The railgun's shot: a slug through everything in its line, specimens and props alike, until a wall stops it, each
// struck for RailDamage. The line is drawn on every machine by KFRailBeam. Fuel vapour along it goes up (KFFireGrid).
//=============================================================================
class RailgunFire extends KFFire;

#exec OBJ LOAD FILE=..\Sounds\WeaponSounds.uax

var() float RailRange, RailMomentum;
var() int RailDamage;
var() Sound RechargeSound;

function DoFireEffect()
{
	local vector Start, X, End, HL, HN, From, WallHit;
	local Actor Other, Target;
	local array<Actor> Off, Hit;
	local array<byte> Flags;
	local KFWeaponAttachment WeapAttach;
	local int i, Tries;
	local bool bSeen, bWall;
	local KFRailBeam B;

	Instigator.MakeNoise(1.0);
	Start = Instigator.Location + Instigator.EyePosition();
	X = vector(AdjustAim(Start, AimError));
	End = Start + X * RailRange;
	WallHit = End;
	From = Start;
	WeapAttach = KFWeaponAttachment(Weapon.ThirdPersonActor);
	// on through everything to the first wall: each thing met is struck once and looked through (its collision off
	// until the shot is done), and the trace goes on from where it was met
	while ( Tries++ < 48 )
	{
		Other = Instigator.Trace(HL, HN, End, From, true);
		if ( Other == None )
			break;
		if ( Other.bWorldGeometry || Other == Level || HitScanBlockingVolume(Other) != None )
		{
			WallHit = HL;
			bWall = true;
			if ( WeapAttach != None )
				WeapAttach.UpdateHit(Other, HL + 2.0 * HN, HN);
			break;
		}
		Target = Other;
		if ( ExtendedZCollision(Other) != None && Other.Owner != None )
			Target = Other.Owner;
		bSeen = Other == Instigator || Other.Base == Instigator || Target == Instigator;
		for ( i = 0; i < Hit.Length && !bSeen; i++ )
			if ( Hit[i] == Target )
				bSeen = true;
		if ( !bSeen && !(Pawn(Target) != None && FriendlyFireOff(Pawn(Target))) )
		{
			if ( KFMonster(Target) != None && Pawn(Target).Health <= 0 && WeapAttach != None )
				WeapAttach.UpdateCorpseHit(HL);
			else if ( Pawn(Target) == None && WeapAttach != None )
				WeapAttach.UpdateHit(Other, HL, HN);
			Hit[Hit.Length] = Target;
			Target.TakeDamage(RailDamage, Instigator, HL, X * RailMomentum, DamageType);
		}
		RailLookThrough(Other, Off, Flags);
		if ( Target != Other && Target != None && !Target.bDeleteMe )
			RailLookThrough(Target, Off, Flags);
		From = HL;
	}
	// collision back as it was for all that was looked through (what the shot destroyed is gone)
	for ( i = 0; i < Off.Length; i++ )
		if ( Off[i] != None && !Off[i].bDeleteMe )
			Off[i].SetCollision((Flags[i] & 1) != 0, (Flags[i] & 2) != 0, (Flags[i] & 4) != 0);

	B = Weapon.Spawn(class'KFRailBeam', Instigator,, Start, rotator(X));
	if ( B != None )
	{
		B.EndPoint = WallHit;
		B.bWall = bWall;
	}
	class'KFFireGrid'.static.HeatLine(Weapon, Start, WallHit, 1.6);
}

// One the slug is to pass through from now on, its collision noted to be put back as it was
function RailLookThrough( Actor A, out array<Actor> Off, out array<byte> Flags )
{
	local byte F;

	if ( A == None || !A.bCollideActors )
		return;
	F = 1;
	if ( A.bBlockActors )
		F = F | 2;
	if ( A.bBlockPlayers )
		F = F | 4;
	Off[Off.Length] = A;
	Flags[Flags.Length] = F;
	A.SetCollision(false, false, false);
}

function PlayFiring()
{
	Super.PlayFiring();
	if ( RechargeSound != None )
		Weapon.PlayOwnedSound(RechargeSound, SLOT_Misc, 0.45,, 300, 1.6, false);
}

defaultproperties
{
     RailRange=12000.000000
     RailMomentum=60000.000000
     RailDamage=480
     RechargeSound=Sound'WeaponSounds.LightningGun.LightningGunChargeUp'
     DamageType=Class'KFMod.DamTypeRailgun'
     DamageMin=480
     DamageMax=480
     FlashFXClass=Class'KFMod.KFFlashRifle'
     FireSound=Sound'WeaponSounds.BaseFiringSounds.BLightningGunFire'
     TransientSoundVolume=2.000000
     FireAnim="Fire"
     FireAnimRate=0.600000
     FireRate=1.400000
     AmmoClass=Class'KFMod.RailgunAmmo'
     AmmoPerFire=1
     bWaitForRelease=True
     ShakeRotMag=(X=200.000000,Y=200.000000,Z=200.000000)
     ShakeRotRate=(X=12000.000000,Y=12000.000000,Z=12000.000000)
     ShakeRotTime=1.500000
     ShakeOffsetMag=(X=-14.000000,Y=0.000000,Z=4.000000)
     ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
     ShakeOffsetTime=1.200000
     BotRefireRate=0.500000
     aimerror=0.000000
     Spread=0.000000
}
