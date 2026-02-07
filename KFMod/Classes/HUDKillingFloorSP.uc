class HUDKillingFloorSP extends HUDKillingFloor;

simulated function DrawKFHUDTextElements(Canvas Canvas )
{
	if( KFSPObjectiveBoard(ScoreBoard)!=None )
		KFSPObjectiveBoard(ScoreBoard).RenderObjectivedBoard(Canvas);
}

defaultproperties
{
<<<<<<< HEAD
	YouveWonTheMatch="Mission Complete."
	YouveLostTheMatch="Mission Failed."
=======
     YouveWonTheMatch="Mission Complete."
     YouveLostTheMatch="Mission Failed."
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
