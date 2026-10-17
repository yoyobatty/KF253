//ConcussionRifle as part of the GoodKarma package
//Build 1 Beta 4.5 Release
//By: Jonathan Zepp
//Another way to show off da' physics, half damage, more than triple hit impulse.
//This sniper rifle is noticably larger and is found in the target practice arena in the test level.

class ConcussionRifle extends SniperRifle ;

defaultproperties
{
	FireModeClass(0)=Class'GoodKarma.ConcussionFire'
	Description="The Concussion Rifle sacrifices damage for impact, making it very fun to shoot at physics objects."
	PickupClass=Class'GoodKarma.ConcussionPickup'
	ItemName="Concussion Rifle"
	DrawScale=0.600000
}
