class KFZombiesGameType extends KFEndlessGameType;

var() float BaseWaveMonsters;
var() float MonstersPerWave;
var() float MonstersPerExtraPlayer;

var() int BaseConcurrentCap;
var() float ConcurrentCapPerWave;
var() int ConcurrentCapPerExtraPlayer;

var() float BaseSpawnInterval;
var() float MaxSpawnInterval;
var() float SpawnIntervalWaveDecay;
var() float TrickleInterval;

var() int NormalSquadCap, HoldoutSquadCap;

var() int RoundBreakTime;

var() float HealthScalePerRound, LateRoundHealthScale;
var() int LateRoundStart;

var() int HitPoints, KillPoints, HeadshotKillPoints, MeleeKillPoints;
var() int RevivePoints, NukePoints, CarpenterPoints;

var() float UpgradedDamageScale;
var() int RoundGrenades;

var() float StuckCheckInterval, StuckMoveDist, StuckPlayerDist;

struct StuckInfo
{
    var KFMonster M;
    var vector Loc;
};
var() bool bBotZombiePawns;  // bots on the mode's pawn (SpawnBot)
var array<StuckInfo> StuckList;
var float NextStuckCheckTime;

var array<KFMonster> ScaledZeds;

var KFMonster LastKilledMonster;
var class<DamageType> LastKillDamageType;

event InitGame( string Options, out string Error )
{
    Super.InitGame(Options, Error);
    StartingCash = 500;
    GameDifficulty = 3.0;
    bPerksEnabled = False; // Nope!
    InitialCountDownValue = RoundBreakTime;

    HoldoutMonsterClasses.Length = 4;
    HoldoutMonsterClasses[0] = class<KFMonster>(DynamicLoadObject("KFChar.ZombieClotZombies", class'Class'));
    HoldoutMonsterClasses[1] = class<KFMonster>(DynamicLoadObject("KFChar.ZombieGorefastZombies", class'Class'));
    HoldoutMonsterClasses[2] = class<KFMonster>(DynamicLoadObject("KFChar.ZombieWretchZombies", class'Class'));
    HoldoutMonsterClasses[3] = class<KFMonster>(DynamicLoadObject("KFChar.ZombieStalkerZombies", class'Class'));
}

event PostNetBeginPlay()
{
    local KFBarricadePlank Plank;

    Super.PostNetBeginPlay();

    KFGameReplicationInfo(GameReplicationInfo).bZombiesMode = true;

    PowerUpClasses.Length = 4;
    PowerUpClasses[0] = class'KFPowerUpMaxAmmo';
    PowerUpClasses[1] = class'KFPowerUpInstaKill';
    PowerUpClasses[2] = class'KFPowerUpDoublePoints';
    PowerUpClasses[3] = class'KFPowerUpNuke';

    foreach DynamicActors(class'KFBarricadePlank', Plank)
    {
        PowerUpClasses[4] = class'KFPowerUpCarpenter';
        break;
    }
}

