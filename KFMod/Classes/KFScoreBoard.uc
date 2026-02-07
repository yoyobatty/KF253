class KFScoreBoard extends ScoreBoardDeathMatch;

var localized string TeamScoreString;
var localized string WaveString;
var() localized string	  HealthText,KillsText;
var bool bDisplayWithKills;

function DrawTitle(Canvas Canvas, float HeaderOffsetY, float PlayerAreaY, float PlayerBoxSizeY)
{
	local string titlestring,scoreinfostring,RestartString;
	local float TitleXL,ScoreInfoXL,YL;

	if ( Canvas.ClipX < 512 )
		return; 

	titlestring = SkillLevel[Clamp(InvasionGameReplicationInfo(GRI).BaseDifficulty,0,7)]@GRI.GameName@WaveString@(InvasionGameReplicationInfo(GRI).WaveNumber+1)$MapName$Level.Title;
	Canvas.StrLen(TitleString,TitleXL,YL);

	if ( GRI.TimeLimit != 0 )
		ScoreInfoString = ScoreInfoString@spacer@TimeLimit$FormatTime(GRI.RemainingTime);
	else ScoreInfoString = ScoreInfoString@spacer@FooterText@FormatTime(GRI.ElapsedTime);

	Canvas.DrawColor = HUDClass.default.RedColor;
	if ( UnrealPlayer(Owner).bDisplayLoser )
		ScoreInfoString = class'HUDBase'.default.YouveLostTheMatch;
	else if ( UnrealPlayer(Owner).bDisplayWinner )
		ScoreInfoString = class'HUDBase'.default.YouveWonTheMatch;
	else if ( PlayerController(Owner).IsDead() )
	{
		RestartString = Restart;
		if ( PlayerController(Owner).PlayerReplicationInfo.bOutOfLives )
			RestartString = OutFireText;
		if ( Canvas.ClipY - HeaderOffsetY - PlayerAreaY >= 2.5 * YL )
		{
			Canvas.StrLen(RestartString,ScoreInfoXL,YL);
			Canvas.SetPos(0.5*(Canvas.ClipX-ScoreInfoXL), Canvas.ClipY - 2.5 * YL);
			Canvas.DrawText(RestartString,true);
		}	   
		else ScoreInfoString = RestartString;
	}
	Canvas.StrLen(ScoreInfoString,ScoreInfoXL,YL);
	
	Canvas.SetPos(0.5*(Canvas.ClipX-TitleXL), ((HeaderOffsetY-PlayerBoxSizeY) - YL)*0.5 );
	Canvas.DrawText(TitleString,true);
	Canvas.SetPos(0.5*(Canvas.ClipX-ScoreInfoXL), Canvas.ClipY - 1.5 * YL);
	Canvas.DrawText(ScoreInfoString,true);
}

// Adjust for Kills, instead of cash.
simulated function bool InOrder( PlayerReplicationInfo P1, PlayerReplicationInfo P2 )
{
	local KFPlayerReplicationInfo P11,P22;
  
	P11 = KFPlayerReplicationInfo(P1);
	P22 = KFPlayerReplicationInfo(P2);

	if( P11==None || P22==None )
		return true;
	if( P1.bOnlySpectator )
	{
		if( P2.bOnlySpectator )
			return true;
		else return false;
	}
	else if ( P2.bOnlySpectator )
		return true;

	if( P11.ThreeSecondScore < P22.ThreeSecondScore )
		return false;
	else if( P11.ThreeSecondScore==P22.ThreeSecondScore )
	{
		// Kills is equal, go for cash.
		if( P11.Score < P22.Score )
			return false;
		else if( P11.Score==P22.Score )
			return (P1.PlayerName<P2.PlayerName); // Go for name.
	}
	return true;
}


