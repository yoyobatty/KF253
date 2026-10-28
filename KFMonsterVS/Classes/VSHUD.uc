Class VSHUD extends HUDKillingFloor;

var Monster IDInfoPawn;
var float DisplayTimer;
var ClientLight LightSrc;		// a dim light about the player's own specimen, to see by in the dark
var bool bHasMessagedInfo;
var float NextSpotCheck;
var byte SpotProblem;			// a ghost's spot as last checked (VSPC.SpawnProblem)

var localized string HalfText, HalfTimeText, SecondHalfInText, RiseAsText, RiseInText, RiseHereText, WarpText;
var localized string SpotTexts[6];
var localized string PatienceText, WonText, LostText;

// The team this player is on in the versus match (255 none)
simulated function byte MySquad()
{
	if( VSPRI(PlayerOwner.PlayerReplicationInfo)!=None )
		return VSPRI(PlayerOwner.PlayerReplicationInfo).VSTeam;
	return 255;
}
simulated function bool IsSpecimenSide()
{
	return PlayerOwner.IsInState('Ghost') || (PlayerOwner.PlayerReplicationInfo!=None && PlayerOwner.PlayerReplicationInfo.Team!=None
		&& PlayerOwner.PlayerReplicationInfo.Team.TeamIndex!=0 && !PlayerOwner.PlayerReplicationInfo.bOnlySpectator);
}

simulated function DrawModOverlay( Canvas C )
{
	local color OldColor;
	local byte OldStyle;

	Super.DrawModOverlay(C);

	if( (KFMonster(PlayerOwner.Pawn)!=None && PlayerOwner.Pawn.Health>0) || PlayerOwner.IsInState('Ghost') )
	{
		if( LightSrc==None )
			LightSrc = Spawn(Class'ClientLight');
		if( LightSrc!=None )
		{
			if( PlayerOwner.Pawn!=None )
				LightSrc.SetLocation(PlayerOwner.Pawn.Location);
			else LightSrc.SetLocation(PlayerOwner.Location);
			LightSrc.bDynamicLight = true;
		}
	}
	else if( LightSrc!=None )
		LightSrc.bDynamicLight = false;

	if( IsSpecimenSide() )
	{
		OldColor = C.DrawColor;
		OldStyle = C.Style;
		DrawHiddenPlayers(C);
		DrawMonsterInfo(C);
		C.SetPos(0,0);
		C.DrawColor = OldColor;
		C.Style = OldStyle;
	}
}

// Survivors behind walls in red, and the team's own specimens in green
simulated final function DrawHiddenPlayers( Canvas C )
{
	local Pawn P;
	local vector X, Pos;
	local float DotDist, DotScale;

	C.Style = ERenderStyle.STY_Translucent;
	X = vector(PlayerOwner.CalcViewRotation);
	DotScale = C.ClipX*0.2;
	foreach DynamicActors(Class'Pawn',P)
	{
		if( P.Health<=0 || P==PlayerOwner.Pawn )
			continue;
		if( KFHumanPawn(P)!=None )
			C.SetDrawColor(255,0,0);
		else if( KFMonster(P)!=None && P.PlayerReplicationInfo!=None )
			C.SetDrawColor(25,255,0);
		else continue;
		DotDist = X Dot (P.Location-PlayerOwner.CalcViewLocation);
		if( DotDist<=0 || DotDist>7000 )
			continue;
		Pos = C.WorldToScreen(P.Location);
		if( Pos.X<-100 || Pos.Y<-100 || Pos.X>(C.ClipX+100) || Pos.Y>(C.ClipY+100) || FastTrace(P.Location,PlayerOwner.CalcViewLocation) )
			continue;
		DotDist = (DotScale/DotDist)*256.0;
		C.SetPos(Pos.X-DotDist*0.25,Pos.Y-DotDist*0.5);
		C.DrawRect(Texture'Engine.WhiteSquareTexture',DotDist*0.5,DotDist);
	}
}

