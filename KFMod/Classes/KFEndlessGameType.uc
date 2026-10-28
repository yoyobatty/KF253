// Endless Killing Floor - infinite waves, always-open trader, combat music throughout.
// Survive as long as you can with ever-scaling difficulty.
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
    EWT_Holdout,
    EWT_Lockdown
};
var EEndlessWaveType CurrentWaveType;

var bool bEndlessWaveActive;

var class<KFMonster> SirenClass;
var class<KFMonster> ShadeClass;

var float HoldoutEndTime;
var array<class<KFMonster> > HoldoutMonsterClasses;
var array<KFMonster> FastZEDs;

// River (holdout waves): specimens come on a steady beat in rows side by side, a riot, from one or two source
// areas that take turns; each source holds for a while and then moves (sooner if a player comes near it or is
// about to see it). The rows keep their places across the way as far as there is room (KFMonsterController.RiotSteer).
var() bool bRiver;                 // False: squads as before
var() float RiverGap;              // seconds a specimen before any wave has been won (a row of four: four times that)
var() float RiverGapPerWave;       // taken off the gap each wave
var() float RiverMinGap;
var() float RiverSurge;            // how far the flow swells and ebbs (0 is a steady flow)
var() float RiverSurgePeriod;      // seconds of one swell and ebb
var() float RiverShiftMin, RiverShiftMax;   // seconds a source holds before the river moves
var() int RiverSources;            // 1 to 4 sources taking turns, spread round the players
var() int RiotRowSize;             // specimens in a row (1: one at a time, no rows)
var() float RiotSpacing;           // gap between neighbours in a row, beyond their bodies
var() class<Monster> RiotClass;    // None: the wave's own mix; else every specimen of the river is of this kind
var() bool bRiotRush;              // the rows sprint in (a horde's rush): nobody holds back for its row
var() float RushSpeed;             // every holdout specimen's speed when seen, whatever its kind (0: the old speed-up)
var() float RushHiddenSpeed;       // and when out of sight
var ZombieVolume RiverSrc[4];
var float RiverShiftAt[4];

// Hordes: in a holdout, from its start and then every HordeEvery seconds, the beat is quickened for HordeLength
// seconds and every source is chosen afresh round the players
var() float HordeLength;           // seconds a horde floods in (0: no hordes)
var() float HordeEvery;            // seconds from one horde to the next in a holdout (0: only at its start)
var() float HordeGapScale;         // the beat is this share of the usual one during a horde
var() float HordeSpreadAngle;      // sources at least this many degrees apart round the players, where the map allows
var float HordeUntil, NextHordeTime;

// Spread approach: each river row first makes for a path node (its first stop) in a part of the map the river has
// not lately been through, by whatever way leads there, then closes in on the players; one that sees a player
// charges at once. Every holdout specimen warms the 512-unit square it stands in four times a second, and the
// warmth fades; the sides round the players taken in turn decide between squares about as cold.
var() bool bSpreadApproach;
var() int ApproachSides;           // how many sides round the players the rows are shared over
var() float ApproachMinDist, ApproachMaxDist;   // the band round the players the first stops are picked from
var() float ApproachHeatWeight;    // what a stop loses for each unit of warmth where it stands
var() float ApproachHeatKeep;      // share of the warmth kept each quarter second
var array<int> HeatKey;
var array<float> HeatVal;
var float RiverNextTime, NextRowCheck;
var int RowsLoosed;
var() float HoldoutChance;         // share of waves from the third on that are holdouts
var() float HoldoutCapScale;       // specimens at once in a holdout: this times the game's Max Specimens (32 to 128)
var() float HoldoutLength;         // seconds a holdout keeps spawning
var() float HoldoutHealthScale;    // a holdout specimen's health (and its head's) is this share of a normal one's
var() float WaveHealthClimb;       // specimen health added each wave, as a share of Normal's
var() float WaveDamageClimb;       // specimen damage added each wave, likewise
var() int DamageClimbWaves;        // damage climbs for this many waves, then holds (0: no end)
var bool bForceNextType;           // the next wave is of ForcedNextType (cheats Holdout, NextWave)
var EEndlessWaveType ForcedNextType;

// Power-ups, as in Zombies: now and then a kill by a player or bot leaves one floating where the specimen fell, for anyone
// to walk into, and it works for the whole team (Max Ammo, Insta-Kill, Double Dosh, Nuke; Zombies adds Carpenter)
var() bool bPowerUps;
var() float PowerUpDropChance;     // share of kills that leave one
var() int MaxPowerUpsPerRound;     // left by kills in one wave at most (the loot specimen's comes on top)
var() float PowerUpDuration;       // seconds Insta-Kill and Double Dosh last
var() array<class<KFZombiesPowerUp> > PowerUpClasses;
var int PowerUpsThisRound;
var array<NavigationPoint> DropNodes;  // the path nodes players can walk to (FindDropNodes, at the first drop)
var bool bDropNodesFound;
var array<BlockingVolume> PlayerBlockers;  // (FindDropNodes) volumes that block players and not specimens
var float InstaKillEndTime, DoublePointsEndTime;
var bool bNuking;
// The loot specimen: in some waves one specimen glows (KFLootGlow) and always drops a power-up where it dies
var() float LootWaveChance;        // share of waves with one (never the Patriarch's)

// Glory kills (Doom style, KFMonster.GloryKill): a specimen knocked below this share of its health staggers and glows for
// a few seconds; a blow by hand or the use key within reach tears it apart and gives health, ammunition and armour
var() bool bGloryKills;
var() float GloryShare;            // ...of its health
var() float GloryWindow;           // seconds it stays open
var() float GloryReach;            // reach beyond its body
var() int GloryHealth;             // health given
var() int GloryArmour;             // armour given
var() float GloryAmmoShare;        // share of each gun's most ammunition given
var() float GloryLockdownScale;    // ...all of it this much more in a lockdown

// Lockdowns (Doom style, KFLockdown): the players are shut in a ring of energy where they stand and fight stages of
// specimens teleporting in round them
var() float LockdownChance;        // share of waves from LockdownFrom on that are lockdowns (0, off at the user's word 10-28; ForceNextWave("Lockdown") still makes one)
var() int LockdownFrom;
var KFLockdown Lockdown;

