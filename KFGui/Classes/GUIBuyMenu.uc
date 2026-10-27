class GUIBuyMenu extends UT2k4MainPage;

// The trader, laid out as Killing Floor 2's is: what the player has down the left (GUITraderInvList: each gun with its
// ammo, the armour, the grenades, and buttons on each row; Refill all above it), what is for sale down the right
// (filtered by the tabs above it, a BUY or UPGRADE button on each row), and the card of the row chosen on either side in
// the middle. A row's name double-clicked does what its button does (BuyCurrent). The footer keeps the cash, the weight
// and Complete.

const BUYLIST_CATS=7;
const CAT_ALL=0;		// (the first tab: every gun for sale)
const CAT_UPGRADES=7;	// (GUIBuyable.SALE_Upgrades: the upgrades of guns the player owns, after the controller's seven)
var automated GUIPanel p_Info;
var automated GUIListBox CategoryBox;		// the shop's tabs: not shown, the tabs choose its row
var automated GUIBuyTabs SaleTabs;			// the shop's tabs, above its list
var automated GUIBuyItemsBox ItemsBox;		// what is for sale
var automated GUITraderInvBox InvBox;		// what the player has
var automated GUITraderRefill RefillBtn;	// Refill all, above it
var automated GUISectionBackground ItemBG,InfoBG,InvBG;
var GUIList myCategories;
var GUITraderInvList myInv;
var GUIBuyable Chosen;					// the row whose card is shown
var bool bOwnChosen;					// ...on the player's own list (else the shop's)
var bool bListing;						// (the lists being made anew: their changes choose nothing)
var class<Inventory> UpgradesOf;		// the Upgrades tab shows only this gun's (its row's UPGRADES button)
var bool bKeepUpgradesOf;
var localized string UpgradesHeader, AllHeader;
var class<KFWeapon> AskedBase, AskedVariant;	// an upgrade clicked in the info panel, opened at the next frame
var GUIBuyable AskedBuy;						// an UPGRADE pressed on the card, bought at the next frame
var GUIBuyItemsList myItems;

//var KFBuyItemsList myItems;
var editconst noexport float SavedPitch;

var array<string> BuyListHeaders;
var array<string> BuyListItemNames;

//Use these values to modify/test
var int playerscore;
var float playerweight;
var float maxweight;
var float GameDifficulty;
var int PendingChecks;

var Sound SellSound,BuySound;

var array < GUIBuyable > AllBuyableItems;

function InitComponent( GUIController MyController, GUIComponent MyOwner )
{
	local int i;
	Super.InitComponent( MyController, MyOwner );

	ItemBG.ManageComponent(ItemsBox);
	InvBG.ManageComponent(InvBox);
	myCategories = CategoryBox.List;

	// (the first tab every gun; the controller's own first, My Inventory, is the list on the left now)
	myCategories.Add(AllHeader);
	for(i=1;i<BUYLIST_CATS;i++)
		myCategories.Add(KFPlayerController(PlayerOwner()).BuyListHeaders[i]);
	myCategories.Add(UpgradesHeader);

	myItems = ItemsBox.List;
	myInv = GUITraderInvList(InvBox.List);
}

event HandleParameters(string Param1, string Param2)
{
	local int i;
	local class<KFWeaponPickup> BuyWeapon;
	local KFLevelRules KFLR, KFLRit;
    
	if (PlayerOwner().GameReplicationInfo != none)
		GameDifficulty = KFGameReplicationInfo(PlayerOwner().GameReplicationInfo).GameDiff;

	//TODO: Can we get this from levelinfo?
	foreach PlayerOwner().DynamicActors(class'KFLevelRules', KFLRit)
	{
		KFLR = KFLRit;
		Break;
	}

	AllBuyableItems.Remove(0,AllBuyableItems.Length);

	for(i=0; i<KFLR.ItemForSale.Length; ++i)
	{
		if(KFLR.ItemForSale[i]!=none)
		{
			BuyWeapon = class<KFWeaponPickup>(KFLR.ItemForSale[i]);

			if(BuyWeapon!=none)
				AddWeapon(BuyWeapon,false);
			else
			{
				// Not a weapon - add as equipment
				// Given up trying to be clever now.
				// We're in the 'Hack It Good and Hard' phase now ;)
				if( class<Vest>(KFLR.ItemForSale[i])!=none)
				{
					AllBuyableItems.Insert(0,1);
					AllBuyableItems[0] = new class'BuyableVest';
					// as KFPawn.ServerBuyKevlar charges: by the armour that is missing, and by difficulty only for a player with a veterancy
					AllBuyableItems[0].cost = AllBuyableItems[0].default.cost * (100.f - PlayerOwner().Pawn.ShieldStrength)/100.f;
					if( KFPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo)!=None && KFPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo).ClientVeteranSkill!=None )
						AllBuyableItems[0].cost *= Class'KFPawn'.Static.GetCostScaling(GameDifficulty);
				}
				if( class<FirstAidKit>(KFLR.ItemForSale[i])!=none)
				{
					AllBuyableItems.Insert(0,1);
					AllBuyableItems[0] = new class'BuyableFirstAidKit';
					// as KFPawn.ServerBuyFirstAid charges: by the health that is missing
					AllBuyableItems[0].cost = Class'KFPawn'.Static.FirstAidCost(PlayerOwner().Pawn.HealthMax - PlayerOwner().Pawn.Health,
					 PlayerOwner().Pawn.HealthMax, GameDifficulty);
				}
			}
		}
	}
	AddUpgrades();
	GUIBuyMenuFooter(t_Footer).SetPlayerStats(PlayerOwner().PlayerReplicationInfo.Score,playerweight);
	CategoryChange(self);
}

