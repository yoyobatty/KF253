class VSGame extends KFGameType;

var bool bHasPlayerMonsters;
var bool bRespawnOnBoss;

var config bool bFullVSMode;
var config array<name> PossessablePawns;
var config float PlayersVSZedsRatio;
var config int MonsterKillTime;

var transient float NextTraderMsg,NextYellTime;
var int KillPLMonstersTimer;

function RestartPlayer( Controller aPlayer )
{
	if( aPlayer.PlayerReplicationInfo.Team==Teams[1] )
	{
		aPlayer.GoToState('PreySpec');
		SyncClientState(PlayerController(aPlayer),'PreySpec');
	}
	else Super.RestartPlayer(aPlayer);
}
final function SyncClientState( PlayerController P, name NewState )
{
	if( P!=None && Viewport(P.Player)==None )
		P.ClientGotoState(NewState,'');
}
final function bool CanTakeMoreSpecimen()
{
	local float Ratio;

	if( Level.NetMode==NM_StandAlone )
		return true;
	if( Teams[0].Size<=1 )
		Ratio = 99999;
	else Ratio = (float(Teams[1].Size)/float(Teams[0].Size));
	return (Ratio<PlayersVSZedsRatio);
}
final function PlayerSwapTeam( VSPC P, byte N )
{
	if( !bFullVSMode || N>1 || P.PlayerReplicationInfo.Team==Teams[N] || P.PlayerReplicationInfo.bOnlySpectator )
		return;
	if( N==1 && !CanTakeMoreSpecimen() )
	{
		P.ClientMessage("Can't switch team: Too many specimen players already!");
		return;
	}
	if( P.Pawn!=None && !P.UnPossessZed() )
		P.Pawn.PlayerChangedTeam();
	P.PlayerReplicationInfo.Team.RemoveFromTeam(P);
	P.PlayerReplicationInfo.Team = Teams[N];
	P.PlayerReplicationInfo.Team.AddToTeam(P);
	Broadcast(Self,P.PlayerReplicationInfo.PlayerName@"joined the"@Eval(N==0,"humans","specimen")$"!");
	if( (P.IsInState('Spectating') || P.IsInState('PlayerWaiting')) && ShouldGoHunt(P) )
	{
		P.GoToState('PreySpec');
		SyncClientState(P,'PreySpec');
	}
	else if( P.IsInState('PreySpec') && !ShouldGoHunt(P) )
	{
		P.GoToState('Spectating');
		SyncClientState(P,'Spectating');
	}
}
final function bool ShouldGoHunt( VSPC P )
{
	if( bFullVSMode )
		return (P.PlayerReplicationInfo.Team==Teams[1]);
	return true;
}
final function PlayerPossess( VSPC P, KFMonster M )
{
	local byte i;
	local bool bRes;

	if( bFullVSMode && P.PlayerReplicationInfo.Team!=Teams[1] )
	{
		P.ClientMessage("Can't possess: Bad player team.");
		return;
	}
	if( MonsterController(M.Controller)==None )
	{
		P.ClientMessage("Can't possess: Already controlled by a player.");
		return;
	}
	for( i=0; i<PossessablePawns.Length; ++i )
		if( M.IsA(PossessablePawns[i]) )
		{
			bRes = true;
			break;
		}
	if( !bRes )
	{
		P.ClientMessage("Can't possess"@GetNameOf(M));
		return;
	}
	if( bWaveInProgress && KillPLMonstersTimer<=0 )
	{
		P.ClientMessage("Can't possess: Player control monster time is up!");
		return;
	}
	if( M.Controller!=None )
	{
		M.Controller.Pawn = None;
		M.Controller.Destroy();
	}
	if( P.PlayerReplicationInfo.Team!=Teams[1] )
	{
		P.PlayerReplicationInfo.Team.RemoveFromTeam(P);
		P.PlayerReplicationInfo.Team = Teams[1];
		P.PlayerReplicationInfo.Team.AddToTeam(P);
	}
	if( bFullVSMode )
		P.PlayerReplicationInfo.bOutOfLives = false;
	P.ClientSetRotation(M.Rotation);
	P.Possess(M);
	//P.bIsPlayer = false; // Stupid hack to prevent other zeds from attacking me!
}

