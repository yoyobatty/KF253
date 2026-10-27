//-----------------------------------------------------------
//
//-----------------------------------------------------------
class KFLevelRules extends ReplicationInfo;

//const MAX_BUYITEMS=25;

//var(Shop) class<Pickup> ItemForSale(MAX_BUYITEMS);
var         array< class<Pickup> >      ItemForSale;

var() float WaveSpawnPeriod;

// (each machine: the list is not sent) The trader also sells what came after the maps' lists were made
simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	// (the magnum revolver is off the trader until it is reworked)
	// (the BFG, Gore Cannon, Railgun, Cryo Cannon and Void Executioner are upgrades of the guns they are built on:
	// KFTraderUpgrades)
}

simulated function AddForSale( class<Pickup> P )
{
	local int i;

	for ( i = 0; i < ItemForSale.Length; i++ )
		if ( ItemForSale[i] == P )
			return;
	ItemForSale[ItemForSale.Length] = P;
}

defaultproperties
{
     ItemForSale(0)=Class'KFMod.ShotgunPickup'
     ItemForSale(1)=Class'KFMod.DeaglePickup'
     ItemForSale(2)=Class'KFMod.CrossbowPickup'
     ItemForSale(3)=Class'KFMod.BullpupPickup'
     ItemForSale(4)=Class'KFMod.DualiesPickup'
     ItemForSale(5)=Class'KFMod.FragPickup'
     ItemForSale(6)=Class'KFMod.LAWPickup'
     ItemForSale(7)=Class'KFMod.BoomStickPickup'
     ItemForSale(8)=Class'KFMod.WinchesterPickup'
     ItemForSale(9)=Class'KFMod.Vest'
     ItemForSale(10)=Class'KFMod.KnifePickup'
     ItemForSale(11)=Class'KFMod.BatPickup'
     ItemForSale(12)=Class'KFMod.AxePickup'
     ItemForSale(13)=Class'KFMod.FlameThrowerPickup'
     ItemForSale(14)=Class'KFMod.FirstAidKit'
     //ItemForSale(15)=Class'KFMod.SinglePickup'
     WaveSpawnPeriod=2.000000
}
