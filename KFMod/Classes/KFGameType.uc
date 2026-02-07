class KFGameType extends Invasion
	config;

#exec OBJ LOAD FILE=KillingFloorTextures.utx
#exec OBJ LOAD FILE=KillingFloorWeapons.utx
#exec OBJ LOAD FILE=KillingFloorManorTextures.utx
#exec OBJ LOAD FILE=KillingFloorManorTextures.utx
#exec OBJ LOAD FILE=KillingFloorHUD.utx
#exec OBJ LOAD FILE=KFX.utx
#exec OBJ LOAD FILE=KFMaterials.utx
#exec OBJ LOAD FILE=KillingFloorLabTextures.utx
#exec OBJ LOAD FILE=KillingFloorStatics.usx
#exec OBJ LOAD FILE=KillingFloorManorStatics.usx
#exec OBJ LOAD FILE=KillingFloorLabStatics.usx
#exec OBJ LOAD FILE=PatchStatics.usx
#exec OBJ LOAD FILE=KFWeaponModels.ukx

struct MClassTypes
{
	var() config string MClassName,MID;
};
var() globalconfig array<MClassTypes> MonsterClasses;
struct IMClassList
{
	var class<Monster> MClass;
	var string ID;
};
struct MSquadsList
{
	var array< class<Monster> > MSquad;
};
var array<MSquadsList> InitSquads;

var string HumanName[4];
var string ZombieName[4];
var int Time,LobbyTimeCounter;
var int ZombiesKilled;
var int TotalMaxMonsters;
var int SquadsToSpawn;
var bool rewardFlag;
var bool bUpdateViewTargs;
var KFMusicTrigger MapSongHandler;

var PlayerReplicationInfo KFPRIArray[16];

const MAX_BUYITEMS=50;

const KFPROPNUM = 8;
var localized string KFSurvivalPropText[KFPROPNUM];
var localized string KFSurvivalDescText[KFPROPNUM];

var() globalconfig float WaveStartSpawnPeriod;
var() globalconfig int StartingCash,MinRespawnCash;  // Cash amount Players start with to buy equipment
var() globalconfig bool bNoBots,bUseEndGameBoss;
var() globalconfig bool bNoLateJoiners;
var() globalconfig string EndGameBossClass,BossBattleSong;
var globalconfig string TmpWavesInf,TmpSquadsInf,TmpMClassInf;

var(LoadingHints) localized array<string> KFHints;

var() globalconfig array<string> MonsterSquad;

var array<int> SquadsToUse; // Pointers
var array < class<Monster> > NextSpawnSquad;
var array<ShopVolume> ShopList;
var vector lastSpawnLocation;

var byte TraderProblemLevel;
var bool bTradingDoorsOpen;

var class<AIController>ControllerClass;
var string ControllerClassName;

var float LastWaveStartTime;

var() globalconfig int LobbyTimeOut; // Number of Seconds after someone has gone to a Ready state that the game auto-begins.
var() globalconfig int InitialCountDownValue;  // Value (in seconds) for the base countdown.

var float StoredRadius, StoredHeight;

var bool MusicPlaying,CalmMusicPlaying;

var KFLevelRules KFLRules;

var bool bBotsAdded;

var config bool bEnemyHealthBars;

var ZombieVolume LastZVol;

var array<PlayerDeathMark> DeathMarkers; // For zombie eating.

var array<KFPlayerStats> ActiveStats;
var float LastStatsSaveTime;

var() globalconfig array<string> VeterancySkills,AvailableChars;
var array< Class<KFVeterancyTypes> > LoadedSkills;
var() globalconfig bool bPerksEnabled;
var() globalconfig int MaxZombiesOnce;

var bool bWaveBossInProgress,bHasSetViewYet;
var KFMonster ViewingBoss;

function bool BecomeSpectator(PlayerController P)
{
	if( P.PlayerReplicationInfo==None || P.PlayerReplicationInfo.bOnlySpectator )
		Return False; // Already are spectator.
	Return Super.BecomeSpectator(P);
}
function bool AllowBecomeActivePlayer(PlayerController P)
{
	if( P.PlayerReplicationInfo==None || !P.PlayerReplicationInfo.bOnlySpectator )
		Return False; // Already are active player.
	if ( !GameReplicationInfo.bMatchHasBegun || (NumPlayers >= MaxPlayers) || P.IsInState('GameEnded') || P.IsInState('RoundEnded') )
	{
		P.ReceiveLocalizedMessage(GameMessageClass, 13);
		return false;
	}
	if ( (Level.NetMode==NM_Standalone) && (NumBots>InitialBots) )
	{
		RemainingBots--;
		bPlayerBecameActive = true;
	}
	P.PlayerReplicationInfo.Score = StartingCash;
	return true;
}

function KFPlayerStats GenerateStats( string ID )
{
	local KFPlayerStats S;
	local int i;

	S = KFPlayerStats(FindObject("Package."$ID, class'KFPlayerStats'));
	if( S==None )
		S = New(None,ID) Class'KFPlayerStats';
	i = ActiveStats.Length;
	ActiveStats.Length = i+1;
	ActiveStats[i] = S;
	Return S;
}
function KFPlayerStats FindStats( string ID )
{
	local int i;

	For( i=0; i<ActiveStats.Length; i++ )
	{
		if( string(ActiveStats[i].Name)~=ID )
			Return ActiveStats[i];
	}
	Return None;
}
function SaveAllStats() // Ultimate lag function.
{
	local int i;

	if( LastStatsSaveTime>Level.TimeSeconds )
		Return;
	Log("Saving all stats...",'KFPlayerStats');
	LastStatsSaveTime = Level.TimeSeconds+100;
	For( i=0; i<ActiveStats.Length; i++ )
	{
		if( ActiveStats[i]==None )
		{
			ActiveStats.Remove(i,1);
			i--;
		}
		else ActiveStats[i].SaveConfig();
	}
}
function LoadUpMonsterList()
{
	local int i,j,q,c,n;
	local Class<Monster> MC;
	local string S,ID;
	local bool bInitSq;
	local array<IMClassList> InitMList;

	Log("Loading up monster classes...",'Init');
	for( i=0; i<MonsterClasses.Length; i++ )
	{
		if( MonsterClasses[i].MClassName=="" || MonsterClasses[i].MID=="" )
			Continue;
		MC = Class<Monster>(DynamicLoadObject(MonsterClasses[i].MClassName,Class'Class'));
		if( MC==None )
			Continue;
		InitMList.Length = j+1;
		InitMList[j].MClass = MC;
		InitMList[j].ID = MonsterClasses[i].MID;
		j++;
	}
	Log("Got"@j@"monsters. Loading up monster squads...",'Init');
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
					MC = InitMList[j].MClass;
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
	Log("Got"@c@"monster squads.",'Init');
	if( FallbackMonster==class'EliteKrall' && InitMList.Length>0 )
		FallbackMonster = InitMList[0].MClass;
}

event InitGame( string Options, out string Error )
{
	local int i,j;
	local KFLevelRules KFLRit;
	local ShopVolume SH;

	bTradingDoorsOpen = true;

	Super.InitGame(Options, Error);

	LoadUpMonsterList();

	foreach DynamicActors(class'KFLevelRules',KFLRit)
	{
		if(KFLRules==none)
			KFLRules = KFLRit;
		else Warn("MULTIPLE KFLEVELRULES FOUND!!!!!");
	}
	foreach AllActors(class'ShopVolume',SH)
		ShopList[ShopList.Length] = SH;

	//provide default rules if mapper did not need custom one
	if(KFLRules==none)
		KFLRules = spawn(class'KFLevelRules');

	log("KFLRules = "$KFLRules);

	For( i=0; i<VeterancySkills.Length; i++ )
	{
		if( VeterancySkills[i]=="" || VeterancySkills[i]~="None" )
			continue;
		LoadedSkills.Length = j+1;
		LoadedSkills[j] = Class<KFVeterancyTypes>(DynamicLoadObject(VeterancySkills[i],Class'Class'));
		if( LoadedSkills[j]==None )
			LoadedSkills.Length = j;
		else j++;
	}
	LoadUpMonsterList();
}

// For the GUI buy menu
simulated function float GetDifficulty()
{
	return GameDifficulty;
}

static function PrecacheGameTextures(LevelInfo myLevel)
{
	class'xTeamGame'.static.PrecacheGameTextures(myLevel);

	myLevel.AddPrecacheMaterial(Texture'KillingFloorWeapons.AxeTexture');
	myLevel.AddPrecacheMaterial(Texture'KillingFloorWeapons.AxeTexture3P');
	myLevel.AddPrecacheMaterial(Texture'KillingFloorWeapons.BatTex');
	myLevel.AddPrecacheMaterial(Texture'KillingFloorWeapons.ClawsSkin');
	myLevel.AddPrecacheMaterial(Texture'KillingFloorWeapons.ClawsSkin2');
	myLevel.AddPrecacheMaterial(Texture'KillingFloorWeapons.Deagle');
	myLevel.AddPrecacheMaterial(Texture'KillingFloorWeapons.Deagle3P');
	myLevel.AddPrecacheMaterial(Texture'KillingFloorWeapons.FragSkin');
	myLevel.AddPrecacheMaterial(Texture'KillingFloorWeapons.KnifeSkin');
	myLevel.AddPrecacheMaterial(Texture'KillingFloorWeapons.KnifeSkin3P');
	myLevel.AddPrecacheMaterial(Texture'KillingFloorWeapons.L85Cross');
	myLevel.AddPrecacheMaterial(Material'KillingFloorWeapons.LensFinal');
	myLevel.AddPrecacheMaterial(Texture'KillingFloorWeapons.CommandoCross');
	myLevel.AddPrecacheMaterial(Texture'KillingFloorWeapons.XbowSkin');
	myLevel.AddPrecacheMaterial(Texture'KillingFloorWeapons.XbowSkin3P');
	myLevel.AddPrecacheMaterial(Material'KillingFloorWeapons.XbowScopeFinal');

	//Other for better loads.....
	myLevel.AddPrecacheMaterial(Material'KFX.BrainSplash');
	myLevel.AddPrecacheMaterial(Material'KFX.BloodSplash');
	myLevel.AddPrecacheMaterial(Material'KillingFloorHud.Generic.HUD');
	myLevel.AddPrecacheMaterial(Material'KFMaterials.GlassChips');
	myLevel.AddPrecacheMaterial(Material'KFMaterials.PlantBits');
	myLevel.AddPrecacheMaterial(Material'KFMaterials.WoodChips');
}