// The bosses an Endless boss wave picks from
var() array<string> BossPool;
var string BossNow;
var() float LootFromShare, LootToShare;   // it is picked once this share of the wave has come (of 80 at most)
var() string LootMessage;
var int LootAt;                    // specimens of the wave come before it is picked (0: none to pick)
var KFMonster LootZed;

event InitGame( string Options, out string Error )
{
    Super.InitGame(Options, Error);

    InitialCountDownValue = 15;
    //InitialWave = 1;
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
    // (where power-ups may be put: worked out now, not as the first one drops in a fight)
    FindDropNodes();
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

	PlayInfo.AddSetting(default.GameGroup,   "InitialWave",  GetDisplayText("InitialWave"), 50,  0,  "Text", "2;1:"$(ArrayCount(default.Waves)) );

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

    if (bForceNextType)
    {
        bForceNextType = false;
        return ForcedNextType;
    }

    if (DisplayWave >= 10 && (DisplayWave % 10) == 0)
        return EWT_Boss;

    if (DisplayWave >= 5 && (DisplayWave % 5) == 0)
    {
        if (Rand(2) == 0)
            return EWT_Siren;
        else
            return EWT_Shade;
    }

    if (DisplayWave >= LockdownFrom && FRand() < LockdownChance)
        return EWT_Lockdown;

    if (DisplayWave >= 3 && FRand() < HoldoutChance)
        return EWT_Holdout;

    return EWT_Normal;
}

// Total monster pool for the wave, before clamping. Overridable for pacing tweaks.
// Base 15, +3 per wave. Wave 1=18, wave 5=30, wave 10=45, wave 20=75, wave 30=105
function float GetWaveTotalMonsters(EEndlessWaveType WType)
{
    local float NewMaxMonsters;

    NewMaxMonsters = 15.0 + float(WaveNum) * 3.0;
    // (one player alone fights a wave for one, as in retail; it was sized for two)
    if (NumPlayers + NumBots <= 1)
        NewMaxMonsters *= (FMin(GameDifficulty, 7.0) + 3.0) / 7.0;
    else
        NewMaxMonsters *= (FMin(GameDifficulty, 7.0) + 3.0) / 7.0 * FClamp(float(NumPlayers + NumBots) * 0.8, 2.0, 50.0);

    // Special waves get fewer but more focused monsters
    if (WType != EWT_Normal)
        NewMaxMonsters *= 0.75;

    return NewMaxMonsters;
}

// Max monsters allowed on screen at once for the wave. Overridable for pacing tweaks.
function int GetWaveConcurrentCap(int TotalMax)
{
    return Clamp(TotalMax, 5, MaxZombiesOnce);
}

// Seconds to wait before the next squad/monster spawn attempt. Overridable for pacing tweaks.
function float GetSpawnInterval()
{
    if (NextSpawnSquad.Length > 0)
        return 0.2;
    if (CurrentWaveType == EWT_Holdout)
        return 0.15;
    return FMax(1.0 - float(WaveNum) * 0.03, 0.4);
}

// Scale wave setup for infinite progression with tiered random squads
function SetupWave()
{
    local int i, j, k, CombinedMask, MaskEnd;
    local float NewMaxMonsters;

    UpdateSwarm();
    FastZEDs.Length = 0;
    TrafficNode.Length = 0;
    TrafficHeat.Length = 0;
    HeatKey.Length = 0;
    HeatVal.Length = 0;
    for (i = 0; i < ArrayCount(RiverSrc); i++)
        RiverSrc[i] = None;
    RiverNextTime = 0;
    NextHordeTime = 0;
    HordeUntil = 0;
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
        // (a boss from the pool: the Patriarch or one of the Killing Floor 2 style prototypes)
        BossNow = EndGameBossClass;
        if (BossPool.Length > 0)
            BossNow = BossPool[Rand(BossPool.Length)];
        if (InStr(BossNow, "KingFleshpound") >= 0)
            Broadcast(Self, "--- BOSS WAVE: The King Fleshpound approaches! ---");
        else if (InStr(BossNow, "Abomination") >= 0)
            Broadcast(Self, "--- BOSS WAVE: The Abomination approaches! ---");
        else
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
        NextSpawnSquad[0] = class<Monster>(DynamicLoadObject(BossNow, class'Class'));
        if (NextSpawnSquad[0] == None)
            NextSpawnSquad[0] = FallbackMonster;

        bWaveBossInProgress = true;
        return;
    }

    if (CurrentWaveType == EWT_Lockdown)
    {
        // the lockdown makes its own specimens; the wave ends when it is cleared (LockdownDone)
        TotalMaxMonsters = 999;
        MaxMonsters = 64;
        KFGameReplicationInfo(Level.Game.GameReplicationInfo).MaxMonsters = 0;
        KFGameReplicationInfo(Level.Game.GameReplicationInfo).MaxMonstersOn = false;
        WaveEndTime = Level.TimeSeconds + 900.0;
        NextSpawnSquad.Length = 0;
        if (Lockdown != None)
            Lockdown.Destroy();
        Lockdown = Spawn(class'KFLockdown');
        if (Lockdown != None)
            Lockdown.Begin(self);
        else
            TotalMaxMonsters = 0;
        return;
    }

    if (CurrentWaveType == EWT_Holdout)
    {
        Broadcast(Self, "--- HOLDOUT WAVE: Survive the swarm for "$int(HoldoutLength)$" seconds! ---");

        // Effectively infinite pool - wave ends by timer, not by running out
        TotalMaxMonsters = 999;
        // Allow lots on screen at once for the swarm feel
        NewMaxMonsters = float(MaxZombiesOnce) * HoldoutCapScale;
        MaxMonsters = Clamp(int(NewMaxMonsters), 32, 128);

        KFGameReplicationInfo(Level.Game.GameReplicationInfo).MaxMonsters = TotalMaxMonsters;
        KFGameReplicationInfo(Level.Game.GameReplicationInfo).MaxMonstersOn = true;
        WaveEndTime = Level.TimeSeconds + 255.0;
        HoldoutEndTime = Level.TimeSeconds + HoldoutLength;

        BuildNextSquad();
        return;
    }

    // Special waves: announce and reduce monster count slightly
    if (CurrentWaveType == EWT_Siren)
        Broadcast(Self, "--- SPECIAL WAVE: Sirens! ---");
    else if (CurrentWaveType == EWT_Shade)
        Broadcast(Self, "--- SPECIAL WAVE: Shades! ---");

    // Monster count: own scaling formula, independent of Waves array
    NewMaxMonsters = GetWaveTotalMonsters(CurrentWaveType);

    TotalMaxMonsters = Clamp(int(NewMaxMonsters), 5, 800);
    MaxMonsters = GetWaveConcurrentCap(TotalMaxMonsters);

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

