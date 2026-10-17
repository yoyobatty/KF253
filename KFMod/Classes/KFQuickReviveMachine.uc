class KFQuickReviveMachine extends KFPerkMachine
	placeable;

var() int SoloCost, SoloLimit;
var() string SoldOutMessage;

function bool HasPerk( KFPlayerReplicationInfo KFPRI )
{
	Return KFPRI.bHasQuickRevive;
}

function int GetCost()
{
	if( IsSoloGame() )
		Return SoloCost;
	Return Cost;
}

function bool CanBuy( KFHumanPawnZombies P, KFPlayerReplicationInfo KFPRI )
{
	if( IsSoloGame() && KFPRI.QuickRevivesBought>=SoloLimit )
	{
		Notify(P, SoldOutMessage);
		Return false;
	}
	Return true;
}

function GivePerk( KFHumanPawnZombies P, KFPlayerReplicationInfo KFPRI )
{
	KFPRI.bHasQuickRevive = true;
	if( IsSoloGame() )
		KFPRI.QuickRevivesBought++;
}

defaultproperties
{
	Cost=1500
	SoloCost=500
	SoloLimit=3
	PerkName="Second Wind"
	AlreadyBoughtMessage="You already have Second Wind."
	PurchasedMessage="Second Wind purchased!"
	SoldOutMessage="Second Wind is sold out."
}
