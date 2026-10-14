class GUIBuyMenu extends UT2k4MainPage;

const BUYLIST_CATS=7;
var automated GUIPanel p_Info;
var automated GUIListBox CategoryBox;
var automated GUIBuyItemsBox ItemsBox;
var automated GUISectionBackground CategoryBG,ItemBG,InfoBG;
var GUIList myCategories;
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

	CategoryBG.ManageComponent(CategoryBox);
	ItemBG.ManageComponent(ItemsBox);
	myCategories = CategoryBox.List;
	// (spread down their box, a row each and in a bigger font: they were small lines crowded at its top)
	myCategories.GetItemHeight = CategoryRowHeight;
	myCategories.FontScale = FNS_Large;

	for(i=0;i<BUYLIST_CATS;i++)
		myCategories.Add(KFPlayerController(PlayerOwner()).BuyListHeaders[i]);

	myItems = ItemsBox.List;
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
			{
				// Difficulty Scaling  (% of regular cost)
				// - easy  = 80%
				// - normal = 100%
				// - Skilled = 133%
				// - Elite = 166%
				// - Suicidal = 233%
				AllBuyableItems.Insert(0,1);
				AllBuyableItems[0] = new class'BuyableWeapon';
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

				if(class<KFWeapon>(BuyWeapon.default.InventoryType).default.FireModeClass[0].default.AmmoClass!=none)
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
					//PlayerOwner().Level.Game.Broadcast(PlayerOwner().Pawn, "Buy cost is: " $AllBuyableItems[0].cost$"");
				}
				if( class<FirstAidKit>(KFLR.ItemForSale[i])!=none)
				{
					AllBuyableItems.Insert(0,1);
					AllBuyableItems[0] = new class'BuyableFirstAidKit';
					// as KFPawn.ServerBuyFirstAid charges: the same whatever health is missing
					AllBuyableItems[0].cost = int(AllBuyableItems[0].default.cost * Class'KFPawn'.Static.GetCostScaling(GameDifficulty));
				}
			}
		}
	}
	GUIBuyMenuFooter(t_Footer).SetPlayerStats(PlayerOwner().PlayerReplicationInfo.Score,playerweight);
	CategoryChange(self);
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
	{
		p_Info = new b.GetPanelType(eSaleCat(myCategories.Index));
		GUIBuyMenuFooter(t_Footer).SetBuyMode(b.GetBuyCaption(eSaleCat(myCategories.Index)),CanAfford(b)&&b.CanButtonMe(PlayerOwner(),myCategories.Index != 0),FillShown(b),FillAllowed(b),FillCaption(b));
	}
	else
	{
		p_Info = new class'GUIBuyInfoPanel';
		GUIBuyMenuFooter(t_Footer).SetBuyMode("Buy",false,false,false);
	}
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
	return myCategories.Index == 0 || (playerscore-b.cost >=0 && playerweight+b.weight <= maxweight);
}
// Why a thing on the lists cannot be bought: too dear, or too heavy for what is carried already
function bool TooDear(GUIBuyable b)
{
	return myCategories.Index!=0 && playerscore<b.cost;
}
function bool TooHeavy(GUIBuyable b)
{
	return myCategories.Index!=0 && playerweight+b.weight>maxweight;
}

// The categories: a row each, spread down their box, in the biggest of the list's fonts that fits a row
function float CategoryRowHeight(Canvas C)
{
	local float H;

	H = myCategories.ActualHeight()/float(BUYLIST_CATS);
	if( RowFontHeight(C,FNS_Large)<=H )
		myCategories.FontScale = FNS_Large;
	else if( RowFontHeight(C,FNS_Medium)<=H )
		myCategories.FontScale = FNS_Medium;
	else myCategories.FontScale = FNS_Small;
	return H;
}
// How tall a line of the category list is in one of its fonts. (Measured with the style's loaded fonts: its
// TextSize is static, and measured with whatever font the canvas held.)
function float RowFontHeight(Canvas C, eFontScale S)
{
	local GUIFont F;
	local Font Was;
	local float XL,YL;

	if( myCategories.Style==None )
		return 0;
	F = myCategories.Style.Fonts[int(S)*5];	// (the blurry state's, the first of each size's five)
	if( F==None )
		return 0;
	Was = C.Font;
	C.Font = F.GetFont(C.ClipX);
	C.TextSize("My Inventory",XL,YL);
	C.Font = Was;
	return YL;
}