//Gotta override this shit
static function FillPlayInfo(PlayInfo PlayInfo)
{
    Super(Info).FillPlayInfo(PlayInfo);

    PlayInfo.AddSetting(default.GameGroup,"MinRespawnCash", "Min Respawn Cash amount",70,0,"Text","200;0:5000");

    PlayInfo.AddSetting(default.RulesGroup,"bNoBots", GetDisplayText("bNoBots"),	1, 0, "Check",				,				,True,True);
    PlayInfo.AddSetting(default.RulesGroup,  "bAllowBehindView",		GetDisplayText("bAllowBehindview"),	1, 0, "Check",				,				,True,True);
    PlayInfo.AddSetting(default.RulesGroup,"bNoLateJoiners", GetDisplayText("bNoLateJoiners"),	1, 0, "Check",				,				,True,True);

    PlayInfo.AddSetting(default.ServerGroup, "LobbyTimeOut",			GetDisplayText("LobbyTimeOut"),			0, 1, "Text",		"3;0:120",				,True,True);
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

// Bots get the mode's pawn as players do: the perk machines serve them, and they carry what players carry (no syringe
// or welder). Only players go down (PreventDeath), so a bot still dies as before.
function Bot SpawnBot(optional string botName)
{
    local Bot B;

    B = Super.SpawnBot(botName);
    if (B != None && bBotZombiePawns)
        B.PawnClass = class'KFHumanPawnZombies';
    return B;
}

function bool IsSoloGame()
{
    return NumPlayers + NumBots <= 1;
}

function EEndlessWaveType GetWaveType(int Wave)
{
    local int DisplayWave;
    DisplayWave = Wave + 1;

    if (DisplayWave >= 5 && (DisplayWave % 5) == 0)
        return EWT_Shade;

    return EWT_Normal;
}

function bool IsAllowedMonsterClass(class<Monster> MC)
{
    local int i;

    for (i = 0; i < HoldoutMonsterClasses.Length; i++)
        if (HoldoutMonsterClasses[i] == MC)
            return true;
    return false;
}

function float GetWaveTotalMonsters(EEndlessWaveType WType)
{
    local float NewMaxMonsters;

    NewMaxMonsters = BaseWaveMonsters + float(WaveNum) * MonstersPerWave
        + FMax(0, NumPlayers + NumBots - 1) * MonstersPerExtraPlayer;

    if (WType != EWT_Normal)
        NewMaxMonsters *= 0.75;

    return NewMaxMonsters;
}

function int GetWaveConcurrentCap(int TotalMax)
{
    local int RoundCap;

    RoundCap = BaseConcurrentCap + int(float(WaveNum) * ConcurrentCapPerWave)
        + Max(0, NumPlayers + NumBots - 1) * ConcurrentCapPerExtraPlayer;
    return Clamp(TotalMax, 3, Max(3, Min(MaxZombiesOnce, RoundCap)));
}

function float GetSpawnInterval()
{
    if (NextSpawnSquad.Length > 0)
        return TrickleInterval;
    return FMax(MaxSpawnInterval - float(WaveNum) * SpawnIntervalWaveDecay, BaseSpawnInterval);
}

function float GetRoundHealthScale()
{
    if (WaveNum < LateRoundStart)
        return 1.0 + HealthScalePerRound * float(WaveNum);
    return (1.0 + HealthScalePerRound * float(LateRoundStart)) * (LateRoundHealthScale ** float(WaveNum - LateRoundStart));
}

function SetupWave()
{
    ScaledZeds.Length = 0;
    StuckList.Length = 0;
    PowerUpsThisRound = 0;
    NextStuckCheckTime = Level.TimeSeconds + StuckCheckInterval;

    Super.SetupWave();
}

function BuildNextSquad()
{
    local int Cap, i;

    Super.BuildNextSquad();

    if (CurrentWaveType == EWT_Normal)
    {
        for (i = 0; i < NextSpawnSquad.Length; i++)
        {
            if (!IsAllowedMonsterClass(NextSpawnSquad[i]))
                NextSpawnSquad[i] = HoldoutMonsterClasses[Rand(HoldoutMonsterClasses.Length)];
        }
    }

    if (CurrentWaveType == EWT_Holdout)
        Cap = HoldoutSquadCap;
    else
        Cap = NormalSquadCap;
    if (NextSpawnSquad.Length > Cap)
        NextSpawnSquad.Length = Cap;
}

function bool AddSquad()
{
    local bool Result;

    Result = Super.AddSquad();
    if (Result)
        ScaleNewZeds();
    return Result;
}

function ScaleNewZeds()
{
    local Controller C;
    local KFMonster M;
    local float Scale;
    local int i;
    local bool bDone;

    Scale = GetRoundHealthScale();

    for (C = Level.ControllerList; C != None; C = C.NextController)
    {
        M = KFMonster(C.Pawn);
        if (MonsterController(C) == None || M == None || M.Health <= 0)
            continue;

        bDone = false;
        for (i = 0; i < ScaledZeds.Length; i++)
        {
            if (ScaledZeds[i] == M)
            {
                bDone = true;
                break;
            }
        }
        if (bDone)
            continue;

        ScaledZeds[ScaledZeds.Length] = M;
        M.Health *= Scale;
        M.HealthMax *= Scale;
        M.HeadHealth *= Scale;
    }
}

event Tick(float DeltaTime)
{
    Super.Tick(DeltaTime);

    if (bEndlessWaveActive && !bWaveBossInProgress && !bGameEnded && TotalMaxMonsters > 0
        && Level.TimeSeconds > NextMonsterTime && NumMonsters + NextSpawnSquad.Length <= MaxMonsters)
    {
        AddSquad();
        NextMonsterTime = Level.TimeSeconds + GetSpawnInterval();
    }
}

function bool HasStandingTeammate(Pawn Ignore)
{
    local Controller C;
    local KFHumanPawn P;

    for (C = Level.ControllerList; C != None; C = C.NextController)
    {
        P = KFHumanPawn(C.Pawn);
        if (C.bIsPlayer && P != None && P != Ignore && P.Health > 0 && !P.bIsDowned)
            return true;
    }
    return false;
}

function ExpireDownedPlayers()
{
    local Controller C;
    local KFHumanPawnZombies P;

    for (C = Level.ControllerList; C != None; C = C.NextController)
    {
        P = KFHumanPawnZombies(C.Pawn);
        if (P != None && P.bIsDowned && !P.bSelfReviving && P.Health > 0)
            P.ForceBleedOut();
    }
}

function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation)
{
    local KFHumanPawnZombies KFH;
    local KFPlayerReplicationInfo KFPRI;

    KFH = KFHumanPawnZombies(Killed);
    if (KFH == None || KFH.bIsDowned || bGameEnded || PlayerController(KFH.Controller) == None
        || damageType == class'Suicided' || KFH.PlayerReplicationInfo == None || KFH.PlayerReplicationInfo.bOnlySpectator)
        return Super.PreventDeath(Killed, Killer, damageType, HitLocation);

    if (HasStandingTeammate(KFH))
    {
        KFH.GoDowned();
        return true;
    }

    KFPRI = KFPlayerReplicationInfo(KFH.PlayerReplicationInfo);
    if (KFPRI != None && KFPRI.bHasQuickRevive && IsSoloGame())
    {
        KFH.GoDowned(true);
        return true;
    }

    return Super.PreventDeath(Killed, Killer, damageType, HitLocation);
}

