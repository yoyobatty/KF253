Class KFVetBerserker extends KFVeterancyTypes
	Abstract;

static function bool QualityFor( KFPlayerStats Other )
{
	Return (Other.TotalMeleeDamage>=10000);
}

static function int AddDamage( KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType )
{
	if( Class<KFWeaponDamageType>(DmgType)!=None && Class<KFWeaponDamageType>(DmgType).Default.bIsMeleeDamage )
<<<<<<< HEAD
		Return InDamage*1.25;
=======
		Return InDamage*2; //deal double damage because we swing much harder
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	Return InDamage;
}
static function float GetMeleeMovementSpeedModifier()
{
<<<<<<< HEAD
	Return 0.15;
}
static function int ReduceDamage( KFPawn Injured, KFMonster DamageTaker, int InDamage, class<DamageType> DmgType )
{
	Return InDamage/1.15;
}
static function float GetFireSpeedMod( Weapon Other )
{
	if( KFMeleeGun(Other)!=None )
		Return 1.1;
=======
	Return 0.2;
}
static function int ReduceDamage( KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType )
{
	if ( class<DamTypeVomit>(DmgType) != none )
		return float(InDamage) * 0.20; // 80% reduced Bloat Bile damage
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
		Return 1.25; //swing 25% faster because of our training
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	Return 1;
}
static function bool CanBeGrabbed( KFMonster Other )
{
	Return !Other.IsA('ZombieClot');
}

defaultproperties
{
<<<<<<< HEAD
	OnHUDIcon=Texture'KFX.Berserker'
	VeterancyName="Berserker"
	VeterancyDescription="|BERSERKER||+ 25% damage for all melee weapons|+ 10% refire speed for all melee weapons|+ 15% movement speed adjustment when using a melee weapon|+ 15% resistance to all forms of damage|+ resistance to escape from clot's grabbing"
=======
	bHasPerkWeapon=true
	OnHUDIcon=Texture'KFX.Berserker'
	VeterancyName="Berserker"
	VeterancyDescription="|BERSERKER||Double damage for all melee weapons|+25% refire speed for all melee weapons|+20% movement speed adjustment when using a melee weapon|+40% resistance to all forms of damage + 80% resistance to vomit damage + 60% resistance to siren scream damage + 25% better armour|Resistance to escape from clot's grabbing"
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	VeterancyRequirement="|REQUIREMENTS:||- Deal 10,000 damage with melee weapons"
}