// Called once the wave's monster pool is exhausted (TotalMaxMonsters<=0).
// Helps wind down a wave by force-killing a remaining zombie no player can
// currently see (so players don't have to hunt down a straggler hiding in a
// corner), then ends the wave once every monster is dead. Overridable so a
// stricter mode can require every last zombie to be genuinely killed.
function HandleWaveMonsterPoolExhausted()
{
    local Controller C;

    if (NumMonsters <= 5)
    {
        for (C = Level.ControllerList; C != None; C = C.NextController)
            if (MonsterController(C) != None && C.Pawn != LootZed && !C.Pawn.PlayerCanSeeMe())
            {
                C.Pawn.KilledBy(C.Pawn);
                break;
            }
    }
    if (NumMonsters <= 0)
        DoWaveEnd();
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

        if (bPowerUps)
        {
            UpdatePowerUpTimers();
            LootCheck();
        }

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

            // Holdout wave: stop spawning after timer expires, let players kill the rest
            if (CurrentWaveType == EWT_Holdout && HoldoutEndTime > 0 && Level.TimeSeconds >= HoldoutEndTime)
            {
                TotalMaxMonsters = 0;
                HoldoutEndTime = 0;
                KFGameReplicationInfo(Level.Game.GameReplicationInfo).MaxMonsters = NumMonsters;
                Broadcast(Self, "--- HOLDOUT SURVIVED! Kill the remaining" @ NumMonsters @ "specimens! ---");
            }


            if (!MusicPlaying)
                StartGameMusic(true);

            if (TotalMaxMonsters <= 0)
            {
                HandleWaveMonsterPoolExhausted();
            }
            // Still monsters left to spawn (a river is fed from Tick)
            else if (CurrentWaveType != EWT_Lockdown && !RiverOn() && Level.TimeSeconds > NextMonsterTime
                     && (NumMonsters + NextSpawnSquad.Length <= MaxMonsters))
            {
                WaveEndTime = Level.TimeSeconds + 160.0;
                AddSquad();
                NextMonsterTime = Level.TimeSeconds + GetSpawnInterval();
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
            SetGlassSolid(true);

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
                PlanLoot();

                // Re-enable pawn collision
                for (C = Level.ControllerList; C != None; C = C.NextController)
                    if (C.Pawn != None && C.Pawn.Health > 0)
                        C.Pawn.bBlockActors = C.Pawn.default.bBlockActors;
                SetGlassSolid(false);

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
        local KFDoorMover KFDM;

        // Stop boss music so regular combat music can restart
        if (bWaveBossInProgress)
        {
            for (C = Level.ControllerList; C != None; C = C.NextController)
                if (PlayerController(C) != None)
                    PlayerController(C).ClientSetMusic("", MTRAN_FastFade);
            MusicPlaying = false;
        }
        
        bEndlessWaveActive = false;
        bWaveBossInProgress = false;
        CurrentWaveType = EWT_Normal;

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

function SetupEndlessDoors()
{
    local KFUseTrigger T;
    local int i, Roll;

    foreach DynamicActors(class'KFUseTrigger', T)
    {
        if (T.DoorOwners.Length == 0)
            continue;

        // Skip elevator doors
        if (KFElevatorTrigger(T) != None)
            continue;

        // Skip doors that are already key-locked, hidden or too far to trigger
        if (T.DoorOwners[0].bKeyLocked || T.DoorOwners[0].bHidden || T.DoorOwners[0].bTriggerTooFar || T.DoorOwners[0].MyTrigger==None)
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

// (KFLockdown) The lockdown is cleared: the wave ends once the last of it is gone
function LockdownDone(KFLockdown L)
{
    if (L == Lockdown)
        Lockdown = None;
    TotalMaxMonsters = 0;
}

// (KFMonster.GloryKill) What a glory kill gives: health, ammunition for every gun carried, armour; the drops fly to the
// one who made it (KFGloryBurst)
function GloryReward( Pawn Killer, KFMonster M )
{
	local KFGloryBurst B;
	local Inventory Inv;
	local KFWeapon W;
	local float Scale;
	local int Heal, Armour, Got, i;
	local bool bAmmo;

	Scale = 1.0;
	if (CurrentWaveType == EWT_Lockdown)
		Scale = GloryLockdownScale;
	Heal = int(float(GloryHealth) * Scale);
	Armour = int(float(GloryArmour) * Scale);
	Killer.GiveHealth(Heal, Killer.HealthMax);
	if (xPawn(Killer) != None && Killer.ShieldStrength < 100)
		Killer.AddShieldStrength(Armour);
	for (Inv = Killer.Inventory; Inv != None && i < 100; Inv = Inv.Inventory)
	{
		i++;
		W = KFWeapon(Inv);
		if (W == None || W.bMeleeWeapon || W.AmmoClass[0] == None)
			continue;
		Got = int(float(W.MaxAmmo(0)) * GloryAmmoShare * Scale);
		if (Got > 0 && W.AmmoAmount(0) < W.MaxAmmo(0))
		{
			W.AddAmmo(Got, 0);
			bAmmo = true;
		}
	}
	B = Spawn(class'KFGloryBurst', Killer,, M.Location);
	if (B != None)
	{
		B.Instigator = Killer;
		B.Health = 3 + Rand(2);
		if (bAmmo)
			B.Ammo = 3;
		if (Armour > 0)
			B.Armour = 2;
		if (Level.NetMode != NM_DedicatedServer)
			B.SetTimer(0.02, false);
	}
}

function bool WaveRunning()
{
    return bEndlessWaveActive || bWaveBossInProgress;
}

// A holdout still spawning
function bool HoldoutSpawning()
{
    return bEndlessWaveActive && CurrentWaveType == EWT_Holdout && HoldoutEndTime > 0;
}

// The next wave made of a kind: normal, siren, shade, boss or holdout. False for any other word
function bool ForceNextWave(string Kind)
{
    if (Kind ~= "normal")
        ForcedNextType = EWT_Normal;
    else if (Kind ~= "siren" || Kind ~= "sirens")
        ForcedNextType = EWT_Siren;
    else if (Kind ~= "shade" || Kind ~= "shades")
        ForcedNextType = EWT_Shade;
    else if (Kind ~= "boss" || Kind ~= "patriarch")
        ForcedNextType = EWT_Boss;
    else if (Kind ~= "holdout")
        ForcedNextType = EWT_Holdout;
    else if (Kind ~= "Lockdown")
        ForcedNextType = EWT_Lockdown;
    else
        return false;
    bForceNextType = true;
    return true;
}

function string WaveTypeName()
{
    return Mid(string(GetEnum(enum'EEndlessWaveType', CurrentWaveType)), 4);
}

function bool RiverOn()
{
    return bRiver && bEndlessWaveActive && !bWaveBossInProgress && CurrentWaveType == EWT_Holdout;
}

// Seconds a specimen of the river: shorter each wave, swelling and ebbing over RiverSurgePeriod
function float RiverGapNow()
{
    local float G;

    G = FMax(RiverGap - float(WaveNum) * RiverGapPerWave, RiverMinGap);
    if (RiverSurgePeriod > 0)
        G /= 1.0 + RiverSurge * Sin(2.0 * Pi * Level.TimeSeconds / RiverSurgePeriod);
    return G;
}

// Source K, moved first if its time is up or a player has come near it or is about to see it. The best area by
// the usual rating, not the other source's: the one just used is out of the running for a while
function ZombieVolume RiverSourceFor(int K)
{
    local int i;

    if (RiverSrc[K] == None || Level.TimeSeconds >= RiverShiftAt[K] || AreaClashes(RiverSrc[K]))
    {
        RiverSrc[K] = FindSourceApart(K);
        if (RiverSrc[K] == None)
            RiverSrc[K] = FindSpawningVolume();
        for (i = 0; i < ArrayCount(RiverSrc) && RiverSrc[K] != None; i++)
            if (i != K && RiverSrc[i] == RiverSrc[K])
                RiverSrc[K] = None;
        if (RiverSrc[K] != None)
            LastSpawnLocation = RiverSrc[K].Location;
        RiverShiftAt[K] = Level.TimeSeconds + RiverShiftMin + FRand() * (RiverShiftMax - RiverShiftMin);
    }
    return RiverSrc[K];
}

// A source for slot K: the best spawn area by the usual rating that is at least HordeSpreadAngle round the players
// from every other source (one closer in angle loses out to any that is not, but is used if there is no other)
function ZombieVolume FindSourceApart(int K)
{
    local ZombieVolume Z, Best;
    local float Score, BestScore;
    local vector Mid;
    local int i;

    Mid = PlayersMiddle();
    BestScore = 1;
    foreach AllActors(class'ZombieVolume', Z)
    {
        if (KFZombieSpawnVolume(Z) != None && !KFZombieSpawnVolume(Z).bActive)
            continue;
        Score = RateZombieVolume(Z);
        if (Score <= 1)
            continue;
        for (i = 0; i < ArrayCount(RiverSrc); i++)
            if (i != K && RiverSrc[i] != None)
            {
                if (RiverSrc[i] == Z)
                    Score = -1;
                else if (AngleRound(Z.Location, RiverSrc[i].Location, Mid) < HordeSpreadAngle)
                    Score -= 6000000;
            }
        if (Score > BestScore)
        {
            BestScore = Score;
            Best = Z;
        }
    }
    return Best;
}

// The warmth of the 512-unit square Spot stands in
function int HeatCell(vector Spot)
{
    return (int(Spot.X / 512.0) + 1000) * 2000 + int(Spot.Y / 512.0) + 1000;
}

function float HeatAt(vector Spot)
{
    local int i, K;

    K = HeatCell(Spot);
    for (i = 0; i < HeatKey.Length; i++)
        if (HeatKey[i] == K)
            return HeatVal[i];
    return 0;
}

function AddHeat(vector Spot)
{
    local int i, K;

    K = HeatCell(Spot);
    for (i = 0; i < HeatKey.Length; i++)
        if (HeatKey[i] == K)
        {
            HeatVal[i] += 1.0;
            return;
        }
    HeatKey[HeatKey.Length] = K;
    HeatVal[HeatVal.Length] = 1.0;
}

function CoolHeat()
{
    local int i;

    for (i = HeatKey.Length - 1; i >= 0; i--)
    {
        HeatVal[i] *= ApproachHeatKeep;
        if (HeatVal[i] < 0.05)
        {
            HeatKey.Remove(i, 1);
            HeatVal.Remove(i, 1);
        }
    }
}

// Row R's first stop: a plain path node ApproachMinDist to ApproachMaxDist from the players, at about the players'
// height, in the coldest part of the map the river has been through, nearest the bearing of side R of
// ApproachSides round them between parts about as cold (a little give either way)
function NavigationPoint ApproachNode(int R)
{
    local NavigationPoint N, Best;
    local vector Mid, D, Want;
    local float Ang, Dist, Score, BestScore;

    Mid = PlayersMiddle();
    if (Mid == vect(0,0,0))
        return None;
    Ang = 2.0 * Pi * ((R % Max(ApproachSides, 1)) + 0.6 * (FRand() - 0.5)) / float(Max(ApproachSides, 1));
    Want.X = Cos(Ang);
    Want.Y = Sin(Ang);
    BestScore = -2;
    for (N = Level.NavigationPointList; N != None; N = N.NextNavigationPoint)
    {
        if (N.bSpecialMove || LiftCenter(N) != None || LiftExit(N) != None || Ladder(N) != None || Door(N) != None)
            continue;
        if (Abs(N.Location.Z - Mid.Z) > 400)
            continue;
        D = N.Location - Mid;
        D.Z = 0;
        Dist = VSize(D);
        if (Dist < ApproachMinDist || Dist > ApproachMaxDist)
            continue;
        Score = (Normal(D) Dot Want) - ApproachHeatWeight * HeatAt(N.Location) + 0.05 * FRand();
        if (Score > BestScore)
        {
            BestScore = Score;
            Best = N;
        }
    }
    return Best;
}

// Where the living players are, on average
function vector PlayersMiddle()
{
    local Controller C;
    local vector Sum;
    local int n;

    for (C = Level.ControllerList; C != None; C = C.NextController)
        if (MonsterController(C) == None && C.Pawn != None && C.Pawn.Health > 0)
        {
            Sum += C.Pawn.Location;
            n++;
        }
    if (n == 0)
        return Sum;
    return Sum / float(n);
}

// Degrees between A and B seen from Mid, across the ground
function float AngleRound(vector A, vector B, vector Mid)
{
    A -= Mid;
    B -= Mid;
    A.Z = 0;
    B.Z = 0;
    if (VSize(A) < 1 || VSize(B) < 1)
        return 180;
    return Acos(FClamp(Normal(A) Dot Normal(B), -1.0, 1.0)) * 180.0 / Pi;
}

// A horde: every source chosen afresh round the players
function StartHorde()
{
    local int i;

    for (i = 0; i < Clamp(RiverSources, 1, 4); i++)
        RiverShiftAt[i] = 0;
    for (i = 0; i < Clamp(RiverSources, 1, 4); i++)
        RiverSourceFor(i);
}

// The next row of the river: up to RiotRowSize specimens from the front of the squad queue, side by side across
// the way from the source to the nearest player; each told its row and its place in it. Returns how many came
function int RiverRow()
{
    local int K, i, n, Want, Row;
    local ZombieVolume Z;
    local vector Fwd, Right;
    local float Off;
    local class<Monster> C;
    local Monster M;
    local KFMonsterController MC;
    local NavigationPoint Via;
    local bool bViaTried;

    K = RowsLoosed % Clamp(RiverSources, 1, 4);
    Z = RiverSourceFor(K);
    // (no room for this one: the first source that has one)
    for (i = 0; Z == None && i < Clamp(RiverSources, 1, 4); i++)
        if (i != K)
        {
            K = i;
            Z = RiverSourceFor(i);
        }
    if (Z == None)
        return 0;

    Fwd = WayToPlayers(Z.Location);
    Right.X = -Fwd.Y;
    Right.Y = Fwd.X;
    Want = Clamp(RiotRowSize, 1, 8);
    Row = RowsLoosed % 32;
    bStraightSpawn = true;
    for (i = 0; i < Want && TotalMaxMonsters > 0; i++)
    {
        if (RiotClass != None)
            C = RiotClass;
        else
        {
            if (NextSpawnSquad.Length == 0)
                BuildNextSquad();
            if (NextSpawnSquad.Length == 0)
                break;
            C = NextSpawnSquad[0];
        }
        // (every other row half a place across, so that rows pack into a crowd rather than ranks)
        Off = (float(i) - 0.5 * float(Want - 1) + 0.5 * (RowsLoosed % 2)) * (2.0 * C.default.CollisionRadius + RiotSpacing);
        M = RowSpawn(Z, C, Off, Fwd, Right);
        if (M == None)
            continue;
        if (RiotClass == None)
            NextSpawnSquad.Remove(0, 1);
        n++;
        MC = KFMonsterController(M.Controller);
        if (MC != None && Want > 1)
        {
            MC.RiotRow = Row;
            MC.RiotLane = Off;
            MC.bRiotRush = bRiotRush;
        }
        if (MC != None && bSpreadApproach)
        {
            if (Via == None && !bViaTried)
            {
                Via = ApproachNode(RowsLoosed);
                bViaTried = true;
            }
            if (Via != None)
            {
                MC.InitialPathGoal = Via;
                MC.PathFindState = 1;
            }
        }
    }
    bStraightSpawn = false;
    if (n == 0)
        RiverShiftAt[K] = 0;    // no room there: this source moves on the next beat
    else
    {
        RowsLoosed++;
        BoostHoldoutZeds();
    }
    return n;
}

// Flat way from Spot to the nearest player
function vector WayToPlayers(vector Spot)
{
    local Controller C;
    local vector Best, D;
    local float BestDist;

    BestDist = -1;
    for (C = Level.ControllerList; C != None; C = C.NextController)
        if (MonsterController(C) == None && C.Pawn != None && C.Pawn.Health > 0)
        {
            D = C.Pawn.Location - Spot;
            D.Z = 0;
            if (BestDist < 0 || VSize(D) < BestDist)
            {
                BestDist = VSize(D);
                Best = D;
            }
        }
    if (VSize(Best) < 1)
        Best = vect(1,0,0);
    return Normal(Best);
}

// One of a row at its place Off across the way from the source's middle; else a step back; else the first free
// place on two rings round the middle
function Monster RowSpawn(ZombieVolume Z, class<Monster> C, float Off, vector Fwd, vector Right)
{
    local vector Spot, Dir;
    local float R;
    local int i;
    local Monster M;

    R = C.default.CollisionRadius;
    for (i = 0; i < 18; i++)
    {
        if (i == 0)
            Spot = Z.Location + Right * Off;
        else if (i == 1)
            Spot = Z.Location + Right * Off - Fwd * (2.0 * R + RiotSpacing);
        else
        {
            Dir.X = Cos(float(i) * Pi / 4.0);
            Dir.Y = Sin(float(i) * Pi / 4.0);
            Spot = Z.Location + Dir * R * (3.0 + 3.0 * float((i - 2) / 8));
        }
        if (i > 0 || Abs(Off) > 1)
        {
            if (!FastTrace(Spot, Z.Location) || !SpotFloored(Spot))
                continue;
        }
        if (SpotTaken(Spot, C))
            continue;
        M = Spawn(C,,, Spot, rotator(Fwd));
        if (M != None)
        {
            TotalMaxMonsters--;
            WaveMonsters++;
            NumMonsters++;
            Z.LastSpawnedTime = Level.TimeSeconds;
            Z.SpawnCount++;
            return M;
        }
    }
    return None;
}

function bool SpotFloored(vector Spot)
{
    local vector HitL, HitN;

    return Trace(HitL, HitN, Spot - vect(0,0,400), Spot, false) != None;
}

// A body in the way of one of class C at Spot. The engine tests bodies as boxes, so this does too: a spawn into
// one would be made and then thrown away
function bool SpotTaken(vector Spot, class<Monster> C)
{
    local Pawn P;
    local vector D;

    foreach CollidingActors(class'Pawn', P, 4.0 * C.default.CollisionRadius, Spot)
    {
        D = P.Location - Spot;
        if (Abs(D.X) < P.CollisionRadius + C.default.CollisionRadius + 2 && Abs(D.Y) < P.CollisionRadius + C.default.CollisionRadius + 2
            && Abs(D.Z) < P.CollisionHeight + C.default.CollisionHeight)
            return true;
    }
    return false;
}

// Each riot row's average distance from its victims, for the ones ahead to ease off
function UpdateRiotRows()
{
    local Controller C;
    local KFMonsterController MC;
    local float Sum[32];
    local int Num[32], i;

    if (RiverOn())
    {
        if (bSpreadApproach)
            CoolHeat();
        CoolTraffic();
    }
    for (C = Level.ControllerList; C != None; C = C.NextController)
    {
        MC = KFMonsterController(C);
        if (MC != None && MC.Pawn != None && bSpreadApproach && RiverOn())
            AddHeat(MC.Pawn.Location);
        if (MC != None && MC.Pawn != None && RiverOn() && KFMonster(MC.Pawn) != None && KFMonster(MC.Pawn).bFixedPace)
            AddTraffic(NavigationPoint(MC.MoveTarget), 0.25);
        if (MC != None && MC.RiotRow >= 0 && MC.Pawn != None && MC.Enemy != None)
        {
            Sum[MC.RiotRow % 32] += VSize(MC.Enemy.Location - MC.Pawn.Location);
            Num[MC.RiotRow % 32]++;
        }
    }
    for (i = 0; i < 32; i++)
    {
        if (Num[i] > 0)
            RiotRowDist[i] = Sum[i] / float(Num[i]);
        else
            RiotRowDist[i] = 0;
    }
}

event Tick(float DeltaTime)
{
    local int n;
    local float G;

    Super.Tick(DeltaTime);

    if (RiverOn() && !bSpawnsPaused && TotalMaxMonsters > 0 && HordeLength > 0 && Level.TimeSeconds >= NextHordeTime)
    {
        HordeUntil = Level.TimeSeconds + HordeLength;
        if (HordeEvery > 0)
            NextHordeTime = Level.TimeSeconds + HordeEvery;
        else
            NextHordeTime = Level.TimeSeconds + 1000000;
        StartHorde();
    }
    if (RiverOn() && !bSpawnsPaused && TotalMaxMonsters > 0 && Level.TimeSeconds >= RiverNextTime && NumMonsters + Clamp(RiotRowSize, 1, 8) <= MaxMonsters)
    {
        n = RiverRow();
        G = RiverGapNow();
        if (Level.TimeSeconds < HordeUntil)
            G *= HordeGapScale;
        RiverNextTime = Level.TimeSeconds + G * float(Max(n, 1));
        WaveEndTime = Level.TimeSeconds + 160.0;
    }
    if (Level.TimeSeconds >= NextRowCheck)
    {
        NextRowCheck = Level.TimeSeconds + 0.25;
        UpdateRiotRows();
    }
}

// Override AddSquad to boost monster speed during holdout waves
function bool AddSquad()
{
    local bool Result;

    Result = Super.AddSquad();

    if (Result && CurrentWaveType == EWT_Holdout)
        BoostHoldoutZeds();

    return Result;
}

// A stuck or stranded specimen back in the queue (KFGameType's version waits for bWaveInProgress, never set here)
function bool RecycleMonster(KFMonster M)
{
    if (!bEndlessWaveActive || bWaveBossInProgress || bGameEnded || M.bBoss)
        return false;
    RecycledSquad[RecycledSquad.Length] = M.Class;
    TotalMaxMonsters++;
    LastZVol = None;
    if (M == LootZed)
    {
        // another one gets its power-up (it would be dropped where this one was stuck)
        M.bLootCarrier = false;
        LootZed = None;
        LootAt = 1;
    }
    M.KilledBy(M);
    return true;
}

function BoostHoldoutZeds()
{
    local Controller C;
    local KFMonster M;
    local int i;
    local bool AlreadyBoosted;
    local float F;

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
                    if (RushSpeed > 0)
                    {
                        // (one pace for every kind: RushSpeed seen, RushHiddenSpeed out of sight)
                        M.OriginalGroundSpeed = RushSpeed;
                        M.SetGroundSpeed(RushSpeed);
                        M.HiddenGroundSpeed = FMax(RushSpeed, RushHiddenSpeed);
                        M.bFixedPace = true;
                    }
                    else
                    {
                        M.OriginalGroundSpeed *= 1.5 + float(WaveNum) * 0.02; // Scale speed boost with wave number for extra challenge
                        M.SetGroundSpeed(M.GroundSpeed * (1.5 + float(WaveNum) * 0.02));
                        M.HiddenGroundSpeed *= 1.5 + float(WaveNum) * 0.02;
                    }
                    // (and frailer: a holdout is a fight to cut through)
                    F = float(M.Health) * HoldoutHealthScale;
                    M.Health = Max(1, int(F));
                    M.HealthMax *= HoldoutHealthScale;
                    M.HeadHealth *= HoldoutHealthScale;
                    FastZEDs[FastZEDs.Length] = M;
                }
            }
        }
    }
}

