// Endless Killing Floor - infinite waves, always-open trader, combat music throughout.
// Inspired by Call of Duty Zombies: survive as long as you can with ever-scaling difficulty.
//
// Key differences from KFGameType:
//   - Waves never end (no FinalWave check, no boss wave)
//   - Trader doors stay open and buy menu is accessible at all times
//   - Short 10-second breaks between waves (dead players respawn here)
//   - Combat music plays continuously
//   - Difficulty and monster count scale infinitely beyond wave 15
//   - Special waves every 5 waves (Sirens only, Shades only)
//   - Boss waves every 10 waves (Patriarch)
class KFEndlessGameType extends KFGameType;

enum EEndlessWaveType
{
    EWT_Normal,
    EWT_Siren,
    EWT_Shade,
    EWT_Boss,
    EWT_Holdout
};
var EEndlessWaveType CurrentWaveType;

var bool bEndlessWaveActive;

var class<KFMonster> SirenClass;
var class<KFMonster> ShadeClass;

var float HoldoutEndTime;
var array<class<KFMonster> > HoldoutMonsterClasses;
var array<KFMonster> FastZEDs;

event InitGame( string Options, out string Error )
{
    Super.InitGame(Options, Error);

    InitialCountDownValue = 15;
    InitialWave = 1;
    FinalWave = 99999;

    SirenClass = class<KFMonster>(DynamicLoadObject("KFChar.ZombieSiren", class'Class'));
    ShadeClass = class<KFMonster>(DynamicLoadObject("KFChar.ZombieShade", class'Class'));

    // Pre-load low-tier monster classes for holdout waves
    HoldoutMonsterClasses.Length = 5;
    HoldoutMonsterClasses[0] = class<KFMonster>(DynamicLoadObject("KFChar.ZombieClot", class'Class'));
    HoldoutMonsterClasses[1] = class<KFMonster>(DynamicLoadObject("KFChar.ZombieCrawler", class'Class'));
    HoldoutMonsterClasses[2] = class<KFMonster>(DynamicLoadObject("KFChar.ZombieGoreFast", class'Class'));
    HoldoutMonsterClasses[3] = class<KFMonster>(DynamicLoadObject("KFChar.ZombieStalker", class'Class'));
    HoldoutMonsterClasses[4] = class<KFMonster>(DynamicLoadObject("KFChar.ZombieWretch", class'Class'));
}

static function FillPlayInfo(PlayInfo PlayInfo)
{
    Super(Info).FillPlayInfo(PlayInfo);  // Always begin with calling parent

    PlayInfo.AddSetting(default.GameGroup,	"GameDifficulty",			GetDisplayText("GameDifficulty"),		0, 2, "Select", default.GIPropsExtras[0], "Xb");
    PlayInfo.AddSetting(default.GameGroup,"WaveStartSpawnPeriod", GetDisplayText("WaveStartSpawnPeriod"),50,0,"Text","3;0.0:6.0");
    PlayInfo.AddSetting(default.GameGroup,"StartingCash", GetDisplayText("StartingCash"),70,0,"Text","200;0:5000");
    PlayInfo.AddSetting(default.GameGroup,"MinRespawnCash", "Min Respawn Cash amount",70,0,"Text","200;0:5000");
    
    PlayInfo.AddSetting(default.RulesGroup,"bNoBots", GetDisplayText("bNoBots"),	1, 0, "Check",				,				,True,True);
    PlayInfo.AddSetting(default.RulesGroup,  "bAllowBehindView",		GetDisplayText("bAllowBehindview"),	1, 0, "Check",				,				,True,True);
    PlayInfo.AddSetting(default.RulesGroup,"bNoLateJoiners", GetDisplayText("bNoLateJoiners"),	1, 0, "Check",				,				,True,True);
    PlayInfo.AddSetting(default.RulesGroup, "MaxZombiesOnce","Max Specimens",0,1,"Text","4;6:600");
    PlayInfo.AddSetting(default.RulesGroup,"bPerksEnabled","Perks enabled",0,1,"Check");
    
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
        case "bUseEndGameBoss":				return "Spawn the final boss on end of final wave.";
        case "TmpWavesInf":					return "Configure the KF waves.";
        case "TmpSquadsInf":				return "Configure the monster squads to use on waves.";
        case "TmpMClassInf":				return "Configure the monster classes to be used in the squads.";
        case "EndGameBossClass":				return "The boss battle monster class.";
        case "MinRespawnCash":				return "Minimum amount of Cash when respawning on new wave (to stop people's reconnection needs).";
    }
    return Super.GetDescriptionText(PropName);
}