// Stub
static function Texture GetRandomTeamSymbol(int base)
{
	return Texture'Engine.DefaultTexture';
}

event PreBeginPlay()
{
	Super.PreBeginPlay();

	KFGameReplicationInfo(GameReplicationInfo).bNoBots = bNoBots;
	KFGameReplicationInfo(GameReplicationInfo).PendingBots = 0;
	KFGameReplicationInfo(GameReplicationInfo).GameDiff = GameDifficulty;
	KFGameReplicationInfo(GameReplicationInfo).bEnemyHealthBars = bEnemyHealthBars;

	Teams[1] = GetBlueTeam(0);
	Teams[1].TeamIndex = 1;
	Teams[1].AI = Spawn(TeamAIType[1]);
	Teams[1].AI.Team = Teams[1];
	Teams[0].AI.EnemyTeam = Teams[1];
	Teams[1].AI.EnemyTeam = Teams[0];
	Teams[1].AI.SetObjectiveLists();

	if( bFullVSMode )
		ScoreBoardType = string(Class'VSTeamScoreBoard');
}

function PostBeginPlay()
{
	Super.PostBeginPlay();
	GameReplicationInfo.bNoTeamChanges = !bFullVSMode;
}

final function SetGameSpeedX( float Speed )
{
	Level.TimeDilation = Speed*1.1f;
	Level.NetUpdateTime = Level.TimeSeconds-1.f;
}

final function EndZEDTime()
{
}
// Overriden to handle ZEDTime zombie death slomo system
event Tick(float DeltaTime)
{
}


// Force stop all remaining zeds when the boss dies
function DoBossDeath()
{
	local Controller C;
	local Controller nextC;
	local int num;

	num = NumMonsters;

	c = Level.ControllerList;

	// turn off all the other zeds so they don't attack the player
	while (c != none && num > 0)
	{
		nextC = c.NextController;
		if (KFMonsterController(C)!=None)
		{
			C.GotoState('GameEnded');
			--num;
		}
		c = nextC;
	}
}

final function class<KFMonster> GetReplacement( class<KFMonster> M )
{
	if( Class<ZombieClot>(M)!=None )
		return class'AwesomeClot';
	if( Class<ZombieBloat>(M)!=None )
		return class'AwesomeBloat';
	if( Class<ZombieShade>(M)!=None )
		return class'AwesomeShade';
	if( Class<ZombieCrawler>(M)!=None )
		return class'AwesomeCrawler';
	if( Class<ZombieFleshPound>(M)!=None )
		return class'AwesomeFleshPound';
	if( Class<ZombieGorefast>(M)!=None )
		return class'AwesomeGoreFast';
	if( Class<ZombieScrake>(M)!=None )
		return class'AwesomeScrake';
	if( Class<ZombieSiren>(M)!=None )
		return class'AwesomeSiren';
	if( Class<ZombieStalker>(M)!=None )
		return class'AwesomeStalker';
	if( Class<ZombieWretch>(M)!=None )
		return class'AwesomeWretch';
	return M;
}

function LoadUpMonsterList()
{
	local int i,j,q,c,n;
	local Class<KFMonster> MC;
	local string S,ID;
	local bool bInitSq;
	local array<IMClassList> InitMList;

	//Log("Loading up monster classes...",'Init');
	for( i=0; i<MonsterClasses.Length; i++ )
	{
		if( MonsterClasses[i].MClassName=="" || MonsterClasses[i].MID=="" )
			Continue;
		MC = Class<KFMonster>(DynamicLoadObject(MonsterClasses[i].MClassName,Class'Class'));
		if( MC==None )
			Continue;
		InitMList.Length = j+1;
		InitMList[j].MClass = GetReplacement(MC);
		InitMList[j].ID = MonsterClasses[i].MID;
		j++;
	}
	//Log("Got"@j@"monsters. Loading up monster squads...",'Init');
	for( i=0; i<MonsterSquad.Length; i++ )
	{
		S = MonsterSquad[i];
		if( S=="" )
			Continue;
		bInitSq = False;
		n = 0;
		While( S!="" )
		{
			q = int(Left(S,1));
			ID = Mid(S,1,1);
			S = Mid(S,2);
			MC = None;
			for( j=0; j<InitMList.Length; j++ )
			{
				if( InitMList[j].ID~=ID )
				{
					MC = Class<KFMonster>(InitMList[j].MClass);
					Break;
				}
			}
			if( MC==None )
				Continue;
			if( !bInitSq )
			{
				InitSquads.Length = c+1;
				bInitSq = True;
			}
			while( (q--)>0 )
			{
				InitSquads[c].MSquad.Length = n+1;
				InitSquads[c].MSquad[n] = MC;
				n++;
			}
		}
		if( bInitSq )
			c++;
	}
	//Log("Got"@c@"monster squads.",'Init');
	if( FallbackMonster==class'EliteKrall' && InitMList.Length>0 )
		FallbackMonster = GetReplacement(Class<KFMonster>(InitMList[0].MClass));
}


