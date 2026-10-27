class KFPackAPunchMachine extends KFZombiesUsable
	placeable;

var() int Cost;
var() int RepackCost;			// an upgraded weapon re-packed with a special ammo (KFAmmoMod)
var() float ShowTime;			// seconds the machine has the weapon (KFPaPShow)
var() string NotEnoughPointsMessage, CantUpgradeMessage, UpgradedMessage, RepackedMessage, BusyMessage;
var() sound PurchaseSound;
var KFWeapon Working;			// the weapon in it now
var Pawn WorkingFor;
var bool bWorkingRepack;
var float WorkDoneAt;

function KFWeapon GetUpgradeTarget( Pawn P )
{
	local KFWeapon W;

	W = KFWeapon(P.Weapon);
	if( W==None || W.UpgradeName=="" || W.bUpgradeBusy )
		Return None;
	Return W;
}

function string GetPrompt( Pawn P )
{
	local KFWeapon W;

	W = GetUpgradeTarget(P);
	if( W==None || Working!=None )
		Return "";
	if( W.bUpgraded )
		Return "[USE] Re-pack" @ W.UpgradeName @ "with special ammo -" @ RepackCost;
	Return "[USE] Upgrade" @ W.ItemName @ "to" @ W.UpgradeName @ "-" @ Cost;
}

function UsedBy( Pawn user )
{
	if( CanUseNow(user) )
		Upgrade(user, GetUpgradeTarget(user));
}

// (a bot names the gun it wants upgraded, not the one in its hands; an upgraded one is re-packed)
function bool Upgrade( Pawn user, KFWeapon W )
{
	local KFPaPShow Show;
	local int Price;

	if( Working!=None )
	{
		Notify(user, BusyMessage);
		Return false;
	}
	if( W==None || W.UpgradeName=="" || W.bUpgradeBusy )
	{
		Notify(user, CantUpgradeMessage);
		Return false;
	}
	Price = Cost;
	if( W.bUpgraded )
		Price = RepackCost;
	if( !Charge(user, Price) )
	{
		Notify(user, NotEnoughPointsMessage);
		Return false;
	}

	// the machine has it a while: it hums and glows in the weapon's element, then gives it back done
	Working = W;
	WorkingFor = user;
	bWorkingRepack = W.bUpgraded;
	WorkDoneAt = Level.TimeSeconds + ShowTime;
	W.bUpgradeBusy = true;
	W.NetUpdateTime = Level.TimeSeconds - 1;
	Show = Spawn(class'KFPaPShow',,, Location + vect(0,0,30));
	if( Show!=None )
	{
		Show.ShowElement = W.Element;
		Show.ShowTime = ShowTime;
	}
	Return true;
}

function Tick( float DT )
{
	Super.Tick(DT);
	if( Working!=None && Level.TimeSeconds>=WorkDoneAt )
		WorkDone();
}

function WorkDone()
{
	local KFWeapon W;

	W = Working;
	Working = None;
	if( W==None || W.bDeleteMe )
		Return;
	W.bUpgradeBusy = false;
	if( bWorkingRepack )
	{
		W.Repack();
		if( WorkingFor!=None )
			Notify(WorkingFor, RepackedMessage @ class'KFAmmoMod'.static.NameOf(W.AmmoMod) $ "!");
	}
	else
	{
		W.Upgrade();
		if( WorkingFor!=None )
			Notify(WorkingFor, UpgradedMessage @ W.UpgradeName $ "!");
	}
	W.NetUpdateTime = Level.TimeSeconds - 1;
	if( PurchaseSound!=None )
		PlaySound(PurchaseSound,,255,,100);
	WorkingFor = None;
}

defaultproperties
{
	Cost=5000
	NotEnoughPointsMessage="Not enough dosh!"
	CantUpgradeMessage="This weapon can't be upgraded."
	UpgradedMessage="Upgraded to"
	RepackCost=2500
	ShowTime=3.000000
	RepackedMessage="Re-packed with"
	BusyMessage="The machine is busy."
	PurchaseSound=Sound'GameSounds.ComboActivated'
}
