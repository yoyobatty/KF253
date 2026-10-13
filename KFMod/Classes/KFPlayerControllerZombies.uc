class KFPlayerControllerZombies extends KFPlayerController;

function SetPawnClass(string inClass, string inCharacter)
{
	PawnClass = Class'KFHumanPawnZombies';
	inCharacter = Class'KFGameType'.Static.GetValidCharacter(inCharacter);
	PawnSetupRecord = class'xUtil'.static.FindPlayerRecord(inCharacter);
	PlayerReplicationInfo.SetCharacterName(inCharacter);
}

function ServerAccumulateUse(float DeltaTime)
{
	local KFHumanPawnZombies P, Best;
	local float D, BestD;

	Super.ServerAccumulateUse(DeltaTime);

	if( Pawn==None || Pawn.Health<=0 || !Pawn.bCanUse )
		Return;
	if( KFHumanPawn(Pawn)!=None && KFHumanPawn(Pawn).bIsDowned )
		Return;

	ForEach Pawn.VisibleCollidingActors(class'KFHumanPawnZombies', P, class'KFHumanPawnZombies'.Default.ReviveRadius*2)
	{
		if( P==Pawn || !P.bIsDowned || P.Health<=0 )
			Continue;
		D = VSize(P.Location-Pawn.Location);
		if( D<=P.ReviveRadius && (Best==None || D<BestD) )
		{
			Best = P;
			BestD = D;
		}
	}

	if( Best!=None )
		Best.AccumulateRevive(Pawn);
}

defaultproperties
{
}