function ScoreKill(Controller Killer, Controller Other)
{
	local PlayerReplicationInfo OtherPRI;
	local float KillScore;

	OtherPRI = Other.PlayerReplicationInfo;
	if ( OtherPRI != None )
	{
		if( OtherPRI.Team==Teams[0] )
		{
			OtherPRI.NumLives++;
			OtherPRI.Score -= (OtherPRI.Score * (GameDifficulty * 0.05));	// you Lose 35% of your current cash on suicidal, 15% on normal.
			OtherPRI.Team.Score -= (OtherPRI.Score * (GameDifficulty * 0.05));

			if (OtherPRI.Score < 0 )
				OtherPRI.Score = 0;
			if (OtherPRI.Team.Score < 0 )
				OtherPRI.Team.Score = 0;

			OtherPRI.Team.NetUpdateTime = Level.TimeSeconds - 1;
			OtherPRI.bOutOfLives = true;
			if( Killer!=None && Killer.PlayerReplicationInfo!=None && Killer.bIsPlayer )
			{
				if( Killer.PlayerReplicationInfo.Team!=OtherPRI.Team )
					BroadcastLocalizedMessage(class'VSInvasionMessage',1,OtherPRI,Killer.PlayerReplicationInfo,Killer.Pawn.Class);
				else BroadcastLocalizedMessage(class'VSInvasionMessage',1,OtherPRI,Killer.PlayerReplicationInfo);
			}
			else if( Killer==None || Monster(Killer.Pawn)==None )
				BroadcastLocalizedMessage(class'VSInvasionMessage',1,OtherPRI);
			else BroadcastLocalizedMessage(class'VSInvasionMessage',1,OtherPRI,,Killer.Pawn.Class);
			CheckScore(None);
		}
		else if( OtherPRI.Team==Teams[1] )
		{
			if( bFullVSMode )
				OtherPRI.bOutOfLives = true;
			if( Killer!=None && Other!=Killer && PlayerController(Other)!=None )
			{
				if( Killer.PlayerReplicationInfo!=None )
					PlayerController(Other).ReceiveLocalizedMessage(class'VSKilledMessage',,Killer.PlayerReplicationInfo);
				else PlayerController(Other).ReceiveLocalizedMessage(class'VSKilledMessage',,,,Killer.Pawn.Class);
			}
		}
	}

	if ( GameRulesModifiers != None )
		GameRulesModifiers.ScoreKill(Killer, Other);

	if( (killer == Other) || (killer == None) )
	{
		if ( Other.PlayerReplicationInfo != None )
		{
			Other.PlayerReplicationInfo.Score -= 1;
			Other.PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;
			ScoreEvent(Other.PlayerReplicationInfo,-1,"self_frag");
		}
	}
	else if ( Other.bIsPlayer && OtherPRI!=None && OtherPRI.Team==Teams[0] && !Killer.bIsPlayer )
	{
		// Specimen killed a player, score for specimen!
		Teams[1].Score+=1;
		Teams[1].NetUpdateTime = Level.TimeSeconds - 1;
		return;
	}

	if ( Killer==None || !Killer.bIsPlayer || (Killer==Other) || MonsterController(Killer)!=None )
		return;

	if ( Other.bIsPlayer && OtherPRI!=None && OtherPRI.Team==Teams[0] )
	{
		if( OtherPRI!=None && Killer.PlayerReplicationInfo.Team!=OtherPRI.Team )
		{
			Killer.PlayerReplicationInfo.Kills++;
			Killer.PlayerReplicationInfo.Score += 50;
			Killer.PlayerReplicationInfo.Team.Score+=1;
			Killer.PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;
			Killer.PlayerReplicationInfo.Team.NetUpdateTime = Level.TimeSeconds - 1;
		}
		else
		{
			Killer.PlayerReplicationInfo.Score -= 5;
			Killer.PlayerReplicationInfo.Team.Score -= 2;
			Killer.PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;
			Killer.PlayerReplicationInfo.Team.NetUpdateTime = Level.TimeSeconds - 1;
			ScoreEvent(Killer.PlayerReplicationInfo, -5, "team_frag");
		}
	}
	else if( Killer.PlayerReplicationInfo!=None )
	{
		if( Monster(Other.Pawn)!=None )
			KillScore = Monster(Other.Pawn).ScoringValue;
		else if( LastKilledMonsterClass!=None )
			KillScore = LastKilledMonsterClass.Default.ScoringValue;
		else KillScore = 1;

		// Scale killscore by difficulty
		if ( GameDifficulty >= 7.0 ) // Suicidal
			KillScore *= 0.65;
		else if ( GameDifficulty >= 4.0 ) // Hard
			KillScore *= 0.85;
		else if ( GameDifficulty >= 2.0 ) // Normal
			KillScore *= 1.0;
		else // Beginner
			KillScore *= 2.0;

		if( Killer.PlayerReplicationInfo.Team==Teams[1] ) // Was in-team kill.
		{
			//Killer.PlayerReplicationInfo.Kills--;
			Killer.PlayerReplicationInfo.Score -= KillScore;
			Killer.PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;
			return;
		}
		KillScore = Max(1,int(KillScore));
		Killer.PlayerReplicationInfo.Kills++;
		Killer.PlayerReplicationInfo.Score += KillScore;
		Killer.PlayerReplicationInfo.Team.Score += KillScore;
		Killer.PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;
		Killer.PlayerReplicationInfo.Team.NetUpdateTime = Level.TimeSeconds - 1;
		TeamScoreEvent(Killer.PlayerReplicationInfo.Team.TeamIndex, 1, "tdm_frag");
		if( KFPlayerReplicationInfo(Killer.PlayerReplicationInfo)!=None )
			KFPlayerReplicationInfo(Killer.PlayerReplicationInfo).ThreeSecondScore+=KillScore;
	}

	if (Killer.PlayerReplicationInfo !=none && Killer.PlayerReplicationInfo.Score < 0)
		Killer.PlayerReplicationInfo.Score = 0;
}

