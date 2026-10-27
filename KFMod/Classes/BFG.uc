//=============================================================================
// BFG
// The BFG 9000: a prototype plasma cannon on the LAW's frame, in the toxic-green camo of the upgraded guns (KFElement
// 6; it comes upgraded, so it takes no further upgrade). Its fire is BFGFire; its zoom the LAW's.
//=============================================================================
class BFG extends LAW;

// (bots take the LAW's view of it, but never buy one: KFInvasionBot.GetLegalPurchases)

defaultproperties
{
     Element=6
     bUpgraded=True
     UpgradeName="BFG 9000"
     ItemName="BFG 9000"
     Description="A Horzine prototype plasma cannon built on a L.A.W's frame."
     FireModeClass(0)=Class'KFMod.BFGFire'
     PickupClass=Class'KFMod.BFGPickup'
     ReloadRate=2.500000
     Priority=51
}