simulated function DrawMonsterInfo( Canvas C )
{
	local Actor A;
	local vector HL, HN;
	local float T, XL, YL;

	A = PlayerOwner.ViewTarget.Trace(HL,HN,vector(PlayerOwner.CalcViewRotation)*1000.0+PlayerOwner.CalcViewLocation,PlayerOwner.CalcViewLocation,true);
	if( ExtendedZCollision(A)!=None )
		A = A.Owner;
	if( Monster(A)!=None && A!=PlayerOwner.ViewTarget )
	{
		IDInfoPawn = Monster(A);
		DisplayTimer = Level.TimeSeconds;
	}
	if( IDInfoPawn==None )
		return;
	T = Level.TimeSeconds-DisplayTimer;
	if( T>1.0 )
	{
		IDInfoPawn = None;
		return;
	}
	T = 1.0-T;
	C.Font = GetConsoleFont(C);
	C.TextSize("TWAQ",XL,YL);
	XL = C.ClipY*0.7;
	C.Style = ERenderStyle.STY_Translucent;
	C.SetDrawColor(80.0*T, 80.0*T, 255.0*T);
	C.bCenter = true;
	C.SetPos(0,XL);
	C.DrawText(IDInfoPawn.MenuName,true);
	C.CurY = XL+YL;
	C.DrawText("Health:"@IDInfoPawn.Health,true);
	if( IDInfoPawn.PlayerReplicationInfo!=None )
	{
		C.CurY = XL+YL*2;
		C.DrawText("Controller:"@IDInfoPawn.PlayerReplicationInfo.PlayerName,true);
	}
	C.bCenter = false;
}

simulated function DrawHud( Canvas C )
{
	Super.DrawHud(C);
	DrawVersus(C);
}
simulated function DrawSpectatingHud( Canvas C )
{
	Super.DrawSpectatingHud(C);
	DrawVersus(C);
}

// The match's score along the top, the break between halves, a ghost's rising and a heavy's patience
simulated final function DrawVersus( Canvas C )
{
	local VSGRI G;
	local VSPRI R;
	local string S;
	local float XL, YL, Y;
	local vector Spot;
	local byte i;

	G = VSGRI(PlayerOwner.GameReplicationInfo);
	if( G==None || !G.bMatchHasBegun || G.WinnerSquad!=255 )
		return;
	R = VSPRI(PlayerOwner.PlayerReplicationInfo);

	C.Font = GetConsoleFont(C);
	C.Style = ERenderStyle.STY_Alpha;
	S = HalfText@G.Half$":";
	for( i=0; i<2; i++ )
		S = S$"   "$G.SquadName(i)$" ("$G.RoleOf(i)$") "$G.SquadScore[i];
	C.StrLen(S,XL,YL);
	Y = C.ClipY*0.01;
	C.SetDrawColor(0,0,0,140);
	C.SetPos(C.ClipX*0.5-XL*0.5-6,Y-2);
	C.DrawTile(Texture'Engine.WhiteSquareTexture',XL+12,YL+4,0,0,1,1);
	C.SetDrawColor(255,255,255,230);
	C.SetPos(C.ClipX*0.5-XL*0.5,Y);
	C.DrawText(S,false);

	if( G.HalfTimeLeft>0 )
	{
		C.Font = GetFontSizeIndex(C,2);
		C.StrLen(HalfTimeText,XL,YL);
		C.SetDrawColor(255,60,40,255);
		C.SetPos(C.ClipX*0.5-XL*0.5,C.ClipY*0.3);
		C.DrawText(HalfTimeText,false);
		C.Font = GetFontSizeIndex(C,0);
		S = G.SquadName(G.SurvivorSquad)@G.SquadScore[G.SurvivorSquad]$".   "$SecondHalfInText@G.HalfTimeLeft;
		C.StrLen(S,XL,YL);
		C.SetDrawColor(255,255,255,255);
		C.SetPos(C.ClipX*0.5-XL*0.5,C.ClipY*0.3+YL*2);
		C.DrawText(S,false);
		return;
	}

	if( R==None )
		return;
	C.Font = GetFontSizeIndex(C,-1);
	if( PlayerOwner.IsInState('Ghost') && R.SpawnClass!=None )
	{
		Y = C.ClipY*0.72;
		S = RiseAsText@R.SpawnClass.Default.MenuName;
		C.StrLen(S,XL,YL);
		C.SetDrawColor(255,255,255,255);
		C.SetPos(C.ClipX*0.5-XL*0.5,Y);
		C.DrawText(S,false);
		Y += YL*1.2;
		if( R.SpawnWait>0 )
		{
			S = RiseInText@R.SpawnWait;
			C.SetDrawColor(255,200,60,255);
		}
		else if( !G.bWaveInProgress )
		{
			S = SpotTexts[1];
			C.SetDrawColor(255,200,60,255);
		}
		else
		{
			if( Level.TimeSeconds>=NextSpotCheck && VSPC(PlayerOwner)!=None )
			{
				NextSpotCheck = Level.TimeSeconds + 0.2;
				SpotProblem = VSPC(PlayerOwner).SpawnProblem(R.SpawnClass,Spot);
			}
			if( SpotProblem==0 )
			{
				S = RiseHereText;
				C.SetDrawColor(80,255,80,255);
			}
			else
			{
				S = SpotTexts[Min(SpotProblem,5)];
				C.SetDrawColor(255,70,70,255);
			}
		}
		C.StrLen(S,XL,YL);
		C.SetPos(C.ClipX*0.5-XL*0.5,Y);
		C.DrawText(S,false);
		Y += YL*1.2;
		C.StrLen(WarpText,XL,YL);
		C.SetDrawColor(200,200,200,220);
		C.SetPos(C.ClipX*0.5-XL*0.5,Y);
		C.DrawText(WarpText,false);
	}
	else if( KFMonster(PlayerOwner.Pawn)!=None && R.Patience>0 && R.Patience<100 )
		class'VSZed'.static.DrawCharge(C,R.Patience/100.0,PatienceText,C.ClipY*0.12);
}