// A gun on the lists, and its ammo (and its second ammo, as explosive shells). A variant of another gun is bought as an
// upgrade of that gun: it is only on the player's own list, to be sold, and its ammo on the ammo list.
function AddWeapon( class<KFWeaponPickup> BuyWeapon, bool bVariant )
{
	// Difficulty Scaling  (% of regular cost)
	// - easy  = 80%
	// - normal = 100%
	// - Skilled = 133%
	// - Elite = 166%
	// - Suicidal = 233%
	AllBuyableItems.Insert(0,1);
	AllBuyableItems[0] = new class'BuyableWeapon';
	BuyableWeapon(AllBuyableItems[0]).bVariant = bVariant;
	AllBuyableItems[0].cost = int(float(BuyWeapon.default.cost) * Class'KFPawn'.Static.GetCostScaling(GameDifficulty));
	AllBuyableItems[0].sellValue = int(BuyWeapon.default.cost * 0.75);
	AllBuyableItems[0].Weight= BuyWeapon.default.Weight;
	BuyableWeapon(AllBuyableItems[0]).PowerValue=BuyWeapon.default.PowerValue;
	BuyableWeapon(AllBuyableItems[0]).RangeValue=BuyWeapon.default.RangeValue;
	BuyableWeapon(AllBuyableItems[0]).SpeedValue=BuyWeapon.default.SpeedValue;
	AllBuyableItems[0].Description = BuyWeapon.default.Description;
	AllBuyableItems[0].ItemName=BuyWeapon.default.ItemName;
	AllBuyableItems[0].showMesh=BuyWeapon.default.ShowMesh;
	AllBuyableItems[0].relatedInventory=BuyWeapon.default.InventoryType;
	// (its ammo, for the fill button on what the player owns)
	BuyableWeapon(AllBuyableItems[0]).AmmoType = class<KFWeapon>(BuyWeapon.default.InventoryType).default.FireModeClass[0].default.AmmoClass;

	if(class<KFWeapon>(BuyWeapon.default.InventoryType).default.bKFNeverThrow==true)
		BuyableWeapon(AllBuyableItems[0]).bHideSale=true;

	// (a gun added only to stand for one the player has, as a variant or the 9mm, does not sell its ammo twice)
	if(class<KFWeapon>(BuyWeapon.default.InventoryType).default.FireModeClass[0].default.AmmoClass!=none
	 && !(bVariant && SellsAmmo(class<KFWeapon>(BuyWeapon.default.InventoryType).default.FireModeClass[0].default.AmmoClass)))
	{
		AllBuyableItems.Insert(0,1);
		AllBuyableItems[0] = new class'BuyableAmmo';
		AllBuyableItems[0].cost = int(BuyWeapon.default.ammocost * Class'KFPawn'.Static.GetCostScaling(GameDifficulty));
		AllBuyableItems[0].myShowMesh=BuyWeapon.default.AmmoMesh;

		// Little hack for the LAW ammo :P  it's huge.
		if(BuyWeapon.default.AmmoMesh == StaticMesh'KillingFloorStatics.LAWAmmo')
			AllBuyableItems[0].infoDrawScale *= 0.5;

		AllBuyableItems[0].ItemName=BuyWeapon.default.AmmoItemName;
		AllBuyableItems[0].relatedInventory=BuyWeapon.default.InventoryType;
		BuyableAmmo(AllBuyableItems[0]).ammoType=class<KFWeapon>(BuyWeapon.default.InventoryType).default.FireModeClass[0].default.AmmoClass;

		// Add a separate entry for weapons that have a secondary ammo type (e.g. explosive shells)
		if (class<KFWeapon>(BuyWeapon.default.InventoryType).default.FireModeClass[1] != None &&
			class<KFWeapon>(BuyWeapon.default.InventoryType).default.FireModeClass[1].default.AmmoClass != None &&
			class<KFWeapon>(BuyWeapon.default.InventoryType).default.FireModeClass[1].default.AmmoClass !=
				class<KFWeapon>(BuyWeapon.default.InventoryType).default.FireModeClass[0].default.AmmoClass)
		{
			AllBuyableItems.Insert(0,1);
			AllBuyableItems[0] = new class'BuyableAmmo';
			if (BuyWeapon.default.SecondaryAmmoCost > 0)
				AllBuyableItems[0].cost = int(BuyWeapon.default.SecondaryAmmoCost * Class'KFPawn'.Static.GetCostScaling(GameDifficulty));
			else
				AllBuyableItems[0].cost = int(BuyWeapon.default.ammocost * Class'KFPawn'.Static.GetCostScaling(GameDifficulty));
			AllBuyableItems[0].myShowMesh=BuyWeapon.default.AmmoMesh;
			if (BuyWeapon.default.SecondaryAmmoItemName != "")
				AllBuyableItems[0].ItemName = BuyWeapon.default.SecondaryAmmoItemName;
			else
				AllBuyableItems[0].ItemName = BuyWeapon.default.AmmoItemName@"(Alt)";
			AllBuyableItems[0].relatedInventory=BuyWeapon.default.InventoryType;
			BuyableAmmo(AllBuyableItems[0]).ammoType=class<KFWeapon>(BuyWeapon.default.InventoryType).default.FireModeClass[1].default.AmmoClass;
		}
	}
}

function bool SellsAmmo(class<Ammunition> A)
{
	local int i;

	for(i=0;i<AllBuyableItems.length;i++)
	{
		if( BuyableAmmo(AllBuyableItems[i])!=None && BuyableAmmo(AllBuyableItems[i]).ammoType==A )
			return true;
	}
	return false;
}

// The trader's upgrades (KFTraderUpgrades), each for a gun the player may own, and the variants they make (to be sold)
function AddUpgrades()
{
	local int i;
	local class<KFWeapon> B,V;
	local class<KFWeaponPickup> P;
	local BuyableUpgrade U;

	for(i=0;i<class'KFTraderUpgrades'.default.Lines.Length;i++)
	{
		B = class'KFTraderUpgrades'.default.Lines[i].Base;
		V = class'KFTraderUpgrades'.default.Lines[i].Variant;
		if( B==None )
			continue;
		if( V!=None && FindWeapon(V)==None && class<KFWeaponPickup>(V.default.PickupClass)!=None )
			AddWeapon(class<KFWeaponPickup>(V.default.PickupClass),true);
		U = new class'BuyableUpgrade';
		U.Line = i;
		U.Base = B;
		U.Variant = V;
		U.cost = int(float(class'KFTraderUpgrades'.static.PriceOf(i)) * Class'KFPawn'.Static.GetCostScaling(GameDifficulty));
		if( V!=None )
		{
			U.weight = V.default.Weight-B.default.Weight;
			U.relatedInventory = V;
			P = class<KFWeaponPickup>(V.default.PickupClass);
		}
		else
		{
			U.relatedInventory = B;
			P = class<KFWeaponPickup>(B.default.PickupClass);
		}
		U.ItemName = class'KFTraderUpgrades'.static.NameOf(i);
		U.Description = class'KFTraderUpgrades'.static.InfoOf(i);
		if( V!=None )
			U.Description = U.Description @ "It takes the place of your" @ B.default.ItemName$".";
		if( P!=None )
		{
			U.showMesh = P.default.ShowMesh;
			U.PowerValue = P.default.PowerValue;
			U.RangeValue = P.default.RangeValue;
			U.SpeedValue = P.default.SpeedValue;
		}
		AllBuyableItems[AllBuyableItems.Length] = U;
	}
}

