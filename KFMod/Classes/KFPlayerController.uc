class KFPlayerController extends xPlayer
	DependsOn(KFPlayerStats);

//const MAX_BUYITEMS=50;
const BUYLIST_CATS=7;
const LIBLIST_CATS=3;

//TODO: Kill these last remenants of the old buy system
var string BuyListHeaders[BUYLIST_CATS];
var string LibraryListHeaders[LIBLIST_CATS];

var bool bChoseStarting, bClassChosen;
var bool IsInLobby;
var int CashThrowAmount; // Amount of cash a player throws per keypress.   Set in the player settings menu

var KFMusicInteraction KFInterAct;
var string DelayedSongToPlay;
var bool bHasDelayedSong,bHasChosenSkill;

var KFPlayerStats MyActiveStats;

var array<KFPlayerStats.ActStats> ActStats;
var byte ClientStatsState;
var float StatsUdpTimer;
var int CLStats[11];

replication
{
	reliable if(REMOTEROLE == ROLE_AUTONOMOUSPROXY)
		NetPlayMusic, NetStopMusic,ClientSwitchToBestMeleeWeapon,ShowLobbyMenu,ClientReceiveStat,StatsFinished,ClientGetStats;

	reliable if( Role < ROLE_Authority )
		KFSwitchToBestWeapon,ServerSetGRIPendingBots,ServerSetTempBotName,GRIKillBotCall,SelectVeterancy,ServerSendStats,UpdateStatsScreen;

	// Functions server can call.
	reliable if( Role==ROLE_Authority )
		KFClientNetWorkMsg;
}

function bool FindStatsObject()
{
	local string ID;

	if( MyActiveStats!=None )
		Return True; // Error?
	if( Player==None || KFGameType(Level.Game)==None )
		Return False;
	ID = GetPlayerIDHash();
	MyActiveStats = KFGameType(Level.Game).FindStats(ID);
	if( MyActiveStats==None )
		MyActiveStats = KFGameType(Level.Game).GenerateStats(ID);
	MyActiveStats.UserName = PlayerReplicationInfo.PlayerName;
	MyActiveStats.InitFor(Self);
	Return True;
}

event ClientOpenMenu (string Menu, optional bool bDisconnect,optional string Msg1, optional string Msg2)
{
	if(Player == None)
		Return;
	else Super.ClientOpenMenu(Menu,bDisconnect,Msg1,Msg2);
}





// TODO : Why are we not in state PlayerWaiting, where this was cut n' pasted
//        from in the first place?
function ServerReStartPlayer()
{
	if( PlayerReplicationInfo.bOutOfLives )
		Return; // No more main menu bug closing.

	ClientCloseMenu(true, true);

	if ( Level.Game.bWaitingToStartMatch )
		PlayerReplicationInfo.bReadyToPlay = true;
	else Level.Game.RestartPlayer(self);
}


exec function FreeCamera( bool B )
{
    bFreeCamera = B;
    bBehindView = B;
}

// Toggle the Flashlight on or off via an exec call.
exec function ToggleTorch()
{
	if (pawn.Weapon != none && KFWeapon(pawn.Weapon).bTorchEnabled)
		KFWeapon(pawn.Weapon).LightFire();
}

function GRIKillBotCall(int NumBotsToKill)
{
	if (KFGameType(Level.Game) != none && NumBotsToKill > 0)
		KFGameType(Level.Game).KillBots(NumBotsToKill);
}

function KFClientNetWorkMsg(string ParamA, string ParamB)
{
	ClientOpenMenu("KFGUI.KFNetworkStatusMsg", true, ParamA, ParamB);
}

function BecomeSpectator()
{
	if (Role < ROLE_Authority)
		return;

	if ( !Level.Game.BecomeSpectator(self) )
		return;

	if ( Pawn != None )
		Pawn.Died(self, class'DamageType', Pawn.Location);

	if ( PlayerReplicationInfo.Team != None )
		PlayerReplicationInfo.Team.RemoveFromTeam(self);
	PlayerReplicationInfo.Team = None;
	ServerSpectate();
	BroadcastLocalizedMessage(Level.Game.GameMessageClass, 14, PlayerReplicationInfo);

	ClientBecameSpectator();
}


function ServerSetGRIPendingBots(int NumBotsPending,string BotName)
{
	local int arraydifference;

	//if (KFGameReplicationInfo(GameReplicationInfo).PendingBots  > 0)
	//	arraydifference = 1;
	//else
         arraydifference = 0;

	KFGameReplicationInfo(GameReplicationInfo).PendingBots = NumBotsPending;
	KFGameReplicationInfo(GameReplicationInfo).LastBotName[KFGameReplicationInfo(GameReplicationInfo).PendingBots - arraydifference] = BotName;
}


