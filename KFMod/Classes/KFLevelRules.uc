//-----------------------------------------------------------
//
//-----------------------------------------------------------
class KFLevelRules extends ReplicationInfo;

const MAX_BUYITEMS=25;

var(Shop) class<Pickup> ItemForSale[MAX_BUYITEMS];

var() float WaveSpawnPeriod;

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
     WaveSpawnPeriod=2.000000
}