// ---- Power-ups -------------------------------------------------------------------------------------------------------

function Killed(Controller Killer, Controller Killed, Pawn KilledPawn, class<DamageType> damageType)
{
    local KFMonster M;

    M = KFMonster(KilledPawn);
    Super.Killed(Killer, Killed, KilledPawn, damageType);
    if (!bPowerUps || M == None)
        return;
    if (M == LootZed)
    {
        LootZed = None;
        DropPowerUp(M.Location);
    }
    else if (!bNuking && Killer != None && Killer.bIsPlayer)
        TryDropPowerUp(M.Location);
}

// Insta-Kill: every hit on a specimen by a player or bot kills it (not the Patriarch)
function int ReduceDamage(int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
    Damage = Super.ReduceDamage(Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);
    if (Damage > 0 && Level.TimeSeconds < InstaKillEndTime && KFMonster(injured) != None && !KFMonster(injured).bBoss
        && KFHumanPawn(instigatedBy) != None)
        Damage = Max(Damage, injured.Health);
    return Damage;
}

// Double Dosh
function float KillCashScale()
{
    if (Level.TimeSeconds < DoublePointsEndTime)
        return 2.0;
    return 1.0;
}

function TryDropPowerUp(vector DropLocation)
{
    if (PowerUpClasses.Length == 0 || PowerUpsThisRound >= MaxPowerUpsPerRound || FRand() > PowerUpDropChance)
        return;
    if (DropPowerUp(DropLocation))
        PowerUpsThisRound++;
}