function ServerSetTempBotName(string KFBotName)
{
	KFGameReplicationInfo(GameReplicationInfo).TempBotName = KFBotName;
}


exec function ThrowGrenade()
{
	KFPawn(Pawn).ThrowGrenade();
}

exec function ShoutSupport()
{
	ServerSpeech('SUPP', 0, "");
}

exec function ShoutFormUp()
{
	ServerSpeech('FORM', 0, "");
}

exec function ShoutTakeThis()
{
	ServerSpeech('TAKE', 0, "");
}

exec function ShoutTrading()
{
	ServerSpeech('TRAD', 0, "");
}

exec function ShoutMedic()
{
	ServerSpeech('MEDIC', 0, "");
}

exec function ShoutWelding()
{
	ServerSpeech('WELD', 0, "");
}

exec function ShoutCovering()
{
	ServerSpeech('COVER', 0, "");
}

simulated event PostNetReceive()
{
	Super.PostNetReceive();

	if ( PlayerReplicationInfo != none) // && bWaitingForPRI )
	{
		//bWaitingForPRI = False;

        //rec = class'xUtil'.static.FindPlayerRecord(PlayerReplicationInfo.CharacterName);
		//if ( rec.Species != None )
		//{
		//	if ( PlayerReplicationInfo.Team == None )
		//		rec.Species.static.LoadResources(rec, Level, PlayerReplicationInfo, 255);
		//	else
		//		rec.Species.static.LoadResources(rec, Level, PlayerReplicationInfo, PlayerReplicationInfo.Team.TeamIndex);

        // HACK !!!
        // TODO: remove hack
		PlayerReplicationInfo.VoiceTypeName = "KFCoreVoice.AussieVoice";
		PlayerReplicationInfo.VoiceType = class<VoicePack>(DynamicLoadObject(PlayerReplicationInfo.VoiceTypeName,class'Class'));
	}
}

function KFSwitchToBestWeapon()
{
	KFClientSwitchToBestWeapon();
}


function KFClientSwitchToBestWeapon()
{
	nextWeapon();
}

function ShowBuyMenu(string wlTag,float maxweight)
{
	StopForceFeedback();  // jdf - no way to pause feedback

	// Open menu
	ClientOpenMenu("KFGUI.GUIBuyMenu",,wlTag,string(maxweight));
}

function ShowLobbyMenu()
{
	StopForceFeedback();  // jdf - no way to pause feedback
	// Open menu
	ClientOpenMenu("KFGUI.LobbyMenu");
}

function ClientRestart(Pawn NewPawn)
{
	//KILL LOBBY
	ClientCloseMenu(true, true);
	super.ClientRestart(NewPawn);
}

simulated function bool FindInterAction()
{
	local int i;

	if( Player.InteractionMaster==None )
		Return False;
	For( i=0; i<Player.InteractionMaster.GlobalInteractions.Length; i++ ) // First search if one remains from last map.
	{
		if( KFMusicInteraction(Player.InteractionMaster.GlobalInteractions[i])!=None )
		{
			KFInterAct = KFMusicInteraction(Player.InteractionMaster.GlobalInteractions[i]);
			Return True;
		}
	}
	// Else create one.
	KFInterAct = New(None)Class'KFMusicInteraction';
	KFInterAct.ViewportOwner = Player;
	KFInterAct.Master = Player.InteractionMaster;
	i = Player.InteractionMaster.GlobalInteractions.Length;
	Player.InteractionMaster.GlobalInteractions.Length = i+1;
	Player.InteractionMaster.GlobalInteractions[i] = KFInterAct;
	KFInterAct.Initialize();
}

