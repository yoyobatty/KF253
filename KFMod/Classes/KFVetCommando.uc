Class KFVetCommando extends KFVeterancyTypes
	Abstract;

static function bool QualityFor( KFPlayerStats Other )
{
	Return (Other.StalkerKills>=20 && Other.BullpupDamage>10000);
}

// Display enemy health bars
static function SpecialHUDInfo( Canvas C )
{
	local KFMonster KFEnemy;
	local HUDKillingFloor HKF;

	HKF = HUDKillingFloor(C.ViewPort.Actor.myHUD);
	if( HKF==None || C.ViewPort.Actor.Pawn==None )
		Return;
	foreach C.ViewPort.Actor.DynamicActors(class'KFMonster',KFEnemy)
	{
		if( KFEnemy.Health > 0 && !KFEnemy.Cloaked() )
			HKF.DrawHealthBar(C, KFEnemy, KFEnemy.Health, KFEnemy.HealthMax , 50.0);
	}
}

static function bool ShowStalkers()
{
	Return True;
}

static function int AddDamage( KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType )
{
	if( DmgType==Class'DamTypeBullpup' )
		Return InDamage*1.25;
	Return InDamage;
}

static function float ModifyRecoilSpread( WeaponFire Other, out float Recoil )
{
	if( Bullpup(Other.Weapon)!=None )
	{
		Recoil = 0.8;
		Return Recoil;
	}
	Recoil = 1;
	Return Recoil;
}

static function float GetReloadSpeedModifier( KFWeapon Other )
{
	Return 1.1;
}

defaultproperties
{
	OnHUDIcon=Texture'KFX.Commando'
	VeterancyName="Commando"
	VeterancyDescription="|COMMANDO ||+ 25% damage with 'Bullpup' weapon|- 20% recoil/spread with 'bullpup' weapon|+ 10% faster reloading with all weapons|+ Enemy health conditions appear on HUD | + Automatically reveal cloaked 'Stalkers' in an AOE"
	VeterancyRequirement="|REQUIREMENTS:||- Kill at least 20 stalkers|- Deal 10,000 damage with 'bullpup'"
}
