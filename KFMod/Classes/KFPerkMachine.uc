class KFPerkMachine extends KFZombiesUsable
	abstract;

var() int Cost;
var() string PerkName;
var() string AlreadyBoughtMessage, NotEnoughPointsMessage, PurchasedMessage;
var() sound PurchaseSound;

function bool HasPerk( KFPlayerReplicationInfo KFPRI );
function GivePerk( KFHumanPawnZombies P, KFPlayerReplicationInfo KFPRI );

function int GetCost()
{
	Return Cost;
}

function bool CanBuy( KFHumanPawnZombies P, KFPlayerReplicationInfo KFPRI )
{
	Return true;
}

function string GetPrompt( Pawn P )
{
	local KFPlayerReplicationInfo KFPRI;

	KFPRI = KFPlayerReplicationInfo(P.PlayerReplicationInfo);
	if( KFHumanPawnZombies(P)==None || KFPRI==None || HasPerk(KFPRI) )
		Return "";
	Return "[USE] Buy" @ PerkName @ "-" @ GetCost();
}

function UsedBy( Pawn user )
{
	local KFHumanPawnZombies KFH;
	local KFPlayerReplicationInfo KFPRI;

	KFH = KFHumanPawnZombies(user);
	if( KFH==None || !CanUseNow(user) )
		Return;

	KFPRI = KFPlayerReplicationInfo(KFH.PlayerReplicationInfo);
	if( KFPRI==None )
		Return;

	if( HasPerk(KFPRI) )
	{
		Notify(user, AlreadyBoughtMessage);
		Return;
	}

	if( !CanBuy(KFH, KFPRI) )
		Return;

	if( !Charge(user, GetCost()) )
	{
		Notify(user, NotEnoughPointsMessage);
		Return;
	}

	GivePerk(KFH, KFPRI);
	Notify(user, PurchasedMessage);
	if( PurchaseSound!=None )
		PlaySound(PurchaseSound,,255,,100);
}

defaultproperties
{
	Cost=2000
	NotEnoughPointsMessage="Not enough dosh!"
	PurchaseSound=Sound'CODSounds.ui_buygeneric01'
}