// Always play combat music, never calm
function StartGameMusic(bool bCombat)
{
    Super.StartGameMusic(true);
}

// Gate respawns on our own wave-active flag instead of bWaveInProgress
function RestartPlayer(Controller aPlayer)
{
    if (aPlayer.PlayerReplicationInfo.bOutOfLives || aPlayer.Pawn != None)
        return;

    // During active waves, dead players spectate until wave end
    if (bEndlessWaveActive && PlayerController(aPlayer) != None)
    {
        aPlayer.PlayerReplicationInfo.bOutOfLives = true;
        aPlayer.PlayerReplicationInfo.NumLives = 1;
        aPlayer.GoToState('Spectating');
        return;
    }

    // bWaveInProgress is always false, so parent proceeds straight to respawn
    Super.RestartPlayer(aPlayer);
}

// Determine what type of wave this should be
function EEndlessWaveType GetWaveType(int Wave)
{
    local int DisplayWave;
    DisplayWave = Wave + 1;

    if (DisplayWave >= 10 && (DisplayWave % 10) == 0)
        return EWT_Boss;

    if (DisplayWave >= 5 && (DisplayWave % 5) == 0)
    {
        if (Rand(2) == 0)
            return EWT_Siren;
        else
            return EWT_Shade;
    }

    if (DisplayWave >= 3 && Rand(4) == 0)
        return EWT_Holdout;

    return EWT_Normal;
}

