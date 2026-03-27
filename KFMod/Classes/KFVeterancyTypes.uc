// Base class of all veterancy types
Class KFVeterancyTypes extends Info
	Abstract;

// HUD Icon is what appears for other players next to playername, sub hud icon can stand for sergeant or something else..
var() Material OnHUDIcon,SubHUDIcon;
var() localized string VeterancyName,VeterancyDescription,VeterancyRequirement;

var string VetButtonStyle; // OBSOLOTE!
<<<<<<< HEAD
=======
var bool bHasPerkWeapon;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

// This skill can be qualified for..?
static function bool QualityFor( KFPlayerStats Other )
{
	Return True;
}
// Modify syringe charge speed
static function float GetSyringeChargeRate()
{
	Return 1;
}
static function float GetHealPotency()
{
	Return 1;
}
// Modify movement speed
static function float GetMovementSpeedModifier()
{
	Return 1;
}
// Modify movement speed ONLY when holding melee weapon
static function float GetMeleeMovementSpeedModifier()
{
	Return 0;
}
// Reduce damage zombies can deal to you
<<<<<<< HEAD
static function int ReduceDamage( KFPawn Injured, KFMonster DamageTaker, int InDamage, class<DamageType> DmgType )
=======
static function int ReduceDamage( KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType )
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
{
	Return InDamage;
}
// Add damage you deal to zombies
<<<<<<< HEAD
static function int AddDamage( KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType )
=======
static function int AddDamage( KFMonster Injured, KFPawn Instigator, int InDamage, class<DamageType> DmgType )
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
{
	Return InDamage;
}

<<<<<<< HEAD


=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
// Add max carry weight for weapons
static function int AddCarryMaxWeight()
{
	Return 0;
}
// Welding speed modifier
static function float GetVeldSpeedModifier()
{
	Return 1;
}
// Add extra ammo for a weapon
static function float AddExtraAmmoFor( Class<Ammunition> AmmoType )
{
	Return 1;
}
<<<<<<< HEAD
=======

static function float GetMagCapacityMod(KFWeapon Other)
{
	return 1.0;
}

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
// Multiply headshot damage
static function float GetHeadShotDamMulti()
{
	Return 1;
}

// Render some extra info on HUD
static function SpecialHUDInfo( Canvas C );

// Modify the spear/recoil for a weapon fire.
static function float ModifyRecoilSpread( WeaponFire Other, out float Recoil )
{
	Recoil = 1;
	Return 1;
}
// Modify weapon reload speed
static function float GetReloadSpeedModifier( KFWeapon Other )
{
	Return 1;
}
// Modify fire speed
static function float GetFireSpeedMod( Weapon Other )
{
	Return 1;
}

// Can Clots grab me?
static function bool CanBeGrabbed( KFMonster Other )
{
	Return True;
}

// Show stalkers?
static function bool ShowStalkers()
{
	Return False;
}

// Incendiary Grenades?
static function bool FlamingNades()
{
	Return False;
}

<<<<<<< HEAD
=======
// Healing Grenades? Muahahaha
static function bool HealingNades()
{
	Return False;
}

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
// Change effective range on FLamethrower
static function int ExtraRange()
{
	Return 0;
}

<<<<<<< HEAD
defaultproperties
{
=======
static function class<DamageType> GetMAC10DamageType()
{
	return class'KFMod.DamTypeBullpup';
}

// Reduce damage when wearing Armor
static function float GetBodyArmorDamageModifier()
{
	return 1.0;
}

defaultproperties
{
	bHasPerkWeapon=false
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