function KFBuyMenuClosed(optional Bool bCanceled)
{
	local rotator NewRot;

	// Reset player
	NewRot = PlayerOwner().Rotation;
	NewRot.Pitch = SavedPitch;
	PlayerOwner().SetRotation(NewRot);

	Super.OnClose(bCanceled);

	//Indicate that we're not buying things.
	KFPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo).bStartingEquipmentChosen = true;
}

event Opened(GUIComponent Sender)
{
	local rotator PlayerRot;

	Super.Opened(Sender);
	// Set camera's pitch to zero when menu initialised (otherwise spinny weap goes kooky)
	PlayerRot = PlayerOwner().Rotation;
	SavedPitch = PlayerRot.Pitch;
	PlayerRot.Yaw = PlayerRot.Yaw % 65536;
	PlayerRot.Pitch = 0;
	PlayerRot.Roll = 0;
	PlayerOwner().SetRotation(PlayerRot);
	SetTimer(1,True);
	UpdateCosts(None);
}

function NewInfo(GUIBuyable b)
{
	if(p_Info != None)
	{
		RemoveComponent(p_Info,true);
		InfoBG.UnmanageComponent(p_Info);
		p_Info.Closed(p_Info,false);
		p_Info.free();
		p_Info = None;
	}
	if(b != None)
		p_Info = new b.GetPanelType(eSaleCat(myCategories.Index));
	else
		p_Info = new class'GUIBuyInfoPanel';
	p_Info.WinLeft=0;
	p_Info.WinTop=0;
	p_Info.WinWidth=1;
	p_Info.WinHeight=1;
	AppendComponent(p_Info,true);
	InfoBG.ManageComponent(p_Info);
	if(p_Info.IsA('GUIBuyInfoPanel'))
		GUIBuyInfoPanel(p_Info).Display(b);
}

function bool CanAfford(GUIBuyable b)
{
	return b!=None && playerscore-b.cost >=0 && (b.weight<=0 || playerweight+b.weight <= maxweight);
}
// Why a thing on the shop's list cannot be bought: too dear, or too heavy for what is carried already
function bool TooDear(GUIBuyable b)
{
	return playerscore<b.cost;
}
function bool TooHeavy(GUIBuyable b)
{
	return b.weight>0 && playerweight+b.weight>maxweight;
}

// The tabs, the Info panel and the footer stop short of the round clock the HUD draws in the top right corner, under the
// menu; the footer runs the menu's width, with the cash and the weight at its left. (And an upgrade clicked in the Info
// panel is opened here, a frame later: the click came from inside the panel that opening it replaces.)
function bool ClearClock(Canvas C)
{
	local float R;
	local HUDKillingFloor H;

	// (the right edge it had)
	R = 0.946916;
	H = HUDKillingFloor(PlayerOwner().myHUD);
	if( H!=None && C.ClipX>0 )
		R = FMin(R, 1.0-(H.HudUnits(H.CornerUnits)+C.ClipX*0.006)/C.ClipX);
	SaleTabs.WinWidth = R-SaleTabs.WinLeft;
	ItemBG.WinWidth = R-ItemBG.WinLeft;
	t_Footer.WinLeft = InvBG.WinLeft;
	t_Footer.WinWidth = R-InvBG.WinLeft;
	if( AskedBase!=None )
	{
		ShowUpgrade(AskedBase,AskedVariant);
		AskedBase = None;
	}
	if( AskedBuy!=None )
	{
		BuyGun(AskedBuy);
		AskedBuy = None;
	}
	return false;
}

// An UPGRADE pressed on the card (GUIBuyUpgradeLines): the card is made anew by the purchase, so it waits for the frame
function AskBuy(GUIBuyable b)
{
	AskedBuy = b;
}

function AskUpgrade(class<KFWeapon> Base, class<KFWeapon> Variant)
{
	AskedBase = Base;
	AskedVariant = Variant;
}

// The Upgrades tab, with one upgrade of a gun the player owns chosen
function ShowUpgrade(class<KFWeapon> Base, class<KFWeapon> Variant)
{
	local int i;

	UpgradesOf = None;
	if( myCategories.Index!=CAT_UPGRADES )
		myCategories.SetIndex(CAT_UPGRADES);
	else
		CategoryChange(self);
	for(i=0;i<myItems.Elements.Length;i++)
	{
		if( BuyableUpgrade(myItems.Elements[i])!=None && BuyableUpgrade(myItems.Elements[i]).Base==Base
		 && BuyableUpgrade(myItems.Elements[i]).Variant==Variant )
			myItems.SetIndex(i);
	}
}

// A gun's UPGRADES button: the Upgrades tab with only that gun's
function ShowUpgradesFor(class<Inventory> C)
{
	bKeepUpgradesOf = true;
	UpgradesOf = C;
	if( myCategories.Index!=CAT_UPGRADES )
		myCategories.SetIndex(CAT_UPGRADES);
	else
		CategoryChange(self);
	bKeepUpgradesOf = false;
}

// Whether a gun the player has can be upgraded now
function bool HasUpgrades(KFWeapon W)
{
	local int i;

	if( W==None || W.bUpgraded )
		return false;
	for(i=0;i<AllBuyableItems.length;i++)
	{
		if( BuyableUpgrade(AllBuyableItems[i])!=None && BuyableUpgrade(AllBuyableItems[i]).Base==W.Class )
			return true;
	}
	return false;
}