function bool RewardSurvivingPlayers()
{
	local Controller C;
	local int moneyPerPlayer,div;
	local TeamInfo T;

	T = Teams[0];
	for ( C = Level.ControllerList; C != none; C = C.NextController )
	{
		if ( C.Pawn != none && C.PlayerReplicationInfo != none && C.PlayerReplicationInfo.Team==T )
			div++;
	}

	if ( T == none || T.Score <= 0 )
	{
		return false;
	}

	moneyPerPlayer = int(T.Score / float(div));

	for ( C = Level.ControllerList; C != none; C = C.NextController )
	{
		if ( C.Pawn != none && C.PlayerReplicationInfo != none && C.PlayerReplicationInfo.Team==T )
		{
			if ( div == 1 )
			{
				C.PlayerReplicationInfo.Score += T.Score;
				T.Score = 0;
			}
			else
			{
				C.PlayerReplicationInfo.Score += moneyPerPlayer;
				T.Score-=moneyPerPlayer;
				div--;
			}

			C.PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;

			if( T.Score <= 0 )
			{
				T.Score = 0;
				Break;
			}
		}
	}

	T.NetUpdateTime = Level.TimeSeconds - 1;

	return true;
}

final function HandleMonsterKill()
{
	local Controller C;

	if( KillPLMonstersTimer<=0 )
	{
		for( C=Level.ControllerList; C!=None; C=C.nextController )
		{
			if( Monster(C.Pawn)!=None && C.Pawn.Health>0 && PlayerController(C)!=None )
			{
				C.Pawn.Suicide();
				break;
			}
		}
	}
	else if( KillPLMonstersTimer>2 )
	{
		for( C=Level.ControllerList; C!=None; C=C.nextController )
		{
			if( Monster(C.Pawn)!=None && C.Pawn.Health>0 && PlayerController(C)!=None )
				PlayerController(C).ReceiveLocalizedMessage(class'VSTimeMessage',(KillPLMonstersTimer-2));
		}
	}
}