function NotifyRevived(KFHumanPawnZombies Revived, Pawn Reviver)
{
    if (Reviver != None)
        AwardPoints(Reviver.Controller, RevivePoints);
}

function AwardPoints(Controller C, int Amount)
{
    local KFPlayerReplicationInfo KFPRI;

    if (C == None || C.PlayerReplicationInfo == None || Amount <= 0)
        return;

    if (Level.TimeSeconds < DoublePointsEndTime)
        Amount *= 2;

    C.PlayerReplicationInfo.Score += Amount;
    C.PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;

    KFPRI = KFPlayerReplicationInfo(C.PlayerReplicationInfo);
    if (KFPRI != None)
        KFPRI.ThreeSecondScore += Amount;
}

function AwardAll(int Amount)
{
    local Controller C;

    for (C = Level.ControllerList; C != None; C = C.NextController)
    {
        if (C.bIsPlayer && KFHumanPawn(C.Pawn) != None && C.Pawn.Health > 0)
            AwardPoints(C, Amount);
    }
}

function ScoreMonsterHit(KFMonster M, Pawn InstigatedBy, int Damage, class<DamageType> DamageType)
{
    if (Damage <= 0 || M.Health <= 0 || class<Burned>(DamageType) != None || class<DamTypeFlamethrower>(DamageType) != None)
        return;

    AwardPoints(InstigatedBy.Controller, HitPoints);
}