simulated function DrawEndGameHUD( Canvas C, bool bVictory )
{
	local VSGRI G;
	local string S;
	local float XL, YL;

	G = VSGRI(PlayerOwner.GameReplicationInfo);
	if( G==None || G.WinnerSquad>2 )
	{
		Super.DrawEndGameHUD(C,bVictory);
		return;
	}
	if( G.WinnerSquad<2 )
		Super.DrawEndGameHUD(C,G.WinnerSquad==MySquad());
	C.Font = GetFontSizeIndex(C,1);
	if( G.WinnerSquad==2 )
		S = G.DrawText;
	else S = G.SquadName(G.WinnerSquad)@WonText;
	S = S$"   "$G.SquadName(0)@G.SquadScore[0]$",  "$G.SquadName(1)@G.SquadScore[1];
	C.StrLen(S,XL,YL);
	C.Style = ERenderStyle.STY_Alpha;
	C.SetDrawColor(255,255,255,255);
	C.SetPos(C.ClipX*0.5-XL*0.5,C.ClipY*0.68);
	C.DrawText(S,false);
}

simulated function Destroyed()
{
	if( LightSrc!=None )
		LightSrc.Destroy();
	Super.Destroyed();
}

defaultproperties
{
     HalfText="Half"
     HalfTimeText="HALF TIME"
     SecondHalfInText="The teams change sides in"
     RiseAsText="You rise as the"
     RiseInText="You may rise in"
     RiseHereText="Fire: rise here"
     WarpText="Alt-Fire: go to a survivor"
     SpotTexts(0)=""
     SpotTexts(1)="Wait for the wave"
     SpotTexts(2)="No floor below"
     SpotTexts(3)="A survivor can see this spot"
     SpotTexts(4)="Too close to a survivor"
     SpotTexts(5)="No room here"
     PatienceText="Patience: hurt a survivor or lose the heavy"
     WonText="wins!"
     LostText="loses"
}