simulated event UpdateScoreBoard(Canvas Canvas)
{
	local PlayerReplicationInfo PRI, OwnerPRI;
	local int i, FontReduction, NetXPos, PlayerCount,HeaderOffsetY,HeadFoot, MessageFoot, PlayerBoxSizeY, BoxSpaceY, NameXPos, BoxTextOffsetY, OwnerOffset, ScoreXPos, HealthXPos, BoxXPos,KillsXPos, TitleYPos, BoxWidth;
	local float XL,YL, MaxScaling;
	local float deathsXL, scoreXL,KillsXL, netXL,HealthXL, MaxNamePos;
	local bool bNameFontReduction;
	local Material VeterancyBox;

	OwnerPRI = KFPlayerController(Owner).PlayerReplicationInfo;
	OwnerOffset = -1;
	for (i=0; i<GRI.PRIArray.Length; i++)
	{
		PRI = GRI.PRIArray[i];
		if ( !PRI.bOnlySpectator )
		{
			if ( PRI == OwnerPRI )
				OwnerOffset = i;
			PlayerCount++;
		}
	}
	PlayerCount = Min(PlayerCount,MAXPLAYERS);
	
	// Select best font size and box size to fit as many players as possible on screen
	Canvas.Font = HUDClass.static.GetMediumFontFor(Canvas);
	Canvas.StrLen("Test", XL, YL);
	BoxSpaceY = 0.25 * YL;
	PlayerBoxSizeY = 1.5 * YL;
	HeadFoot = 7*YL;
	MessageFoot = 1.5 * HeadFoot;
	if ( PlayerCount > (Canvas.ClipY - 1.5 * HeadFoot)/(PlayerBoxSizeY + BoxSpaceY) )
	{
		BoxSpaceY = 0.125 * YL;
		PlayerBoxSizeY = 1.25 * YL;
		if ( PlayerCount > (Canvas.ClipY - 1.5 * HeadFoot)/(PlayerBoxSizeY + BoxSpaceY) )
		{
			if ( PlayerCount > (Canvas.ClipY - 1.5 * HeadFoot)/(PlayerBoxSizeY + BoxSpaceY) )
				PlayerBoxSizeY = 1.125 * YL;
			if ( PlayerCount > (Canvas.ClipY - 1.5 * HeadFoot)/(PlayerBoxSizeY + BoxSpaceY) )
			{
				FontReduction++;
				Canvas.Font = GetSmallerFontFor(Canvas,FontReduction); 
				Canvas.StrLen("Test", XL, YL);
				BoxSpaceY = 0.125 * YL;
				PlayerBoxSizeY = 1.125 * YL;
				HeadFoot = 7*YL;
				if ( PlayerCount > (Canvas.ClipY - HeadFoot)/(PlayerBoxSizeY + BoxSpaceY) )
				{
					FontReduction++;
					Canvas.Font = GetSmallerFontFor(Canvas,FontReduction); 
					Canvas.StrLen("Test", XL, YL);
					BoxSpaceY = 0.125 * YL;
					PlayerBoxSizeY = 1.125 * YL;
					HeadFoot = 7*YL;
					if ( (Canvas.ClipY >= 768) && (PlayerCount > (Canvas.ClipY - HeadFoot)/(PlayerBoxSizeY + BoxSpaceY)) )
					{
						FontReduction++;
						Canvas.Font = GetSmallerFontFor(Canvas,FontReduction); 
						Canvas.StrLen("Test", XL, YL);
						BoxSpaceY = 0.125 * YL;
						PlayerBoxSizeY = 1.125 * YL;
						HeadFoot = 7*YL;
					}
				}
			}   
		}   
	}   
	if ( Canvas.ClipX < 512 )
		PlayerCount = Min(PlayerCount, 1+(Canvas.ClipY - HeadFoot)/(PlayerBoxSizeY + BoxSpaceY) );
	else
		PlayerCount = Min(PlayerCount, (Canvas.ClipY - HeadFoot)/(PlayerBoxSizeY + BoxSpaceY) );

	if ( FontReduction > 2 )
		MaxScaling = 3; 
	else
		MaxScaling = 2.125;
	PlayerBoxSizeY = FClamp((1.25+(Canvas.ClipY - 0.67 * MessageFoot))/PlayerCount - BoxSpaceY, PlayerBoxSizeY, MaxScaling * YL);
		
	bDisplayMessages = (PlayerCount <= (Canvas.ClipY - MessageFoot)/(PlayerBoxSizeY + BoxSpaceY));
	HeaderOffsetY = 5 * YL;
	BoxWidth = 0.9375 * Canvas.ClipX;
	BoxXPos = 0.5 * (Canvas.ClipX - BoxWidth);
	BoxWidth = Canvas.ClipX - 2*BoxXPos;
	NameXPos = BoxXPos + 0.0625 * BoxWidth;
	KillsXPos = BoxXPos + 0.3 * BoxWidth;
	ScoreXPos = BoxXPos + 0.45 * BoxWidth;
	HealthXpos = BoxXPos + 0.65 * BoxWidth;
	NetXPos = BoxXPos + 0.8625 * BoxWidth;
		
	// draw background boxes
	Canvas.Style = ERenderStyle.STY_Alpha;
	Canvas.DrawColor = HUDClass.default.WhiteColor * 0.5;
	for ( i=0; i<PlayerCount; i++ )
	{
		Canvas.SetPos(BoxXPos, HeaderOffsetY + (PlayerBoxSizeY + BoxSpaceY)*i);
		Canvas.DrawTileStretched( BoxMaterial, BoxWidth, PlayerBoxSizeY);
	}

	// draw title
	Canvas.Style = ERenderStyle.STY_Normal;
	DrawTitle(Canvas, HeaderOffsetY, (PlayerCount+1)*(PlayerBoxSizeY + BoxSpaceY), PlayerBoxSizeY);

	// Draw headers
	TitleYPos = HeaderOffsetY - 1.25*YL;
	Canvas.StrLen(PointsText, ScoreXL, YL);
	Canvas.StrLen(HealthText, HealthXL, YL);
	Canvas.StrLen(DeathsText, DeathsXL, YL);
	Canvas.StrLen(KillsText, KillsXL, YL);
	
	Canvas.DrawColor = HUDClass.default.WhiteColor;
	Canvas.SetPos(NameXPos, TitleYPos);
	Canvas.DrawText(PlayerText,true);
	if( bDisplayWithKills )
	{
		Canvas.SetPos(KillsXPos - 0.5*KillsXL, TitleYPos);
		Canvas.DrawText(KillsText,true);
	}
	Canvas.SetPos(ScoreXPos - 0.15*ScoreXL, TitleYPos);
	Canvas.DrawText(PointsText,true);
	Canvas.SetPos(HealthXPos - 0.05*HealthXL, TitleYPos);
	Canvas.DrawText(HealthText,true);
			
	// draw player names
	MaxNamePos = 0.9 * (KillsXPos - NameXPos);
	for ( i=0; i<PlayerCount; i++ )
	{
		Canvas.StrLen(GRI.PRIArray[i].PlayerName, XL, YL);
		if ( XL > MaxNamePos )
		{
			bNameFontReduction = true;
			break;
		}
	}
	if ( bNameFontReduction )
		Canvas.Font = GetSmallerFontFor(Canvas,FontReduction+1); 

	Canvas.Style = ERenderStyle.STY_Normal;
	Canvas.DrawColor = HUDClass.default.WhiteColor;
	Canvas.SetPos(0.5 * Canvas.ClipX, HeaderOffsetY + 4);
	BoxTextOffsetY = HeaderOffsetY + 0.5 * (PlayerBoxSizeY - YL);

	Canvas.DrawColor = HUDClass.default.WhiteColor;
	MaxNamePos = Canvas.ClipX;
	Canvas.ClipX = KillsXPos-4.f;
	for ( i=0; i<PlayerCount; i++ )
	{
		Canvas.SetPos(NameXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);
		if( i==OwnerOffset )
			Canvas.DrawColor.B = 0;
		else Canvas.DrawColor.B = 255;
		Canvas.DrawTextClipped(GRI.PRIArray[i].PlayerName);
	}
	Canvas.ClipX = MaxNamePos;
	Canvas.DrawColor = HUDClass.default.WhiteColor;
	if ( bNameFontReduction )
		Canvas.Font = GetSmallerFontFor(Canvas,FontReduction); 

	Canvas.Style = ERenderStyle.STY_Normal;
	MaxScaling = FMax(PlayerBoxSizeY,30.f);

	// Draw the player informations.
	for ( i=0; i<PlayerCount; i++ )
	{
		Canvas.DrawColor = HUDClass.default.WhiteColor;

		// Display perks.
		if( KFPlayerReplicationInfo(GRI.PRIArray[i])!=None && KFPlayerReplicationInfo(GRI.PRIArray[i]).ClientVeteranSkill != none )
		{
			VeterancyBox = KFPlayerReplicationInfo(GRI.PRIArray[i]).ClientVeteranSkill.default.OnHUDIcon;
			if( VeterancyBox!=None )
			{
				Canvas.SetPos(NameXPos-MaxScaling/2,(PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY-PlayerBoxSizeY*0.025);
				Canvas.DrawTile(VeterancyBox,MaxScaling*0.5,MaxScaling*0.5,0,0,VeterancyBox.MaterialUSize(),VeterancyBox.MaterialVSize());
			}
		}

		// draw kills
		if( bDisplayWithKills )
		{
			Canvas.SetPos(KillsXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);
			Canvas.DrawText(KFPlayerReplicationInfo(GRI.PRIArray[i]).Kills$"/"$int(KFPlayerReplicationInfo(GRI.PRIArray[i]).Deaths),true);
		}

		// draw cash
		Canvas.SetPos(ScoreXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);
		Canvas.DrawText(int(GRI.PRIArray[i].Score),true);

		// draw healths
		Canvas.SetPos(HealthXpos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);
		if ( GRI.PRIArray[i].bOutOfLives )
		{
			Canvas.DrawColor = HUDClass.default.RedColor;
			Canvas.DrawText(OutText,true);
		}
		else
		{
			if( KFPlayerReplicationInfo(GRI.PRIArray[i]).PlayerHealth>=95 )
			{
				Canvas.DrawColor = HUDClass.default.GreenColor;
				Canvas.DrawText("HEALTHY",true);
			}
			else if( KFPlayerReplicationInfo(GRI.PRIArray[i]).PlayerHealth>=50 )
			{
				Canvas.DrawColor = HUDClass.default.GoldColor;
				Canvas.DrawText("INJURED",true);
			}
			else
			{
				Canvas.DrawColor = HUDClass.default.RedColor;
				Canvas.DrawText("CRITICAL",true);
			}
		}
	}

	if ( Level.NetMode == NM_Standalone )
		return;

	Canvas.StrLen(NetText, NetXL, YL);
	Canvas.DrawColor = HUDClass.default.WhiteColor;
	Canvas.SetPos(NetXPos + 0.5*NetXL, TitleYPos);
	Canvas.DrawText(NetText,true);

	for ( i=0; i<GRI.PRIArray.Length; i++ )
		PRIArray[i] = GRI.PRIArray[i];
	DrawNetInfo(Canvas,FontReduction,HeaderOffsetY,PlayerBoxSizeY,BoxSpaceY,BoxTextOffsetY,OwnerOffset,PlayerCount,NetXPos);
	DrawMatchID(Canvas,FontReduction);
}

defaultproperties
{
     TeamScoreString="Cash Bonus:"
     WaveString="Wave"
     HealthText="Status"
     KillsText="Kills/Deaths"
     PointsText="Cash"
     OutText="DEAD"
     OutFireText="   You are dead. Fire to view other players."
     SkillLevel(1)="Easy"
     SkillLevel(3)="Normal"
     SkillLevel(4)="Skilled"
     SkillLevel(5)="Elite"
     SkillLevel(7)="Suicidal"
     Restart="   You were killed..."
     Ended="The game has ended."
     BoxMaterial=Texture'2K4Menus.NewControls.Display1'
}
