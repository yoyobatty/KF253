//-----------------------------------------------------------
//
//-----------------------------------------------------------
class KFLevelRules extends ReplicationInfo;

<<<<<<< HEAD
const MAX_BUYITEMS=25;

var(Shop) class<Pickup> ItemForSale[MAX_BUYITEMS];
=======
//const MAX_BUYITEMS=25;

//var(Shop) class<Pickup> ItemForSale(MAX_BUYITEMS);
var         array< class<Pickup> >      ItemForSale;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

var() float WaveSpawnPeriod;

defaultproperties
{
<<<<<<< HEAD
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
	WaveSpawnPeriod=2.000000
=======
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
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
