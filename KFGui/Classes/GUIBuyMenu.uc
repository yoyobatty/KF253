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

var Sound SellSound,BuySound;

var array < GUIBuyable > AllBuyableItems;

function InitComponent( GUIController MyController, GUIComponent MyOwner )
{
	local int i;
	Super.InitComponent( MyController, MyOwner );

	CategoryBG.ManageComponent(CategoryBox);
	ItemBG.ManageComponent(ItemsBox);
	myCategories = CategoryBox.List;

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
				AllBuyableItems[0].cost = BuyWeapon.default.cost * Class'KFPawn'.Static.GetCostScaling(GameDifficulty);
				AllBuyableItems[0].Weight= BuyWeapon.default.Weight;
				BuyableWeapon(AllBuyableItems[0]).PowerValue=BuyWeapon.default.PowerValue;
				BuyableWeapon(AllBuyableItems[0]).RangeValue=BuyWeapon.default.RangeValue;
				BuyableWeapon(AllBuyableItems[0]).SpeedValue=BuyWeapon.default.SpeedValue;
				AllBuyableItems[0].Description = BuyWeapon.default.Description;
				AllBuyableItems[0].ItemName=BuyWeapon.default.ItemName;
				AllBuyableItems[0].showMesh=BuyWeapon.default.ShowMesh;
				AllBuyableItems[0].relatedInventory=BuyWeapon.default.InventoryType;

				if(class<KFWeapon>(BuyWeapon.default.InventoryType).default.bKFNeverThrow==true)
					BuyableWeapon(AllBuyableItems[0]).bHideSale=true;

				if(class<KFWeapon>(BuyWeapon.default.InventoryType).default.FireModeClass[0].default.AmmoClass!=none)
				{
					AllBuyableItems.Insert(0,1);
					AllBuyableItems[0] = new class'BuyableAmmo';
					AllBuyableItems[0].cost = BuyWeapon.default.ammocost * Class'KFPawn'.Static.GetCostScaling(GameDifficulty);
					AllBuyableItems[0].myShowMesh=BuyWeapon.default.AmmoMesh;
            
					// Little hack for the LAW ammo :P  it's huge.
					if(BuyWeapon.default.AmmoMesh == StaticMesh'KillingFloorStatics.LAWAmmo')
						AllBuyableItems[0].infoDrawScale *= 0.5;

					AllBuyableItems[0].ItemName=BuyWeapon.default.AmmoItemName;
					AllBuyableItems[0].relatedInventory=BuyWeapon.default.InventoryType;
					BuyableAmmo(AllBuyableItems[0]).ammoType=class<KFWeapon>(BuyWeapon.default.InventoryType).default.FireModeClass[0].default.AmmoClass;
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
					AllBuyableItems[0].cost = AllBuyableItems[0].default.cost * Class'KFPawn'.Static.GetCostScaling(GameDifficulty);
					AllBuyableItems[0].cost *= (100.f - PlayerOwner().Pawn.ShieldStrength)/100.f;
					//PlayerOwner().Level.Game.Broadcast(PlayerOwner().Pawn, "Buy cost is: " $AllBuyableItems[0].cost$"");
				}
				if( class<FirstAidKit>(KFLR.ItemForSale[i])!=none)
				{
					AllBuyableItems.Insert(0,1);
					AllBuyableItems[0] = new class'BuyableFirstAidKit';
					AllBuyableItems[0].cost = AllBuyableItems[0].default.cost * Class'KFPawn'.Static.GetCostScaling(GameDifficulty);
					AllBuyableItems[0].cost *= (100.f - PlayerOwner().Pawn.Health)/100.f;
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
		p_Info = new b.GetPanelType(eSaleCat(myCategories.Index));;
		GUIBuyMenuFooter(t_Footer).SetBuyMode(b.GetBuyCaption(eSaleCat(myCategories.Index)),CanAfford(b)&&b.CanButtonMe(PlayerOwner(),myCategories.Index != 0),b.IsA('BuyableAmmo') && myCategories.Index !=0,b.Isa('BuyableAmmo') && BuyableAmmo(b).BuyMoreClips()*b.cost < playerscore);
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

function BuyCurrent()
{
	local GUIBuyable b;
	local int i;

	b = myItems.Elements[myItems.Index];
	if(myCategories.Index == 0) //sell, don't buy
	{
		b.SellMe(KFPawn(playerOwner().Pawn));
		PlayerOwner().pawn.PlaySound(SellSound,SLOT_Interface,255.0,,120);
	}
	else
	{
		b.BuyMe(KFPawn(playerOwner().Pawn));
		BuySound = b.relatedInventory.default.PickupClass.default.PickupSound;
		PlayerOwner().pawn.PlaySound(BuySound,SLOT_Interface,255.0,,120);
	}

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

	b = BuyableAmmo(myItems.Elements[myItems.Index]);
	b.FillMe(KFPawn(playerOwner().pawn));
	myCategories.IndexChanged(myItems);
}

function bool CanAutoAmmo()
{
	local int requiredScore,i;
	for(i=0;i<AllBuyableItems.length;i++)
	{
		if(AllBuyableItems[i].IsA('BuyableAmmo') && AllBuyableItems[i].HasMe(PlayerOwner().Pawn))
			requiredScore += BuyableAmmo(AllBuyableItems[i]).BuyMoreClips()*AllBuyableItems[i].cost;
	}
	return playerscore >= requiredScore;
}

function DoAutoAmmo()
{
	local int i;
	local BuyableWeapon RelWeapon;

	for(i=0;i<AllBuyableItems.length;i++)
	{
		if(AllBuyableItems[i].IsA('BuyableAmmo') )
		{
			RelWeapon = FindWeapon(AllBuyableItems[i].relatedInventory );
			if(RelWeapon!=none && RelWeapon.HasMe(PlayerOwner().Pawn))
				BuyableAmmo(AllBuyableItems[i]).FillMe(KFPawn(playerOwner().pawn));
		}
	}
	myCategories.IndexChanged(myItems);
	GUIBuyMenuFooter(t_Footer).SetPlayerStats(playerscore,playerweight);
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
	local float W;

	PC = PlayerOwner();
	if( KFHumanPawn(PC.Pawn)==None ) Return;
	playerscore = PC.PlayerReplicationInfo.Score;
	W = KFHumanPawn(PC.Pawn).CurrentWeight;
	if( W!=playerweight )
	{
		playerweight = W;
		InitAmmoForNewGun();
	}
	maxweight = KFHumanPawn(PC.Pawn).MaxCarryWeight;
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
         WinHeight=0.383940
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
         WinTop=0.454030
         WinLeft=0.010000
         WinWidth=0.440000
         WinHeight=0.486185
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
}
