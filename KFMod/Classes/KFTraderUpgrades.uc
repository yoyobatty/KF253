//=============================================================================
// KFTraderUpgrades
// What the trader sells as upgrades of a gun the player owns (KFPawn.ServerUpgradeWeapon), in every game mode: a gun's
// own upgrade (KFWeapon.Upgrade, the one the Zombies machine gives) for cash, and the variants built on a gun, which take
// its place. A variant is not on the trader's lists as a gun of its own; it is sold back as one. Each gun is upgraded once.
//=============================================================================
class KFTraderUpgrades extends Object
	abstract;

struct UpgradeLine
{
	var() class<KFWeapon>	Base;		// the gun owned
	var() class<KFWeapon>	Variant;	// what it becomes; None: its own upgrade
	var() string			Info;		// (its own upgrade) what it does; a variant's pickup says it (the numbers: NumbersOf)
	var() string			MagWord;	// (its own upgrade) what its magazine is called in the numbers; "": Magazine
	var() string			AmmoWord;	// (its own upgrade) what its ammo is called; "": Ammo
	var() int				Price;		// (its own upgrade) what it costs; 0: UpgradeBase and UpgradeShare of the gun's price
};
var() array<UpgradeLine> Lines;
var() int UpgradeBase;
var() float UpgradeShare;

// The line for an upgrade of Base, or -1
static function int Find( class<Weapon> Base, class<KFWeapon> Variant )
{
	local int i;

	for ( i = 0; i < default.Lines.Length; i++ )
		if ( default.Lines[i].Base == Base && default.Lines[i].Variant == Variant )
			return i;
	return -1;
}

// Whether a gun is a variant of another (sold back, never upgraded)
static function bool IsVariant( class<Weapon> W )
{
	local int i;

	for ( i = 0; i < default.Lines.Length; i++ )
		if ( default.Lines[i].Variant == W )
			return true;
	return false;
}

static function int GunPrice( class<Weapon> W )
{
	if ( W == None || class<KFWeaponPickup>(W.default.PickupClass) == None )
		return 0;
	return class<KFWeaponPickup>(W.default.PickupClass).default.Cost;
}

// What a line costs before the difficulty's scaling: a variant the difference between its price and the gun's (what the
// two cost bought one after the other)
static function int PriceOf( int i )
{
	if ( default.Lines[i].Variant != None )
		return Max(GunPrice(default.Lines[i].Variant) - GunPrice(default.Lines[i].Base), 0);
	if ( default.Lines[i].Price > 0 )
		return default.Lines[i].Price;
	return default.UpgradeBase + int(default.UpgradeShare * GunPrice(default.Lines[i].Base));
}

static function string NameOf( int i )
{
	if ( default.Lines[i].Variant != None )
		return default.Lines[i].Variant.default.ItemName;
	return default.Lines[i].Base.default.UpgradeName;
}

static function string InfoOf( int i )
{
	if ( default.Lines[i].Variant != None && class<KFWeaponPickup>(default.Lines[i].Variant.default.PickupClass) != None )
		return class<KFWeaponPickup>(default.Lines[i].Variant.default.PickupClass).default.Description;
	return default.Lines[i].Info;
}

