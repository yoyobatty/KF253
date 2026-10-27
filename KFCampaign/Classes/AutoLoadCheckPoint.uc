// KFS-RESUMEGAME: carries the player on to the map of the campaign checkpoint, or back to the menu when there is none.
class AutoLoadCheckPoint extends Triggers;

function Trigger( Actor Other, Pawn EventInstigator )
{
	if( class'KFCampaignSave'.static.HasSave() )
		Level.ServerTravel(class'KFCampaignSave'.static.URL(), false);
	else if( Level.GetLocalPlayerController()!=None )
		Level.GetLocalPlayerController().ClientOpenMenu("KFGUI.KFMainMenu", true);
}
