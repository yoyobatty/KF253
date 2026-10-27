// KFMod 1.0's single-player campaign (KFS-Intro, KFS-01 to KFS-05, KFS-Outro) on KFMod254's game.
// No lobby, waves or trader; one player; what the player carries is saved at every map change,
// and a death restarts the map from that checkpoint.
class KFCampaignGame extends KFSPGameType;

var bool bDiedHere;
var float RestartAt;
var() float AutoRestartDelay;
var localized string DiedMessage;

static function string MapOf( string URL )
{
	local int i;

	i = InStr(URL, "#");
	if( i>=0 )
		URL = Left(URL, i);
	i = InStr(URL, "?");
	if( i>=0 )
		URL = Left(URL, i);
	i = InStr(Caps(URL), ".UT2");
	if( i>=0 )
		URL = Left(URL, i);
	return Caps(URL);
}

static function string PortalOf( string URL )
{
	local int i;

	i = InStr(URL, "#");
	if( i<0 )
		return "";
	URL = Mid(URL, i+1);
	i = InStr(URL, "?");
	if( i>=0 )
		URL = Left(URL, i);
	return URL;
}

function string ThisMap()
{
	return Caps(string(Level.Outer.Name));
}

function bool IsMissionMap()
{
	return Left(ThisMap(), 5)=="KFS-0";
}

event InitGame( string Options, out string Error )
{
	Super.InitGame(Options, Error);
	MaxLives = 0;
	bNoBots = true;
	if( ThisMap()=="KFS-INTRO" )
		class'KFCampaignSave'.static.Clear();
}

event PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
	if( KFSGameReplicationInfo(GameReplicationInfo)!=None )
		KFSGameReplicationInfo(GameReplicationInfo).bHUDShowCash = false;
}

event PostLogin( PlayerController NewPlayer )
{
	NewPlayer.SetGRI(GameReplicationInfo);
	NewPlayer.PlayerReplicationInfo.PlayerID = CurrentID++;
	Super(Invasion).PostLogin(NewPlayer);
	NewPlayer.PlayerReplicationInfo.bReadyToPlay = true;
	if( KFPlayerController(NewPlayer)!=None && KFPlayerController(NewPlayer).MyActiveStats==None )
		KFPlayerController(NewPlayer).FindStatsObject();
}

function StartInitGameMusic( KFPlayerController Other );
function StartGameMusic( bool bCombat );

// A map is entered at the teleporter its URL names: by tag as the engine does, else by name (KFS-02 sends players
// to "KFTeleporter1", the name of KFS-03's arrival teleporter, whose tag is KFTeleporter). With no name given and the
// map's player starts all switched off (KFS-02 to KFS-05), the player arrives at its arrival teleporter, or at the
// switched-off start itself where there is none.
function NavigationPoint FindPlayerStart( Controller Player, optional byte InTeam, optional string incomingName )
{
	local Teleporter Tel;
	local NavigationPoint N;

	if( Player!=None && Player.StartSpot!=None && bWaitingToStartMatch )
		return Super.FindPlayerStart(Player, InTeam, incomingName);
	if( incomingName!="" )
	{
		foreach AllActors(class'Teleporter', Tel)
			if( string(Tel.Tag)~=incomingName )
				return Tel;
		foreach AllActors(class'Teleporter', Tel)
			if( string(Tel.Name)~=incomingName )
				return Tel;
	}
	for( N=Level.NavigationPointList; N!=None; N=N.NextNavigationPoint )
		if( PlayerStart(N)!=None && PlayerStart(N).bEnabled )
			return Super.FindPlayerStart(Player, InTeam, incomingName);
	foreach AllActors(class'Teleporter', Tel)
		if( Tel.URL=="" )
			return Tel;
	// (KFS-Training: its one start is switched off, and the engine would rate any path node above it)
	for( N=Level.NavigationPointList; N!=None; N=N.NextNavigationPoint )
		if( PlayerStart(N)!=None )
			return N;
	return Super.FindPlayerStart(Player, InTeam, incomingName);
}

function bool CheckMaxLives( PlayerReplicationInfo Scorer )
{
	return false;
}

function bool ShouldRespawn( Pickup Other )
{
	return false;
}