State MatchInProgress
{
	function bool UpdateMonsterCount()
	{
		local Controller C;
		local int i,j;

		bHasPlayerMonsters = false;
		For( C=Level.ControllerList; C!=None; C=C.NextController )
		{
			if( C.Pawn!=None && C.Pawn.Health>0 )
			{
				if( Monster(C.Pawn)!=None )
				{
					if( !bHasPlayerMonsters && PlayerController(C)!=None )
						bHasPlayerMonsters = true;
					i++;
				}
				else j++;
			}
		}
		NumMonsters = i;
		Return (j>0);
	}

	function Timer()
	{
		local Controller C;
		local bool bOneMessage;
		local Bot B;

		Global.Timer();

		if ( !bFinalStartup )
		{
			bFinalStartup = true;
			PlayStartupMessage();
		}
		if ( NeedPlayers() && AddBot() && (RemainingBots > 0) )
			RemainingBots--;
		ElapsedTime++;
		GameReplicationInfo.ElapsedTime = ElapsedTime;
		if( !UpdateMonsterCount() )
		{
			EndGame(None,"TimeLimit");
			Return;
		}

		if( bUpdateViewTargs )
			UpdateViews();

		if (!bNoBots && !bBotsAdded)
		{
			if(KFGameReplicationInfo(GameReplicationInfo) != none)

			if((NumPlayers + NumBots) < MaxPlayers && KFGameReplicationInfo(GameReplicationInfo).PendingBots > 0 )
			{
				AddBots(1);
				KFGameReplicationInfo(GameReplicationInfo).PendingBots --;
			}

			if (KFGameReplicationInfo(GameReplicationInfo).PendingBots == 0)
			{
				bBotsAdded = true;
				return;
			}
		}

		if( bWaveBossInProgress )
		{
			if( TraderProblemLevel<4 )
			{
				if( BootShopPlayers() )
					TraderProblemLevel = 0;
				else TraderProblemLevel++;
			}
			if( !bHasSetViewYet && TotalMaxMonsters<=0 && NumMonsters>0 )
			{
				bHasSetViewYet = True;
				for ( C = Level.ControllerList; C != None; C = C.NextController )
					if ( C.Pawn!=None && KFMonster(C.Pawn)!=None && KFMonster(C.Pawn).MakeGrandEntry() )
					{
						ViewingBoss = KFMonster(C.Pawn);
						Break;
					}
				if( ViewingBoss!=None )
				{
					ViewingBoss.bAlwaysRelevant = True;
					for ( C = Level.ControllerList; C != None; C = C.NextController )
					{
						if( PlayerController(C)!=None )
						{
							PlayerController(C).SetViewTarget(ViewingBoss);
							PlayerController(C).ClientSetViewTarget(ViewingBoss);
							PlayerController(C).bBehindView = True;
							PlayerController(C).ClientSetBehindView(True);
							PlayerController(C).ClientSetMusic(BossBattleSong,MTRAN_FastFade);
						}
						if ( C.PlayerReplicationInfo!=None && bRespawnOnBoss )
						{
							C.PlayerReplicationInfo.bOutOfLives = false;
							C.PlayerReplicationInfo.NumLives = 0;
							if ( (C.Pawn == None) && !C.PlayerReplicationInfo.bOnlySpectator && PlayerController(C)!=None )
								C.GotoState('PlayerWaiting');
						}
					}
				}
			}
			else if( ViewingBoss!=None && !ViewingBoss.bShotAnim )
			{
				ViewingBoss = None;
				for ( C = Level.ControllerList; C != None; C = C.NextController )
					if( PlayerController(C)!=None )
					{
						if( C.Pawn==None && !C.PlayerReplicationInfo.bOnlySpectator && bRespawnOnBoss )
							C.ServerReStartPlayer();
						if( C.Pawn!=None )
						{
							PlayerController(C).SetViewTarget(C.Pawn);
							PlayerController(C).ClientSetViewTarget(C.Pawn);
						}
						else
						{
							PlayerController(C).SetViewTarget(C);
							PlayerController(C).ClientSetViewTarget(C);
						}
						PlayerController(C).bBehindView = False;
						PlayerController(C).ClientSetBehindView(False);
					}
			}
			if( TotalMaxMonsters<=0 || (Level.TimeSeconds>WaveEndTime) )
			{
				// if everyone's spawned and they're all dead
				if ( NumMonsters <= 0 )
					DoWaveEnd();
			}
			else AddBoss();
		}
		else if(bWaveInProgress)
		{
			WaveTimeElapsed += 1.0;

			if( TraderProblemLevel<4 )
			{
				if( BootShopPlayers() )
					TraderProblemLevel = 0;
				else TraderProblemLevel++;
			}
			if(!MusicPlaying)
				StartGameMusic(True);

			if( TotalMaxMonsters<=0 )
			{
				if( KillPLMonstersTimer>0 )
					--KillPLMonstersTimer;
				if( bHasPlayerMonsters )
					HandleMonsterKill();
				if ( NumMonsters <= 5 /*|| Level.TimeSeconds>WaveEndTime*/ )
				{
					for ( C = Level.ControllerList; C != None; C = C.NextController )
						if ( KFMonsterController(C)!=None && !C.Pawn.PlayerCanSeeMe() )
						{
							C.Pawn.KilledBy( C.Pawn );
							Break;
						}
				}
				// if everyone's spawned and they're all dead
				if ( NumMonsters <= 0 )
				{
					DoWaveEnd();
				}
			} // all monsters spawned
			else if ( (Level.TimeSeconds > NextMonsterTime) && (NumMonsters+NextSpawnSquad.Length <= MaxMonsters) )
			{
				WaveEndTime = Level.TimeSeconds+160;
				AddSquad();

				if(nextSpawnSquad.length>0)
					NextMonsterTime = Level.TimeSeconds + 0.2;
				else NextMonsterTime = Level.TimeSeconds + CalcNextSquadSpawnTime();
  			}
		}
		else if ( NumMonsters <= 0 )
		{
			if ( WaveNum == FinalWave && !bUseEndGameBoss )
			{

				EndGame(None,"TimeLimit");
				return;
			}
			else if( WaveNum == (FinalWave + 1) && bUseEndGameBoss )
			{

				EndGame(None,"TimeLimit");
				return;
			}

			WaveCountDown--;
			if ( !CalmMusicPlaying )
			{
				StartGameMusic(False);
			}

			KFGameReplicationInfo(GameReplicationInfo).TimeToNextWave = WaveCountDown;
			if ( WaveCountDown == 5 )
			{
				KFGameReplicationInfo(Level.Game.GameReplicationInfo).MaxMonstersOn=false;
				InvasionGameReplicationInfo(GameReplicationInfo).WaveNumber = WaveNum;

				if( bFullVSMode )
				{
					for ( C = Level.ControllerList; C != None; C = C.NextController )
					{
						if ( VSPC(C)!=None && !VSPC(C).bSeenTeamHint )
						{
							VSPC(C).bSeenTeamHint = true;
							VSPC(C).ReceiveLocalizedMessage(class'VSInfoMessage',1);
						}
					}
				}
			}
			else if ( (WaveCountDown > 0) && (WaveCountDown < 5) )
			{
				if( WaveNum == FinalWave && bUseEndGameBoss )
				    BroadcastLocalizedMessage(class'KFMod.WaitingMessage', 3);
				else BroadcastLocalizedMessage(class'KFMod.WaitingMessage', 1);
			}
			else if ( WaveCountDown <= 1 )
			{
				bWaveInProgress = true;
				KFGameReplicationInfo(GameReplicationInfo).bWaveInProgress = true;

				if( WaveNum == FinalWave && bUseEndGameBoss )
				{
				    StartWaveBoss();
				}
				else
				{
					SetupWave();

					for ( C = Level.ControllerList; C != none; C = C.NextController )
					{
						if ( PlayerController(C) != none )
						{
							PlayerController(C).LastPlaySpeech = 0;
						}

						if ( Bot(C) != none )
						{
							B = Bot(C);
							InvasionBot(B).bDamagedMessage = false;
							B.bInitLifeMessage = false;

							if ( !bOneMessage && (FRand() < 0.65) )
							{
								bOneMessage = true;

								if ( (B.Squad.SquadLeader != None) && B.Squad.CloseToLeader(C.Pawn) )
								{
									B.SendMessage(B.Squad.SquadLeader.PlayerReplicationInfo, 'OTHER', B.GetMessageIndex('INPOSITION'), 20, 'TEAM');
									B.bInitLifeMessage = false;
								}
							}
						}
					}
			    }
		    }
		}
	}


	function float CalcNextSquadSpawnTime()
	{
		local float Res;
		local int OldCount;

		OldCount = NumPlayers;
		NumPlayers = Teams[0].Size;
		Res = Super.CalcNextSquadSpawnTime();
		NumPlayers = OldCount;
		return Res;
	}

	function DoWaveEnd()
	{
		local Controller C;
		local KFDoorMover KFDM;
		local PlayerController Survivor;
		local int SurvivorCount;

        // Only reset this at the end of wave 0. That way the sine wave that scales
        // the intensity up/down will be somewhat random per wave
        if( WaveNum < 1 )
        {
            WaveTimeElapsed = 0;
        }

		if ( !rewardFlag )
			RewardSurvivingPlayers();


		bWaveInProgress = false;
		bWaveBossInProgress = false;
		KFGameReplicationInfo(GameReplicationInfo).bWaveInProgress = false;

		WaveCountDown = Max(InitialCountDownValue,1);
		KFGameReplicationInfo(GameReplicationInfo).TimeToNextWave = WaveCountDown;
		WaveNum++;

		for ( C = Level.ControllerList; C != none; C = C.NextController )
		{
			if ( C.PlayerReplicationInfo != none )
			{
				if( C.PlayerReplicationInfo.Team!=Teams[0] && !bFullVSMode )
				{
					C.PlayerReplicationInfo.Team.RemoveFromTeam(C);
					C.PlayerReplicationInfo.Team = Teams[0];
					C.PlayerReplicationInfo.Team.AddToTeam(C);
				}
				C.PlayerReplicationInfo.bOutOfLives = false;
				C.PlayerReplicationInfo.NumLives = 0;

				if ( C.Pawn != none )
				{
					if ( PlayerController(C)!=none && C.PlayerReplicationInfo.Team==Teams[0] )
					{
						Survivor = PlayerController(C);
						SurvivorCount++;
					}
				}
				else if ( !C.PlayerReplicationInfo.bOnlySpectator && C.PlayerReplicationInfo.Team==Teams[0] )
				{
					C.PlayerReplicationInfo.Score = Max(MinRespawnCash,int(C.PlayerReplicationInfo.Score));

					if( PlayerController(C) != none )
					{
						PlayerController(C).GotoState('PlayerWaiting');
						PlayerController(C).SetViewTarget(C);
						PlayerController(C).ClientSetBehindView(false);
						PlayerController(C).bBehindView = False;
						PlayerController(C).ClientSetViewTarget(C.Pawn);
					}

					C.ServerReStartPlayer();
				}

			}
		}

		bUpdateViewTargs = True;

		//respawn doors
		foreach DynamicActors(class'KFDoorMover', KFDM)
			KFDM.RespawnDoor();
	}
}
state MatchOver
{
	function BeginState()
	{
		local Controller C;

		Super.BeginState();
		if( bFullVSMode )
			return;
		for( C=Level.ControllerList; C!=None; C=C.nextController )
		{
			if( C.PlayerReplicationInfo!=None && C.PlayerReplicationInfo.Team==Teams[1] ) // Fix teams so it doesn't show incorrectly winner.
			{
				C.PlayerReplicationInfo.Team = Teams[0];
				C.PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds-1;
			}
		}
	}
}