function ClientSetMusic( string NewSong, EMusicTransition NewTransition )
{
	local float FadeIn, FadeOut;

	switch (NewTransition)
	{
		case MTRAN_Segue:
			FadeIn = 7.0;
			FadeOut = 3.0;
			break;
		case MTRAN_Fade:
			FadeIn = 3.0;
			FadeOut = 3.0;
			break;
		case MTRAN_FastFade:
			FadeIn = 1.0;
			FadeOut = 1.0;
			break;
		case MTRAN_SlowFade:
			FadeIn = 5.0;
			FadeOut = 5.0;
			break;
	}
	if( NewSong=="" )
		NetStopMusic(FadeOut);
	else NetPlayMusic(NewSong,FadeIn,FadeOut);
}
function NetPlayMusic( string Song, float FadeInTime, float FadeOutTime )
{
	if( Player==None )
	{
		if( Song=="" )
			Return;
		DelayedSongToPlay = Song;
		bHasDelayedSong = True;
		Return;
	}
	else if( NetConnection(Player)!=None )
		Return;
	if( KFInterAct==None && !FindInterAction() )
		Return;
	bHasDelayedSong = False;
	KFInterAct.SetSong(Song,FadeInTime,FadeOutTime);
}
function NetStopMusic(float FadeOutTime)
{
	bHasDelayedSong = False;
	if( Player==None || NetConnection(Player)!=None )
		Return;
	if( KFInterAct==None && !FindInterAction() )
		Return;
	KFInterAct.StopSong(FadeOutTime);
}

event PlayerTick( float DeltaTime )
{
	if( bHasDelayedSong && Player!=None )
		NetPlayMusic(DelayedSongToPlay,0.5,0);
	Super.PlayerTick(DeltaTime);
}

//  enforce Lobby menu appearance here - there were all sorts of conditions attached,
//  but none of them should occur in KF. This simplifies matters ;)
simulated function ShowLoginMenu()
{
	if( (Pawn != None && Pawn.Health > 0) )
		return;
	ClientReplaceMenu("KFGUI.LobbyMenu");
}


auto state PlayerWaiting
{
	exec function Fire(optional float F)
	{
		LoadPlayers();
	}

	function bool CanRestartPlayer()
	{
		if(Level.Game.GameReplicationInfo.bMatchHasBegun)
			return False;
		return ((bReadyToStart || (DeathMatch(Level.Game) != None && DeathMatch(Level.Game).bForceRespawn)) && Super.CanRestartPlayer());
	}
}

state Dead
{
	function BeginState()
	{
		bBehindView=false;
		Super.BeginState();
	}
}

// unpossessed a pawn (because pawn was killed)
function PawnDied(Pawn P)
{
	local int i;

	for (i = 0; i < CameraEffects.Length; i++)
	{
      	RemoveCameraEffect(CameraEffects[i]);
	}
	Super.PawnDied(P);
}
 
 
function ZoneInfo GetCurrentZone()
{
  return Region.Zone;
}


simulated function PlayBeepSound()
{
    if ( ViewTarget != None )
        ViewTarget.PlaySound(sound'KFWeaponSound.bullethitflesh2', SLOT_None,,,,,false);
}
function ShowMidGameMenu(bool bPause)
{
	// Pause if not already
	if( Level.Pauser==None && Level.NetMode==NM_StandAlone )
		SetPause(true);

	if ( Level.NetMode != NM_DedicatedServer )
		StopForceFeedback();  // jdf - no way to pause feedback

	// Open menu
	if (bDemoOwner)
		ClientopenMenu(DemoMenuClass);

	else if ( LoginMenuClass != "" )
		ClientOpenMenu(LoginMenuClass);

	else ClientOpenMenu(MidGameMenuClass);
}

// Fast Melee Switch Code.
// server calls this to force client to switch
function ClientSwitchToBestMeleeWeapon()
{
	SwitchToBestMeleeWeapon();
}

// Same as SwitchToBestWeapon, but we're only dealing in Melee arms now.
exec function SwitchToBestMeleeWeapon()
{
	local inventory inv;

	if ( Pawn == None || KFMeleeGun(Pawn.Inventory) == None )
		return;

	if ( (Pawn.PendingWeapon == None)  )
	{
		for(inv = pawn.Inventory; inv!=None; inv=inv.Inventory)
      	{
			if(inv.IsA('Knife'))
			{
				Pawn.PendingWeapon = Knife(inv);
				Break;
			}
		}
		if ( Pawn.PendingWeapon == Pawn.Weapon )
			Pawn.PendingWeapon = None;
		if ( Pawn.PendingWeapon == None )
			return;
	}
	StopFiring();

	if ( Pawn.Weapon == None )
		Pawn.ChangedWeapon();
	else if ( Pawn.Weapon != Pawn.PendingWeapon )
		Pawn.Weapon.PutDown();
}
function SelectVeterancy( Class<KFVeterancyTypes> VetSkill )
{
	local int i,j;

	if( VetSkill==None || MyActiveStats==None )
		Return;
	if( bHasChosenSkill )
	{
		ClientMessage("You can't change veterancy twice on the same map.");
		Return;
	}
	if( VetSkill==KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill )
	{
		ClientMessage("You are already a '"$VetSkill.Default.VeterancyName$"'");
		Return;
	}
	j = MyActiveStats.ActiveStats.Length;
	for( i=0; i<j; i++ )
	{
		if( MyActiveStats.ActiveStats[i].VetCl==VetSkill )
		{
			if( !MyActiveStats.ActiveStats[i].bNotified )
				Return; // Can't get that, dude.
			MyActiveStats.ApplyVeterancy(VetSkill);
			ClientMessage("You have chosen to be a '"$VetSkill.Default.VeterancyName$"'");
			bHasChosenSkill = True;
			Return;
		}
	}
}

