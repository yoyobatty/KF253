Class KFVetBerserker extends KFVeterancyTypes
	Abstract;

// Buffs on test (0, and 1.0 for the share, leave things as they were)
var() float ScrakeStaggerGap;	// a melee headshot staggers a Scrake, at most once in so many seconds
var() int KillHealth;			// health back for each melee kill
var() float MeleeRageShare;		// the share of melee damage that counts towards a Fleshpound's rage

static function bool QualityFor( KFPlayerStats Other )
{
	Return (Other.TotalMeleeDamage>=10000);
}
static function string ProgressFor( KFPlayerStats Other )
{
	Return Tally("Melee damage dealt",Other.TotalMeleeDamage,10000);
}

static function int AddDamage( KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType )
{
	if( Class<KFWeaponDamageType>(DmgType)!=None && Class<KFWeaponDamageType>(DmgType).Default.bIsMeleeDamage )
		Return InDamage*2; //deal double damage because we swing much harder
	Return InDamage;
}
static function float GetMeleeMovementSpeedModifier()
{
	Return 0.2;
}
static function int ReduceDamage( KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType )
{
	// 80% reduced Bloat Bile damage (rounded at random: rounded down, a tick of 2 or 3 came to nothing)
	if ( class<DamTypeVomit>(DmgType) != none )
		return int(float(InDamage) * 0.20 + FRand());
	if ( class<SirenScreamDamage>(DmgType) != none )
		return float(InDamage) * 0.40; // 60% reduced Siren Scream damage

	Return float(InDamage)*0.60; //take 40% less because we're badass
}

// Reduce damage when wearing Armor
static function float GetBodyArmorDamageModifier()
{
	return 0.75;
}

static function float GetFireSpeedMod( Weapon Other )
{
	if( KFMeleeGun(Other)!=None && Welder(Other)==None )
		Return 1.3; //swing 30% faster because of our training
	Return 1;
}
static function bool CanBeGrabbed( KFMonster Other )
{
	Return !Other.IsA('ZombieClot');
}
static function float HeadStaggerGap( KFMonster Other )
{
	if ( Other.IsA('ZombieScrake') )
		Return default.ScrakeStaggerGap;
	Return 0;
}
static function int MeleeKillHealth()
{
	Return default.KillHealth;
}
static function float RageShare( class<DamageType> DmgType )
{
	if( Class<KFWeaponDamageType>(DmgType)!=None && Class<KFWeaponDamageType>(DmgType).Default.bIsMeleeDamage )
		Return default.MeleeRageShare;
	Return 1.0;
}

defaultproperties
{
	MeleeRageShare=1.000000
	bHasPerkWeapon=true
	OnHUDIcon=Texture'KFX.Berserker'
	VeterancyName="Berserker"
	VeterancyDescription="|BERSERKER||Double damage for all melee weapons|+30% refire speed for all melee weapons|+20% movement speed adjustment when using a melee weapon|+40% resistance to all forms of damage + 80% resistance to vomit damage + 60% resistance to siren scream damage + 25% better armour|Resistance to escape from clot's grabbing"
	VeterancyRequirement="|REQUIREMENTS:||- Deal 10,000 damage with melee weapons"
}
