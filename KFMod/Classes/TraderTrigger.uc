Class TraderTrigger extends Trigger
	NotPlaceable;

var WeaponLocker EffectedTrader;

function PostBeginPlay();
function PreBeginPlay();
function Reset();
function Touch( Actor Other )
{
	if( Pawn(Other)!=None && PlayerController(Pawn(Other).Controller)!=None && KFGameType(Level.Game)!=None && !KFGameType(Level.Game).bWaveInProgress )
	{
		EffectedTrader.SetOpen(true);
		PlayerController(Pawn(Other).Controller).ReceiveLocalizedMessage(Class'KFMainMessages',3);
	}
}
function UnTouch( Actor Other )
{
	if( Pawn(Other)!=None && PlayerController(Pawn(Other).Controller)!=None && KFGameType(Level.Game)!=None )
		EffectedTrader.SetOpen(false);
}
function UsedBy( Pawn user )
{
	if( KFPlayerController(user.Controller)!=None && KFGameType(Level.Game)!=None && !KFGameType(Level.Game).bWaveInProgress )
		KFPlayerController(user.Controller).ShowBuyMenu(string(EffectedTrader.Tag),KFHumanPawn(user).MaxCarryWeight);
}

defaultproperties
{
	bOnlyAffectPawns=True
}