// The gun the player owns that a row stands for
function KFWeapon OwnedGun(GUIBuyable b)
{
	local Inventory I;

	if( b==None || PlayerOwner().Pawn==None )
		return None;
	for( I=PlayerOwner().Pawn.Inventory; I!=None; I=I.Inventory )
	{
		if( I.Class==b.relatedInventory )
			return KFWeapon(I);
	}
	return None;
}

// A gun on the player's own list has its upgrade's name after its own
function string RowName(GUIBuyable b)
{
	local KFWeapon W;

	if( BuyableWeapon(b)!=None )
	{
		W = OwnedGun(b);
		if( W!=None && W.bUpgraded && W.UpgradeName!="" && !class'KFTraderUpgrades'.static.IsVariant(W.Class) )
			return b.ItemName@"("$W.UpgradeName$")";
	}
	return b.ItemName;
}

function string InvName(int i)
{
	if( i<0 || i>=myInv.Elements.Length )
		return "";
	if( BuyableWeapon(myInv.Elements[i])==None && myInv.GunOf[i]!=None && !myInv.GunOf[i].IsA('Frag') )
		return myInv.GunOf[i].ItemName;
	return RowName(myInv.Elements[i]);
}

function bool CanSell(GUIBuyable b)
{
	return BuyableWeapon(b)!=None && BuyableUpgrade(b)==None && !BuyableWeapon(b).bHideSale && OwnedGun(b)!=None;
}

// The ammo the trader sells that a gun the player has takes (its own row's, if it has one)
function BuyableAmmo AmmoOfGun(KFWeapon W)
{
	local int i;
	local BuyableAmmo Any;

	if( W==None || W.AmmoClass[0]==None )
		return None;
	for(i=0;i<AllBuyableItems.length;i++)
	{
		if( BuyableAmmo(AllBuyableItems[i])!=None && BuyableAmmo(AllBuyableItems[i]).ammoType==W.AmmoClass[0] )
		{
			if( AllBuyableItems[i].relatedInventory==W.Class )
				return BuyableAmmo(AllBuyableItems[i]);
			if( Any==None )
				Any = BuyableAmmo(AllBuyableItems[i]);
		}
	}
	return Any;
}

// What healing to full costs now, as KFPawn.ServerBuyFirstAid charges
function int HealCost()
{
	local Pawn P;

	P = PlayerOwner().Pawn;
	if( P==None || P.Health>=P.HealthMax )
		return 0;
	return Class'KFPawn'.Static.FirstAidCost(P.HealthMax - P.Health, P.HealthMax, GameDifficulty);
}

// What selling a gun pays: three quarters of its price, and of what its upgrade cost at the trader (KFPawn.ServerSellWeapon)
function float SellValueOf(GUIBuyable b)
{
	local KFWeapon W;

	W = OwnedGun(b);
	if( W!=None )
		return b.sellValue+int(W.UpgradePaid*0.75);
	return b.sellValue;
}

// The ammo the trader sells for a gun
function BuyableAmmo AmmoFor(BuyableWeapon W)
{
	local int i;

	if( W==None )
		return None;
	for(i=0;i<AllBuyableItems.length;i++)
	{
		if( BuyableAmmo(AllBuyableItems[i])!=None && AllBuyableItems[i].relatedInventory==W.relatedInventory
		 && BuyableAmmo(AllBuyableItems[i]).ammoType==W.AmmoType )
			return BuyableAmmo(AllBuyableItems[i]);
	}
	return None;
}
// What a row of the player's own list fills: its ammo
function BuyableAmmo FillTarget(GUIBuyable b)
{
	local int i;

	if( !bOwnChosen )
		return None;
	for(i=0;i<myInv.Elements.Length;i++)
	{
		if( myInv.Elements[i]==b )
			return myInv.AmmoOf[i];
	}
	return None;
}

// Another tab: its list from its top, its first row chosen
function CategoryChange(GUIComponent Sender)
{
	if( !bKeepUpgradesOf )
		UpgradesOf = None;
	Chosen = None;
	bOwnChosen = false;
	myItems.SetTopItem(0);
	Relist();
}

// The shop's list for the tab shown
function FillShop()
{
	local int i,j;
	local Pawn P;
	local GUIBuyable b;
	local bool bShow;

	myItems.Clear();
	i = myCategories.Index;
	P = PlayerOwner().Pawn;
	for(j=0;j<AllBuyableItems.length;j++)
	{
		b = AllBuyableItems[j];
		if( i==CAT_ALL )
			bShow = b.ShowMe(P,eSaleCat(1),self) || b.ShowMe(P,eSaleCat(2),self) || b.ShowMe(P,eSaleCat(3),self) || b.ShowMe(P,eSaleCat(4),self);
		else if( i==CAT_UPGRADES )
			bShow = b.ShowMe(P,eSaleCat(i),self) && (UpgradesOf==None || BuyableUpgrade(b).Base==UpgradesOf);
		else
			bShow = b.ShowMe(P,eSaleCat(i),self);
		if( bShow )
			myItems.Add(b);
	}
	// (the list's box is named for the tab shown)
	if( i==CAT_UPGRADES && UpgradesOf!=None )
		ItemBG.Caption = "Upgrades:"@UpgradesOf.default.ItemName;
	else if( i>=0 && i<myCategories.ItemCount )
		ItemBG.Caption = myCategories.GetItemAtIndex(i);
}