exec function OpenVeterancyMenu() 
{ 
	if( Viewport(Player)==None || PlayerReplicationInfo==None || PlayerReplicationInfo.bOnlySpectator || KFGameReplicationInfo(Level.GRI)==None
	 || !KFGameReplicationInfo(Level.GRI).bPerksEnabled )
		Return;
	Super.ClientOpenMenu("KFGUI.GUIVeterancyBinder", false);
}

simulated function RequestForClasses()
{
	if( ClientStatsState==0 )
	{
		ClientStatsState = 1;
		ServerSendStats();
	}
}
function ServerSendStats()
{
	local int i;

	if( MyActiveStats==None || !FindStatsObject() || KFGameReplicationInfo(Level.GRI)==None || !KFGameReplicationInfo(Level.GRI).bPerksEnabled )
	{
		StatsFinished();
		Return;
	}
	For( i=0; i<MyActiveStats.ActiveStats.Length; i++ )
		ClientReceiveStat(MyActiveStats.ActiveStats[i].VetCl,MyActiveStats.ActiveStats[i].bNotified);
	StatsFinished();
}


simulated function ClientReceiveStat( Class<KFVeterancyTypes> StatClass, bool bEnabled )
{
	local int i;

	for( i=0; i<ActStats.Length; i++ )
	{
		if( ActStats[i].VetCl==StatClass )
		{
			ActStats[i].bNotified = bEnabled;
			Return;
		}
	}
	i = ActStats.Length;
	ActStats.Length = i+1;
	ActStats[i].VetCl = StatClass;
	ActStats[i].bNotified = bEnabled;
}
simulated function StatsFinished()
{
	ClientStatsState = 2;
}

// Stats...
function UpdateStatsScreen()
{
	if( StatsUdpTimer>Level.TimeSeconds )
		Return;
	StatsUdpTimer = Level.TimeSeconds+10;
	if( MyActiveStats==None || !FindStatsObject() )
		Return;
	ClientGetStats(MyActiveStats.TotalKills,MyActiveStats.TotalMeleeDamage,MyActiveStats.DecaptedKills,MyActiveStats.PowerWpnKills
	 ,MyActiveStats.TotalHealed,MyActiveStats.TotalWelded,MyActiveStats.StalkerKills,MyActiveStats.BullpupDamage,MyActiveStats.TotalPlaytime
	 ,MyActiveStats.GamesWon,MyActiveStats.GamesLost);
}

simulated function ClientGetStats( int TK, int TMK, int TDK, int TPK, int THL, int TWL, int TSLK, int TBDM, int TPLT, int GW, int GL )
{
	CLStats[0] = TK;
	CLStats[1] = TMK;
	CLStats[2] = TDK;
	CLStats[3] = TPK;
	CLStats[4] = THL;
	CLStats[5] = TWL;
	CLStats[6] = TSLK;
	CLStats[7] = TBDM;
	CLStats[8] = TPLT;
	CLStats[9] = GW;
	CLStats[10] = GL;
}

function Destroyed()
{
	if( MyActiveStats!=None && MyActiveStats.CurrentOwner==Self )
		MyActiveStats.CurrentOwner = None;
	MyActiveStats = None;
	Super.Destroyed();
}

defaultproperties
{
     BuyListHeaders(0)="My Inventory"
     BuyListHeaders(1)="Melee"
     BuyListHeaders(2)="Power"
     BuyListHeaders(3)="Speed"
     BuyListHeaders(4)="Range"
     BuyListHeaders(5)="Ammo"
     BuyListHeaders(6)="Equipment"
     LibraryListHeaders(0)="BackStory"
     LibraryListHeaders(1)="Equipment"
     LibraryListHeaders(2)="Enemies"
     bBehindView=True
     CheatClass=Class'KFMod.KFCheatManager'
     TeamBeaconTexture=Texture'ONSInterface-TX.HealthBar'
     MidGameMenuClass="KFGUI.KFInvasionLoginMenu"
     PlayerReplicationInfoClass=Class'KFMod.KFPlayerReplicationInfo'
}