function Killed(Controller Killer, Controller Killed, Pawn KilledPawn, class<DamageType> damageType)
{
    LastKilledMonster = KFMonster(KilledPawn);
    LastKillDamageType = damageType;

    // (the power-up a kill may leave comes from KFEndlessGameType.Killed)
    Super.Killed(Killer, Killed, KilledPawn, damageType);

    LastKilledMonster = None;
}

function ScoreKill(Controller Killer, Controller Other)
{
    local int Points;

    if (LastKilledMonster == None || Other == None || Other.bIsPlayer || Killer == None || !Killer.bIsPlayer
        || Killer.PlayerReplicationInfo == None)
    {
        Super.ScoreKill(Killer, Other);
        return;
    }

    if (GameRulesModifiers != None)
        GameRulesModifiers.ScoreKill(Killer, Other);

    if (class<DamTypeMelee>(LastKillDamageType) != None)
        Points = MeleeKillPoints;
    else if (LastKilledMonster.bDecapitated)
        Points = HeadshotKillPoints;
    else
        Points = KillPoints;

    Killer.PlayerReplicationInfo.Kills++;
    AwardPoints(Killer, Points);
}

function int ReduceDamage(int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
    Damage = Super.ReduceDamage(Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);

    if (Damage > 0 && KFMonster(injured) != None && KFHumanPawn(instigatedBy) != None)
    {
        if (KFWeapon(instigatedBy.Weapon) != None && KFWeapon(instigatedBy.Weapon).bUpgraded)
            Damage *= UpgradedDamageScale;
        if (Level.TimeSeconds < InstaKillEndTime)
            Damage = Max(Damage, injured.Health);
    }

    return Damage;
}

function TryDropPowerUp(vector DropLocation)
{
    if (PowerUpClasses.Length == 0 || PowerUpsThisRound >= MaxPowerUpsPerRound || FRand() > PowerUpDropChance)
        return;

    if (Spawn(PowerUpClasses[Rand(PowerUpClasses.Length)],,, DropLocation) != None)
        PowerUpsThisRound++;
}