// The player's own list: the armour, a medical kit (when the trader sells one), the grenades, then the guns in the order
// of their groups, each with the ammo the trader sells for it. (A gun not on the trader's lists, as the 9mm, is added
// to stand for it, without its ammo when that is sold already.)
function FillInv()
{
	local Inventory I;
	local KFWeapon W;
	local BuyableWeapon B;
	local BuyableAmmo A;
	local Pawn P;
	local int k,j;
	local array<KFWeapon> Guns;

	myInv.Clear();
	P = PlayerOwner().Pawn;
	if( P==None )
		return;
	if( FindVest()!=None )
		myInv.AddRow(FindVest(),None,None);
	for(k=0;k<AllBuyableItems.length;k++)
	{
		if( BuyableFirstAidKit(AllBuyableItems[k])!=None )
			myInv.AddRow(AllBuyableItems[k],None,None);
	}
	for( I=P.Inventory; I!=None; I=I.Inventory )
	{
		W = KFWeapon(I);
		if( W==None || W.IsA('Syringe') || W.IsA('Welder') )
			continue;
		if( W.IsA('Frag') )
		{
			A = AmmoOfGun(W);
			if( A!=None )
				myInv.AddRow(A,A,W);
			continue;
		}
		for(j=0;j<Guns.Length;j++)
		{
			if( Guns[j].InventoryGroup*100+Guns[j].GroupOffset > W.InventoryGroup*100+W.GroupOffset )
				break;
		}
		Guns.Insert(j,1);
		Guns[j] = W;
	}
	for(j=0;j<Guns.Length;j++)
	{
		W = Guns[j];
		B = FindWeapon(W.Class);
		if( B==None && class<KFWeaponPickup>(W.PickupClass)!=None )
		{
			AddWeapon(class<KFWeaponPickup>(W.PickupClass),true);
			B = FindWeapon(W.Class);
		}
		// (one just sold here, still on its way out on a network client)
		if( B!=None && !B.HasMe(P) )
			continue;
		A = AmmoOfGun(W);
		if( B!=None )
			myInv.AddRow(B,A,W);
		else if( A!=None )
			myInv.AddRow(A,A,W);
	}
}

// A row chosen on one of the lists (a click, a key, or a script): its card in the middle
function ListChose(GUIBuyItemsList L)
{
	if( bListing || L==None || L.Index<0 || L.Index>=L.Elements.Length )
		return;
	Chosen = L.Elements[L.Index];
	bOwnChosen = (L==myInv);
	NewInfo(Chosen);
}

function CloseSale(bool savePurchases)
{
	// Change weapons, when we sell.
//	PlayerOwner().SwitchToBestWeapon();
	Controller.CloseMenu(!savePurchases);

	//Indicate that we're not buying things.
	KFPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo).bStartingEquipmentChosen = true;
}

// What a thing that is not a weapon will be charged at: a clip of ammo (nothing when there is no room for more),
// armour by what is missing of it, anything else its price
function float Charge(GUIBuyable b)
{
	if( BuyableAmmo(b)!=None && BuyableAmmo(b).FillCost(PlayerOwner().Pawn)<=0 )
		Return 0;
	if( BuyableVest(b)!=None )
		Return VestCost();
	Return b.cost;
}
// The cash shown, after something that costs Ask was asked for. Playing alone the purchase is made already and the
// cash is read off. On a network client the answer is still on its way: the price is taken off meanwhile, and the
// once-a-second look puts it right if the server said no. (Before, the cash shown stood still for a second or two
// after ammo or armour was bought.)
function Paid(float Was, float Ask)
{
	local float Is;

	Is = PlayerOwner().PlayerReplicationInfo.Score;
	if( Is!=Was )
		playerscore = Is;
	else if( PlayerOwner().Level.NetMode==NM_Client )
		playerscore = Max(0,playerscore-int(Ask));
}
// Both lists made anew, with the row that was chosen chosen again; if it is gone (sold, or bought from the shop's list
// and not on the player's yet) the shop's first row
function Relist()
{
	local int i, ShopTop, InvTop;
	local bool bFound;

	// (each list kept where it was scrolled to: made anew it showed its top again, after every purchase)
	ShopTop = myItems.Top;
	InvTop = myInv.Top;
	bListing = true;
	FillShop();
	FillInv();
	myItems.SetTopItem(ShopTop);
	myInv.SetTopItem(InvTop);
	if( Chosen!=None && bOwnChosen )
	{
		for(i=0;i<myInv.Elements.Length;i++)
		{
			if( myInv.Elements[i]==Chosen )
			{
				myInv.SetIndex(i);
				bFound = true;
			}
		}
	}
	else if( Chosen!=None )
	{
		for(i=0;i<myItems.Elements.Length;i++)
		{
			if( myItems.Elements[i]==Chosen )
			{
				myItems.SetIndex(i);
				bFound = true;
			}
		}
	}
	if( !bFound )
	{
		bOwnChosen = false;
		Chosen = None;
		if( myItems.Elements.Length>0 )
		{
			myItems.SetIndex(0);
			Chosen = myItems.Elements[0];
		}
	}
	bListing = false;
	NewInfo(Chosen);
	if( GUIBuyMenuFooter(t_Footer)!=None )
		GUIBuyMenuFooter(t_Footer).SetPlayerStats(playerscore,playerweight);
}

function BuyableVest FindVest()
{
	local int i;
	for(i=0;i<AllBuyableItems.length;i++)
	{
		if( BuyableVest(AllBuyableItems[i])!=None )
			Return BuyableVest(AllBuyableItems[i]);
	}
	Return None;
}
// What mending the armour costs now, as KFPawn.ServerBuyKevlar charges; nothing if it is whole or not sold here
function float VestCost()
{
	local float C;
	local Pawn P;

	P = PlayerOwner().Pawn;
	if( P==None || P.ShieldStrength>=100 || FindVest()==None )
		Return 0;
	C = class'BuyableVest'.default.cost * (100.f - P.ShieldStrength)/100.f;
	if( KFPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo)!=None && KFPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo).ClientVeteranSkill!=None )
		C *= Class'KFPawn'.Static.GetCostScaling(GameDifficulty);
	Return C;
}
// What filling every weapon's ammo costs now
function float AmmoCost()
{
	local float C;
	local int i;

	for(i=0;i<AllBuyableItems.length;i++)
	{
		if( BuyableAmmo(AllBuyableItems[i])!=None && AllBuyableItems[i].ShowMe(PlayerOwner().Pawn,eSaleCat(5),self) )
			C += BuyableAmmo(AllBuyableItems[i]).FillCost(PlayerOwner().Pawn);
	}
	Return C;
}
// The refill button fills the ammo, and mends the armour as well when there is cash for both
function bool RefillsArmour()
{
	local float V;

	V = VestCost();
	Return V>0 && playerscore>=AmmoCost()+V;
}
function float RefillCost()
{
	if( RefillsArmour() )
		Return AmmoCost()+VestCost();
	Return AmmoCost();
}
// (with less cash than a full refill, what it will spend: all of it)
function string RefillCaption()
{
	local float C;

	C = RefillCost();
	if( C<=0 )
		Return "Refill all";
	if( RefillsArmour() || VestCost()<=0 )
		Return "Refill all:"@int(FMin(C,playerscore));
	Return "Refill ammo:"@int(FMin(C,playerscore));
}
// A row's name double-clicked (GUIBuyItemsList.DoubleClicked): on the shop's list bought (or upgraded); on the player's
// own the armour mended, the health made whole, the ammo filled. (Never a sale: that is its SELL only.)
function BuyCurrent()
{
	if( Chosen==None )
		Return;
	if( bOwnChosen && BuyableVest(Chosen)!=None )
		MendArmour();
	else if( bOwnChosen && BuyableFirstAidKit(Chosen)!=None )
		Heal(Chosen);
	else if( bOwnChosen )
		BuyFill();
	else
		BuyGun(Chosen);
}