// The Items panel and the footer stop short of the round clock the HUD draws in the top right corner, under the
// menu; the footer runs the menu's width, with the cash and the weight at its left
function bool ClearClock(Canvas C)
{
	local float R;
	local HUDKillingFloor H;

	// (the right edge it had)
	R = 0.946916;
	H = HUDKillingFloor(PlayerOwner().myHUD);
	if( H!=None && C.ClipX>0 )
		R = FMin(R, 1.0-(H.HudUnits(H.CornerUnits)+C.ClipX*0.006)/C.ClipX);
	ItemBG.WinWidth = R-ItemBG.WinLeft;
	t_Footer.WinLeft = CategoryBG.WinLeft;
	t_Footer.WinWidth = R-CategoryBG.WinLeft;
	return false;
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
// What the fill button fills: on the ammo list the ammo picked, on what the player owns the picked gun's ammo
function BuyableAmmo FillTarget(GUIBuyable b)
{
	if( myCategories.Index!=0 )
		return BuyableAmmo(b);
	return AmmoFor(BuyableWeapon(b));
}
function bool FillShown(GUIBuyable b)
{
	local BuyableAmmo A;

	A = FillTarget(b);
	if( A==None )
		return false;
	// (on what the player owns, only while that gun has room for more)
	return myCategories.Index!=0 || A.FillCost(PlayerOwner().Pawn)>0;
}
// (with less cash than a fill costs, as much is bought as the cash pays for)
function bool FillAllowed(GUIBuyable b)
{
	local BuyableAmmo A;

	A = FillTarget(b);
	return A!=None && A.FillCost(PlayerOwner().Pawn)>0 && playerscore>0;
}
function string FillCaption(GUIBuyable b)
{
	local BuyableAmmo A;

	A = FillTarget(b);
	if( A==None || myCategories.Index!=0 )
		return "Fill Up";
	return "Fill ammo:"@A.FillCost(PlayerOwner().Pawn);
}

function CategoryChange(GUIComponent Sender)
{
	local int i,j;

	myItems.Clear();
	i = myCategories.Index;

	for(j=0;j<allBuyableItems.length;j++)
	{
		if(AllBuyableItems[j].ShowMe(PlayerOwner().Pawn,eSaleCat(i),self))
			myItems.Add(AllBuyableItems[j]);
	}
	myItems.OnChange(myItems);
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
// The list made anew with the same thing chosen in it
function Relist()
{
	local GUIBuyable Chosen;
	local int i;

	if( myItems.Index>=0 && myItems.Index<myItems.Elements.Length )
		Chosen = myItems.Elements[myItems.Index];
	CategoryChange(self);
	for(i=0;i<myItems.Elements.Length;i++)
	{
		if( myItems.Elements[i]==Chosen )
			myItems.SetIndex(i);
	}
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
function BuyCurrent()
{
	local GUIBuyable b;
	local int i;
	local float Was,Ask;

	if( myItems.Index<0 || myItems.Index>=myItems.Elements.Length )
		Return;
	b = myItems.Elements[myItems.Index];
	// (a greyed Buy button can still be pressed with a key)
	if( myCategories.Index!=0 && !CanAfford(b) )
		Return;
	if(myCategories.Index == 0) //sell, don't buy
	{
		b.SellMe(KFPawn(playerOwner().Pawn));
		PlayerOwner().pawn.PlaySound(SellSound,SLOT_Interface,255.0,,120);
		playerscore += b.sellValue;
		playerweight -= b.weight;
	}
	else
	{
		Was = PlayerOwner().PlayerReplicationInfo.Score;
		Ask = Charge(b);
		b.BuyMe(KFPawn(playerOwner().Pawn));
		if( b.relatedInventory!=None && b.relatedInventory.default.PickupClass!=None )
			BuySound = b.relatedInventory.default.PickupClass.default.PickupSound;
		else BuySound = default.BuySound;
		PlayerOwner().pawn.PlaySound(BuySound,SLOT_Interface,255.0,,120);
		if( BuyableWeapon(b)!=None )
		{
			playerscore -= b.cost;
			playerweight += b.weight;
		}
		else Paid(Was,Ask);
	}
	PendingChecks = 2;

	myCategories.IndexChanged(myCategories);  //update lists
   	//Only refresh if we're out of whatever we bought.
	if(b.ShowMe(PlayerOwner().Pawn,eSaleCat(myCategories.Index), self ) )
	{
		for(i=0;i<myItems.Elements.Length;i++)
		{
			if(myItems.Elements[i] == b)
				myItems.SetIndex(i);
		}
	}
	GUIBuyMenuFooter(t_Footer).SetPlayerStats(playerscore,playerweight);    //update footer
}

function BuyFill()
{
	local BuyableAmmo b;
	local float Was,Ask;

	if( myItems.Index<0 || myItems.Index>=myItems.Elements.Length )
		Return;
	b = FillTarget(myItems.Elements[myItems.Index]);
	if( b==None )
		Return;
	Was = PlayerOwner().PlayerReplicationInfo.Score;
	Ask = b.FillCost(PlayerOwner().Pawn);
	b.FillMe(KFPawn(playerOwner().pawn));
	Paid(Was,Ask);
	PendingChecks = 2;
	Relist();
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
		if(AllBuyableItems[i].IsA('BuyableWeapon') && AllBuyableItems[i].RelatedInventory==WeaponType)
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
	local GUIBuyable Chosen;
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
		if( myItems.Index>=0 && myItems.Index<myItems.Elements.Length )
			Chosen = myItems.Elements[myItems.Index];
		CategoryChange(self);
		for(i=0;i<myItems.Elements.Length;i++)
		{
			if( myItems.Elements[i]==Chosen )
				myItems.SetIndex(i);
		}
	}
	if( GUIBuyMenuFooter(t_Footer)!=None )
		GUIBuyMenuFooter(t_Footer).SetPlayerStats(playerscore,playerweight);
}

defaultproperties
{
     Begin Object Class=GUIListBox Name=BoxForCategories
         bVisibleWhenEmpty=True
         OnCreateComponent=BoxForCategories.InternalOnCreateComponent
         Hint="Choose among these categories of equipment."
         WinTop=0.110215
         WinLeft=0.020000
         WinWidth=0.400000
         WinHeight=0.500000
         TabOrder=1
         bBoundToParent=True
         bScaleToParent=True
         OnChange=GUIBuyMenu.CategoryChange
     End Object
     CategoryBox=GUIListBox'KFGui.GUIBuyMenu.BoxForCategories'

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

     Begin Object Class=AltSectionBackground Name=catbg
         Caption="Categories"
         WinTop=0.060215
         WinLeft=0.010000
         WinWidth=0.440000
         WinHeight=0.300000
         OnPreDraw=catbg.InternalPreDraw
     End Object
     CategoryBG=AltSectionBackground'KFGui.GUIBuyMenu.catbg'

     Begin Object Class=AltSectionBackground Name=itmbg
         Caption="Items"
         WinTop=0.060258
         WinLeft=0.447875
         WinWidth=0.499041
         WinHeight=0.879846
         OnPreDraw=itmbg.InternalPreDraw
     End Object
     ItemBG=AltSectionBackground'KFGui.GUIBuyMenu.itmbg'

     Begin Object Class=AltSectionBackground Name=infbg
         Caption="Info"
         WinTop=0.370000
         WinLeft=0.010000
         WinWidth=0.440000
         WinHeight=0.570000
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
