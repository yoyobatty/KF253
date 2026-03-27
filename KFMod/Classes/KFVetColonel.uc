Class KFVetColonel extends KFVeterancyTypes
	Abstract;

	
// Display enemy health bars
static function SpecialHUDInfo( Canvas C )
{
	local xPawn KFEnemy;
	local HUDKillingFloor HKF;

	HKF = HUDKillingFloor(C.ViewPort.Actor.myHUD);
	if( HKF==None || C.ViewPort.Actor.Pawn==None )
		Return;
	foreach C.ViewPort.Actor.DynamicActors(class'xPawn',KFEnemy)
	{
		if( KFEnemy.Health > 0 )
			HKF.DrawHealthBar(C, KFEnemy, KFEnemy.Health, KFEnemy.HealthMax , 50.0);
	}
}

static function bool ShowStalkers()
{
	Return True;
}

static function bool QualityFor( KFPlayerStats Other )
{
	Return True;
}

static function int AddDamage( KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType )
{
	Return InDamage*2;
}
static function float GetMeleeMovementSpeedModifier()
{
	Return 0.25;
}

static function int ReduceDamage( KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType )
{
	Return float(InDamage)*0.5; //take 50% less because we're badass
}

static function bool CanBeGrabbed( KFMonster Other )
{
	Return False;
}

static function float GetSyringeChargeRate()
{
	Return 2.5;
}
static function float GetHealPotency()
{
	Return 2;
}
static function float GetMovementSpeedModifier()
{
	Return 1.25;
}
static function float GetRecoilMovementSpeedModifier()
{
	Return 1.0;
}
static function bool HealingNades()
{
	Return True;
}
// Reduce damage when wearing Armor
static function float GetBodyArmorDamageModifier()
{
	return 0.5;
}

// Change effective range on FLamethrower
static function int ExtraRange()
{
	Return 2; // he he
}

static function float GetReloadSpeedModifier( KFWeapon Other )
{
	Return 2;
}

static function class<DamageType> GetMAC10DamageType()
{
	return class'KFMod.DamTypeFlamethrower';
}

static function float GetFireSpeedMod( Weapon Other )
{
	Return 1.5;
}

static function int AddCarryMaxWeight()
{
	Return 10;  // 10 more carry slots
}
static function float GetVeldSpeedModifier()
{
	Return 2.5;
}
static function float AddExtraAmmoFor( Class<Ammunition> AmmoType )
{
	Return 2.0;
}

static function float ModifyRecoilSpread( WeaponFire Other, out float Recoil )
{
	Return 0.25;
}
static function float GetHeadShotDamMulti()
{
	Return 1.5;
}

defaultproperties
{
	OnHUDIcon=Texture'KFPatch2.Sergeant'
	VeterancyName="Colonel"
	VeterancyDescription="|Colonel ||+Gives all perk bonuses on steroids"
	VeterancyRequirement="|REQUIREMENTS:||- None"
}
