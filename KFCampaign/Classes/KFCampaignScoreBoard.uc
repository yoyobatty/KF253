// The campaign's scoreboard: the map in the title instead of the wave, and the retry told on death.
class KFCampaignScoreBoard extends KFScoreBoardNew;

var localized string CampaignString, RetryText;

function DrawTitle( Canvas Canvas, float HeaderOffsetY, float PlayerAreaY, float PlayerBoxSizeY )
{
	local string TitleString, InfoString;
	local float XL, YL;

	if ( Canvas.ClipX < 512 )
		return;

	TitleString = SkillLevel[Clamp(InvasionGameReplicationInfo(GRI).BaseDifficulty,0,7)]@CampaignString@string(Level.Outer.Name);
	InfoString = FooterText@FormatTime(GRI.ElapsedTime);
	if ( PlayerController(Owner).IsDead() )
		InfoString = RetryText;

	Canvas.DrawColor = HUDClass.default.RedColor;
	Canvas.StrLen(TitleString, XL, YL);
	Canvas.SetPos(0.5*(Canvas.ClipX-XL), ((HeaderOffsetY-PlayerBoxSizeY) - YL)*0.5);
	Canvas.DrawText(TitleString, true);
	Canvas.StrLen(InfoString, XL, YL);
	Canvas.SetPos(0.5*(Canvas.ClipX-XL), Canvas.ClipY - 1.5*YL);
	Canvas.DrawText(InfoString, true);
}

defaultproperties
{
	CampaignString="Campaign:"
	RetryText="You died. Press Fire to retry from the start of this area."
}