function SetupWave()
{
	local int OldNP,OldNB;

	KillPLMonstersTimer = MonsterKillTime+3;
	OldNP = NumPlayers;
	OldNB = NumBots;
	NumPlayers = Teams[0].Size;
	NumBots = 0;
	Super.SetupWave();
	NumPlayers = OldNP;
	NumBots = OldNB;
}

function SendPlayer( PlayerController aPlayer, string URL )
{
	if( bGameEnded || aPlayer==None || aPlayer.PlayerReplicationInfo==None )
		Return;
	Broadcast(Self,aPlayer.PlayerReplicationInfo.PlayerName@"has ended the level.");
	if( Left(URL,4)~="NULL" )
	{
		WaveNum = FinalWave+1;
		EndGame(None,"TimeLimit");
		Return;
	}
	Level.ServerTravel(URL,False);
	bGameEnded = True;
}

function NotifySpree(Controller Other, int num)
{
	if( Other.PlayerReplicationInfo!=None && Other.PlayerReplicationInfo.Team==Teams[1] )
		Super.NotifySpree(Other,num);
}
function EndSpree(Controller Killer, Controller Other)
{
	if( Other.PlayerReplicationInfo!=None && Other.PlayerReplicationInfo.Team==Teams[1] )
		Super.EndSpree(Killer,Other);
}