// A gun (or an upgrade) from the shop's list; then it is chosen on the player's own list
function BuyGun(GUIBuyable b)
{
	local int i;

	if( b==None || !CanAfford(b) || !b.CanButtonMe(PlayerOwner(),true) )
		Return;
	b.BuyMe(KFPawn(playerOwner().Pawn));
	// (an upgrade may have put another gun in the place of one: what is owned is read again)
	if( BuyableUpgrade(b)!=None )
	{
		for(i=0;i<AllBuyableItems.length;i++)
		{
			if( BuyableWeapon(AllBuyableItems[i])!=None )
				BuyableWeapon(AllBuyableItems[i]).bInitalInit = False;
		}
	}
	if( b.relatedInventory!=None && b.relatedInventory.default.PickupClass!=None )
		BuySound = b.relatedInventory.default.PickupClass.default.PickupSound;
	else BuySound = default.BuySound;
	PlayerOwner().pawn.PlaySound(BuySound,SLOT_Interface,255.0,,120);
	playerscore -= b.cost;
	playerweight += b.weight;
	PendingChecks = 2;
	Chosen = FindWeapon(b.relatedInventory);
	bOwnChosen = Chosen!=None;
	Relist();
}

function SellGun(GUIBuyable b)
{
	local float Pays;

	if( !CanSell(b) )
		Return;
	// (what it pays, read before it is gone)
	Pays = SellValueOf(b);
	b.SellMe(KFPawn(playerOwner().Pawn));
	PlayerOwner().pawn.PlaySound(SellSound,SLOT_Interface,255.0,,120);
	playerscore += Pays;
	playerweight -= b.weight;
	PendingChecks = 2;
	Relist();
}

// A button on a row of the player's own list (GUITraderInvList): 1 a clip, 2 fill (the armour mended, the health made
// whole), 3 sell, 4 the gun's upgrades
function InvAction(int Item, byte Act)
{
	local GUIBuyable b;

	if( Item<0 || Item>=myInv.Elements.Length )
		Return;
	b = myInv.Elements[Item];
	if( Act==1 )
		BuyClip(myInv.AmmoOf[Item]);
	else if( Act==2 && BuyableVest(b)!=None )
		MendArmour();
	else if( Act==2 && BuyableFirstAidKit(b)!=None )
		Heal(b);
	else if( Act==2 )
		FillAmmo(myInv.AmmoOf[Item]);
	else if( Act==3 )
		SellGun(b);
	else if( Act==4 && myInv.GunOf[Item]!=None )
		ShowUpgradesFor(myInv.GunOf[Item].Class);
}

function BuyClip(BuyableAmmo A)
{
	local float Was;

	if( A==None )
		Return;
	Was = PlayerOwner().PlayerReplicationInfo.Score;
	A.BuyMe(KFPawn(playerOwner().Pawn));
	Paid(Was,A.cost);
	PendingChecks = 2;
	Relist();
}

function FillAmmo(BuyableAmmo A)
{
	local float Was,Ask;

	if( A==None )
		Return;
	Was = PlayerOwner().PlayerReplicationInfo.Score;
	Ask = A.FillCost(PlayerOwner().Pawn);
	A.FillMe(KFPawn(playerOwner().Pawn));
	Paid(Was,Ask);
	PendingChecks = 2;
	Relist();
}

function MendArmour()
{
	local float Was,Ask;

	if( FindVest()==None )
		Return;
	Was = PlayerOwner().PlayerReplicationInfo.Score;
	Ask = VestCost();
	FindVest().BuyMe(KFPawn(playerOwner().Pawn));
	Paid(Was,Ask);
	PendingChecks = 2;
	Relist();
}

function Heal(GUIBuyable b)
{
	local float Was,Ask;

	Was = PlayerOwner().PlayerReplicationInfo.Score;
	Ask = HealCost();
	b.BuyMe(KFPawn(playerOwner().Pawn));
	Paid(Was,Ask);
	PendingChecks = 2;
	Relist();
}

