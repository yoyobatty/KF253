Class VSHUD extends HUDKillingFloor;

#exec obj load file="KFMapEndTextures.utx"

var Monster IDInfoPawn;
var float DisplayTimer;
var ClientLight LightSrc;
var bool bInitNearDeath,bHasMessagedInfo;
var Material SpectatorOverlay;

simulated function DrawMonsterInfo(Canvas C)
{
	local Actor A;
	local vector HL,HN;
	local float T,XL,YL;

	// Draw identification info.
	A = PlayerOwner.ViewTarget.Trace(HL,HN,vector(PlayerOwner.CalcViewRotation)*1000.f+PlayerOwner.CalcViewLocation,PlayerOwner.CalcViewLocation,true);
	if( ExtendedZCollision(A)!=None )
		A = A.Owner;
	if( Monster(A)!=None && A!=PlayerOwner.ViewTarget )
	{
		IDInfoPawn = Monster(A);
		DisplayTimer = Level.TimeSeconds;
		if( !bHasMessagedInfo && IDInfoPawn.Health>0 && IDInfoPawn.PlayerReplicationInfo==None && PlayerOwner.Pawn==None )
		{
			bHasMessagedInfo = true;
			PlayerOwner.ReceiveLocalizedMessage(class'VSInfoMessage');
		}
	}

	if( IDInfoPawn!=None )
	{
		T = (Level.TimeSeconds-DisplayTimer);
		if( T>1.f )
			IDInfoPawn = None;
		else
		{
			T = (1.f-T);
			C.Font = GetConsoleFont(C);
			C.TextSize("TWAQ",XL,YL);
			XL = C.ClipY*0.7f;
			C.Style = ERenderStyle.STY_Translucent;
			C.SetDrawColor(80.f*T, 80.f*T, 255.f*T);
			C.bCenter = true;
			C.SetPos(0,C.ClipY*0.7f);
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
	}
}
simulated final function Draw3DPlayers( Canvas C )
{
	local KFPawn P;
	local xPawn PP;
	local vector X,Pos;
	local float DotDist,DotScale;

	C.Style = ERenderStyle.STY_Translucent;
	X = vector(PlayerOwner.CalcViewRotation);
	C.SetDrawColor(255,50,0);
	DotScale = C.ClipX*0.2f;

	if( PlayerOwner.Pawn==None )
	{
		foreach DynamicActors(Class'xPawn',PP)
		{
			DotDist = X Dot (PP.Location-PlayerOwner.CalcViewLocation);
			if( PP.Health>0 && DotDist>0.f && DotDist<7000.f )
			{
				Pos = C.WorldToScreen(PP.Location);
				if( Pos.X<-100 || Pos.Y<-100 || Pos.X>(C.ClipX+100) || Pos.Y>(C.ClipY+100) || FastTrace(PP.Location,PlayerOwner.CalcViewLocation) )
					continue;
				if( KFPawn(PP)!=None )
					C.SetDrawColor(255,0,0);
				else C.SetDrawColor(25,255,0);
				DotDist = (DotScale/DotDist)*256.f;
				C.SetPos(Pos.X-DotDist*0.25f,Pos.Y-DotDist*0.5f);
				C.DrawRect(Texture'Engine.WhiteSquareTexture',DotDist*0.5f,DotDist);
			}
		}
	}
	else
	{
		foreach DynamicActors(Class'KFPawn',P)
		{
			DotDist = X Dot (P.Location-PlayerOwner.CalcViewLocation);
			if( P.Health>0 && DotDist>0.f && DotDist<7000.f )
			{
				Pos = C.WorldToScreen(P.Location);
				if( Pos.X<-100 || Pos.Y<-100 || Pos.X>(C.ClipX+100) || Pos.Y>(C.ClipY+100) || FastTrace(P.Location,PlayerOwner.CalcViewLocation) )
					continue;
				DotDist = (DotScale/DotDist)*256.f;
				C.SetPos(Pos.X-DotDist*0.25f,Pos.Y-DotDist*0.5f);
				C.DrawRect(Texture'Engine.WhiteSquareTexture',DotDist*0.5f,DotDist);
			}
		}
	}
}
simulated function DrawEndGameHUD(Canvas C, bool bVictory)
{
	local float Scalar;

	// Inverse victory for the bad guys.
	if( PlayerOwner.PlayerReplicationInfo!=None && PlayerOwner.PlayerReplicationInfo.Team!=None && PlayerOwner.PlayerReplicationInfo.Team.TeamIndex!=0 )
		bVictory = !bVictory;

	C.DrawColor.A = 255;
	C.DrawColor.R = 255;
	C.DrawColor.G = 255;
	C.DrawColor.B = 255;
	Scalar = FClamp(C.ClipY, 320, 1024);
	C.CurX = C.ClipX / 2 - Scalar / 2;
	C.CurY = C.ClipY / 2 - Scalar / 2;
	C.Style = ERenderStyle.STY_Alpha;

	if ( bVictory )
	{
		C.DrawTile(Shader'VictoryShader', Scalar, Scalar, 0, 0, 1024, 1024);
	}
	else
	{
		C.DrawTile(Shader'DefeatShader', Scalar, Scalar, 0, 0, 1024, 1024);
	}
	if ( bShowScoreBoard && ScoreBoard != None )
	{
		ScoreBoard.DrawScoreboard(C);
	}
}
simulated function DrawModOverlay( Canvas C )
{
	local int FinalR, FinalG, FinalB;
	local int MaxRBrighten, MaxGBrighten, MaxBBrighten;
	local int BaseR, BaseG, BaseB;
	local color OldColor;
	local byte OldStyle;

	C.SetPos(0, 0);
	if( !bInitNearDeath )
	{
		bInitNearDeath = true;
		C.DrawTile(NearDeathOverlay, 1, 1, 0, 0, 1, 1);
		C.DrawTile(Shader'VictoryShader', 1, 1, 0, 0, 1, 1);
		C.DrawTile(Shader'DefeatShader', 1, 1, 0, 0, 1, 1);
	}

	if( PlayerOwner.IsInState('PreySpec') || (PlayerOwner.PlayerReplicationInfo!=None && PlayerOwner.PlayerReplicationInfo.Team!=None && PlayerOwner.PlayerReplicationInfo.Team.TeamIndex!=0) )
	{
		OldColor = C.DrawColor;
		OldStyle = C.Style;
		Draw3DPlayers(C);
		DrawMonsterInfo(C);
		C.SetPos(0, 0);
		C.DrawColor = OldColor;
		C.Style = OldStyle;
	}

	// We want the overlay to start black, and fade in, almost like the player opened their eyes
	// BrightFactor = 1.5;   // Not too bright.  Not too dark.  Livens things up just abit
	// Hook for Optional Vision overlay.  - Alex
	if ( VisionOverlay != none )
	{
		if( PlayerOwner == none || PlayerOwner.PlayerReplicationInfo == none )
		{
			return;
		}

		if( LightSrc!=None )
			LightSrc.bDynamicLight = false;
		VisionOverlay = default.VisionOverlay;

		// if critical, pulsate.  otherwise, dont.
		if ( PlayerOwner.Pawn != none && PlayerOwner.Pawn.Health > 0 )
		{
			if ( PlayerOwner.pawn.Health < 25 )
			{
				VisionOverlay = NearDeathOverlay;
			}
			else
			{
				VisionOverlay = default.VisionOverlay;
			}
			if( Monster(PlayerOwner.Pawn)!=None )
			{
				if( LightSrc==None )
					LightSrc = Spawn(Class'ClientLight');
				LightSrc.SetLocation(PlayerOwner.Pawn.Location);
				LightSrc.bDynamicLight = true;
			}
		}
		else
		{
			// Dead Players see Red
			if( (PlayerOwner.PlayerReplicationInfo.bOutOfLives || PlayerOwner.PlayerReplicationInfo.bIsSpectator)
			 && !PlayerOwner.PlayerReplicationInfo.bOnlySpectator
			 && (PlayerOwner.PlayerReplicationInfo.Team==None || PlayerOwner.PlayerReplicationInfo.Team.TeamIndex==0) )
			{
				C.DrawTile(SpectatorOverlay, C.SizeX, C.SizeY, 0, 0, 1024, 1024);
				return;
			}
			return;
		}

		// Hook for fade in from black at the start.
		if ( !bInitialDark && PlayerOwner.PlayerReplicationInfo.bReadyToPlay )
		{
			C.SetDrawColor(0, 0, 0, 255);
			C.DrawTile(VisionOverlay, C.SizeX, C.SizeY, 0, 0, 1024, 1024);
			bInitialDark = true;
			return;
		}

		// Players can choose to turn this feature off completely.
		// conversely, setting bDistanceFog = false in a Zone
		//will cause the code to ignore that zone for a shift in RGB tint
		if ( KFLevelRule != none && !KFLevelRule.bUseVisionOverlay )
		{
			return;
		}

		// Choose base color: if we never picked up a fog tint, use neutral white so screen isn't black.
		if( LastR==0 && LastG==0 && LastB==0 )
		{
			BaseR = 255;
			BaseG = 255;
			BaseB = 255;
		}
		else
		{
			BaseR = LastR;
			BaseG = LastG;
			BaseB = LastB;
		}

		// Desaturate from 100 to 0 health, darken at 50 health and lower
		DesaturationFactor = 0.5 + 0.5 * (float(PlayerOwner.Pawn.Health) / PlayerOwner.Pawn.HealthMax);

		// here we determine the maximum "brighten" amounts for each value.  CANNOT exceed 255
		MaxRBrighten = Round(BaseR * (1.0 - (BaseR / 255)) - 2);
		MaxGBrighten = Round(BaseG * (1.0 - (BaseG / 255)) - 2);
		MaxBBrighten = Round(BaseB * (1.0 - (BaseB / 255)) - 2);

		FinalR = Clamp(Round((BaseR + MaxRBrighten) * DesaturationFactor), 0, 255);
		FinalG = Clamp(Round((BaseG + MaxGBrighten) * DesaturationFactor), 0, 255);
		FinalB = Clamp(Round((BaseB + MaxBBrighten) * DesaturationFactor), 0, 255);

		C.SetDrawColor(FinalR, FinalG, FinalB, GrainAlpha);
		C.DrawTile(VisionOverlay, C.SizeX, C.SizeY, 0, 0, 1024, 1024);

		// Here we change over the Zone.
		// What happens of importance is
		// A.  Set Old Zone to current
		// B.  Set New Zone
		// C.  Set Color info up for use by Tick()

		// if we're in a new zone or volume without distance fog...just , dont touch anything.
		// the physicsvolume check is abit screwy because the player is always in a volume called "DefaultPhyicsVolume"
		// so we've gotta make sure that the return checks take this into consideration.

		if ( PlayerOwner != none && PlayerOwner.Pawn != none )
		{
			// This block of code here just makes sure that if we've already got a tint, and we step into a zone/volume without
			// bDistanceFog, our current tint is not affected.
			// a.  If I'm in a zone and its not bDistanceFog. AND IM NOT IN A PHYSICSVOLUME. Just a zone.
			// b.  If I'm in a Volume
			if ( PlayerOwner.PlayerReplicationInfo.PlayerZone != none && !PlayerOwner.PlayerReplicationInfo.PlayerZone.bDistanceFog &&
				 PlayerOwner.PlayerReplicationInfo.PlayerVolume == none || DefaultPhysicsVolume(PlayerOwner.pawn.PhysicsVolume)==None &&
				 !PlayerOwner.pawn.PhysicsVolume.bDistanceFog )
			{
				return;
			}
		}

		if ( PlayerOwner != none && !bZoneChanged && PlayerOwner.Pawn != none )
		{
			// Grab the most recent zone info from our PRI
			// Only update if it's different
			// EDIT:  AND HAS bDISTANCEFOG true
			if ( CurrentZone != PlayerOwner.PlayerReplicationInfo.PlayerZone || DefaultPhysicsVolume(PlayerOwner.pawn.PhysicsVolume) == None &&
				 CurrentVolume != PlayerOwner.pawn.PhysicsVolume )
			{
				if ( CurrentZone != none )
				{
				    LastZone = CurrentZone;
				}
				else if ( CurrentVolume != none )
				{
					LastVolume = CurrentVolume;
				}

				// This is for all occasions where we're either in a Levelinfo handled zone
				// Or a zoneinfo.
				// If we're in a LevelInfo / ZoneInfo  and NOT touching a Volume.  Set current Zone
				if ( PlayerOwner.PlayerReplicationInfo.PlayerZone != none && PlayerOwner.PlayerReplicationInfo.PlayerZone.bDistanceFog &&
					 DefaultPhysicsVolume(PlayerOwner.pawn.PhysicsVolume)!= none )
				{
					CurrentVolume = none;
					CurrentZone = PlayerOwner.PlayerReplicationInfo.PlayerZone;
				}
				else if ( DefaultPhysicsVolume(PlayerOwner.pawn.PhysicsVolume) == None && PlayerOwner.pawn.PhysicsVolume.bDistanceFog)
				{
					CurrentZone = none;
					CurrentVolume = PlayerOwner.pawn.PhysicsVolume;
				}

				if ( CurrentVolume != none )
				{
					LastZone = none;
				}
				else if ( CurrentZone != none )
				{
					LastVolume = none;
				}

				if ( LastZone != none )
				{
                    LastR = LastZone.DistanceFogColor.R;
    				LastG = LastZone.DistanceFogColor.G;
    				LastB = LastZone.DistanceFogColor.B;
				}
				else if ( LastVolume != none )
				{
    				LastR = LastVolume.DistanceFogColor.R;
    				LastG = LastVolume.DistanceFogColor.G;
    				LastB = LastVolume.DistanceFogColor.B;
				}
				else if ( LastZone != none && LastVolume != none )
				{
					return;
				}

				if ( LastZone != CurrentZone || LastVolume != CurrentVolume )
				{
					bZoneChanged = true;
					SetTimer(OverlayFadeSpeed, false);
				}
			}
		}
		if ( !bTicksTurn && bZoneChanged )
		{
			// Pass it off to the tick now
			// valueCheckout signifies that none of the three values have been
			// altered by Tick() yet.

			// BOUNCE IT BACK! :D
			ValueCheckOut = 0;
			bTicksTurn = true;
			SetTimer(OverlayFadeSpeed, false);
		}
	}
}

defaultproperties
{
     SpectatorOverlay=Shader'KFX.NearDeathShader'
}