function bool NeedPlayers()
{
	if( !bFullVSMode )
		return Super.NeedPlayers();
	if ( Level.NetMode == NM_Standalone )
		return ( RemainingBots > 0 );
	if ( bMustJoinBeforeStart )
		return false;
	return (Teams[0].Size < MinPlayers);
}
function bool TooManyBots(Controller botToRemove)
{
	if( !bFullVSMode )
		return Super.TooManyBots(botToRemove);
	if ( bPlayerBecameActive )
	{
		bPlayerBecameActive = false;
		return true;
	}
	return ( (Level.NetMode != NM_Standalone) && (Teams[0].Size > MinPlayers) );
}

static function FillPlayInfo(PlayInfo PlayInfo)
{
	Super.FillPlayInfo(PlayInfo);

	PlayInfo.AddSetting(default.ServerGroup,"bFullVSMode","Full VS mode",1,1,"Check");
	PlayInfo.AddSetting(default.ServerGroup,"MinPlayers","Num Bots",0,1,"Text","6;1:32");
	PlayInfo.AddSetting(default.ServerGroup,"PlayersVSZedsRatio","Players V Zeds ratio",0,1,"Text","6;0.00:5.00");
}
static event string GetDescriptionText(string PropName)
{
	switch (PropName)
	{
		case "bFullVSMode":		return "Full versius mode, have 2 differnet player teams.";
		case "MinPlayers":		return "Number of bots that should fill out empty player slots.";
		case "PlayersVSZedsRatio":	return "The ratio allowed between specimen and player teams.";
	}
	return Super.GetDescriptionText(PropName);
}

