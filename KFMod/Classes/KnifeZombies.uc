class KnifeZombies extends Knife;

var() float StabDuration, StabDelay;
var bool bStabActive, bStabTraced, bServerStabPending;
var float NextServerStabTime;

replication
{
	reliable if( Role<ROLE_Authority )
		ServerStab;
}

simulated event StartStab()
{
	local KFMeleeFire MF;

	MF = KFMeleeFire(GetFireMode(0));
	if( MF!=None )
		MF.ModeDoFire();

	if( Role<ROLE_Authority )
		ServerStab();

	bStabActive = true;
	bStabTraced = false;
	SetTimer(StabDelay, False);
}

function ServerStab()
{
	if( Instigator==None || Instigator.Health<=0 || Level.TimeSeconds<NextServerStabTime )
		Return;
	if( KFHumanPawn(Instigator)!=None && KFHumanPawn(Instigator).bIsDowned )
		Return;

	NextServerStabTime = Level.TimeSeconds + StabDuration*0.75;
	bServerStabPending = true;
	Instigator.SetAnimAction('KnifeStab');
	// (a network player's own stab brings its check on his speed with his move: see KFPawn.WeaponBrake)
	if( Instigator.Physics!=PHYS_Falling && KFPawn(Instigator)!=None )
		KFPawn(Instigator).WeaponBrake(ChopSlowRate);
	SetTimer(StabDelay, False);
}

simulated function Timer()
{
	local KFMeleeFire MF;

	if( bServerStabPending )
	{
		bServerStabPending = false;
		MF = KFMeleeFire(GetFireMode(0));
		if( MF!=None )
			MF.DoTrace();
	}
	else if( bStabActive && !bStabTraced )
	{
		bStabTraced = true;
		MF = KFMeleeFire(GetFireMode(0));
		if( MF!=None )
			MF.DoTrace(); //Bleh it's hacky but it works lol
		SetTimer(FMax(StabDuration - StabDelay, 0.0), False);
	}
	else if( bStabActive )
	{
		bStabActive = false;
		if( KFHumanPawnZombies(Instigator)!=None )
			KFHumanPawnZombies(Instigator).QuickMeleeFinished();
	}
	else
		Super.Timer();
}

simulated function float RateSelf()
{
	return -100;
}

simulated function Weapon PrevWeapon(Weapon CurrentChoice, Weapon CurrentWeapon)
{
	if ( Inventory == None )
		return CurrentChoice;
	else
		return Inventory.PrevWeapon(CurrentChoice,CurrentWeapon);
}
simulated function Weapon NextWeapon(Weapon CurrentChoice, Weapon CurrentWeapon)
{
	if ( Inventory == None )
		return CurrentChoice;
	else
		return Inventory.NextWeapon(CurrentChoice,CurrentWeapon);
}
simulated function Weapon WeaponChange( byte F, bool bSilent )
{
	if ( Inventory == None )
		return None;
	else return Inventory.WeaponChange(F,bSilent);
}

defaultproperties
{
	StabDuration=0.600000
	StabDelay=0.250000
	FireModeClass(0)=Class'KFMod.KnifeZombiesStabFire'
	BringUpTime=0.150000
	PutDownTime=0.200000
	SelectAnimRate=2.500000
	bSpeedMeUp=False
}