static function PrecacheGameAnnouncements(AnnouncerVoice V, bool bRewardSounds)
{
	//TODO - sortage of this lot
	Super.PrecacheGameAnnouncements(V,bRewardSounds);
	if(!bRewardSounds)
	{
		V.PrecacheSound('HereTheyCome1');
		V.PrecacheSound('HereTheyCome2');
		V.PrecacheSound('HereTheyCome3');
	}
}

static function FillPlayInfo(PlayInfo PlayInfo)
{
	Super(Info).FillPlayInfo(PlayInfo);  // Always begin with calling parent

	PlayInfo.AddSetting(default.GameGroup,	"GameDifficulty",			GetDisplayText("GameDifficulty"),		0, 2, "Select", default.GIPropsExtras[0], "Xb");
	PlayInfo.AddSetting(default.GameGroup,"WaveStartSpawnPeriod", GetDisplayText("WaveStartSpawnPeriod"),50,0,"Text","3;0.0:6.0");
	PlayInfo.AddSetting(default.GameGroup,"StartingCash", GetDisplayText("StartingCash"),70,0,"Text","200;0:500");
	PlayInfo.AddSetting(default.GameGroup,"MinRespawnCash", "Min Respawn Cash amount",70,0,"Text","200;0:500");
//	PlayInfo.AddSetting(default.GameGroup,"bEnemyHealthBars", GetDisplayText("bEnemyHealthBars"),	80, 0, "Check");
PlayInfo.AddSetting(default.GameGroup,"InitialCountDownValue", GetDisplayText("InitialCountDownValue"),50,0,"Text","60;1:100");
	
	PlayInfo.AddSetting(default.RulesGroup,"bNoBots", GetDisplayText("bNoBots"),	1, 0, "Check",				,				,True,True);
	PlayInfo.AddSetting(default.RulesGroup,  "bAllowBehindView",		GetDisplayText("bAllowBehindview"),	1, 0, "Check",				,				,True,True);
	PlayInfo.AddSetting(default.RulesGroup,"bNoLateJoiners", GetDisplayText("bNoLateJoiners"),	1, 0, "Check",				,				,True,True);
	PlayInfo.AddSetting(default.RulesGroup, "MaxZombiesOnce","Max Specimens",0,1,"Text","4;6:600");
	PlayInfo.AddSetting(default.RulesGroup,"bPerksEnabled","Perks enabled",0,1,"Check");
	PlayInfo.AddSetting(default.RulesGroup,"bUseEndGameBoss","Use EndGame Boss",0,1,"Check");
	
	PlayInfo.AddSetting(default.ServerGroup, "LobbyTimeOut",			GetDisplayText("LobbyTimeOut"),			0, 1, "Text",		"3;0:120",				,True,True);
	PlayInfo.AddSetting(default.ServerGroup, "bEnableStatLogging",		GetDisplayText("bEnableStatLogging"),	0, 1, "Check",				,				,True);
	PlayInfo.AddSetting(default.ServerGroup, "bAdminCanPause",			GetDisplayText("bAdminCanPause"),		1, 1, "Check",				,				,True,True);
	PlayInfo.AddSetting(default.ServerGroup, "MaxSpectators",			GetDisplayText("MaxSpectators"),		1, 1, "Text",		"3;0:32",				,True,True);
	PlayInfo.AddSetting(default.ServerGroup, "MaxPlayers",				GetDisplayText("MaxPlayers"),			0, 1, "Text",		"3;0:32",				,True);
	PlayInfo.AddSetting(default.ServerGroup, "MaxIdleTime",			GetDisplayText("MaxIdleTime"),			0, 1, "Text",		"3;0:300",				,True,True);

	PlayInfo.AddSetting(default.GameGroup,"TmpWavesInf","Waves Config",60,0,"Custom",";;KFGui.KFInvWaveConfig",,,True);
	PlayInfo.AddSetting(default.GameGroup,"TmpSquadsInf","Squads Config",60,0,"Custom",";;KFGui.KFInvSquadConfig",,,True);
	PlayInfo.AddSetting(default.GameGroup,"TmpMClassInf","Monsters Config",60,0,"Custom",";;KFGui.KFInvClassConfig",,,True);

	// Bots
	PlayInfo.AddSetting(default.BotsGroup, "BotMode", default.MPGIPropsDisplayText[2], 30, 1, "Select", default.BotModeText);
	PlayInfo.AddSetting(default.BotsGroup, "MinPlayers", default.MPGIPropsDisplayText[0], 0, 0, "Text", "3;0:32");

	// Add GRI's PIData
	if (default.GameReplicationInfoClass != None)
	{
		default.GameReplicationInfoClass.static.FillPlayInfo(PlayInfo);
		PlayInfo.PopClass();
	}

	if (default.VoiceReplicationInfoClass != None)
	{
		default.VoiceReplicationInfoClass.static.FillPlayInfo(PlayInfo);
		PlayInfo.PopClass();
	}

	if (default.BroadcastClass != None)
		default.BroadcastClass.static.FillPlayInfo(PlayInfo);
	else class'BroadcastHandler'.static.FillPlayInfo(PlayInfo);

	PlayInfo.PopClass();

	if (class'Engine.GameInfo'.default.VotingHandlerClass != None)
	{
		class'Engine.GameInfo'.default.VotingHandlerClass.static.FillPlayInfo(PlayInfo);
		PlayInfo.PopClass();
	}
	else
		log("GameInfo::FillPlayInfo class'Engine.GameInfo'.default.VotingHandlerClass = None");
}

static event string GetDisplayText( string PropName )
{
	switch (PropName)
	{
		case "WaveStartSpawnPeriod":			return default.KFSurvivalPropText[0];
		case "StartingCash":				return default.KFSurvivalPropText[2];
		case "bNoBots":					return default.KFSurvivalPropText[3];
		case "bNoLateJoiners":				return default.KFSurvivalPropText[4];
		case "LobbyTimeOut":				return default.KFSurvivalPropText[5];
	//	case "bEnemyHealthBars":			return default.KFSurvivalPropText[6];
	       case "InitialCountDownValue":                    return default.KFSurvivalPropText[7];
	}
	return Super.GetDisplayText( PropName );
}

static event string GetDescriptionText(string PropName)
{
	switch (PropName)
	{
		case "WaveStartSpawnPeriod":			return default.KFSurvivalDescText[0];
		case "StartingCash":				return default.KFSurvivalDescText[2];
		case "bNoBots":					return default.KFSurvivalDescText[3];
		case "bNoLateJoiners":				return default.KFSurvivalDescText[4];
		case "LobbyTimeOut":				return default.KFSurvivalDescText[5];
		case "MaxZombiesOnce":				return "Maximum zombies at once on playtime, note that high values will LAG when theres a lot of them.";
		case "bPerksEnabled":				return "Have special player veterancy skills enabled.";
		case "InitialCountDownValue":			return default.KFSurvivalDescText[7];
		case "bUseEndGameBoss":				return "Spawn the final boss on end of final wave.";
		case "TmpWavesInf":					return "Configure the KF waves.";
		case "TmpSquadsInf":				return "Configure the monster squads to use on waves.";
		case "TmpMClassInf":				return "Configure the monster classes to be used in the squads.";
		case "EndGameBossClass":				return "The boss battle monster class.";
		case "MinRespawnCash":				return "Minimum amount of Cash when respawning on new wave (to stop people's reconnection needs).";
	}
	return Super.GetDescriptionText(PropName);
}

event PostNetBeginPlay()
{
	KFGameReplicationInfo(GameReplicationInfo).bNoBots = bNoBots;
	KFGameReplicationInfo(GameReplicationInfo).PendingBots = 0;
	KFGameReplicationInfo(GameReplicationInfo).GameDiff = GameDifficulty;
	KFGameReplicationInfo(GameReplicationInfo).bEnemyHealthBars = bEnemyHealthBars;
	KFGameReplicationInfo(GameReplicationInfo).bPerksEnabled = bPerksEnabled;
}

//TODO: Is this really the place?
function bool PickupQuery( Pawn Other, Pickup item )
{
	local Inventory i;
	local bool haveTheGun;

	haveTheGun=false;
	if(item.IsA('KFAmmoPickup'))
	{
		for(i=Other.Inventory;i != None;i = i.Inventory)
		{
			if( Weapon(i) == None )
				continue;
			if( Weapon(i).AmmoClass[0]==item.InventoryType || Weapon(i).AmmoClass[1]==item.InventoryType )
			{
				haveTheGun = true;
				break;
			}
		}
		if(!haveTheGun)
			return false;
	}
	return Super.PickupQuery(Other,item);
}

function AddMonster()
{
	local NavigationPoint StartSpot;
	local Pawn NewMonster;
	local class<Monster> NewMonsterClass;
	local int MonstersAdded;

	StartSpot = FindPlayerStart(None,1);
	if ( StartSpot == None )
		return;

	NewMonsterClass = WaveMonsterClass[Rand(WaveNumClasses)];
	MonstersAdded ++;
	NewMonster = Spawn(NewMonsterClass,,,StartSpot.Location+(NewMonsterClass.Default.CollisionHeight - StartSpot.CollisionHeight) * vect(0,0,1),StartSpot.Rotation);
	if ( NewMonster ==  None )
		NewMonster = Spawn(FallBackMonster,,,StartSpot.Location+(FallBackMonster.Default.CollisionHeight - StartSpot.CollisionHeight) * vect(0,0,1),StartSpot.Rotation);
	MonstersAdded ++;
	if ( NewMonster != None )
	{
		WaveMonsters++;
		NumMonsters++;
	}

	if (NewMonster != none && MonstersAdded < 3)
		Super.AddMonster();

	if (MonstersAdded >= 3)
		MonstersAdded = 0;
}

