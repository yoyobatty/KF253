// The campaign checkpoint: what the player carried into the map they are on.
class KFCampaignSave extends Object
	config(User);

var config string MapName, Portal;	// the map to go on in, and the teleporter there to arrive at
var config string RetryMap;	// a map being played again after a death (its opening cutscene is not shown again)
var config int Health, Armor;
var config array<string> Items;	// "Package.Class Ammo0 Ammo1 ClipLeft"

static function bool HasSave()
{
	return default.MapName != "";
}

static function string URL()
{
	if( default.Portal!="" )
		return default.MapName$"#"$default.Portal;
	return default.MapName;
}

static function Clear()
{
	default.MapName = "";
	default.Portal = "";
	default.Items.Length = 0;
	StaticSaveConfig();
}

static function Store( Pawn P, string NewMap, optional string NewPortal )
{
	local Inventory Inv;
	local Weapon W;
	local int A0, A1, Clip;

	default.MapName = NewMap;
	default.Portal = NewPortal;
	default.Items.Length = 0;
	default.Health = 100;
	default.Armor = 0;
	if( P!=None && P.Health>0 )
	{
		default.Health = P.Health;
		default.Armor = P.ShieldStrength;
		for( Inv=P.Inventory; Inv!=None; Inv=Inv.Inventory )
		{
			W = Weapon(Inv);
			if( W==None )
				continue;
			A0 = W.AmmoAmount(0);
			A1 = 0;
			if( W.AmmoClass[1]!=None && W.AmmoClass[1]!=W.AmmoClass[0] )
				A1 = W.AmmoAmount(1);
			Clip = -1;
			if( KFWeapon(W)!=None )
				Clip = KFWeapon(W).ClipLeft;
			default.Items[default.Items.Length] = string(W.Class)@A0@A1@Clip;
		}
	}
	StaticSaveConfig();
}

static function Restore( Pawn P )
{
	local int i, A0, A1, Clip;
	local array<string> Parts;
	local class<Weapon> WC;
	local Weapon W;

	if( P==None )
		return;
	for( i=0; i<default.Items.Length; i++ )
	{
		Split(default.Items[i], " ", Parts);
		if( Parts.Length<4 )
			continue;
		WC = class<Weapon>(DynamicLoadObject(Parts[0], class'Class', true));
		if( WC==None )
			continue;
		if( P.FindInventoryType(WC)==None )
			P.CreateInventory(Parts[0]);
		W = Weapon(P.FindInventoryType(WC));
		if( W==None )
			continue;
		A0 = int(Parts[1]);
		A1 = int(Parts[2]);
		Clip = int(Parts[3]);
		SetAmmo(W, 0, A0);
		if( W.AmmoClass[1]!=None && W.AmmoClass[1]!=W.AmmoClass[0] )
			SetAmmo(W, 1, A1);
		if( Clip>=0 && KFWeapon(W)!=None )
			KFWeapon(W).ClipLeft = Min(Clip, W.AmmoAmount(0));
	}
	P.Health = Clamp(default.Health, 1, P.HealthMax);
	P.ShieldStrength = Max(default.Armor, 0);
}

static function SetAmmo( Weapon W, int Mode, int Amount )
{
	local int Have;

	Have = W.AmmoAmount(Mode);
	if( Amount<Have )
		W.ConsumeAmmo(Mode, Have-Amount, true);
	else if( Amount>Have )
		W.AddAmmo(Amount-Have, Mode);
}
