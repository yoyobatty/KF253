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
<<<<<<< HEAD
		Return InDamage*1.25;
	Return InDamage;
}

=======
		Return InDamage*1.5;
	Return InDamage;
}

static function float AddExtraAmmoFor( Class<Ammunition> AmmoType )
{
	if( AmmoType==Class'BullpupAmmo' )
		Return 1.25;   // 25% more ammo
	Return 1;
}

static function float GetMagCapacityMod(KFWeapon Other)
{
	if(Bullpup(Other) != none)
		return 1.25;	
	return 1.0;
}

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
static function float ModifyRecoilSpread( WeaponFire Other, out float Recoil )
{
	if( Bullpup(Other.Weapon)!=None )
	{
<<<<<<< HEAD
		Recoil = 0.8;
=======
		Recoil = 0.6;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		Return Recoil;
	}
	Recoil = 1;
	Return Recoil;
}

static function float GetReloadSpeedModifier( KFWeapon Other )
{
<<<<<<< HEAD
	Return 1.1;
=======
	Return 1.35;
}

static function float GetFireSpeedMod( Weapon Other )
{
	if( Bullpup(Other) != none )
		Return 1.15; //Shoot 15% faster for fun
	Return 1;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

defaultproperties
{
<<<<<<< HEAD
	OnHUDIcon=Texture'KFX.Commando'
	VeterancyName="Commando"
	VeterancyDescription="|COMMANDO ||+ 25% damage with 'Bullpup' weapon|- 20% recoil/spread with 'bullpup' weapon|+ 10% faster reloading with all weapons|+ Enemy health conditions appear on HUD | + Automatically reveal cloaked 'Stalkers' in an AOE"
	VeterancyRequirement="|REQUIREMENTS:||- Kill at least 20 stalkers|- Deal 10,000 damage with 'bullpup'"
=======
	bHasPerkWeapon=true
	OnHUDIcon=Texture'KFX.Commando'
	VeterancyName="Commando"
	VeterancyDescription="|COMMANDO ||+50% damage with 'Bullpup' weapon|-40% recoil/spread with 'Bullpup' weapon|+35% faster reloading with all weapons|+15% Faster firing with 'Bullpup' weapon|+25% extra ammo and mag capacity with Bullpup|Enemy health conditions appear on HUD |Automatically reveal cloaked 'Stalkers' in an AOE"
	VeterancyRequirement="|REQUIREMENTS:||- Kill at least 20 stalkers|- Deal 10,000 damage with 'Bullpup'"
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