function bool CheckMaxLives(PlayerReplicationInfo Scorer)
{
	local Controller C;
	local PlayerController Living;
	local byte AliveCount;

	if ( MaxLives > 0 )
	{
		for ( C=Level.ControllerList; C!=None; C=C.NextController )
		{
			if ( (C.PlayerReplicationInfo != None) && C.bIsPlayer && !C.PlayerReplicationInfo.bOutOfLives && !C.PlayerReplicationInfo.bOnlySpectator )
			{
				AliveCount++;
				if( Living==None )
					Living = PlayerController(C);
			}
		}
		if ( AliveCount==0 )
		{
			EndGame(Scorer,"LastMan");
			return true;
		}
		else if( AliveCount==1 && Living!=None )
			Living.ReceiveLocalizedMessage(Class'KFLastManStandingMsg');
	}
	return false;
}

function ScoreKill(Controller Killer, Controller Other)
{
	local PlayerReplicationInfo OtherPRI;
	local float KillScore;

	OtherPRI = Other.PlayerReplicationInfo;
	if ( OtherPRI != None )
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
			BroadcastLocalizedMessage(class'KFInvasionMessage',1,OtherPRI,Killer.PlayerReplicationInfo);
		else if( Killer==None || Monster(Killer.Pawn)==None )
			BroadcastLocalizedMessage(class'KFInvasionMessage',1,OtherPRI);
		else BroadcastLocalizedMessage(class'KFInvasionMessage',1,OtherPRI,,Killer.Pawn.Class);
		CheckScore(None);
	}

	if ( GameRulesModifiers != None )
		GameRulesModifiers.ScoreKill(Killer, Other);

	if ( MonsterController(Killer) != None )
		return;

	if( (killer == Other) || (killer == None) )
	{
		if ( Other.PlayerReplicationInfo != None )
		{
			Other.PlayerReplicationInfo.Score -= 1;
			Other.PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;
			ScoreEvent(Other.PlayerReplicationInfo,-1,"self_frag");
		}
	}

	if ( Killer==None || !Killer.bIsPlayer || (Killer==Other) )
		return;

	if ( Other.bIsPlayer )
	{
		Killer.PlayerReplicationInfo.Score -= 5;
		Killer.PlayerReplicationInfo.Team.Score -= 2;
		Killer.PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;
		Killer.PlayerReplicationInfo.Team.NetUpdateTime = Level.TimeSeconds - 1;
		ScoreEvent(Killer.PlayerReplicationInfo, -5, "team_frag");
		return;
	}
	if ( LastKilledMonsterClass == None )
		KillScore = 1;
	else if(Killer.PlayerReplicationInfo !=none)
	{
		KillScore = (LastKilledMonsterClass.Default.ScoringValue * 5 + Rand(LastKilledMonsterClass.Default.ScoringValue * 2));
		KillScore*=Clamp((GameDifficulty-1)/5.f+1,0.5,3);
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

function SetupWaveBot(Inventory BotsInv);

/* Spawn and initialize a bot
*/
function Bot SpawnBot(optional string botName)
{
	local KFInvasionBot NewBot;
	local RosterEntry Chosen;
	local UnrealTeamInfo BotTeam;

	BotTeam = GetBotTeam();
	Chosen = BotTeam.ChooseBotClass(botName);

	if (Chosen.PawnClass == None)
		Chosen.Init(); //amb
	NewBot = Spawn(class 'KFInvasionBot');

	if ( NewBot != None )
		InitializeBot(NewBot,BotTeam,Chosen);

	// Decide if bot should be a veteran.
	if( bPerksEnabled && LoadedSkills.Length>0 && FRand()<0.35 && KFPlayerReplicationInfo(NewBot.PlayerReplicationInfo)!=None )
		KFPlayerReplicationInfo(NewBot.PlayerReplicationInfo).ClientVeteranSkill = LoadedSkills[Rand(LoadedSkills.Length)];
	NewBot.PlayerReplicationInfo.Score = StartingCash;

	return NewBot;
}

 
function InitializeBot(Bot NewBot, UnrealTeamInfo BotTeam, RosterEntry Chosen)
{   
	local string S;

	NewBot.InitializeSkill(AdjustedDifficulty);
	Chosen.InitBot(NewBot);
	BotTeam.AddToTeam(NewBot);
	if ( Chosen.ModifiedPlayerName != "" )
		ChangeName(NewBot, Chosen.ModifiedPlayerName, false);
	else ChangeName(NewBot, Chosen.PlayerName, false);
	BotTeam.SetBotOrders(NewBot,Chosen);

	S = Class'KFGameType'.Static.GetValidCharacter("");
	NewBot.PlayerReplicationInfo.SetCharacterName(S);
	xBot(NewBot).PawnSetupRecord = class'xUtil'.static.FindPlayerRecord(S);
}
 
function OverrideInitialBots();

function ReplenishWeapons(Pawn P);

// Play The Warning Sound at the Beginning of the Match
function WarningTimer()
{
	if( Level.TimeSeconds >= Time &&  bWaveInProgress )
		Time += 90;
}

function bool RewardSurvivingPlayers()
{
	local Controller C;
	local int moneyPerPlayer,div;
	local TeamInfo T;

	C=Level.ControllerList;

	for ( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		if ( C.Pawn!=None && C.PlayerReplicationInfo!=None && C.PlayerReplicationInfo.Team!=None )
		{
			T = C.PlayerReplicationInfo.Team;
			div++;
		}
	}
	if ( T==None || T.Score<=0 )
		Return False;

	moneyPerPlayer = int(T.Score / float(div));

	for ( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		if ( C.Pawn!=None && C.PlayerReplicationInfo!=None && C.PlayerReplicationInfo.Team!=None )
		{
			if( div==1 )
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
			if( T.Score<=0 )
			{
				T.Score = 0;
				Break;
			}
		}
	}
	T.NetUpdateTime = Level.TimeSeconds - 1;
	return true;
}

function Timer()
{
	local int i;

	Super.Timer();
	WarningTimer();
	For( i=0; i<ActiveStats.Length; i++ )
	{
		if( ActiveStats[i].CurrentOwner!=None && ActiveStats[i].CurrentOwner.PlayerReplicationInfo!=None
		 && !ActiveStats[i].CurrentOwner.PlayerReplicationInfo.bOnlySpectator )
			ActiveStats[i].TotalPlaytime++;
	}
}

function StartGameMusic( bool bCombat )
{
	local Controller C;
	local string S;

	if( MapSongHandler==None )
		Return;
	if( bCombat )
	{
		if( MapSongHandler.WaveBasedSongs.Length<=WaveNum || MapSongHandler.WaveBasedSongs[WaveNum].CombatSong=="" )
			S = MapSongHandler.CombatSong;
		else S = MapSongHandler.WaveBasedSongs[WaveNum].CombatSong;
		MusicPlaying = True;
		CalmMusicPlaying = False;
	}
	else
	{
		if( MapSongHandler.WaveBasedSongs.Length<=WaveNum || MapSongHandler.WaveBasedSongs[WaveNum].CalmSong=="" )
			S = MapSongHandler.Song;
		else S = MapSongHandler.WaveBasedSongs[WaveNum].CalmSong;
		CalmMusicPlaying = True;
		MusicPlaying = False;
	}

	for( C=Level.ControllerList;C!=None;C=C.NextController )
	{
		if (KFPlayerController(C)!= none)
			KFPlayerController(C).NetPlayMusic(S, MapSongHandler.FadeInTime,MapSongHandler.FadeOutTime);
	}
}
function StartInitGameMusic( KFPlayerController Other )
{
	local string S;

	if( MapSongHandler==None )
		Return;
	if( MusicPlaying )
	{
		if( MapSongHandler.WaveBasedSongs.Length<=WaveNum || MapSongHandler.WaveBasedSongs[WaveNum].CombatSong=="" )
			S = MapSongHandler.CombatSong;
		else S = MapSongHandler.WaveBasedSongs[WaveNum].CombatSong;
	}
	else if( CalmMusicPlaying )
	{
		if( MapSongHandler.WaveBasedSongs.Length<=WaveNum || MapSongHandler.WaveBasedSongs[WaveNum].CalmSong=="" )
			S = MapSongHandler.Song;
		else S = MapSongHandler.WaveBasedSongs[WaveNum].CalmSong;
	}
	if( S!="" )
		Other.NetPlayMusic(S,0.5,0);
}

function StopGameMusic()
{
	local Controller C;
	local float FdT;

	if( MapSongHandler!=None )
		FdT = MapSongHandler.FadeOutTime;
	else FdT = 1;

	for( C=Level.ControllerList;C!=None;C=C.NextController )
	{
		if (KFPlayerController(C)!= none)
			KFPlayerController(C).NetStopMusic(FdT);
	}
	MusicPlaying = False;
	CalmMusicPlaying = False;
}

exec function AddBots(int num)
{
	num = Clamp(num, 0, MaxPlayers - (NumPlayers + NumBots));

	while (--num >= 0)
	{
		if ( Level.NetMode != NM_Standalone )
			MinPlayers = Max(MinPlayers + 1, NumPlayers + NumBots + 1);
		AddBot();
	}
}

// lazy Cut n' paste to allow maximum tweakage without worrying
// about the effects of underlying classes
function bool AddBot(optional string botName)
{
	local Bot NewBot;

	if (bNoBots)
		return false;

	NewBot = SpawnBot(botName);

	if ( NewBot == None )
	{
		warn("Failed to spawn bot.");
		return false;
	}

	NewBot.PlayerReplicationInfo.PlayerID = CurrentID++;
	NumBots++;
	if ( Level.NetMode == NM_Standalone )
		RestartPlayer(NewBot);
	else
		NewBot.GotoState('Dead','MPStart');
	return true;
}

auto State PendingMatch
{
	function RestartPlayer( Controller aPlayer )
	{
		if ( CountDown <= 0 )
			RestartPlayer(aPlayer);
	}
	function Timer()
	{
		local Controller P;
		local bool bReady;
		local int RdyCount;

		Global.Timer();

		// first check if there are enough net players, and enough time has elapsed to give people
		// a chance to join
		if ( NumPlayers == 0 )
			bWaitForNetPlayers = true;

		if ( bWaitForNetPlayers && (Level.NetMode != NM_Standalone) )
		{
			if ( NumPlayers >= MinNetPlayers )
				ElapsedTime++;
			else ElapsedTime = 0;
			if ( (NumPlayers == MaxPlayers) || (ElapsedTime > NetWait) )
				bWaitForNetPlayers = false;
		}

		if ( (Level.NetMode != NM_Standalone) && (bWaitForNetPlayers || (bTournament && (NumPlayers < MaxPlayers))) )
		{
			PlayStartupMessage();
			return;
		}

		// check if players are ready
		bReady = true;
		StartupStage = 1;

		for (P=Level.ControllerList; P!=None; P=P.NextController )
		{
			if(P.IsA('PlayerController') && (P.PlayerReplicationInfo != None)
				&& P.bIsPlayer && P.PlayerReplicationInfo.bWaitingPlayer)
			{
				if(!P.PlayerReplicationInfo.bReadyToPlay )
					bReady = false;
				else RdyCount++;
			}
		}

		if ( bReady && !bReviewingJumpspots )
			StartMatch();
		PlayStartupMessage();
		if( NumPlayers>2 )
			ElapsedTime++;
		if( (RdyCount>=(NumPlayers*0.65) || ElapsedTime>300) && NumPlayers>2 && LobbyTimeout>0 )
		{
			if( LobbyTimeout<=1 )
			{
				for (P=Level.ControllerList; P!=None; P=P.NextController )
				{
					if( P.PlayerReplicationInfo!=None )
						P.PlayerReplicationInfo.bReadyToPlay = True;
				}
				LobbyTimeout = 0;
			}
			else LobbyTimeout--;
			KFGameReplicationInfo(GameReplicationInfo).LobbyTimeout = LobbyTimeout;
		}
		else KFGameReplicationInfo(GameReplicationInfo).LobbyTimeout = -1;
	}
	function beginstate()
	{
		bWaitingToStartMatch = true;
		StartupStage = 0;
		if( LobbyTimeout<=0 )
			LobbyTimeCounter = 10;
		else LobbyTimeCounter = LobbyTimeout;
		NetWait = Max(NetWait,0);
	}
	function EndState()
	{
		KFGameReplicationInfo(GameReplicationInfo).LobbyTimeout = -1;
	}

Begin:
	if ( bQuickStart )
		StartMatch();
}

State MatchInProgress
{
      function bool UpdateMonsterCount() // To avoid invasion errors.
	{ 
          local Controller C; 
          local int i,j; 
 
          For( C=Level.ControllerList; C!=None; C=C.NextController ) 
          { 
               if( C.Pawn!=None && C.Pawn.Health>0 ) 
               { 
                    if( KFMonsterController(C) !=None )
                         i++; 
                    else j++; 
               } 
          } 
          NumMonsters = i; 
          Return (j>0); 
	}
	function bool BootShopPlayers()
	{
		local int i,j;
		local bool bRes;

		j = ShopList.Length;
		for( i=0; i<j; i++ )
		{
			if( ShopList[i].BootPlayers() )
				bRes = True;
		}
		Return bRes;
	}
	function Timer()
	{
		local Controller C; //,OtherPlayer;
		local bool bOneMessage;
		local Bot B;
		local KFTraderDoor TDoor;
 
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
			// Close Trader doors
			if (bTradingDoorsOpen)
			{
				foreach DynamicActors(class'KFTraderDoor',TDoor)
					TDoor.TriggerEvent(TDoor.Tag, TDoor, None);
				bTradingDoorsOpen = False;
				TraderProblemLevel = 0;
			}
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
						if( PlayerController(C)!=None )
						{
							PlayerController(C).SetViewTarget(ViewingBoss);
							PlayerController(C).ClientSetViewTarget(ViewingBoss);
							PlayerController(C).bBehindView = True;
							PlayerController(C).ClientSetBehindView(True);
							PlayerController(C).ClientSetMusic(BossBattleSong,MTRAN_FastFade);
						}
				}
			}
			else if( ViewingBoss!=None && !ViewingBoss.bShotAnim )
			{
				ViewingBoss = None;
				for ( C = Level.ControllerList; C != None; C = C.NextController )
					if( PlayerController(C)!=None )
					{
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
			// Close Trader doors
			if (bTradingDoorsOpen)
			{
				foreach DynamicActors(class'KFTraderDoor',TDoor)
					TDoor.TriggerEvent(TDoor.Tag, TDoor, None);
				bTradingDoorsOpen = False;
				TraderProblemLevel = 0;
			}
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
				if ( Level.TimeSeconds>WaveEndTime )
				{
					for ( C = Level.ControllerList; C != None; C = C.NextController )
						if ( (MonsterController(C)!=None) && !C.Pawn.PlayerCanSeeMe() )
						{
							C.Pawn.KilledBy( C.Pawn );
							Break;
						}
				}
				// if everyone's spawned and they're all dead
				if ( NumMonsters <= 0 )
				{
					if( bUseEndGameBoss && WaveNum==(FinalWave-1) )
						StartWaveBoss();
					else DoWaveEnd();
				}
			} // all monsters spawned
			else if ( (Level.TimeSeconds > NextMonsterTime) && (NumMonsters+NextSpawnSquad.Length <= MaxMonsters) )
			{
				WaveEndTime = Level.TimeSeconds+60;
				AddSquad();
				if(nextSpawnSquad.length>0)
					NextMonsterTime = Level.TimeSeconds + 0.2;  // 3
				else NextMonsterTime = Level.TimeSeconds + KFLRules.WaveSpawnPeriod;
  			}
		}
		else if ( NumMonsters <=0 )
		{
			if ( WaveNum == FinalWave )
			{
				EndGame(None,"TimeLimit");
				return;
			}
			WaveCountDown--;
			if (!CalmMusicPlaying)
				StartGameMusic(False);
			KFGameReplicationInfo(GameReplicationInfo).TimeToNextWave = WaveCountDown;
			if ( WaveCountDown == 6 )
			{
				// Currently, Do nothing
			}
			if ( WaveCountDown == 5 )
			{
				KFGameReplicationInfo(Level.Game.GameReplicationInfo).MaxMonstersOn=false;
				InvasionGameReplicationInfo(GameReplicationInfo).WaveNumber = WaveNum;
			}
			else if ( (WaveCountDown > 0) && (WaveCountDown < 5) )
				BroadcastLocalizedMessage(class'KFMod.WaitingMessage', WaveCountDown-1);
			else if ( WaveCountDown <= 1 )
			{
				bWaveInProgress = true;
				KFGameReplicationInfo(GameReplicationInfo).bWaveInProgress = true;
				SetupWave();
				for ( C = Level.ControllerList; C != None; C = C.NextController )
					if ( PlayerController(C) != None )
						PlayerController(C).LastPlaySpeech = 0;

				for ( C = Level.ControllerList; C != None; C = C.NextController )
					if ( Bot(C) != None )
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

	function DoWaveEnd()
	{
		local Controller C;
		local KFTraderDoor TDoor;
		local KFDoorMover KFDM;

		SaveAllStats();

		if(!rewardFlag)
			RewardSurvivingPlayers();

		bWaveInProgress = False;
		bWaveBossInProgress = False;
		KFGameReplicationInfo(GameReplicationInfo).bWaveInProgress = false;

		WaveCountDown = Max(InitialCountDownValue,1);
		KFGameReplicationInfo(GameReplicationInfo).TimeToNextWave = WaveCountDown;
		WaveNum++;

		// Open Trader doors
		if (!bTradingDoorsOpen)
		{
			foreach DynamicActors(class'KFTraderDoor',TDoor)
				TDoor.TriggerEvent(TDoor.Tag, TDoor, None);

			bTradingDoorsOpen = true;
		}

		for ( C = Level.ControllerList; C != None; C = C.NextController )
		{
			if ( PlayerController(C) != None )
			{
				if ( (C.Pawn == None) && !C.PlayerReplicationInfo.bOnlySpectator )
					PlayerController(C).SetViewTarget(C);
			}
			if ( C.PlayerReplicationInfo != None )
			{
				C.PlayerReplicationInfo.bOutOfLives = false;
				C.PlayerReplicationInfo.NumLives = 0;
				if ( (C.Pawn == None) && !C.PlayerReplicationInfo.bOnlySpectator )
				{
					C.PlayerReplicationInfo.Score = Max(MinRespawnCash,int(C.PlayerReplicationInfo.Score));
					if( (PlayerController(C) != None) )
					{
						PlayerController(C).GotoState('PlayerWaiting');
						PlayerController(C).SetViewTarget(C);
						PlayerController(C).ClientSetBehindView(false);
						PlayerController(C).bBehindView = False;
					}
					C.ServerReStartPlayer();
					if( (PlayerController(C) != None) )
						PlayerController(C).ClientSetViewTarget(C.Pawn);
				}
			}
		}
		bUpdateViewTargs = True;

		//respawn doors
		foreach DynamicActors(class'KFDoorMover', KFDM)
			KFDM.RespawnDoor();
	}
	function StartWaveBoss()
	{
		bHasSetViewYet = False;
		WaveEndTime = Level.TimeSeconds+60;
		NextSpawnSquad.Length = 1;
		NextSpawnSquad[0] = Class<Monster>(DynamicLoadObject(EndGameBossClass,Class'Class'));
		if( NextSpawnSquad[0]==None )
			NextSpawnSquad[0] = FallbackMonster;
		KFGameReplicationInfo(Level.Game.GameReplicationInfo).MaxMonsters = 1;
		TotalMaxMonsters = 1;
		bWaveBossInProgress = True;
	}
	function UpdateViews() // To fix camera stuck on ur spec target
	{
		local Controller C;

		bUpdateViewTargs = False;
		for ( C = Level.ControllerList; C != None; C = C.NextController )
		{
			if ( PlayerController(C) != None && C.Pawn!=None )
				PlayerController(C).ClientSetViewTarget(C.Pawn);
		}
	}

	function BeginState()
	{
		Super.BeginState();
		WaveNum = InitialWave;
		InvasionGameReplicationInfo(GameReplicationInfo).WaveNumber = WaveNum;
		WaveCountDown = Max(InitialCountDownValue,1);
	}
}

State MatchOver
{
	function BeginState()
	{
		Super.BeginState();
		LastStatsSaveTime = 0; // Force all stats to be saved on end-game.
		SaveAllStats();
	}
}

static function array<string> GetAllLoadHints(optional bool bThisClassOnly)
{
	return default.KFHints;
}
function PlayStartupMessage()
{
}

//This is kinda messy, but we need to get rid of those damned blue
//messages.
event PostLogin( PlayerController NewPlayer )
{
	local KFPlayerController PC;

	NewPlayer.SetGRI(GameReplicationInfo);
	NewPlayer.PlayerReplicationInfo.PlayerID = CurrentID++;

	Super.PostLogin(NewPlayer);

	if (UnrealPlayer(NewPlayer) != None)
		UnrealPlayer(NewPlayer).ClientReceiveLoginMenu(LoginMenuClass, bAlwaysShowLoginMenu);
	if ( NewPlayer.PlayerReplicationInfo.Team != None )
		GameEvent("TeamChange",""$NewPlayer.PlayerReplicationInfo.Team.TeamIndex,NewPlayer.PlayerReplicationInfo);

	if( KFPlayerController(NewPlayer)!=None )
		KFPlayerController(NewPlayer).ShowLobbyMenu();
	else NewPlayer.GotoState('PlayerWaiting');

	if( KFPlayerController(NewPlayer)!=None )
		StartInitGameMusic(KFPlayerController(NewPlayer));

	PC = KFPlayerController(NewPlayer);
	if( PC!=None && PC.MyActiveStats==None )
		PC.FindStatsObject();
}

function Killed( Controller Killer, Controller Killed, Pawn KilledPawn, class<DamageType> damageType )
{
	local KFPlayerController PC;

	if( KFMonster(KilledPawn)!=None && 
        Class<KFWeaponDamageType>(damageType)!=None &&
         KFPlayerController(Killer)!=None  )
	{
		PC = KFPlayerController(Killer);
		if( PC!=None && (PC.MyActiveStats!=None || PC.FindStatsObject()) )
			Class<KFWeaponDamageType>(damageType).Static.AwardKill(PC.MyActiveStats,KFMonster(KilledPawn).bDecapitated,KilledPawn.IsA('ZombieStalker'));
	}
	if ( (MonsterController(Killed) != None) || (Monster(KilledPawn) != None) )
	{
		ZombiesKilled++;
		KFGameReplicationInfo(Level.Game.GameReplicationInfo).MaxMonsters = TotalMaxMonsters+NumMonsters-1;
		if( KFGameReplicationInfo(Level.Game.GameReplicationInfo).MaxMonsters<0 )
			KFGameReplicationInfo(Level.Game.GameReplicationInfo).MaxMonsters = 0;
	}
	Super.Killed(Killer,Killed,KilledPawn,DamageType);
}

function SetupWave()
{
	local int i,j;
	local float NewMaxMonsters;

	if ( WaveNum > 15 )
	{
		SetupRandomWave();
		return;
	}

	TraderProblemLevel = 0;
	rewardFlag=false;
	ZombiesKilled=0;
	WaveMonsters = 0;
	WaveNumClasses = 0;
	NewMaxMonsters = Waves[WaveNum].WaveMaxMonsters;
	if ( NumPlayers + NumBots <= 2 )
		NewMaxMonsters = NewMaxMonsters * (FMin(GameDifficulty,7) + 3)/10;
	if ( NumPlayers > 4 )
		NewMaxMonsters *= FClamp((NumPlayers+NumBots)/3,2,50);

	MaxMonsters = NewMaxMonsters;

	//Lets add a random amount around the MaxMonsters
	TotalMaxMonsters = Clamp(2*MaxMonsters - 5 + FRand()* (GameDifficulty * 3),5,600);  //11, MAX 600, MIN 5
	MaxMonsters = Clamp(MaxMonsters,5,MaxZombiesOnce);

	KFGameReplicationInfo(Level.Game.GameReplicationInfo).MaxMonsters=TotalMaxMonsters;
	KFGameReplicationInfo(Level.Game.GameReplicationInfo).MaxMonstersOn=true;
	WaveEndTime = Level.TimeSeconds + Waves[WaveNum].WaveDuration;
	AdjustedDifficulty = GameDifficulty + Waves[WaveNum].WaveDifficulty;

	j = 1;
	SquadsToUse.Length = 0;

	for ( i=0; i<InitSquads.Length; i++ )
	{
		if ( (j & Waves[WaveNum].WaveMask) != 0 )
		{
			SquadsToUse.Insert(0,1);
			SquadsToUse[0] = i;
		}
		j *= 2;
	}

	//Now build the first squad to use
	BuildNextSquad();
}

function BuildNextSquad()
{
	local int i;

	if( SquadsToUse.Length==0 )
	{
		Warn("No squads to initilize with.");
		Return;
	}
	i = Rand(SquadsToUse.Length);
	NextSpawnSquad = InitSquads[SquadsToUse[i]].MSquad;
}

function bool AddSquad()
{
	local int numspawned;
	local int WaveMonsterCount;

	if(LastZVol==none || NextSpawnSquad.length==0)
	{
		BuildNextSquad();
		LastZVol = FindSpawningVolume();
		if(LastZVol!=None)
			lastSpawnLocation = LastZVol.location;
	}

	if(LastZVol == None)
		return false;

	LastZVol.SpawnInHere(NextSpawnSquad,0,,,,,numspawned,TotalMaxMonsters,WaveMonsterCount);
	NumMonsters += numspawned; //NextSpawnSquad.Length;
	WaveMonsters+= numspawned; //NextSpawnSquad.Length;

	NextSpawnSquad.Remove(0, numSpawned);

	return true;
}
function bool AddBoss()
{
	local int numspawned;
	local int WaveMonsterCount;

	if( LastZVol==none )
	{
		LastZVol = FindSpawningVolume();
		if(LastZVol!=None)
			lastSpawnLocation = LastZVol.location;
	}
	if(LastZVol == None)
		return false;

	LastZVol.SpawnInHere(NextSpawnSquad,0,,,,,numspawned,TotalMaxMonsters,WaveMonsterCount);
	NumMonsters+=numspawned;
	WaveMonsters+=numspawned;

	return true;
}

function ZombieVolume FindSpawningVolume()
{
	local ZombieVolume z,BestZ;
	local float BestScore,tScore;
	BestScore = -1;

	ForEach AllActors(class'ZombieVolume',z)
	{
		tScore = RateZombieVolume(z);
		if(tScore > BestScore)
		{
			BestScore=tScore;
			BestZ = z;
		}
	}
	return BestZ;
}

function float RateZombieVolume(ZombieVolume z)
{
	local Controller OtherPlayer;
	local float Score;
	local float dist;

	if ( z.PhysicsVolume.bWaterVolume )
		return -10000000;
	else if( !z.CanSpawnInHere(NextSpawnSquad) )
		return -100;

	Score = 10000000;

	Score += 5000 * FRand(); //randomize

	if(LastSpawnLocation == z.Location)
		return -1;

	// Make points far from the last one better choices
	Score += Min(VSize(LastSpawnLocation-z.Location),1500);

	for ( OtherPlayer=Level.ControllerList; OtherPlayer!=None; OtherPlayer=OtherPlayer.NextController)
	{
		if (OtherPlayer.pawn != none)
		{
			dist = VSize(z.Location - OtherPlayer.Pawn.Location);
			Score += 2000*abs(((LastSpawnLocation - OtherPlayer.Pawn.Location) dot vector(OtherPlayer.Pawn.Rotation)) - ((z.Location - OtherPlayer.Pawn.Location) dot vector(OtherPlayer.Pawn.Rotation)));

			// if fog doesn't hide spawn && lineofsight possible
			if( (!OtherPlayer.Region.Zone.bDistanceFog || (dist < OtherPlayer.Region.Zone.DistanceFogEnd)) && FastTrace(z.Location,OtherPlayer.Pawn.Location) )
				return -100;
			else if(dist < 400)
				return -50;

 			if(VSize(z.Location-OtherPlayer.Pawn.Location) < 8000)
				Score += (8000-VSize(z.Location-OtherPlayer.Pawn.Location))*2;
		}
	}
	// if we get here, return at least a 5
	return FMax(Score,5);
}


function int ReduceDamage( int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType )
{ 
	local float InstigatorSkill; 
	local KFPlayerController PC;

	if( KFPawn(instigatedBy)!=None && KFMonster(Injured)!=None ) 
		Damage = KFPawn(instigatedBy).GetVeteran().Static.AddDamage(KFMonster(Injured),KFPawn(instigatedBy),Damage,DamageType); 
	else if( KFPawn(Injured)!=None && KFMonster(instigatedBy)!=None ) 
		Damage = KFPawn(Injured).GetVeteran().Static.ReduceDamage(KFPawn(Injured),KFMonster(instigatedBy),Damage,DamageType); 

	// This stuff cuts thru all the B.S
	if(DamageType==class'DamTypeVomit' || DamageType==class'DamTypeWelder' || DamageType==class'SirenScreamDamage' )
		return damage; 
 
	if ( instigatedBy == None ) 
		return Super(xTeamGame).ReduceDamage( Damage,injured,instigatedBy,HitLocation,Momentum,DamageType ); 
 
	if ( Monster(Injured) != None ) 
	{
		if( instigatedBy!=None ) 
		{ 
			PC = KFPlayerController(instigatedBy.Controller); 
			if( Class<KFWeaponDamageType>(damageType)!=None && PC!=None && (PC.MyActiveStats!=None || PC.FindStatsObject()) ) 
				Class<KFWeaponDamageType>(damageType).Static.AwardDamage(PC.MyActiveStats,Clamp(Damage,1,Injured.Health)); 
		} 
		return Damage;
	}

	if ( MonsterController(InstigatedBy.Controller) != None )
	{ 
		InstigatorSkill = MonsterController(instigatedBy.Controller).Skill; 
		if ( NumPlayers > 4 ) 
			InstigatorSkill += 1.0; 
		if ( (InstigatorSkill < 7) && (Monster(Injured) == None) ) 
		{ 
			if ( InstigatorSkill <= 3 ) 
				Damage = Damage; 
			else Damage = Damage; 
		} 
	}
	else if ( KFFriendlyAI(InstigatedBy.Controller) != None && KFHumanPawn(Injured) != none  )
		Damage *= 0.25;
	else if ( injured == instigatedBy )
		Damage = Damage * 0.5;
          
          
	if ( InvasionBot(injured.Controller) != None )
	{ 
		if ( !InvasionBot(injured.controller).bDamagedMessage && (injured.Health - Damage < 50) ) 
		{ 
			InvasionBot(injured.controller).bDamagedMessage = true; 
			if ( FRand() < 0.5 ) 
				injured.Controller.SendMessage(None, 'OTHER', 4, 12, 'TEAM'); 
			else injured.Controller.SendMessage(None, 'OTHER', 13, 12, 'TEAM'); 
		} 
		if ( GameDifficulty <= 3 ) 
		{ 
			if ( injured.IsPlayerPawn() && (injured == instigatedby) && (Level.NetMode == NM_Standalone) ) 
				Damage *= 0.5; 
 
			//skill level modification 
			if ( MonsterController(InstigatedBy.Controller) != None ) 
				Damage = Damage; 
		} 
	}
     
	if( injured.InGodMode() )
		return 0;
	if( instigatedBy!=injured && MonsterController(InstigatedBy.Controller)==None && (instigatedBy.Controller==None || instigatedBy.GetTeamNum()==injured.GetTeamNum()) )
	{
		if ( class<WeaponDamageType>(DamageType) != None || class<VehicleDamageType>(DamageType) != None )
			Momentum *= TeammateBoost;
		if ( Bot(injured.Controller) != None )
			Bot(Injured.Controller).YellAt(instigatedBy);

		if ( FriendlyFireScale==0.0 || (Vehicle(injured) != None && Vehicle(injured).bNoFriendlyFire) )
		{
			if ( GameRulesModifiers != None )
				return GameRulesModifiers.NetDamage( Damage, 0,injured,instigatedBy,HitLocation,Momentum,DamageType );
			else return 0;
		}
		Damage *= FriendlyFireScale;
	}
	return Super(DeathMatch).ReduceDamage( Damage,injured,instigatedBy,HitLocation,Momentum,DamageType );
}

static function bool NeverAllowTransloc()
{
	return true;
}

function bool AllowTransloc()
{
	return bAllowTrans || bOverrideTranslocator;
}

function AddGameSpecificInventory(Pawn p);

event PlayerController Login
(
	string Portal,
	string Options,
	out string Error
)
{
	local PlayerController NewPlayer;
	local Controller C;

	NewPlayer = Super.Login(Portal,Options,Error);

	if ( NewPlayer.PlayerReplicationInfo.bOnlySpectator && NumSpectators > MaxSpectators )
	{
		Error = GameMessageClass.Default.MaxedOutMessage;
		NewPlayer.Destroy();
		return None;
	}
	else if ( !NewPlayer.PlayerReplicationInfo.bOnlySpectator && NumPlayers > MaxPlayers && !NewPlayer.PlayerReplicationInfo.bAdmin )
	{
		Error = GameMessageClass.Default.MaxedOutMessage;
		NewPlayer.Destroy();
		return None;
	}

	for ( C=Level.ControllerList; C!=None; C=C.NextController )
		if ( (C.PlayerReplicationInfo != None) && C.PlayerReplicationInfo.bOutOfLives && !C.PlayerReplicationInfo.bOnlySpectator && !GameReplicationInfo.bMatchHasBegun )
		{
			NewPlayer.PlayerReplicationInfo.bOutOfLives = true;
			NewPlayer.PlayerReplicationInfo.NumLives = 1;
			Break;
		}

	NewPlayer.SetGRI(GameReplicationInfo);

	//let's route to our custom KFPlayerController state for class Selection.

	// give the new player the server starting cash
	if ( !NewPlayer.PlayerReplicationInfo.bOnlySpectator ) // must not be a spectator
		NewPlayer.PlayerReplicationInfo.Score = StartingCash;

	if ( bDelayedStart ) //!
	{
		NewPlayer.GotoState('PlayerWaiting');
		return NewPlayer;
	}

	return NewPlayer;
}
event PreLogin( string Options, string Address, string PlayerID, out string Error, out string FailCode )
{
	Super.PreLogin(Options,Address,PlayerID,Error,FailCode);
	if( FailCode=="" && GameReplicationInfo.bMatchHasBegun && bNoLateJoiners )
	{
		FailCode = "FC_NoLateJoiners";
		Error = "This server does not allow late joiners.";
	}
}
function bool AtCapacity(bool bSpectator)
{
	if ( Level.NetMode == NM_Standalone )
		return false;

	if ( bSpectator )
		return ( (NumSpectators >= MaxSpectators)
				&& ((Level.NetMode != NM_ListenServer) || (NumPlayers > 0)) );
	else
		return ( (MaxPlayers>0) && (NumPlayers>=MaxPlayers) );
}

// Mod this to include the choices made in the GUIClassMenu
function RestartPlayer( Controller aPlayer )
{
	if ( aPlayer.PlayerReplicationInfo.bOutOfLives || aPlayer.Pawn!=None )
		return;
	if( bWaveInProgress && PlayerController(aPlayer)!=None )
	{
		aPlayer.PlayerReplicationInfo.bOutOfLives = True;
		aPlayer.PlayerReplicationInfo.NumLives = 1;
		aPlayer.GoToState('Spectating');
		Return;
	}

	Super.RestartPlayer(aPlayer);

	if( KFHumanPawn(aPlayer.Pawn)!=None )
		KFHumanPawn(aPlayer.Pawn).CheckCarryWeight();
}

function BroadcastDeathMessage(Controller Killer, Controller Other, class<DamageType> damageType)
{
	local string S;

	if( damageType==None )
		damageType = Class'DamageType';
	if( Killer!=None && Other!=None && Killer!=Other )
		Broadcast(Self,ParseKillMessage(GetNameOf(Killer.Pawn),GetNameOf(Other.Pawn),damageType.Default.DeathString),'DeathMessage');
	else if( Other!=None )
	{
		if( Other.Pawn!=None && Other.Pawn.bIsFemale )
			S = damageType.Default.FemaleSuicide;
		else S = damageType.Default.MaleSuicide;
		Broadcast(Self,ParseKillMessage("Someone",GetNameOf(Other.Pawn),S),'DeathMessage');
	}
}
function string GetNameOf( Pawn Other )
{
	local string S;

	if( Other==None )
		Return "Someone";
	if( Other.PlayerReplicationInfo!=None )
		Return Other.PlayerReplicationInfo.PlayerName;
	S = Other.MenuName;
	if( S=="" )
	{
		Other.MenuName = string(Other.Class.Name);
		S = Other.MenuName;
	}
	if( Monster(Other)!=None && Monster(Other).bBoss )
		Return "the"@S;
	else if( Class'KFInvasionMessage'.Static.ShouldUseAn(S) )
		Return "an"@S;
	else Return "a"@S;
}
function GetServerDetails( out ServerResponseLine ServerState )
{
	local int i,l;

	Super.GetServerDetails( ServerState );
	l = ServerState.ServerInfo.Length;
	ServerState.ServerInfo.Length = l+1;
	ServerState.ServerInfo[l].Key = "Veterancy skills";
	ServerState.ServerInfo[l].Value = Eval(bPerksEnabled,"Enabled","Disabled");
	l++;
	if( bPerksEnabled )
	{
		For( i=0; i<LoadedSkills.Length; i++ )
		{
			ServerState.ServerInfo.Length = l+1;
			ServerState.ServerInfo[l].Key = "Veterancy";
			ServerState.ServerInfo[l].Value = LoadedSkills[i].Default.VeterancyName;
			l++;
		}
	}
	ServerState.ServerInfo.Length = l+1;
	ServerState.ServerInfo[l].Key = "Max runtime zombies";
	ServerState.ServerInfo[l].Value = string(MaxZombiesOnce);
	l++;
	ServerState.ServerInfo.Length = l+1;
	ServerState.ServerInfo[l].Key = "Starting cash";
	ServerState.ServerInfo[l].Value = string(StartingCash);
	l++;
}
function bool ChangeTeam(Controller Other, int num, bool bNewTeam)
{
	if ( Other.IsA('PlayerController') && Other.PlayerReplicationInfo.bOnlySpectator )
	{
		Other.PlayerReplicationInfo.Team = None;
		return true;
	}

	// check if already on this team
	if ( Other.PlayerReplicationInfo.Team == Teams[0] )
		return false;

	Other.StartSpot = None;

	if ( Teams[0].AddToTeam(Other) )
	{
		if ( bNewTeam && PlayerController(Other)!=None )
			GameEvent("TeamChange",""$num,Other.PlayerReplicationInfo);
	}
	return true;
}
function bool CheckEndGame(PlayerReplicationInfo Winner, string Reason)
{
	local Controller P;
	local PlayerController Player;
	local int i;

	EndTime = Level.TimeSeconds + EndTimeDelay;

	if ( WaveNum >= FinalWave )
	{
		GameReplicationInfo.Winner = Teams[0];
		KFGameReplicationInfo(GameReplicationInfo).EndGameType = 2;
		For( i=0; i<ActiveStats.Length; i++ )
		{
			if( ActiveStats[i].CurrentOwner!=None && ActiveStats[i].CurrentOwner.PlayerReplicationInfo!=None
			 && !ActiveStats[i].CurrentOwner.PlayerReplicationInfo.bOnlySpectator )
				ActiveStats[i].GamesWon++;
		}
	}
	else
	{
		KFGameReplicationInfo(GameReplicationInfo).EndGameType = 1;
		For( i=0; i<ActiveStats.Length; i++ )
		{
			if( ActiveStats[i].CurrentOwner!=None && ActiveStats[i].CurrentOwner.PlayerReplicationInfo!=None
			 && !ActiveStats[i].CurrentOwner.PlayerReplicationInfo.bOnlySpectator )
				ActiveStats[i].GamesLost++;
		}
	}

	for ( P=Level.ControllerList; P!=None; P=P.nextController )
	{
		player = PlayerController(P);
		if ( Player != None )
		{
			player.ClientSetBehindView(true);
			player.ClientGameEnded();
		}
		P.GameHasEnded();
	}

	if ( CurrentGameProfile != None )
		CurrentGameProfile.bWonMatch = false;
	return true;
}

function SendPlayer( PlayerController aPlayer, string URL )
{
	if( bGameEnded || aPlayer==None || aPlayer.PlayerReplicationInfo==None )
		Return;
	Broadcast(Self,aPlayer.PlayerReplicationInfo.PlayerName@"has ended the level.");
	if( Left(URL,4)~="NULL" )
	{
		WaveNum = FinalWave;
		EndGame(None,"TimeLimit");
		Return;
	}
	Level.ServerTravel(URL,False);
	bGameEnded = True;
}

static function string GetValidCharacter( string S )
{
	local int i,l;

	l = Default.AvailableChars.Length;
	if( S!="" )
	{
		for( i=0; i<l; i++ )
		{
			if( Default.AvailableChars[i]~=S )
				Return Default.AvailableChars[i];
		}
	}
	Return Default.AvailableChars[Rand(l)];
}

static function string GetLoadingHint( PlayerController PC, string MapName, Color ColorHint )
{
	local Material Shot;
	local UT2K4ServerLoading LO;
	local LevelSummary LS;
	local array<Material> TexToUse;
	local int i,j;
	local LoadingInfoImage CI;

	// Look for map screenshot.
	LS = LevelSummary(DynamicLoadObject(MapName$".LevelSummary", Class'LevelSummary', True));
	if( LS!=None && LS.ScreenShot!=None )
		Shot = LS.ScreenShot;
	if( Shot==None ) // Try looking for mapname <screenshot>
		Shot = Material(DynamicLoadObject(MapName$".ScreenShot", Class'Material', True));
	if( Shot!=None )
	{
		if( MaterialSequence(Shot)!=None )
		{
			For( i=0; i<MaterialSequence(Shot).SequenceItems.Length; i++ )
			{
				TexToUse.Length = j+1;
				TexToUse[j] = MaterialSequence(Shot).SequenceItems[i].Material;
				j++;
			}
			Shot = TexToUse[Rand(j)];
		}
		if( Texture(Shot) != None )
			Texture(Shot).LODSet = LODSET_Interface;
		foreach PC.AllObjects(Class'UT2K4ServerLoading', LO)
		{
			CI = New(None)Class'LoadingInfoImage';
			LO.Operations[LO.Operations.Length] = CI;
			CI.Image = Shot;
			if( LS!=None )
			{
				CI.MapTitle = LS.Title;
				CI.MapAuthor = LS.Author;
			}
		}
	}
	Return Default.KFHints[Rand(Default.KFHints.Length)];
}

defaultproperties
{
	MonsterClasses(0)=(MClassName="KFChar.ZombieClot",Mid="A")
	MonsterClasses(1)=(MClassName="KFChar.ZombieCrawler",Mid="B")
	MonsterClasses(2)=(MClassName="KFChar.ZombieGoreFast",Mid="C")
	MonsterClasses(3)=(MClassName="KFChar.ZombieStalker",Mid="D")
	MonsterClasses(4)=(MClassName="KFChar.ZombieScrake",Mid="E")
	MonsterClasses(5)=(MClassName="KFChar.ZombieFleshpound",Mid="F")
	MonsterClasses(6)=(MClassName="KFChar.ZombieBloat",Mid="G")
	MonsterClasses(7)=(MClassName="KFChar.ZombieSiren",Mid="H")
	MonsterClasses(8)=(MClassName="KFChar.ZombieFleshpoundRangeAlt",Mid="I")
	HumanName(0)="Cpl.McinTyre"
	HumanName(1)="Sgt.Michaels"
	HumanName(2)="Pvt.Davin"
	HumanName(3)="Cpl.Powers"
	KFSurvivalPropText(0)="Wave Start Spawn Period"
	KFSurvivalPropText(1)="Wave Spawn Period"
	KFSurvivalPropText(2)="Starting Cash"
	KFSurvivalPropText(3)="No Bots"
	KFSurvivalPropText(4)="No Late Joiners"
	KFSurvivalPropText(5)="Lobby TimeOut"
	KFSurvivalPropText(6)="Specimen HealthBars"
	KFSurvivalPropText(7)="Wave Downtime"
	KFSurvivalDescText(0)="Specify time between successive spawns at start of waves(recommended:6.0), lower values may hurt performance!"
	KFSurvivalDescText(1)="Specify time between successive spawns during a wave(recommended:3.0), lower values may hurt performance!"
	KFSurvivalDescText(2)="Specify how much money players should begin the game with. (Max 300)"
	KFSurvivalDescText(3)="Check this box to remove bots from the game."
	KFSurvivalDescText(4)="Check this box to stop people from joining after the game has started."
	KFSurvivalDescText(5)="Set the maximum time on the lobby screen which can elapse after one player has clicked ready before the game automatically starts. "
	KFSurvivalDescText(6)="If true, specimens will have visible health indicators above their heads"
	KFSurvivalDescText(7)="The based amount of time (in seconds) to count between waves."
	WaveStartSpawnPeriod=6.000000
	StartingCash=300
	MinRespawnCash=250
	bUseEndGameBoss=True
	EndGameBossClass="KFChar.ZombieBoss"
	BossBattleSong="KF25-Abandon"
	KFHints(0)="Aiming for the head is a good idea. If you score a critical headshot, you can remove a Specimen's head, rendering them unable to use special abilities, and increasing any further damage they take."
	KFHints(1)="While you can use your medical syringe to heal your own wounds, it is far more effective when used on a team mate."
	KFHints(2)="The Fleshpound Specimen cannot be stunned. Avoid engaging in melee combat with it."
	KFHints(3)="A grenade can be thrown even when you have another weapon drawn by pressing the throw grenade kotkey."
	KFHints(4)="To reload the Combat Shotgun or Winchester press and HOLD the reload key to continue inserting shells."
	KFHints(5)="Some Specimens will perform combo attacks, allowing them to strike you two or even three times in an instant. Stay on your guard in close quarters."
	KFHints(6)="Doors that have been destroyed will respawn at the end of each wave. If your defenses are compromised, try again later."
	KFHints(7)="The volatile liquids the Bloat carries in its belly have a propensity for catching fire."
	KFHints(8)="Your movement speed is affected by your weight total. You can also run faster carrying a melee weapon than a gun."
	KFHints(9)="Bloats will explode in a shower of acidic goop when they die. Keep your distance when taking them down."
	KFHints(10)="Stalkers blend in with their surroundings when not attacking. Train your eye to look for subtle movements."
	KFHints(11)="The Trader will only open her shop for a brief time when the coast is clear. You'll have to find where she is situated in each map, and plan your shopping beforehand."
	KFHints(12)="The larger and more difficult the Specimen you kill, the more cash you will be awarded."
	KFHints(13)="Surviving players receive a cash bonus at the end of each round."
	KFHints(14)="The Siren's sonics can detonate incoming explosives. Be wary of using explosive weapons when she screams."
	MonsterSquad(0)="4A"
	MonsterSquad(1)="3A1G"
	MonsterSquad(2)="2A2G"
	MonsterSquad(3)="1C3D1G"
	MonsterSquad(4)="3A2D1G"
	MonsterSquad(5)="4A2D"
	MonsterSquad(6)="2B2C1D"
	MonsterSquad(7)="1A2C2D1G"
	MonsterSquad(8)="2A3B1C"
	MonsterSquad(9)="4B1H"
	MonsterSquad(10)="1C1E1G1H"
	MonsterSquad(11)="1B2D2E"
	MonsterSquad(12)="1C1D1E1F"
	MonsterSquad(13)="1E1F1H"
	MonsterSquad(14)="1I"
	ControllerClassName="KFmod.KFDoorController"
	LobbyTimeout=20
	InitialCountDownValue=60
	VeterancySkills(0)="KFMod.KFVetFieldMedic"
	VeterancySkills(1)="KFMod.KFVetSupportSpec"
	VeterancySkills(2)="KFMod.KFVetSharpshooter"
	VeterancySkills(3)="KFMod.KFVetCommando"
	VeterancySkills(4)="KFMod.KFVetBerserker"
	VeterancySkills(5)="KFMod.KFVetFirebug"
	VeterancySkills(6)="KFMod.KFVetSergeant"
	AvailableChars(0)="Soldier_Black"
	AvailableChars(1)="Soldier_Urban"
	AvailableChars(2)="Soldier"
	AvailableChars(3)="Soldier_Lewis"
	AvailableChars(4)="Soldier_Davin"
	AvailableChars(5)="Hazmat"
	AvailableChars(6)="Stalker"
	AvailableChars(7)="Soldier_Kara"
	AvailableChars(8)="Soldier_Powers"
	AvailableChars(9)="Soldier_Masterson"
	bPerksEnabled=True
	MaxZombiesOnce=32
	WaveConfigMenu="KFGUI.KFWaveConfigMenu"
	FallbackMonsterClass="KFChar.ZombieStalker"
	FinalWave=10
	InvasionBotNames(1)="Zombie"
	InvasionBotNames(2)="Zombie"
	InvasionBotNames(3)="Zombie"
	InvasionBotNames(4)="Zombie"
	InvasionBotNames(5)="Zombie"
	InvasionBotNames(6)="Zombie"
	InvasionBotNames(7)="Zombie"
	InvasionBotNames(8)="Zombie"
	InvasionEnd(0)="Sound"
	InvasionEnd(1)="Sound"
	InvasionEnd(2)="Sound"
	InvasionEnd(3)="Sound"
	InvasionEnd(4)="Sound"
	InvasionEnd(5)="Sound"
	Waves(0)=(WaveMask=7,WaveMaxMonsters=32,WaveDuration=254)
	Waves(1)=(WaveMask=56,WaveMaxMonsters=32,WaveDuration=254,WaveDifficulty=0.100000)
	Waves(2)=(WaveMask=320,WaveMaxMonsters=32,WaveDuration=254,WaveDifficulty=0.100000)
	Waves(3)=(WaveMask=592,WaveMaxMonsters=32,WaveDuration=254,WaveDifficulty=0.200000)
	Waves(4)=(WaveMask=1344,WaveMaxMonsters=32,WaveDuration=254,WaveDifficulty=0.200000)
	Waves(5)=(WaveMask=2114,WaveMaxMonsters=32,WaveDuration=254,WaveDifficulty=0.300000)
	Waves(6)=(WaveMask=5121,WaveMaxMonsters=32,WaveDuration=254,WaveDifficulty=0.300000)
	Waves(7)=(WaveMask=8708,WaveMaxMonsters=32,WaveDuration=254,WaveDifficulty=0.400000)
	Waves(8)=(WaveMask=12304,WaveMaxMonsters=32,WaveDuration=254,WaveDifficulty=0.400000)
	Waves(9)=(WaveMask=20488,WaveMaxMonsters=32,WaveDuration=254)
	Waves(10)=(WaveDuration=254)
	Waves(11)=(WaveDuration=254)
	Waves(12)=(WaveDuration=254)
	Waves(13)=(WaveDuration=254)
	Waves(14)=(WaveDuration=254)
	Waves(15)=(WaveDuration=254)
	MaxTeamSize=6
	TeamAIType(0)=Class'KFMod.KFTeamAI'
	TeamAIType(1)=Class'KFMod.KFTeamAI'
	bForceRespawn=True
	NumRounds=10
	SpawnProtectionTime=0.000000
	EndGameSoundName(0)="Sound"
	EndGameSoundName(1)="Sound"
	AltEndGameSoundName(0)="Sound"
	AltEndGameSoundName(1)="Sound"
	EpicNames(0)="Lt.Barker"
	EpicNames(1)="Pvt.Davin"
	EpicNames(2)="Cpl.Power"
	EpicNames(3)="Pvt.Barns"
	EpicNames(4)="Cpl.Hicks"
	EpicNames(5)="Sgt.Apone"
	EpicNames(6)="Pvt.Hudson"
	EpicNames(7)="Maj.Brale"
	EpicNames(8)="Lt.Derricks"
	EpicNames(9)="Pvt.Quick"
	EpicNames(10)="Sgt.Masterson"
	EpicNames(11)="Lt.Barker"
	EpicNames(12)="Pvt.Davin"
	EpicNames(13)="Cpl.Power"
	EpicNames(14)="Pvt.Barns"
	EpicNames(15)="Cpl.Hicks"
	EpicNames(16)="Sgt.Apone"
	EpicNames(17)="Pvt.Hudson"
	EpicNames(18)="Maj.Brale"
	EpicNames(19)="Lt.Derricks"
	EpicNames(20)="Pvt.Quick"
	MaleBackupNames(0)="Lt.Barker"
	MaleBackupNames(1)="Pvt.Davin"
	MaleBackupNames(2)="Cpl.Power"
	MaleBackupNames(3)="Pvt.Barns"
	MaleBackupNames(4)="Cpl.Hicks"
	MaleBackupNames(5)="Sgt.Apone"
	MaleBackupNames(6)="Pvt.Hudson"
	MaleBackupNames(7)="Maj.Brale"
	MaleBackupNames(8)="Lt.Derricks"
	MaleBackupNames(9)="Pvt.Quick"
	MaleBackupNames(10)="Sgt.Masterson"
	MaleBackupNames(11)="Lt.Barker"
	MaleBackupNames(12)="Pvt.Davin"
	MaleBackupNames(13)="Cpl.Power"
	MaleBackupNames(14)="Pvt.Barns"
	MaleBackupNames(15)="Cpl.Hicks"
	MaleBackupNames(16)="Sgt.Apone"
	MaleBackupNames(17)="Pvt.Hudson"
	MaleBackupNames(18)="Maj.Brale"
	MaleBackupNames(19)="Lt.Derricks"
	MaleBackupNames(20)="Pvt.Quick"
	MaleBackupNames(21)="Pvt.Davin"
	MaleBackupNames(22)="Cpl.Power"
	MaleBackupNames(23)="Pvt.Barns"
	MaleBackupNames(24)="Cpl.Hicks"
	MaleBackupNames(25)="Sgt.Apone"
	MaleBackupNames(26)="Pvt.Hudson"
	MaleBackupNames(27)="Maj.Brale"
	MaleBackupNames(28)="Lt.Derricks"
	MaleBackupNames(29)="Pvt.Quick"
	MaleBackupNames(30)="Sgt.Masterson"
	MaleBackupNames(31)="Lt.Barker"
	FemaleBackupNames(0)="Lt.Vasquez"
	FemaleBackupNames(1)="Pvt.Kara"
	FemaleBackupNames(2)="Sgt.Swanson"
	FemaleBackupNames(3)="Maj.Simons"
	FemaleBackupNames(4)="Pvt.Martinez"
	FemaleBackupNames(5)="Cpl.Sharpe"
	FemaleBackupNames(6)="Pvt.Faulkner"
	FemaleBackupNames(7)="Lt.Vasquez"
	FemaleBackupNames(8)="Pvt.Kara"
	FemaleBackupNames(9)="Sgt.Swanson"
	FemaleBackupNames(10)="Maj.Simons"
	FemaleBackupNames(11)="Pvt.Martinez"
	FemaleBackupNames(12)="Cpl.Sharpe"
	FemaleBackupNames(13)="Pvt.Faulkner"
	FemaleBackupNames(14)="Lt.Vasquez"
	FemaleBackupNames(15)="Pvt.Kara"
	FemaleBackupNames(16)="Sgt.Swanson"
	FemaleBackupNames(17)="Maj.Simons"
	FemaleBackupNames(18)="Pvt.Martinez"
	FemaleBackupNames(19)="Cpl.Sharpe"
	FemaleBackupNames(20)="Pvt.Faulkner"
	FemaleBackupNames(21)="Lt.Vasquez"
	FemaleBackupNames(22)="Pvt.Kara"
	FemaleBackupNames(23)="Sgt.Swanson"
	FemaleBackupNames(24)="Maj.Simons"
	FemaleBackupNames(25)="Pvt.Martinez"
	FemaleBackupNames(26)="Cpl.Sharpe"
	FemaleBackupNames(27)="Pvt.Faulkner"
	FemaleBackupNames(28)="Pvt.Kara"
	FemaleBackupNames(29)="Sgt.Swanson"
	FemaleBackupNames(30)="Maj.Simons"
	FemaleBackupNames(31)="Pvt.Martinez"
	LoginMenuClass="KFGUI.KFInvasionLoginMenu"
	bAllowVehicles=True
	DefaultPlayerClassName="KFmod.KFHumanPawn"
	ScoreBoardType="KFMod.KFScoreBoardNew"
	HUDType="KFmod.HUDKillingFloor"
	MapListType="KFMod.KFMapList"
	MapPrefix="KF"
	BeaconName="KF"
	ResetTimeDelay=10
	DefaultPlayerName="Fresh Meat"
	TimeLimit=0
	DeathMessageClass=Class'KFMod.KFDeathMessage'
	GameMessageClass=Class'KFMod.KFGameMessages'
	MutatorClass="KFmod.KillingFloorMut"
	PlayerControllerClass=Class'KFMod.KFPlayerController'
	PlayerControllerClassName="KFmod.KFPlayerController"
	GameReplicationInfoClass=Class'KFMod.KFGameReplicationInfo'
	GameName="Killing Floor"
	Description="They are coming. There's nothing but you and your squad standing between a mass of escaped laboratory horrors and the world at large."
	ScreenShotName="KFThumbs.KFShots"
	Acronym="KF"
	GIPropsDisplayText(0)="KF Game Difficulty"
	GIPropDescText(0)="Change the game difficulty. Anything above Normal will cause increased zombie speed, damage and health among other things..."
	GIPropsExtras(0)="1.500000;Easy;3.000000;Normal;4.000000;Skilled;5.000000;Elite;7.000000;Suicidal"
}
