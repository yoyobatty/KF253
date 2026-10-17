class KFWallWeaponBuy extends KFZombiesUsable
	placeable;

var() class<KFWeaponPickup> WeaponPickupClass;
var() int CostOverride; // 0 = use WeaponPickupClass's default Cost.
var() string NotEnoughPointsMessage, AlreadyOwnedMessage, NoAmmoBoughtMessage;
var() sound PurchaseSound;

function int GetDisplayPrice()
{
	if( WeaponPickupClass==None )
		Return 0;
	if( CostOverride>0 )
		Return CostOverride;
	Return int(float(WeaponPickupClass.Default.Cost) * class'KFPawn'.static.GetCostScaling(Level.Game.GameDifficulty));
}

function KFWeapon FindOwnedWeapon( Pawn P )
{
	local class<Weapon> WClass;
	local Inventory Inv;

	if( WeaponPickupClass==None )
		Return None;

	WClass = class<Weapon>(WeaponPickupClass.Default.InventoryType);
	if( WClass==None )
		Return None;

	For( Inv=P.Inventory; Inv!=None; Inv=Inv.Inventory )
	{
		if( Inv.Class==WClass )
			Return KFWeapon(Inv);
	}
	Return None;
}

function string GetPrompt( Pawn P )
{
	if( WeaponPickupClass==None )
		Return "";
	if( FindOwnedWeapon(P)!=None )
		Return "[USE] Buy Ammo -" @ WeaponPickupClass.Default.ItemName;
	Return "[USE] Buy" @ WeaponPickupClass.Default.ItemName @ "-" @ GetDisplayPrice();
}

function UsedBy( Pawn user )
{
	local class<Weapon> WClass;
	local KFPawn KFP;
	local KFWeapon OwnedWeapon;
	local int Price;
	local bool bBought;

	if( WeaponPickupClass==None || !CanUseNow(user) )
		Return;

	KFP = KFPawn(user);
	if( KFP==None )
		Return;

	WClass = class<Weapon>(WeaponPickupClass.Default.InventoryType);
	if( WClass==None )
		Return;

	OwnedWeapon = FindOwnedWeapon(user);
	if( OwnedWeapon!=None )
	{
		bBought = KFP.PurchaseAmmo(OwnedWeapon.AmmoClass[0], false);
		if( OwnedWeapon.AmmoClass[1]!=None && OwnedWeapon.AmmoClass[1]!=OwnedWeapon.AmmoClass[0] )
			bBought = KFP.PurchaseAmmo(OwnedWeapon.AmmoClass[1], false) || bBought;

		if( !bBought )
			Notify(user, NoAmmoBoughtMessage);
		else if( PurchaseSound!=None )
			PlaySound(PurchaseSound,,255,,100);
		Return;
	}

	Price = GetDisplayPrice();
	if( user.PlayerReplicationInfo==None || user.PlayerReplicationInfo.Score<Price )
	{
		Notify(user, NotEnoughPointsMessage);
		Return;
	}

	if( KFP.PurchaseWeapon(WClass, Price) && PurchaseSound!=None )
		PlaySound(PurchaseSound,,255,,100);
}

defaultproperties
{
	bRequireLookAt=True
	NotEnoughPointsMessage="Not enough dosh!"
	AlreadyOwnedMessage="You already have this weapon."
	NoAmmoBoughtMessage="Ammo is full, or you can't afford any."
	PurchaseSound=Sound'KFWeaponSound.GunPickupKF'
}