// What a gun's own upgrade does to its magazine and its ammo, in numbers ("Magazine 15 to 30. Ammo 240 to 480."): for
// the player's own gun W, with what their perk adds; for a gun they have not, as sold (with the perk's extra ammo).
// Nothing for a variant, or where neither changes. (Worked out as KFWeapon.UpdateMagCapacity and MaxAmmo do.)
static function string NumbersOf( int i, KFWeapon W, PlayerReplicationInfo PRI )
{
	local class<KFWeapon> C;
	local class<Ammunition> A;
	local class<KFVeterancyTypes> Vet;
	local float F, Perk;
	local int Now, After;
	local string S, Word;

	if ( i < 0 || i >= default.Lines.Length || default.Lines[i].Variant != None || default.Lines[i].Base == None )
		return "";
	C = default.Lines[i].Base;
	if ( KFPlayerReplicationInfo(PRI) != None )
		Vet = KFPlayerReplicationInfo(PRI).ClientVeteranSkill;
	if ( C.default.ClipCount > 1 && C.default.UpgradeMagScale != 1.0 )
	{
		Perk = 1.0;
		if ( Vet != None && W != None )
			Perk = Vet.static.GetMagCapacityMod(W);
		F = C.default.ClipCount * Perk;
		Now = F;
		F *= C.default.UpgradeMagScale;
		After = F;
		Word = default.Lines[i].MagWord;
		if ( Word == "" )
			Word = "Magazine";
		S = Word @ Now @ "to" @ After $ ".";
	}
	if ( C.default.FireModeClass[0] != None )
		A = C.default.FireModeClass[0].default.AmmoClass;
	if ( A != None && A.default.MaxAmmo > 0 && C.default.UpgradeAmmoScale != 1.0 )
	{
		Perk = 1.0;
		if ( Vet != None )
			Perk = Vet.static.AddExtraAmmoFor(A);
		F = A.default.MaxAmmo * Perk;
		Now = F;
		F *= C.default.UpgradeAmmoScale;
		After = F;
		Word = default.Lines[i].AmmoWord;
		if ( Word == "" )
			Word = "Ammo";
		if ( S != "" )
			S = S $ " ";
		S = S $ Word @ Now @ "to" @ After $ ".";
	}
	return S;
}

defaultproperties
{
	UpgradeBase=1500
	UpgradeShare=2.000000
	Lines(0)=(Base=Class'KFMod.Single',Info="Three-round bursts, a quicker trigger, and every round goes through one specimen into the next.")
	Lines(1)=(Base=Class'KFMod.Dualies',Info="Incendiary rounds that set specimens alight.")
	Lines(2)=(Base=Class'KFMod.MachinePistol',Info="A shot that hits a wall ricochets into the nearest specimen.")
	Lines(3)=(Base=Class'KFMod.DualMachinePistols',Info="A quicker trigger, and shots that hit a wall ricochet into the nearest specimen.")
	Lines(4)=(Base=Class'KFMod.Deagle',Info="Goes through everything in its way and staggers what it hits.")
	Lines(5)=(Base=Class'KFMod.Winchester',Info="Goes through bodies, and a headshot stuns the specimens round the one hit.")
	Lines(6)=(Base=Class'KFMod.Shotgun',Info="Burning pellets that set specimens alight and leave fires on the floor.")
	Lines(7)=(Base=Class'KFMod.BoomStick',Info="Blasts that knock specimens back, and a faster reload.")
	Lines(8)=(Base=Class'KFMod.Bullpup',Info="A quicker trigger, and rounds that go through two specimens.")
	Lines(9)=(Base=Class'KFMod.Crossbow',Info="A bolt that explodes a second after it lands.")
	Lines(10)=(Base=Class'KFMod.LAW',Info="Rockets that leave a ring of burning napalm.")
	Lines(11)=(Base=Class'KFMod.FlameThrower',Info="Blue flames that burn longer and creep across any floor, and lightning that jumps between the burning.",MagWord="Tank",AmmoWord="Fuel")
	Lines(12)=(Base=Class'KFMod.Knife',Info="Heals you 10 for every kill.")
	Lines(13)=(Base=Class'KFMod.Axe',Info="Full damage to everyone in a swing, and every swing throws a cut through the air: primary down, alt fire across.")
	Lines(14)=(Base=Class'KFMod.LAW',Variant=Class'KFMod.BFG')
	Lines(15)=(Base=Class'KFMod.LAW',Variant=Class'KFMod.GoreCannon')
	Lines(16)=(Base=Class'KFMod.Bullpup',Variant=Class'KFMod.Railgun')
	Lines(17)=(Base=Class'KFMod.Crossbow',Variant=Class'KFMod.CryoCannon')
	Lines(18)=(Base=Class'KFMod.Axe',Variant=Class'KFMod.AxeVoid')
}