// Scale wave setup for infinite progression with tiered random squads
function SetupWave()
{
    local int i, j, k, CombinedMask, MaskEnd;
    local float NewMaxMonsters;

    TraderProblemLevel = 0;
    rewardFlag = false;
    ZombiesKilled = 0;
    WaveMonsters = 0;
    WaveNumClasses = 0;

    // Difficulty: starts at base GameDifficulty, +0.1 per wave
    AdjustedDifficulty = GameDifficulty + float(WaveNum) * 0.1;

    // Determine wave type
    CurrentWaveType = GetWaveType(WaveNum);

    // Boss wave: use the existing StartWaveBoss-style setup
    if (CurrentWaveType == EWT_Boss)
    {
        Broadcast(Self, "--- BOSS WAVE: The Patriarch approaches! ---");
        bHasSetViewYet = false;

        NewMaxMonsters = 1.0;
        TotalMaxMonsters = 1;
        MaxMonsters = 1;

        KFGameReplicationInfo(Level.Game.GameReplicationInfo).MaxMonsters = 1;
        KFGameReplicationInfo(Level.Game.GameReplicationInfo).MaxMonstersOn = true;
        WaveEndTime = Level.TimeSeconds + 255.0;

        // Set up the boss spawn squad
        NextSpawnSquad.Length = 1;
        NextSpawnSquad[0] = class<Monster>(DynamicLoadObject(EndGameBossClass, class'Class'));
        if (NextSpawnSquad[0] == None)
            NextSpawnSquad[0] = FallbackMonster;

        bWaveBossInProgress = true;
        return;
    }

    if (CurrentWaveType == EWT_Holdout)
    {
        Broadcast(Self, "--- HOLDOUT WAVE: Survive the swarm for 90 seconds! ---");

        // Effectively infinite pool - wave ends by timer, not by running out
        TotalMaxMonsters = 999;
        // Allow lots on screen at once for the swarm feel
        MaxMonsters = Clamp(MaxZombiesOnce * 2, 32, 128);

        KFGameReplicationInfo(Level.Game.GameReplicationInfo).MaxMonsters = TotalMaxMonsters;
        KFGameReplicationInfo(Level.Game.GameReplicationInfo).MaxMonstersOn = true;
        WaveEndTime = Level.TimeSeconds + 255.0;
        HoldoutEndTime = Level.TimeSeconds + 90.0;

        BuildNextSquad();
        return;
    }

    // Special waves: announce and reduce monster count slightly
    if (CurrentWaveType == EWT_Siren)
        Broadcast(Self, "--- SPECIAL WAVE: Sirens! ---");
    else if (CurrentWaveType == EWT_Shade)
        Broadcast(Self, "--- SPECIAL WAVE: Shades! ---");

    // Monster count: own scaling formula, independent of Waves array
    // Base 15, +3 per wave. Wave 1=18, wave 5=30, wave 10=45, wave 20=75, wave 30=105
    NewMaxMonsters = 15.0 + float(WaveNum) * 3.0;
    NewMaxMonsters *= (FMin(GameDifficulty, 7.0) + 3.0) / 7.0 * FClamp(float(NumPlayers + NumBots) * 0.8, 2.0, 50.0);

    // Special waves get fewer but more focused monsters
    if (CurrentWaveType != EWT_Normal)
        NewMaxMonsters *= 0.75;

    TotalMaxMonsters = Clamp(int(NewMaxMonsters), 5, 800);
    MaxMonsters = Clamp(TotalMaxMonsters, 5, MaxZombiesOnce);

    KFGameReplicationInfo(Level.Game.GameReplicationInfo).MaxMonsters = TotalMaxMonsters;
    KFGameReplicationInfo(Level.Game.GameReplicationInfo).MaxMonstersOn = true;
    WaveEndTime = Level.TimeSeconds + 255.0;

    // For normal waves, build allowed squad pool using WaveMask data from the Waves array.
    if (CurrentWaveType == EWT_Normal)
    {
        SquadsToUse.Length = 0;

        if (InitSquads.Length > 0)
        {
            if (WaveNum >= 10)
            {
                // Beyond wave 10: all squads available
                for (i = 0; i < InitSquads.Length; i++)
                    SquadsToUse[SquadsToUse.Length] = i;
            }
            else
            {
                // OR together WaveMasks from wave 0 up to WaveNum+1
                CombinedMask = 0;
                MaskEnd = Min(WaveNum + 1, 9);
                for (i = 0; i <= MaskEnd; i++)
                    CombinedMask = CombinedMask | Waves[i].WaveMask;

                // Extract allowed squad indices from combined mask
                j = 1;
                for (i = 0; i < InitSquads.Length; i++)
                {
                    if ((j & CombinedMask) != 0)
                        SquadsToUse[SquadsToUse.Length] = i;
                    j *= 2;
                }
            }

            // Randomly trim to a subset for variety (at least 3, scales with wave)
            k = Clamp(3 + WaveNum, 3, SquadsToUse.Length);
            while (SquadsToUse.Length > k)
                SquadsToUse.Remove(Rand(SquadsToUse.Length), 1);
        }
    }

    BuildNextSquad();
}

// Override BuildNextSquad to force monster type during special waves
function BuildNextSquad()
{
    local int SquadSize;
    local int i;
    local class<KFMonster> KFMClass;

    // Special waves: build squads of a single monster type
    if (CurrentWaveType == EWT_Siren || CurrentWaveType == EWT_Shade)
    {
        if (CurrentWaveType == EWT_Siren)
            KFMClass = SirenClass;
        else
            KFMClass = ShadeClass;

        if (KFMClass == None)
        {
            // Fallback to normal squad building if class failed to load
            Super.BuildNextSquad();
            return;
        }

        // Build a squad of 3-6 of the special monster
        SquadSize = 3 + Rand(4);
        NextSpawnSquad.Length = SquadSize;
        for (i = 0; i < SquadSize; i++)
            NextSpawnSquad[i] = KFMClass;

        return;
    }

    // Holdout waves: random low-tier squads
    if (CurrentWaveType == EWT_Holdout)
    {
        SquadSize = 4 + Rand(5); // 4-8 per squad
        NextSpawnSquad.Length = SquadSize;
        for (i = 0; i < SquadSize; i++)
            NextSpawnSquad[i] = HoldoutMonsterClasses[Rand(HoldoutMonsterClasses.Length)];
        return;
    }

    // Normal waves: use parent logic
    Super.BuildNextSquad();
}