// A button drawn on a row: a box, lit while the mouse is on it, grey when it cannot be pressed; its caption, and its price
// under it (Price -1: none). Look 0 is the trader's red, 1 green (selling). Where it was drawn is noted on the list.
function DrawButton(Canvas C, GUIBuyItemsList L, float X, float Y, float W, float H, string Cap, int Price, bool bOn, byte Look, int Item, byte Act)
{
	DrawBox(C,L.SectionStyle,X,Y,W,H,Cap,Price,bOn,Look,FNS_Small);
	if( bOn )
		L.AddHit(Item,Act,X,Y,W,H);
}
// (the box and its words, in the style St: Refill all above the player's list is drawn so too)
function DrawBox(Canvas C, GUIStyles St, float X, float Y, float W, float H, string Cap, int Price, bool bOn, byte Look, eFontScale FS)
{
	local bool bOver;
	local eMenuState S;

	bOver = bOn && Controller.MouseX>=X && Controller.MouseX<=X+W && Controller.MouseY>=Y && Controller.MouseY<=Y+H;
	C.Style = 5;
	if( !bOn )
		C.SetDrawColor(38,38,38,215);
	else if( Look==1 && bOver )
		C.SetDrawColor(70,150,60,245);
	else if( Look==1 )
		C.SetDrawColor(40,100,40,235);
	else if( bOver )
		C.SetDrawColor(190,45,40,245);
	else
		C.SetDrawColor(125,22,22,235);
	C.SetPos(X,Y);
	C.DrawTile(Texture'Engine.WhiteTexture',W,H,0,0,1,1);
	if( !bOn )
		C.SetDrawColor(85,85,85,255);
	else if( Look==1 )
		C.SetDrawColor(120,200,110,255);
	else
		C.SetDrawColor(230,90,70,255);
	C.SetPos(X,Y);
	C.DrawTile(Texture'Engine.WhiteTexture',W,1,0,0,1,1);
	C.SetPos(X,Y+H-1);
	C.DrawTile(Texture'Engine.WhiteTexture',W,1,0,0,1,1);
	C.SetPos(X,Y);
	C.DrawTile(Texture'Engine.WhiteTexture',1,H,0,0,1,1);
	C.SetPos(X+W-1,Y);
	C.DrawTile(Texture'Engine.WhiteTexture',1,H,0,0,1,1);
	C.SetDrawColor(255,255,255,255);
	S = MSAT_Blurry;
	if( !bOn )
		S = MSAT_Disabled;
	if( St!=None )
	{
		if( Price>=0 )
		{
			St.DrawText(C,S,X,Y+H*0.04,W,H*0.5,TXTA_Center,Cap,FS);
			St.DrawText(C,S,X,Y+H*0.46,W,H*0.5,TXTA_Center,string(Price),FS);
		}
		else
			St.DrawText(C,S,X,Y,W,H,TXTA_Center,Cap,FS);
	}
}

function BuyFill()
{
	FillAmmo(FillTarget(Chosen));
}

// (with less cash than a full refill it buys what the cash pays for)
function bool CanAutoAmmo()
{
	return RefillCost()>0 && playerscore>0;
}
function DoAutoAmmo()
{
	local int i;
	local float Was,Ask;
	local bool bArmour;

	Was = PlayerOwner().PlayerReplicationInfo.Score;
	Ask = RefillCost();
	bArmour = RefillsArmour();

	if( playerscore<Ask )
		Ask = ShareAmmo(playerscore);
	else
	{
		for(i=0;i<AllBuyableItems.length;i++)
		{
			if(AllBuyableItems[i].IsA('BuyableAmmo') )
			{
				if(AllBuyableItems[i].ShowMe(PlayerOwner().Pawn,eSaleCat(5),self))
					BuyableAmmo(AllBuyableItems[i]).FillMe(KFPawn(playerOwner().pawn));
			}
		}
		if( bArmour && FindVest()!=None )
			FindVest().BuyMe(KFPawn(playerOwner().pawn));
	}
	Paid(Was,Ask);
	PendingChecks = 2;
	Relist();
}

// Less cash than a full refill: clip by clip, one gun after another, so each gets a share; the last of a gun's room,
// less than a clip, is filled for what it costs (a clip bought into it would be paid in full). What it spends is
// returned.
function float ShareAmmo(float Budget)
{
	local array<BuyableAmmo> A;
	local array<int> Have,Most,Clip;
	local int i,n,h,m,c,Rounds;
	local float Price,Spent;
	local bool bAny;
	local Pawn P;

	P = PlayerOwner().Pawn;
	for(i=0;i<AllBuyableItems.length;i++)
	{
		if( BuyableAmmo(AllBuyableItems[i])!=None && AllBuyableItems[i].ShowMe(P,eSaleCat(5),self)
		 && BuyableAmmo(AllBuyableItems[i]).Holding(P,h,m,c) && h<m )
		{
			n = A.Length;
			A[n] = BuyableAmmo(AllBuyableItems[i]);
			Have[n] = h;
			Most[n] = m;
			Clip[n] = c;
		}
	}
	for(Rounds=0;Rounds<200 && Budget>0;Rounds++)
	{
		bAny = False;
		for(i=0;i<A.Length && Budget>0;i++)
		{
			if( Have[i]>=Most[i] )
				continue;
			n = Min(Clip[i],Most[i]-Have[i]);
			Price = float(n)/float(Clip[i])*A[i].cost;
			if( Price<=Budget )
			{
				if( n<Clip[i] )
					A[i].FillMe(KFPawn(P));
				else A[i].BuyMe(KFPawn(P));
				Have[i] += n;
			}
			else
			{
				// (too little left for that: what is left buys the rounds it pays for, if one, and this ammo is done)
				n = int(Budget*float(Clip[i])/A[i].cost);
				Price = float(n)*A[i].cost/float(Clip[i]);
				if( n>0 )
					A[i].FillMe(KFPawn(P));
				Have[i] = Most[i];
			}
			Spent += Price;
			Budget -= Price;
			bAny = bAny || n>0;
		}
		if( !bAny )
			break;
	}
	return Spent;
}

function BuyableWeapon FindWeapon(class<Inventory> WeaponType)
{
	local int i;

	for(i=0;i<AllBuyableItems.length;i++)
	{
		if(AllBuyableItems[i].IsA('BuyableWeapon') && !AllBuyableItems[i].IsA('BuyableUpgrade') && AllBuyableItems[i].RelatedInventory==WeaponType)
			return BuyableWeapon(AllBuyableItems[i]);
	}
	// couldn't find it
	return none;
}

function InitAmmoForNewGun()
{
	local int i;

	for(i=0;i<AllBuyableItems.length;i++)
	{
		if( AllBuyableItems[i].IsA('BuyableAmmo') )
			BuyAbleAmmo(AllBuyableItems[i]).InitNewPurchase(PlayerOwner().Pawn);
	}
}

