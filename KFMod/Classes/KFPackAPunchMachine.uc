class KFPackAPunchMachine extends KFZombiesUsable
	placeable;

var() int Cost;
var() string NotEnoughPointsMessage, CantUpgradeMessage, UpgradedMessage;
var() sound PurchaseSound;

function KFWeapon GetUpgradeTarget( Pawn P )
{
	local KFWeapon W;

	W = KFWeapon(P.Weapon);
	if( W==None || W.bUpgraded || W.bMeleeWeapon || W.bIsGrenadeWeapon || KFMeleeGun(W)!=None )
		Return None;
	Return W;
}

function string GetPrompt( Pawn P )
{
	local KFWeapon W;

	W = GetUpgradeTarget(P);
	if( W==None )
		Return "";
	Return "[USE] Upgrade" @ W.ItemName @ "-" @ Cost;
}

function UsedBy( Pawn user )
{
	local KFWeapon W;

	if( !CanUseNow(user) )
		Return;

	W = GetUpgradeTarget(user);
	if( W==None )
	{
		Notify(user, CantUpgradeMessage);
		Return;
	}

	if( !Charge(user, Cost) )
	{
		Notify(user, NotEnoughPointsMessage);
		Return;
	}

	W.bUpgraded = true;
	W.MaxOutAmmo();
	W.NetUpdateTime = Level.TimeSeconds - 1;

	Notify(user, UpgradedMessage);
	if( PurchaseSound!=None )
		PlaySound(PurchaseSound,,255,,100);
}

defaultproperties
{
	Cost=5000
	NotEnoughPointsMessage="Not enough dosh!"
	CantUpgradeMessage="This weapon can't be upgraded."
	UpgradedMessage="Weapon upgraded! It hits twice as hard."
	PurchaseSound=Sound'CODSounds.1s_powerup01'
}