function bool DropPowerUp(vector DropLocation)
{
    local class<KFZombiesPowerUp> C;

    if (PowerUpClasses.Length == 0)
        return false;
    C = PowerUpClasses[Rand(PowerUpClasses.Length)];
    return Spawn(C,,, DropSpot(DropLocation)) != None || Spawn(C,,, DropLocation) != None;
}

// Where a power-up dropped at From goes: on the floor there when that is open ground beside a path node players can
// walk to, at about its height; else on the nearest such node. (A specimen dies on a ledge, up a wall, on a shelf,
// or in its own zone behind the fence.)
function vector DropSpot(vector From)
{
    local vector HL, HN, Spot;
    local NavigationPoint N, Best;
    local float D, BestD;
    local int i;

    if (!bDropNodesFound)
        FindDropNodes();
    if (DropNodes.Length == 0)
        return From;
    if (Trace(HL, HN, From - vect(0,0,300), From, false, vect(16,16,16)) != None && HN.Z > 0.7)
    {
        Spot = HL + vect(0,0,24);
        for (i = 0; i < DropNodes.Length; i++)
        {
            N = DropNodes[i];
            if (N == None || Abs(N.Location.Z - Spot.Z) > 45.0 || VSize((N.Location - Spot) * vect(1,1,0)) > 500.0)
                continue;
            // (traced in from the node, which is outside any blocker: a spot inside one is caught as the line goes in)
            if (Trace(HL, HN, N.Location, Spot, false, vect(10,10,10)) == None && !CrossesPlayerBlocker(N.Location, Spot))
                return Spot;
        }
    }
    BestD = 1000000.0;
    for (i = 0; i < DropNodes.Length; i++)
    {
        if (DropNodes[i] == None)
            continue;
        D = VSize(DropNodes[i].Location - From);
        if (D < BestD)
        {
            BestD = D;
            Best = DropNodes[i];
        }
    }
    if (Best == None)
        return From;
    return Best.Location;
}