function ForceKillAllMonsters()
{
    local Controller C, Next;

    for (C = Level.ControllerList; C != None; C = Next)
    {
        Next = C.NextController;
        if (MonsterController(C) != None && C.Pawn != None && C.Pawn.Health > 0)
            C.Pawn.KilledBy(C.Pawn);
    }
}

State MatchInProgress
{
    function Timer()
    {
        local Controller C;
        local bool bOneMessage;
        local Bot B;
        local KFTraderDoor TDoor;

        Global.Timer();

        if (!bFinalStartup)
        {
            bFinalStartup = true;
            PlayStartupMessage();
        }
        if (NeedPlayers() && AddBot() && (RemainingBots > 0))
            RemainingBots--;

        ElapsedTime++;
        GameReplicationInfo.ElapsedTime = ElapsedTime;

        if (!UpdateMonsterCount())
        {
            EndGame(None, "TimeLimit");
            return;
        }

        if (bUpdateViewTargs)
            UpdateViews();

        // Pending bot spawning
        if (!bNoBots && !bBotsAdded)
        {
            if (KFGameReplicationInfo(GameReplicationInfo) != none
                && (NumPlayers + NumBots) < MaxPlayers
                && KFGameReplicationInfo(GameReplicationInfo).PendingBots > 0)
            {
                AddBots(1);
                KFGameReplicationInfo(GameReplicationInfo).PendingBots--;
            }
            if (KFGameReplicationInfo(GameReplicationInfo) != none
                && KFGameReplicationInfo(GameReplicationInfo).PendingBots == 0)
            {
                bBotsAdded = true;
                return;
            }
        }

        //--------------------------------------------------------------
        // BOSS WAVE: Patriarch spawn + camera logic
        //--------------------------------------------------------------
        if (bWaveBossInProgress)
        {
            WaveTimeElapsed += 1.0;

            if (!MusicPlaying)
                StartGameMusic(true);

            if (!bHasSetViewYet && TotalMaxMonsters <= 0 && NumMonsters > 0)
            {
                bHasSetViewYet = true;
                for (C = Level.ControllerList; C != None; C = C.NextController)
                    if (C.Pawn != None && KFMonster(C.Pawn) != None && KFMonster(C.Pawn).MakeGrandEntry())
                    {
                        ViewingBoss = KFMonster(C.Pawn);
                        break;
                    }
                if (ViewingBoss != None)
                {
                    ViewingBoss.bAlwaysRelevant = true;
                    for (C = Level.ControllerList; C != None; C = C.NextController)
                        if (PlayerController(C) != None)
                        {
                            PlayerController(C).SetViewTarget(ViewingBoss);
                            PlayerController(C).ClientSetViewTarget(ViewingBoss);
                            PlayerController(C).bBehindView = true;
                            PlayerController(C).ClientSetBehindView(true);
                            PlayerController(C).ClientSetMusic(BossBattleSong, MTRAN_FastFade);
                        }
                }
            }
            else if (ViewingBoss != None && !ViewingBoss.bShotAnim)
            {
                ViewingBoss = None;
                for (C = Level.ControllerList; C != None; C = C.NextController)
                    if (PlayerController(C) != None)
                    {
                        if (C.Pawn != None)
                        {
                            PlayerController(C).SetViewTarget(C.Pawn);
                            PlayerController(C).ClientSetViewTarget(C.Pawn);
                        }
                        else
                        {
                            PlayerController(C).SetViewTarget(C);
                            PlayerController(C).ClientSetViewTarget(C);
                        }
                        PlayerController(C).bBehindView = false;
                        PlayerController(C).ClientSetBehindView(false);
                    }
            }

            // Spawn the boss if not yet spawned
            if (TotalMaxMonsters > 0 && Level.TimeSeconds > NextMonsterTime)
            {
                AddBoss();
                NextMonsterTime = Level.TimeSeconds + 2.0;
            }

            // Boss killed
            if (TotalMaxMonsters <= 0 && NumMonsters <= 0)
                DoWaveEnd();

            return;
        }

        if (bEndlessWaveActive)
        {
            WaveTimeElapsed += 1.0;

            // Holdout wave: force end after 60 seconds
            if (CurrentWaveType == EWT_Holdout && Level.TimeSeconds >= HoldoutEndTime)
            {
                ForceKillAllMonsters();
                Broadcast(Self, "--- HOLDOUT SURVIVED! ---");
                DoWaveEnd();
                return;
            }


            if (!MusicPlaying)
                StartGameMusic(true);

            if (TotalMaxMonsters <= 0 && CurrentWaveType != EWT_Holdout)
            {
                if (NumMonsters <= 5)
                {
                    for (C = Level.ControllerList; C != None; C = C.NextController)
                        if (MonsterController(C) != None && !C.Pawn.PlayerCanSeeMe())
                        {
                            C.Pawn.KilledBy(C.Pawn);
                            break;
                        }
                }
                if (NumMonsters <= 0)
                    DoWaveEnd();
            }
            // Still monsters left to spawn
            else if (Level.TimeSeconds > NextMonsterTime
                     && (NumMonsters + NextSpawnSquad.Length <= MaxMonsters))
            {
                WaveEndTime = Level.TimeSeconds + 160.0;
                AddSquad();
                if (NextSpawnSquad.Length > 0)
                    NextMonsterTime = Level.TimeSeconds + 0.2;
                else
                {
                    if (CurrentWaveType == EWT_Holdout)
                        NextMonsterTime = Level.TimeSeconds + 0.15;
                    else
                        NextMonsterTime = Level.TimeSeconds + FMax(1.0 - float(WaveNum) * 0.03, 0.4);
                }
            }
        }
        else if (NumMonsters <= 0)
        {

            WaveCountDown--;

            if (!MusicPlaying)
                StartGameMusic(true);

            if (!bTradingDoorsOpen)
            {
                foreach DynamicActors(class'KFTraderDoor', TDoor)
                    TDoor.TriggerEvent(TDoor.Tag, TDoor, None);
                bTradingDoorsOpen = true;
            }
            // Disable pawn collision during break for easy movement
            for (C = Level.ControllerList; C != None; C = C.NextController)
                if (C.Pawn != None && C.Pawn.Health > 0)
                    C.Pawn.bBlockActors = false;

            KFGameReplicationInfo(GameReplicationInfo).TimeToNextWave = WaveCountDown;

            if (WaveCountDown == 5)
            {
                KFGameReplicationInfo(Level.Game.GameReplicationInfo).MaxMonstersOn = false;
                InvasionGameReplicationInfo(GameReplicationInfo).WaveNumber = WaveNum;
            }
            else if (WaveCountDown > 0 && WaveCountDown < 5)
            {
                BroadcastLocalizedMessage(class'KFMod.WaitingMessage', WaveCountDown - 1);
            }
            else if (WaveCountDown <= 1)
            {
                // Start next wave
                bEndlessWaveActive = true;
                KFGameReplicationInfo(GameReplicationInfo).bWaveInProgress = true;

                SetupWave();

                // Re-enable pawn collision
                for (C = Level.ControllerList; C != None; C = C.NextController)
                    if (C.Pawn != None && C.Pawn.Health > 0)
                        C.Pawn.bBlockActors = C.Pawn.default.bBlockActors;

                for (C = Level.ControllerList; C != None; C = C.NextController)
                    if (PlayerController(C) != None)
                        PlayerController(C).LastPlaySpeech = 0;

                for (C = Level.ControllerList; C != None; C = C.NextController)
                {
                    if (Bot(C) != None && Bot(C).Pawn != None)
                    {
                        B = Bot(C);
                        InvasionBot(B).bDamagedMessage = false;
                        B.bInitLifeMessage = false;
                        if (!bOneMessage && FRand() < 0.65)
                        {
                            bOneMessage = true;
                            if (B.Squad.SquadLeader != None
                                && B.Squad.CloseToLeader(C.Pawn))
                            {
                                B.SendMessage(B.Squad.SquadLeader.PlayerReplicationInfo,
                                    'OTHER', B.GetMessageIndex('INPOSITION'), 20, 'TEAM');
                                B.bInitLifeMessage = false;
                            }
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
        
        bEndlessWaveActive = false;
        bWaveBossInProgress = false;
        CurrentWaveType = EWT_Normal;

        MusicPlaying = false;
        StartGameMusic(true);

        // Only reset this at the end of wave 0. That way the sine wave that scales
        // the intensity up/down will be somewhat random per wave
        if( WaveNum < 1 )
        {
            WaveTimeElapsed = 0;
        }

        SaveAllStats();

        if(!rewardFlag)
            RewardSurvivingPlayers();

        bWaveInProgress = False;
        bWaveBossInProgress = False;
        KFGameReplicationInfo(GameReplicationInfo).bWaveInProgress = false;

        WaveCountDown = Max(InitialCountDownValue,1);
        KFGameReplicationInfo(GameReplicationInfo).TimeToNextWave = WaveCountDown;
        WaveNum++;

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
                        PlayerController(C).ClientSetViewTarget(C.Pawn);
                    }
                    RestartPlayer(C);
                }

                if(Bot(C) != None)
                {
                    Bot(C).Squad.Team.SetBotOrders(Bot(C),None);
                }
            }
        }
        bUpdateViewTargs = True;

        //respawn doors
        foreach DynamicActors(class'KFDoorMover', KFDM)
            KFDM.RespawnDoor();
    }

    function BeginState()
    {
        Super.BeginState();
        // Start combat music immediately
        StartGameMusic(true);
        SetupEndlessDoors();
    }
}

// Randomize door states at match start: some open, some welded shut
function SetupEndlessDoors()
{
    local KFUseTrigger T;
    local int i, Roll;

    foreach DynamicActors(class'KFUseTrigger', T)
    {
        if (T.DoorOwners.Length == 0)
            continue;

        // Skip doors that are already key-locked or hidden
        if (T.DoorOwners[0].bKeyLocked || T.DoorOwners[0].bHidden)
            continue;

        Roll = Rand(100);

        if (Roll < 40)
        {
            // 40%: Force doors open
            for (i = 0; i < T.DoorOwners.Length; i++)
            {
                if (!T.DoorOwners[i].bHidden && T.DoorOwners[i].bClosed)
                {
                    T.DoorOwners[i].bShouldBeOpen = true;
                    T.DoorOwners[i].GotoState(, 'Open');
                }
            }
        }
        else if (Roll < 70)
        {
            // 30%: Leave as normal (closed, unwelded)
        }
        else
        {
            // 30%: Weld shut with random strength
            if (!T.DoorOwners[0].bNoSeal && !T.DoorOwners[0].bDisallowWeld)
            {
                T.DoorOwners[0].bSealed = true;
                T.WeldStrength = 0;
                T.AddWeld(50.0 + float(Rand(150)), false, None);
            }
        }
    }
}

// Override AddSquad to boost monster speed during holdout waves
function bool AddSquad()
{
    local Controller C;
    local KFMonster M;
    local bool Result;
    local int i;
    local bool AlreadyBoosted;

    Result = Super.AddSquad();

    if (Result && CurrentWaveType == EWT_Holdout)
    {
        for (C = Level.ControllerList; C != None; C = C.NextController)
        {
            if (MonsterController(C) != None && C.Pawn != None)
            {
                M = KFMonster(C.Pawn);
                if (M != None)
                {
                    AlreadyBoosted = false;
                    for (i = 0; i < FastZEDs.Length; i++)
                    {
                        if (FastZEDs[i] == M)
                        {
                            AlreadyBoosted = true;
                            break;
                        }
                    }
                    if (!AlreadyBoosted)
                    {
                        M.OriginalGroundSpeed *= 1.5;
                        M.SetGroundSpeed(M.GroundSpeed * 1.5);
                        M.HiddenGroundSpeed *= 1.5;
                        FastZEDs[FastZEDs.Length] = M;
                    }
                }
            }
        }
    }

    return Result;
}

defaultproperties
{
    InitialCountDownValue=15
    bUseEndGameBoss=False
    FinalWave=99999
    GameName="Endless Killing Floor"
    Description="Survive endless waves of specimens. The trader is always open. How long can you last?"
}