function UpdateCosts(GUIComponent Sender)
{
	local PlayerController PC;
	local float W;
	local int S,i;
	local bool bAgain;

	// Once a second: the cash and the weight the server has. When they have changed, or something was just bought
	// or sold, what the player owns is read again and the list and the buttons are made anew, so that a purchase
	// the server refused does not stay shown as made.
	PC = PlayerOwner();
	if( KFHumanPawn(PC.Pawn)==None ) Return;
	maxweight = KFHumanPawn(PC.Pawn).MaxCarryWeight;
	if( PendingChecks>0 )
	{
		// (the answer to what was just asked for may not be here yet: the menu's own count stands a second longer)
		PendingChecks--;
		if( PendingChecks>0 )
			Return;
		bAgain = True;
	}
	S = PC.PlayerReplicationInfo.Score;
	W = KFHumanPawn(PC.Pawn).CurrentWeight;
	if( S!=playerscore || W!=playerweight )
		bAgain = True;
	playerscore = S;
	if( W!=playerweight )
	{
		playerweight = W;
		InitAmmoForNewGun();
	}
	if( bAgain && myItems!=None )
	{
		for(i=0;i<AllBuyableItems.length;i++)
		{
			if( BuyableWeapon(AllBuyableItems[i])!=None )
				BuyableWeapon(AllBuyableItems[i]).bInitalInit = False;
		}
		Relist();
	}
	if( GUIBuyMenuFooter(t_Footer)!=None )
		GUIBuyMenuFooter(t_Footer).SetPlayerStats(playerscore,playerweight);
}

defaultproperties
{
     Begin Object Class=GUIListBox Name=BoxForCategories
         bVisibleWhenEmpty=True
         OnCreateComponent=BoxForCategories.InternalOnCreateComponent
         WinTop=0.060000
         WinLeft=0.010000
         WinWidth=0.050000
         WinHeight=0.050000
         bVisible=False
         bTabStop=False
         bBoundToParent=True
         bScaleToParent=True
         OnChange=GUIBuyMenu.CategoryChange
     End Object
     CategoryBox=GUIListBox'KFGui.GUIBuyMenu.BoxForCategories'

     Begin Object Class=GUIBuyTabs Name=Tabs
         WinTop=0.060000
         WinLeft=0.625000
         WinWidth=0.310000
         WinHeight=0.046000
         bBoundToParent=True
         bScaleToParent=True
     End Object
     SaleTabs=GUIBuyTabs'KFGui.GUIBuyMenu.Tabs'

     UpgradesHeader="Upgrades"
     AllHeader="All"

     Begin Object Class=GUITraderInvBox Name=ownbox
         bVisibleWhenEmpty=True
         OnCreateComponent=ownbox.InternalOnCreateComponent
         WinHeight=1.000000
         TabOrder=1
         bBoundToParent=True
         bScaleToParent=True
     End Object
     InvBox=GUITraderInvBox'KFGui.GUIBuyMenu.ownbox'

     Begin Object Class=AltSectionBackground Name=ownbg
         Caption="Inventory"
         WinTop=0.112000
         WinLeft=0.010000
         WinWidth=0.300000
         WinHeight=0.828000
         OnPreDraw=ownbg.InternalPreDraw
     End Object
     InvBG=AltSectionBackground'KFGui.GUIBuyMenu.ownbg'

     Begin Object Class=GUITraderRefill Name=refillall
         WinTop=0.060000
         WinLeft=0.010000
         WinWidth=0.300000
         WinHeight=0.046000
         bBoundToParent=True
         bScaleToParent=True
     End Object
     RefillBtn=GUITraderRefill'KFGui.GUIBuyMenu.refillall'

     Begin Object Class=GUIBuyItemsBox Name=itmbox
         bVisibleWhenEmpty=True
         bSorted=True
         OnCreateComponent=itmbox.InternalOnCreateComponent
         Hint="Equipment in this category"
         WinHeight=1.000000
         TabOrder=1
         bBoundToParent=True
         bScaleToParent=True
     End Object
     ItemsBox=GUIBuyItemsBox'KFGui.GUIBuyMenu.itmbox'

     Begin Object Class=AltSectionBackground Name=itmbg
         Caption="Items"
         WinTop=0.112000
         WinLeft=0.625000
         WinWidth=0.310000
         WinHeight=0.828000
         OnPreDraw=itmbg.InternalPreDraw
     End Object
     ItemBG=AltSectionBackground'KFGui.GUIBuyMenu.itmbg'

     Begin Object Class=AltSectionBackground Name=infbg
         Caption="Info"
         WinTop=0.060000
         WinLeft=0.317500
         WinWidth=0.300000
         WinHeight=0.880000
         OnPreDraw=infbg.InternalPreDraw
     End Object
     InfoBG=AltSectionBackground'KFGui.GUIBuyMenu.infbg'

     SellSound=Sound'PatchSounds.SellItem'
     BuySound=Sound'KFWeaponSound.GunPickupKF'
     Begin Object Class=GUITabControl Name=PageTabs
         bDockPanels=True
         TabHeight=0.040000
         WinLeft=0.010000
         WinWidth=0.980000
         WinHeight=0.040000
         RenderWeight=0.490000
         TabOrder=3
         bAcceptsInput=True
         OnActivate=PageTabs.InternalOnActivate
     End Object
     c_Tabs=GUITabControl'KFGui.GUIBuyMenu.PageTabs'

     Begin Object Class=GUIBuyMenuFooter Name=BuyFooter
         WinTop=0.957943
         RenderWeight=0.300000
         TabOrder=8
         OnPreDraw=BuyFooter.InternalOnPreDraw
     End Object
     t_Footer=GUIBuyMenuFooter'KFGui.GUIBuyMenu.BuyFooter'

     Begin Object Class=BackgroundImage Name=KFBackground
         ImageStyle=ISTY_Tiled
         RenderWeight=0.010000
         bBoundToParent=True
         bScaleToParent=True
     End Object
     i_Background=BackgroundImage'KFGui.GUIBuyMenu.KFBackground'

     bAllowedAsLast=True
     OnClose=GUIBuyMenu.KFBuyMenuClosed
     OnTimer=GUIBuyMenu.UpdateCosts
     OnPreDraw=GUIBuyMenu.ClearClock
}