// The path nodes players can walk to: from the player starts along the links a person fits (no flying; the builder
// records UT's 26 by 44 as its smallest size, which KF's players use) that neither cross nor end in a volume that
// blocks only players (KF's zombie zones). Lifts, doors and jump spots are left out as places to put one.
function FindDropNodes()
{
    local NavigationPoint N, E;
    local ReachSpec Spec;
    local BlockingVolume V;
    local array<NavigationPoint> Queue;
    local int i, k;

    bDropNodesFound = true;
    DropNodes.Length = 0;
    PlayerBlockers.Length = 0;
    foreach AllActors(class'BlockingVolume', V)
        if (PlayerBlocker(V))
            PlayerBlockers[PlayerBlockers.Length] = V;
    // (visitedWeight marks those found: a path search sets it afresh for every node when it starts)
    for (N = Level.NavigationPointList; N != None; N = N.nextNavigationPoint)
    {
        N.visitedWeight = 0;
        if (PlayerStart(N) != None && !InPlayerBlocker(N))
        {
            N.visitedWeight = 1;
            Queue[Queue.Length] = N;
        }
    }
    for (i = 0; i < Queue.Length; i++)
    {
        N = Queue[i];
        for (k = 0; k < N.PathList.Length; k++)
        {
            Spec = N.PathList[k];
            if (Spec == None || Spec.End == None)
                continue;
            E = Spec.End;
            if (E.visitedWeight == 1 || Spec.CollisionRadius < 20 || Spec.CollisionHeight < 40 || (Spec.reachFlags & (2 | 128)) != 0
                || InPlayerBlocker(E) || CrossesPlayerBlocker(N.Location, E.Location))
                continue;
            E.visitedWeight = 1;
            Queue[Queue.Length] = E;
        }
    }
    for (i = 0; i < Queue.Length; i++)
        if (LiftCenter(Queue[i]) == None && LiftExit(Queue[i]) == None && Door(Queue[i]) == None && JumpSpot(Queue[i]) == None)
            DropNodes[DropNodes.Length] = Queue[i];
    for (N = Level.NavigationPointList; N != None; N = N.nextNavigationPoint)
        N.visitedWeight = 0;
    log("Power-up drop nodes:" @ DropNodes.Length @ "of" @ Queue.Length @ "reached from the player starts");
}

