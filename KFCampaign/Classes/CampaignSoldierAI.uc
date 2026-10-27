// KFMod254's soldier AI, held back while its pawn is hidden (a soldier waiting off stage for its cue).
class CampaignSoldierAI extends KFFriendlyAI;

function bool SetEnemy( Pawn NewEnemy, optional bool bHateMonster )
{
	if( Pawn!=None && Pawn.bHidden )
		return false;
	return Super.SetEnemy(NewEnemy, bHateMonster);
}

function bool FindNewEnemy()
{
	if( Pawn!=None && Pawn.bHidden )
		return false;
	return Super.FindNewEnemy();
}

// (the monster's dodge reads its pawn as a Monster: a soldier is not one)
function ReceiveWarning( Pawn shooter, float projSpeed, vector FireDir );

// (gone with its soldier: left behind, it was warned of every shot at the body)
function PawnDied( Pawn P )
{
	Super.PawnDied(P);
	if( Pawn==None && !bDeleteMe )
		Destroy();
}

state TacticalMove
{
	function ReceiveWarning( Pawn shooter, float projSpeed, vector FireDir );
}