function AddDefaultInventory( Pawn PlayerPawn )
{
	if( KFHumanPawn(PlayerPawn)!=None )
		KFHumanPawn(PlayerPawn).AddDefaultInventory();
	SetPlayerDefaults(PlayerPawn);
}

function AddGameSpecificInventory( Pawn P )
{
	local int i;

	if( KFHumanPawn(P)!=None && PlayerController(P.Controller)==None )
	{
		for( i=0; i<16; i++ )
			if( KFHumanPawn(P).RequiredEquipment[i]!="" )
				P.CreateInventory(KFHumanPawn(P).RequiredEquipment[i]);
		return;
	}
	if( InStr(ThisMap(), "TRAINING")>=0 || !IsMissionMap() )
		return;
	if( class'KFCampaignSave'.default.MapName~=ThisMap() )
		class'KFCampaignSave'.static.Restore(P);
	else
	{
		P.CreateInventory("KFMod.Knife");
		P.CreateInventory("KFMod.Single");
		class'KFCampaignSave'.static.Store(P, ThisMap(), PortalOf(Level.GetLocalURL()));
	}
	if( P.Controller!=None )
		P.Controller.ClientSwitchToBestWeapon();
}

function SendPlayer( PlayerController aPlayer, string URL )
{
	if( bGameEnded || aPlayer==None )
		return;
	if( Left(MapOf(URL), 5)=="KFS-0" )
		class'KFCampaignSave'.static.Store(aPlayer.Pawn, MapOf(URL), PortalOf(URL));
	Level.ServerTravel(URL, false);
	bGameEnded = true;
}

function Killed( Controller Killer, Controller Killed, Pawn KilledPawn, class<DamageType> damageType )
{
	Super.Killed(Killer, Killed, KilledPawn, damageType);
	if( PlayerController(Killed)!=None )
	{
		Killed.PlayerReplicationInfo.bOutOfLives = false;	// (Invasion sets it, and then Fire would not restart)
		bDiedHere = true;
		RestartAt = Level.TimeSeconds + AutoRestartDelay;
		PlayerController(Killed).ClientMessage(DiedMessage, 'CriticalEvent');
	}
}

function RestartPlayer( Controller aPlayer )
{
	if( aPlayer.Pawn!=None || (PlayerController(aPlayer)!=None && PlayerController(aPlayer).bViewingMatineeCinematic) )
		return;
	if( bDiedHere && PlayerController(aPlayer)!=None )
	{
		RestartLevel();
		return;
	}
	if( PlayerController(aPlayer)!=None && class'KFCampaignSave'.default.RetryMap~=ThisMap() )
		SkipOpening();
	Super.RestartPlayer(aPlayer);
}

// A retry starts where the map started, without its opening cutscene (the start spots' events) again.
function SkipOpening()
{
	local NavigationPoint N;

	for( N=Level.NavigationPointList; N!=None; N=N.NextNavigationPoint )
		if( PlayerStart(N)!=None )
			N.Event = '';
	class'KFCampaignSave'.default.RetryMap = "";
	class'KFCampaignSave'.static.StaticSaveConfig();
}

function RestartLevel()
{
	if( bGameEnded )
		return;
	bGameEnded = true;
	class'KFCampaignSave'.default.RetryMap = ThisMap();
	class'KFCampaignSave'.static.StaticSaveConfig();
	Level.ServerTravel("?restart", false);
}

State MatchInProgress
{
	function Timer()
	{
		local KFTraderDread D;

		Super.Timer();
		if( Level.NetMode!=NM_DedicatedServer )
			foreach DynamicActors(class'KFTraderDread', D)
				D.bDread = false;
		if( bDiedHere && RestartAt>0 && Level.TimeSeconds>RestartAt )
			RestartLevel();
	}
}

defaultproperties
{
	AutoRestartDelay=10.000000
	DiedMessage="You died. Press Fire to retry from the start of this area."
	HUDType="KFCampaign.KFCampaignHUD"
	ScoreBoardType="KFCampaign.KFCampaignScoreBoard"
	MapPrefix="KFS"
	BeaconName="KFS"
	GameName="Campaign"
	Description="KFMod 1.0's single-player campaign."
	Acronym="KFS"
	MaxLives=0
}
