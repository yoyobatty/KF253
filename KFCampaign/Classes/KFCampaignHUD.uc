// The campaign's HUD: KFMod254's, without the wave counter, trader clock and objective board, and hidden with the weapon
// while one of the maps' own (stock) cutscenes runs.
class KFCampaignHUD extends HUDKillingFloor;

var bool bSetCinematic;

simulated function DrawHud( Canvas C )
{
	local KFPlayerReplicationInfo PRI;

	PRI = KFPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo);
	if( PRI!=None )
	{
		if( PlayerOwner.bViewingMatineeCinematic )
		{
			PRI.bViewingMatineeCinematic = true;
			bSetCinematic = true;
		}
		else if( bSetCinematic )
		{
			PRI.bViewingMatineeCinematic = false;
			bSetCinematic = false;
		}
	}
	Super.DrawHud(C);
}

function CanvasDrawActors( Canvas C, bool bClearedZBuffer )
{
	if( !PlayerOwner.bViewingMatineeCinematic )
		Super.CanvasDrawActors(C, bClearedZBuffer);
}

simulated function DrawKFHUDTextElements( Canvas C );
