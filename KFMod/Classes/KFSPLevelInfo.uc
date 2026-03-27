class KFSPLevelInfo extends LevelGameRules;

var () bool bStartingPlayerEquipment; // Gun, welder, Syringe.
var () int PlayerStartHealth; // Amount of starting HP for all players
var () bool bUseVisionOverlay;

// Actor bans
// KEEPS IN MIND that these actor bans only take effect when the game starts. 
// Actors spawned after game start will not be taken into account.

var () class<Actor> EasyBannedClasses [10];   // Actors of this class are banned from Easy Play
var () class<Actor> NormalBannedClasses [10];   // Actors of this class are banned from Normal Play
var () class<Actor> SkilledBannedClasses [10];   // Actors of this class are banned from Skilled Play
var () class<Actor> EliteBannedClasses [10];   // Actors of this class are banned from Elite Play
var () class<Actor> SuicidalBannedClasses [10];   // Actors of this class are banned from Suicidal Play

var () Array<String> MissionObjectives;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	if( KFSGameReplicationInfo(Level.GRI)!=None )
		KFSGameReplicationInfo(Level.GRI).KFPLevel = Self;
}
simulated function SetGRI(GameReplicationInfo GRI)
{
	if( KFSGameReplicationInfo(GRI)!=None )
		KFSGameReplicationInfo(GRI).KFPLevel = Self;
}

defaultproperties
{
     bUseVisionOverlay=True
     bNoDelete=True
}