function BroadcastDeathMessage(Controller Killer, Controller Other, class<DamageType> damageType)
{
	local PlayerReplicationInfo K,V;
	local class<Monster> M;
	local Controller C;

	if( Other==None || Other.PlayerReplicationInfo==None )
		return;
	if( Killer!=None && Killer!=Other )
	{
		K = Killer.PlayerReplicationInfo;
		if( Killer.Pawn!=None )
			M = class<Monster>(Killer.Pawn.Class);
	}
	V = Other.PlayerReplicationInfo;

	for( C=Level.ControllerList; C!=None; C=C.nextController )
		if( C.bIsPlayer && VSPC(C)!=None )
			VSPC(C).ClientDeathMessage(V,damageType,K,M);
}

defaultproperties
{
     bFullVSMode=True
     PossessablePawns(0)="AwesomeBloat"
     PossessablePawns(1)="AwesomeClot"
     PossessablePawns(2)="AwesomeCrawler"
     PossessablePawns(3)="AwesomeFleshPound"
     PossessablePawns(4)="AwesomeGoreFast"
     PossessablePawns(5)="AwesomeHusk"
     PossessablePawns(6)="AwesomeScrake"
     PossessablePawns(7)="AwesomeSiren"
     PossessablePawns(8)="AwesomeStalker"
     PlayersVSZedsRatio=1.000000
     MonsterKillTime=90
     bNoBots=False
     EndGameBossClass="KFMonsterVS.AwesomePat"
     bFirstBlood=True
     LoginMenuClass="KFMonsterVS.VSLoginMenu"
     HUDType="KFMonsterVS.VSHUD"
     MutatorClass="KFMonsterVS.VSBaseMut"
     PlayerControllerClass=Class'KFMonsterVS.VSPC'
     PlayerControllerClassName="KFMonsterVS.VSPC"
     GameName="Team VS KF"
}