// A volume that blocks players and not specimens (KFInvasionBot.VerifyBlockingVolume)
function bool PlayerBlocker(BlockingVolume V)
{
    local bool bPlayers, bMonsters;
    local int i;

    if (V == None || !V.bClassBlocker)
        return false;
    for (i = 0; i < V.BlockedClasses.Length; i++)
    {
        bPlayers = bPlayers || ClassIsChildOf(V.BlockedClasses[i], class'KFHumanPawn');
        bMonsters = bMonsters || ClassIsChildOf(V.BlockedClasses[i], class'KFMonster');
    }
    return bPlayers && !bMonsters;
}

function bool InPlayerBlocker(Actor A)
{
    local int i;

    for (i = 0; i < PlayerBlockers.Length; i++)
        if (PlayerBlockers[i] != None && PlayerBlockers[i].Encompasses(A))
            return true;
    return false;
}

// (going in from A: a line that starts inside a brush is not seen to leave it)
function bool CrossesPlayerBlocker(vector A, vector B)
{
    local vector HL, HN;
    local int i;

    for (i = 0; i < PlayerBlockers.Length; i++)
        if (PlayerBlockers[i] != None && !PlayerBlockers[i].TraceThisActor(HL, HN, B, A))
            return true;
    return false;
}

function PowerUpMessage(string S)
{
    local Controller C;

    if (S == "")
        return;
    for (C = Level.ControllerList; C != None; C = C.NextController)
        if (PlayerController(C) != None)
            PlayerController(C).ClientMessage(S, 'CriticalEvent');
}

