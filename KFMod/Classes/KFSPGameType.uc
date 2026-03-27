// Single player Killing Floor Gametype
class KFSPGameType extends KFGameType;

// Config
var()	 config	int						 RoundLimit;				 // number of pair of rounds
var						 int						 MaxRounds;					// converted to actual number of rounds played
var()	 config	int						 RoundTimeLimit;		 // max round duration (in minutes)
var()	 config	int						 PracticeTimeLimit;	// practice duration (in seconds)

var		 config	int						 ReinforcementsFreq;				 // Reinforcement frequency (seconds, 0 = no reinforcements)
var						 int						 ReinforcementsValidTime;		// delay while players are allowed to join last reinforcement
var						 int						 ReinforcementsCount;

var int SuccessfulAssaultTimeLimit;		 // if first attacking team sucessfully attacked, defenders will have to beat that time to win.

const ASPROPNUM = 5;
var localized string		ASPropsDisplayText[ASPROPNUM];
var localized string		ASPropDescText[ASPROPNUM];

var(LoadingHints) private localized array<string> ASHints;

// internal
var		 byte				CurrentAttackingTeam;	 // Current Attacking team index
var		 byte				FirstAttackingTeam;
var		 byte				CurrentRound;
var		 int				 RoundStartTime;
var		 bool				bDisableReinforcements;

var name		AttackerWinRound[2];
var name		DefenderWinRound[2];
var name		DrawGameSound;

var GameObjective	 CurrentObjective, LastDisabledObjective;
var vehicle KeyVehicle;

var Array<PlayerSpawnManager>	 SpawnManagers;					// Handling player spawning

var SceneManager								CurrentMatineeScene;		// SP matinee intro cinematic
var KFSceneManager		EndCinematic;					 // MP outro cinematic

var bool		bWeakObjectives;		// cheat


// Story Mode Specific Variables

var KFSPLevelInfo SPInfo;	// The reigning Level Info

var bool bDefKFEquips; // Sets whether pawns spawn with regular gear or not.	(KFSP)
var int PlayerStartingHealth;	// The starting amount of Hitpoints for all players.

var bool bPlayedIntro; 

event PostNetBeginPlay()
{
	local KFSPLevelInfo LI;
	//local KFDoorMover DM;
	
	foreach AllActors(class'KFSPLevelInfo',LI)
	{
		if (LI != none)
			SPInfo = LI;
	}

	if (SPInfo != none)
		 bDefKFEquips = SPInfo.bStartingPlayerEquipment;

	/*
        foreach DynamicActors(class'KFDoorMover',DM)
	{
		if( DM != none && DM.bStartSealed )
			DM.SetWeldStrength(DM.MaxWeld);
	}
	*/
}



function PostBeginPlay()
{
	local int i;

	Teams[0] = GetRedTeam(0);
	Teams[1] = GetBlueTeam(0);

	for (i=0;i<2;i++)
	{
		Teams[i].TeamIndex = i;
		Teams[i].AI = Spawn(TeamAIType[i]);
		Teams[i].AI.Team = Teams[i];
		GameReplicationInfo.Teams[i] = Teams[i];
	}
	Teams[0].AI.EnemyTeam = Teams[1];
	Teams[1].AI.EnemyTeam = Teams[0];
	Teams[0].AI.SetObjectiveLists();
	Teams[1].AI.SetObjectiveLists();
}

function OverrideInitialBots();

function bool TooManyBots(Controller botToRemove)
{
	 return false;
}

function RestartPlayer( Controller aPlayer )
{
	Super(gameinfo).RestartPlayer(aPlayer);
		
	// If we've got a player, and our Starting health value is less than his max, but more than 0	(cuz that would...kill him)
	// then adjust his initial health.

	if (SPInfo != none)
		PlayerStartingHealth = SPInfo.PlayerStartHealth;

	if( aPlayer.Pawn != none && PlayerStartingHealth < aPlayer.Pawn.HealthMax && PlayerStartingHealth>0 )
		KFHumanPawn(aPlayer.Pawn).Health = PlayerStartingHealth;
}

function ForceAddBot();

function InitPlacedBot(Controller C, RosterEntry R)
{
	local UnrealTeamInfo BotTeam;

	BotTeam = FindTeamFor(C);
	if ( Bot(C) != None )
	{
		Bot(C).InitializeSkill(AdjustedDifficulty);
		if ( R != None )
				R.InitBot(Bot(C));
	}
	BotTeam.AddToTeam(C);
	if ( R != None )
		ChangeName(C, R.PlayerName, false);
}

function InitializeBot(Bot NewBot, UnrealTeamInfo BotTeam, RosterEntry Chosen);

function bool AddBot(optional string botName)
{
	return false;
}

exec function AddBots(int num);

function Bot SpawnBot(optional string botName)
{
	Return None;
}

event PlayerController Login( string Portal, string Options, out string Error )
{
	local PlayerController NewPlayer;
	local Controller C;
	local bool bTempLate;

	bTempLate = bNoLateJoiners;
	bNoLateJoiners = False;
	NewPlayer = Super.Login(Portal,Options,Error);
	bNoLateJoiners = bTempLate;

	for ( C=Level.ControllerList; C!=None; C=C.NextController )
		if ( (C.PlayerReplicationInfo != None) && C.PlayerReplicationInfo.bOutOfLives && !C.PlayerReplicationInfo.bOnlySpectator && !GameReplicationInfo.bMatchHasBegun )
		{
			NewPlayer.PlayerReplicationInfo.bOutOfLives = true;
			NewPlayer.PlayerReplicationInfo.NumLives = 1;
		}

	NewPlayer.SetGRI(GameReplicationInfo);

	if ( bDelayedStart ) //!
	{
		NewPlayer.GotoState('PlayerWaiting');
		return NewPlayer;
	}
	return NewPlayer;

}