function PowerUpMessage(string S)
{
    local Controller C;

    if (S == "")
        return;

    for (C = Level.ControllerList; C != None; C = C.NextController)
    {
        if (PlayerController(C) != None)
            PlayerController(C).ClientMessage(S, 'CriticalEvent');
    }
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

function GiveMaxAmmo()
{
    local Controller C;
    local Inventory Inv;

    for (C = Level.ControllerList; C != None; C = C.NextController)
    {
        if (!C.bIsPlayer || KFHumanPawn(C.Pawn) == None || C.Pawn.Health <= 0)
            continue;

        for (Inv = C.Pawn.Inventory; Inv != None; Inv = Inv.Inventory)
        {
            if (KFWeapon(Inv) != None && KFMeleeGun(Inv) == None)
                KFWeapon(Inv).MaxOutAmmo();
        }
    }
}

function Nuke()
{
    bNuking = true;
    ForceKillAllMonsters();
    bNuking = false;

    AwardAll(NukePoints);
}

function Carpenter()
{
    local KFBarricadePlank Plank;

    foreach DynamicActors(class'KFBarricadePlank', Plank)
        Plank.InstantRepair();

    AwardAll(CarpenterPoints);
}

function GiveRoundGrenades()
{
    local Controller C;
    local Inventory Inv;

    for (C = Level.ControllerList; C != None; C = C.NextController)
    {
        if (!C.bIsPlayer || C.Pawn == None || C.Pawn.Health <= 0)
            continue;

        for (Inv = C.Pawn.Inventory; Inv != None; Inv = Inv.Inventory)
        {
            if (Frag(Inv) != None)
            {
                Frag(Inv).AddAmmo(RoundGrenades, 0);
                break;
            }
        }
    }
}

function bool IsFarFromPlayers(Pawn P)
{
    local Controller C;

    for (C = Level.ControllerList; C != None; C = C.NextController)
    {
        if (C.bIsPlayer && C.Pawn != None && C.Pawn.Health > 0 && VSize(C.Pawn.Location - P.Location) < StuckPlayerDist)
            return false;
    }
    return true;
}

function CheckStuckZeds()
{
    local Controller C, Next;
    local KFMonster M;
    local array<StuckInfo> NewList;
    local int i;
    local bool bFound;

    for (C = Level.ControllerList; C != None; C = Next)
    {
        Next = C.NextController;

        M = KFMonster(C.Pawn);
        if (MonsterController(C) == None || M == None || M.Health <= 0)
            continue;

        bFound = false;
        for (i = 0; i < StuckList.Length; i++)
        {
            if (StuckList[i].M == M)
            {
                bFound = true;
                break;
            }
        }

        if (bFound && VSize(StuckList[i].Loc - M.Location) < StuckMoveDist && IsFarFromPlayers(M) && !M.PlayerCanSeeMe())
        {
            TotalMaxMonsters++;
            M.KilledBy(M);
            continue;
        }

        NewList.Length = NewList.Length + 1;
        NewList[NewList.Length - 1].M = M;
        NewList[NewList.Length - 1].Loc = M.Location;
    }

    StuckList = NewList;
}

function ZombiesTimer()
{
    UpdatePowerUpTimers();

    if (!HasStandingTeammate(None))
        ExpireDownedPlayers();

    if (bEndlessWaveActive && !bWaveBossInProgress && Level.TimeSeconds >= NextStuckCheckTime)
    {
        NextStuckCheckTime = Level.TimeSeconds + StuckCheckInterval;
        CheckStuckZeds();
    }
}

function SetupEndlessDoors();

function HandleWaveMonsterPoolExhausted()
{
    if (NumMonsters <= 0)
        DoWaveEnd();
}

State MatchInProgress
{
    function Timer()
    {
        Super.Timer();

        if (!bGameEnded)
            ZombiesTimer();
    }

    function DoWaveEnd()
    {
        Super.DoWaveEnd();
        GiveRoundGrenades();
    }
}

defaultproperties
{
     bGloryKills=False
    WaveHealthClimb=0.030000
    WaveDamageClimb=0.030000
    DamageClimbWaves=0
    HiddenSpeedScale=1.000000
    BaseWaveMonsters=6.000000
    MonstersPerWave=2.000000
    MonstersPerExtraPlayer=3.000000
    BaseConcurrentCap=6
    ConcurrentCapPerWave=1.000000
    ConcurrentCapPerExtraPlayer=3
    BaseSpawnInterval=1.000000
    MaxSpawnInterval=2.500000
    SpawnIntervalWaveDecay=0.050000
    TrickleInterval=0.600000
    NormalSquadCap=2
    HoldoutSquadCap=4
    RoundBreakTime=6
    HealthScalePerRound=0.120000
    LateRoundHealthScale=1.080000
    LateRoundStart=10
    HitPoints=10
    KillPoints=60
    HeadshotKillPoints=100
    MeleeKillPoints=130
    RevivePoints=100
    NukePoints=400
    CarpenterPoints=200
    PowerUpDropChance=0.030000
    LootWaveChance=0.000000
    PowerUpDuration=30.000000
    MaxPowerUpsPerRound=4
    UpgradedDamageScale=2.000000
    RoundGrenades=2
    StuckCheckInterval=10.000000
    StuckMoveDist=150.000000
    StuckPlayerDist=1500.000000
    InitialCountDownValue=6
    GameName="Zombies"
    Description="Survive round after round: earn dosh, repair the barricades, buy weapons off the walls and perks from the machines."
    DefaultPlayerClassName="KFMod.KFHumanPawnZombies"
    PlayerControllerClass=Class'KFMod.KFPlayerControllerZombies'
    PlayerControllerClassName="KFmod.KFPlayerControllerZombies"
    bPerksEnabled=False
    bBotZombiePawns=True
}