function UpdatePowerUpTimers()
{
    local KFGameReplicationInfo KFGRI;

    KFGRI = KFGameReplicationInfo(GameReplicationInfo);
    if (KFGRI == None)
        return;
    KFGRI.InstaKillTime = Clamp(int(InstaKillEndTime - Level.TimeSeconds + 0.5), 0, 255);
    KFGRI.DoublePointsTime = Clamp(int(DoublePointsEndTime - Level.TimeSeconds + 0.5), 0, 255);
}

function StartInstaKill()
{
    InstaKillEndTime = Level.TimeSeconds + PowerUpDuration;
    UpdatePowerUpTimers();
}

function StartDoublePoints()
{
    DoublePointsEndTime = Level.TimeSeconds + PowerUpDuration;
    UpdatePowerUpTimers();
}

// Every player's and bot's guns full, grenades and the syringe's charge too
function GiveMaxAmmo()
{
    local Controller C;
    local Inventory Inv;

    for (C = Level.ControllerList; C != None; C = C.NextController)
    {
        if (!C.bIsPlayer || KFHumanPawn(C.Pawn) == None || C.Pawn.Health <= 0)
            continue;
        for (Inv = C.Pawn.Inventory; Inv != None; Inv = Inv.Inventory)
            if (KFWeapon(Inv) != None && KFMeleeGun(Inv) == None)
                KFWeapon(Inv).MaxOutAmmo();
    }
}

// Every specimen alive dies (not the Patriarch); those still to come in the wave come
function Nuke()
{
    local Controller C, Next;

    bNuking = true;
    for (C = Level.ControllerList; C != None; C = Next)
    {
        Next = C.NextController;
        if (MonsterController(C) != None && KFMonster(C.Pawn) != None && C.Pawn.Health > 0 && !KFMonster(C.Pawn).bBoss)
            C.Pawn.KilledBy(C.Pawn);
    }
    bNuking = false;
}

// At a wave's start: whether it has a loot specimen, and after how many of the wave's specimens it is picked
function PlanLoot()
{
    PowerUpsThisRound = 0;
    LootZed = None;
    LootAt = 0;
    if (bPowerUps && !bWaveBossInProgress && CurrentWaveType != EWT_Boss && FRand() < LootWaveChance)
        LootAt = Max(2, int((LootFromShare + FRand() * (LootToShare - LootFromShare)) * float(Min(TotalMaxMonsters, 80))));
}

// Once that many have come: one of those alive that no player sees (it would light up before their eyes), at random
function LootCheck()
{
    local Controller C;
    local KFMonster M, Pick;
    local int n;

    if (LootAt <= 0 || LootZed != None || !bEndlessWaveActive || bWaveBossInProgress || ZombiesKilled + NumMonsters < LootAt)
        return;
    for (C = Level.ControllerList; C != None; C = C.NextController)
    {
        M = KFMonster(C.Pawn);
        if (MonsterController(C) == None || M == None || M.Health <= 0 || M.bBoss || M.PlayerCanSeeMe())
            continue;
        n++;
        if (Rand(n) == 0)
            Pick = M;
    }
    if (Pick == None)
        return;
    LootAt = 0;
    LootZed = Pick;
    Pick.bLootCarrier = true;
    Pick.NetUpdateTime = Level.TimeSeconds - 1;
    PowerUpMessage(LootMessage);
}

defaultproperties
{
     BossPool(0)="KFChar.ZombieBoss"
     BossPool(1)="KFChar.ZombieKingFleshpound"
     BossPool(2)="KFChar.ZombieAbomination"
     LockdownChance=0.000000
     LockdownFrom=3
     bGloryKills=True
     GloryShare=0.250000
     GloryWindow=3.500000
     GloryReach=95.000000
     GloryHealth=20
     GloryArmour=10
     GloryAmmoShare=0.080000
     GloryLockdownScale=1.500000
    bPowerUps=True
    PowerUpDropChance=0.025000
    MaxPowerUpsPerRound=3
    PowerUpDuration=30.000000
    PowerUpClasses(0)=Class'KFMod.KFPowerUpMaxAmmo'
    PowerUpClasses(1)=Class'KFMod.KFPowerUpInstaKill'
    PowerUpClasses(2)=Class'KFMod.KFPowerUpDoublePoints'
    PowerUpClasses(3)=Class'KFMod.KFPowerUpNuke'
    LootWaveChance=0.500000
    LootFromShare=0.200000
    LootToShare=0.700000
    LootMessage="Something out there is glowing... it carries a power-up!"
    WaveHealthClimb=0.015000
    WaveDamageClimb=0.030000
    DamageClimbWaves=10
    InitialCountDownValue=15
    bRiver=True
    RiverGap=0.370000
    RiverGapPerWave=0.005000
    RiverMinGap=0.150000
    HoldoutChance=0.250000
    HoldoutCapScale=2.000000
    HoldoutLength=60.000000
    HoldoutHealthScale=0.600000
    RiverSurge=0.500000
    RiverSurgePeriod=30.000000
    RiverShiftMin=20.000000
    RiverShiftMax=40.000000
    RiverSources=4
    HordeLength=8.000000
    HordeEvery=30.000000
    HordeGapScale=0.250000
    HordeSpreadAngle=60.000000
    bSpreadApproach=True
    ApproachSides=6
    ApproachMinDist=700.000000
    ApproachMaxDist=2400.000000
    ApproachHeatWeight=0.050000
    ApproachHeatKeep=0.988000
    RiotRowSize=4
    RiotSpacing=16.000000
    bRiotRush=True
    RushSpeed=260.000000
    RushHiddenSpeed=600.000000
    bUseEndGameBoss=False
    FinalWave=99999
    GameName="Endless Killing Floor"
    Description="Survive endless waves of specimens. The trader is always open. How long can you last?"
}