event KFSceneEnded( KFSceneManager SM, Actor Other )
{
	GotoState('MatchInProgress');
}

/* cinematic started... */
event KFSceneStarted( KFSceneManager SM, Actor Other )
{
	if ( Other != None && Other.IsA('KFSceneManager') )
		GotoState('MPOutroCinematic');
}

/* network friendly outro */
state MPOutroCinematic
{
}

function bool IsPlayingIntro()
{
	return false;
}

function HighlightCurrentPhysicalObjectives()
{
	local GameObjective GO;

	if( ASGameReplicationInfo(GameReplicationInfo)==None )
		Return;
	for ( GO=Teams[0].AI.Objectives; GO!=None; GO=GO.NextObjective )
	{
		if ( (ASGameReplicationInfo(GameReplicationInfo).ObjectiveProgress >= GO.ObjectivePriority) && GO.IsActive() )
			GO.HighlightPhysicalObjective( true );
		else GO.HighlightPhysicalObjective( false );
	}
}

function GameObjective GetCurrentObjective()
{
	local GameObjective GO;

	// Try to find currently active objective...
	if ( CurrentObjective == None )
		for ( GO=Teams[0].AI.Objectives; GO!=None; GO=GO.NextObjective )
		{
			if ( (ASGameReplicationInfo(GameReplicationInfo).ObjectiveProgress == GO.ObjectivePriority)
				&& GO.IsActive() && ( !GO.bOptionalObjective || CurrentObjective == None ) )
				CurrentObjective = GO;
		}
	return CurrentObjective;
}

function FindNewObjectives(GameObjective DisabledObjective)
{
	if ( !bGameEnded && ResetCountDown < 1 )
		UpdateObjectiveProgression( DisabledObjective ); // Objective has just been disabled, update progress...
	super.FindNewObjectives( DisabledObjective );
}

/*
here we keep track of objective progression through a simple progress index...
This index allows objectives to be shown in order on HUD,
and Briefing screen to show the status of the assault...
*/
function UpdateObjectiveProgression( GameObjective DisabledObjective )
{
	local GameObjective GO;
	local bool bIncPriority, bObjPriority;
	local byte CurrentProgressIndex, BackupProgressIndex;

	if( ASGameReplicationInfo(GameReplicationInfo)==None )
		Return;
	CurrentProgressIndex = ASGameReplicationInfo(GameReplicationInfo).ObjectiveProgress;

	BackupProgressIndex = CurrentProgressIndex;
	bIncPriority				= true;

	for ( GO=Teams[0].AI.Objectives; GO!=None; GO=GO.NextObjective )
	{
		// Check objective progression...
		if ( (CurrentProgressIndex == GO.ObjectivePriority) && !GO.bOptionalObjective )
		{
			// Prioritization is relevant, we found at least one objective matching...
			bObjPriority = true;

			if ( GO.IsActive() )
			{
				// There is at least one Objective with current priority left to disable...
				bIncPriority = false;
				break;
			}
		}
	}

	// Objective Prioritization is relevant and all current priority objectives are disabled ?
	// So increase progress index...
	if ( bObjPriority && bIncPriority )
		CurrentProgressIndex++;

	// Update progress...
	if ( CurrentProgressIndex != BackupProgressIndex )
		ASGameReplicationInfo(GameReplicationInfo).ObjectiveProgress++;

	HighlightCurrentPhysicalObjectives();

	// Update Current Objective
	for ( GO=Teams[0].AI.Objectives; GO!=None; GO=GO.NextObjective )
	{
		if ( (ASGameReplicationInfo(GameReplicationInfo).ObjectiveProgress == GO.ObjectivePriority)
			&& !GO.bDisabled && !GO.bOptionalObjective )
		{
			CurrentObjective = GO;

			if ( !DisabledObjective.bAnnounceNextObjective || (CurrentProgressIndex == BackupProgressIndex
				&& GO.Announcer_ObjectiveInfo == DisabledObjective.Announcer_ObjectiveInfo
				&& !DisabledObjective.bOptionalObjective) )
				break;
			return;
		}
	}
}

State MatchInProgress
{
	function Timer();
		
	function beginstate()
	{
		if (!bPlayedIntro)
		{
			TriggerEvent('IntroScene', Self, None);		 // try to play Matinee intro
			bPlayedIntro = true;
		}
	}
}

/* returns true if Objective is relevant (priority wise) */
function bool	 CheckObjectivePriority(GameObjective GO)
{
	local ASGameReplicationInfo ASGRI;

	ASGRI = ASGamereplicationInfo(GameReplicationInfo);

	if ( ASGRI == None || !GO.IsActive() || GO.bDisabled )
		return false;

	if ( ASGRI.ObjectiveProgress >= GO.ObjectivePriority )
		return true;

	return false;
}

function DisableNextObjective()
{
	local GameObjective GO;

	for ( GO=Teams[0].AI.Objectives; GO!=None; GO=GO.NextObjective )
		if ( CheckObjectivePriority( GO ) )
		{
			GO.CompleteObjective( None );
			break;
		}
}

defaultproperties
{
     bNoLateJoiners=True
     ScoreBoardType="KFMod.KFSPObjectiveBoard"
     HUDType="KFmod.HUDKillingFloorSP"
     MapListType="KFMod.KFMapListSP"
     MapPrefix="KFS"
     BeaconName="KFS"
     GameReplicationInfoClass=Class'KFMod.KFSGameReplicationInfo'
     GameName="Story"
     Description="Story Based Cooperative Gameplay."
     Acronym="KFS"
}
