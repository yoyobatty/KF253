class KFCheatManager extends CheatManager;

var bool  bTurbo;
var array<string> HelpLines;	// for CheatHelp: group|what to type|what it does
var float SavedGroundSpeed, SavedWaterSpeed, SavedAirControl, SavedJumpZ, SavedMaxFallSpeed;

exec function Summon( string ClassName )
{
	local class<actor> NewClass;
	local vector SpawnLoc;
    local Actor SpawnedActor;

	if (!areCheatsEnabled()) return;

	log( "Fabricate " $ ClassName );
	NewClass = class<actor>( DynamicLoadObject( ClassName, class'Class' ) );
	if( NewClass!=None )
	{
		if ( Pawn != None )
			SpawnLoc = Pawn.Location;
		else
			SpawnLoc = Location;
		SpawnedActor = Spawn( NewClass,,,SpawnLoc + 72 * Vector(Rotation) + vect(0,0,1) * 15 );
        if(Pickup(SpawnedActor) != None)
            Pickup(SpawnedActor).AddToNavigation(); // make sure pickup is added to navmesh
	}
	ReportCheat("Summon");
}

exec function Summon2( string ClassName, int Quantity )
{
    local class<actor> NewClass;
    local vector SpawnLoc, TestLoc, Forward, Right;
    local Actor SpawnedActor;
    local int i, j;
    local float Step, Angle;

    if (!areCheatsEnabled()) return;

    log( "Fabricated "$Quantity$ " of: " $ ClassName );
    NewClass = class<actor>( DynamicLoadObject( ClassName, class'Class' ) );
    if( NewClass!=None )
    {
        if ( Pawn != None )
            SpawnLoc = Pawn.Location;
        else
            SpawnLoc = Location;

        Forward = vector(Rotation);
        Right   = Forward cross vect(0,0,1);

        for ( i = 0; i < Quantity; i++ )
        {
            SpawnedActor = None;

            for (j = 0; j < 60 && SpawnedActor == None; j++)
            {
                Step  = 48.0 + 48.0 * (j / 12);
                Angle = 2 * Pi * (j % 12) / 12.0;

                TestLoc = SpawnLoc
                    + (Forward * cos(Angle) + Right * sin(Angle)) * Step
                    + vect(0,0,1) * 15;

                    SpawnedActor = Spawn( NewClass,,, TestLoc );
                    if (SpawnedActor != None && Pickup(SpawnedActor) != None)
                        Pickup(SpawnedActor).AddToNavigation();
            }
        }
    }
    ReportCheat("Summon2");
}

exec function God()
{
	if (!areCheatsEnabled()) return;
	if ( bGodMode )
	{
		bGodMode = false;
        Pawn.bIgnoreForces = Pawn.default.bIgnoreForces;
		ClientMessage("God mode off");
		return;
	}

	bGodMode = true;
    Pawn.bIgnoreForces = true;
	ClientMessage("God Mode on");
	ReportCheat("God");
}

exec function LaidLaw()
{
    if(!areCheatsEnabled()) return;
    if(Pawn != None)
    {
        ClientMessage("Lay down the LAW!");
        ReportCheat("LAW");
    }
}

exec function Arsenal()
{
    local Inventory Inv;

    if (!areCheatsEnabled()) return;
    if( (Pawn == None) )
        return;

    Pawn.GiveWeapon("KFmod.Bullpup");
    Pawn.GiveWeapon("KFmod.Winchester");
    Pawn.GiveWeapon("KFmod.Crossbow");
    Pawn.GiveWeapon("KFmod.Deagle");
    Pawn.GiveWeapon("KFmod.Dualies");
    Pawn.GiveWeapon("KFmod.Single");
    Pawn.GiveWeapon("KFmod.Axe");
    Pawn.GiveWeapon("KFmod.Bat");
    Pawn.GiveWeapon("KFMod.Flamethrower");
    Pawn.GiveWeapon("KFmod.LAW");
    Pawn.GiveWeapon("KFmod.Frag");
    Pawn.GiveWeapon("KFmod.Shotgun");
    Pawn.GiveWeapon("KFmod.BoomStick");

    for( Inv=Pawn.Inventory; Inv!=None; Inv=Inv.Inventory )
    {
        if ( Weapon(Inv)!=None )
            Weapon(Inv).MaxOutAmmo();
    }

    ReportCheat("Arsenal");
    ClientMessage("All KF Weapons.");
}

exec function Backup()
{
    local KFSoldierFriendly Soldier;

    if (!areCheatsEnabled()) return;

    Soldier = Spawn(class'KFmod.KFSoldierFriendly');
    Soldier.PlayerReplicationInfo.Team.TeamIndex = PlayerReplicationInfo.Team.TeamIndex;

    ReportCheat("Backup");
    ClientMessage("Reinforcements are here!");

}

exec function Horde()
{
    local float RandomZombieNum;
    local String ZombieName;

    if (!areCheatsEnabled()) return;

    RandomZombieNum = rand(10);

    if (RandomZombieNum == 0)
        ZombieName = "Clot";
    else if (RandomZombieNum == 1)
        ZombieName = "Crawler";
    else if (RandomZombieNum == 2)
        ZombieName = "Stalker";
    else if (RandomZombieNum == 3)
        ZombieName = "Bloat";
    else if (RandomZombieNum == 4)
        ZombieName = "Gorefast";
    else if (RandomZombieNum == 5)
        ZombieName = "Scrake";
    else if (RandomZombieNum == 6)
        ZombieName = "FleshPound";
    else if (RandomZombieNum == 7)
        ZombieName = "Siren";
    else if (RandomZombieNum == 8)
        ZombieName = "Shade";
    else
        ZombieName = "Wretch";

   if (ZombieName != "")
    ConsoleCommand("Summon KFChar.Zombie"$ZombieName);

    ReportCheat("Horde");
    ClientMessage("You've got company!");
}

exec function Horde2(optional int Quantity)
{
    local int slotsPerRing, ringIndex, slotIndex, spawnedCount;
    local float radiusStep, radius, angleStep, angle;
    local vector SpawnLoc, TestLoc, Forward, Right;
    local actor SpawnedActor;
    local float RandomZombieNum;
    local string ZombieName, ClassName;
    local class<actor> NewClass;

    if (!areCheatsEnabled()) return;

    if (Quantity <= 0)
        Quantity = 16; // default horde size

    if (Pawn != None)
        SpawnLoc = Pawn.Location;
    else
        SpawnLoc = Location;

    Forward      = vector(Rotation);
    Right        = Forward cross vect(0,0,1);
    slotsPerRing = 12;      // how many slots per ring
    radiusStep   = 96.0;    // distance between rings

    while (spawnedCount < Quantity)
    {
        // pick a random zombie type for this one
        RandomZombieNum = rand(10);

        if (RandomZombieNum == 0)
            ZombieName = "Clot";
        else if (RandomZombieNum == 1)
            ZombieName = "Crawler";
        else if (RandomZombieNum == 2)
            ZombieName = "Stalker";
        else if (RandomZombieNum == 3)
            ZombieName = "Bloat";
        else if (RandomZombieNum == 4)
            ZombieName = "Gorefast";
        else if (RandomZombieNum == 5)
            ZombieName = "Scrake";
        else if (RandomZombieNum == 6)
            ZombieName = "FleshPound";
        else if (RandomZombieNum == 7)
            ZombieName = "Siren";
        else if (RandomZombieNum == 8)
            ZombieName = "Shade";
        else
            ZombieName = "Wretch";

        ClassName = "KFChar.Zombie"$ZombieName;
        NewClass  = class<actor>(DynamicLoadObject(ClassName, class'Class'));

        if (NewClass == None)
        {
            // if this type fails, skip it and pick another next loop
            spawnedCount++;
            continue;
        }

        SpawnedActor = None;

        // keep expanding rings outward until we find a free spot
        ringIndex = 0;
        while (SpawnedActor == None && ringIndex < 1000) // big safety cap
        {
            radius    = 48.0 + radiusStep * ringIndex;
            angleStep = 2 * Pi / float(slotsPerRing);

            for (slotIndex = 0; slotIndex < slotsPerRing && SpawnedActor == None; slotIndex++)
            {
                angle   = angleStep * float(slotIndex);
                TestLoc = SpawnLoc
                        + (Forward * cos(angle) + Right * sin(angle)) * radius
                        + vect(0,0,1) * 15;

                SpawnedActor = Spawn(NewClass,,, TestLoc);
            }

            ringIndex++;
        }

        spawnedCount++;
    }

    ReportCheat("Horde2");
    ClientMessage("Mixed horde spawned: "$Quantity$" zeds!");
}

exec function MopUp()
{
    local KFMonster LevelMonster;
    local int LevelMonsterTotal;

    if (!areCheatsEnabled()) return;

    forEach DynamicActors(class 'KFMonster', LevelMonster)
    {
        LevelMonsterTotal++;
        LevelMonster.KilledBy(Pawn);
    }

    ReportCheat("MopUp");
    ClientMessage("The number of zombies in this map was : "$LevelMonsterTotal);
}

exec function StartWave()
{
    if (!areCheatsEnabled()) return;

    if(!KFGameType(Level.Game).WaveRunning())
        KFGameType(Level.Game).WaveCountDown = 6;
    else return;

    ReportCheat("StartWave");
    ClientMessage("Wave starting in 5 seconds.");
}

exec function EndWave()
{
    local KFMonster LevelMonster;
    local KFGameType G;

    if (!areCheatsEnabled()) return;

    G = KFGameType(Level.Game);
    if(!G.WaveRunning())
        return;

    // (nothing more to come: an endless wave or a holdout would otherwise go on spawning)
    G.TotalMaxMonsters = 0;
    G.NextSpawnSquad.Length = 0;
    if (KFEndlessGameType(G) != None)
        KFEndlessGameType(G).HoldoutEndTime = 0;
    forEach DynamicActors(class 'KFMonster', LevelMonster)
        LevelMonster.KilledBy(Pawn);

    G.DoWaveEnd();

    ReportCheat("EndWave");
    ClientMessage("Wave ended.");
}

exec function ExtraTime(optional float ExtraSeconds)
{
    if (!areCheatsEnabled()) return;

    if (ExtraSeconds <= 0)
        ExtraSeconds = 10.0;

    if(KFGameType(Level.Game).WaveCountDown >= 1)
        KFGameType(Level.Game).WaveCountDown += ExtraSeconds;
    else return;

    ReportCheat("ExtraTime");
    ClientMessage("Extra "$ExtraSeconds$" seconds of trader time!");
}

// The next wave is wave N (between waves)
exec function SetWave(int N)
{
    local KFGameType G;

    if (!areCheatsEnabled()) return;

    G = KFGameType(Level.Game);
    if (G.WaveRunning())
    {
        ClientMessage("End the wave first (EndWave), then SetWave.");
        return;
    }
    N = Max(N, 1);
    if (KFEndlessGameType(G) == None)
        N = Min(N, G.FinalWave + 1);
    G.WaveNum = N - 1;
    InvasionGameReplicationInfo(G.GameReplicationInfo).WaveNumber = G.WaveNum;

    ReportCheat("SetWave");
    ClientMessage("Next wave: "$N$". StartWave to begin it now.");
}

// Only N more specimens to come this wave
exec function ZedsLeft(int N)
{
    local KFGameType G;

    if (!areCheatsEnabled()) return;

    G = KFGameType(Level.Game);
    G.TotalMaxMonsters = Max(N, 0);
    if (N <= 0)
        G.NextSpawnSquad.Length = 0;
    KFGameReplicationInfo(G.GameReplicationInfo).MaxMonsters = G.TotalMaxMonsters + G.NumMonsters;

    ReportCheat("ZedsLeft");
    ClientMessage(G.TotalMaxMonsters$" more specimens to come this wave.");
}

// At most N specimens at once, for the rest of this wave
exec function ZedCap(int N)
{
    if (!areCheatsEnabled()) return;

    KFGameType(Level.Game).MaxMonsters = Clamp(N, 1, 600);

    ReportCheat("ZedCap");
    ClientMessage("At most "$KFGameType(Level.Game).MaxMonsters$" specimens at once until the next wave.");
}

// Specimen spawning stopped, or started again
exec function PauseSpawns()
{
    local KFGameType G;

    if (!areCheatsEnabled()) return;

    G = KFGameType(Level.Game);
    G.bSpawnsPaused = !G.bSpawnsPaused;

    ReportCheat("PauseSpawns");
    if (G.bSpawnsPaused)
        ClientMessage("Spawning paused (PauseSpawns again to go on).");
    else
        ClientMessage("Spawning goes on.");
}

exec function WaveInfo()
{
    local KFGameType G;
    local KFEndlessGameType E;
    local string S;

    G = KFGameType(Level.Game);
    E = KFEndlessGameType(G);
    S = "Wave "$(G.WaveNum + 1);
    if (E != None)
        S = S$" ("$E.WaveTypeName()$")";
    if (G.WaveRunning())
        S = S$", running";
    else
        S = S$", next starts in "$G.WaveCountDown$" s";
    ClientMessage(S$". Alive "$G.NumMonsters$", still to come "$G.TotalMaxMonsters$", at most "$G.MaxMonsters$" at once"$Pick(G.bSpawnsPaused, ", SPAWNING PAUSED", "")$".");
    if (E == None)
        return;
    if (E.HoldoutSpawning())
        ClientMessage("Holdout: "$int(E.HoldoutEndTime - Level.TimeSeconds)$" s of spawning left.");
    ClientMessage("Holdouts: "$int(E.HoldoutLength)$" s, chance "$E.HoldoutChance$", cap "$E.HoldoutCapScale$" x Max Specimens, health "$int(100.0 * E.HoldoutHealthScale)$"%. River "$E.bRiver
        $": rows of "$E.RiotRowSize$", "$E.RiverSources$" source(s), kind "$Pick(E.RiotClass == None, "mixed", string(E.RiotClass))
        $", rush "$E.bRiotRush$", pace "$int(E.RushSpeed)$" seen / "$int(E.RushHiddenSpeed)$" hidden, gap "$E.RiverGap$" s.");
}

// Endless: the next wave is a holdout, starting in 5 seconds when between waves
exec function Holdout()
{
    local KFEndlessGameType E;

    if (!areCheatsEnabled()) return;

    E = KFEndlessGameType(Level.Game);
    if (E == None)
    {
        ClientMessage("Holdouts are an Endless mode wave.");
        return;
    }
    E.ForceNextWave("holdout");
    if (!E.WaveRunning())
        E.WaveCountDown = 6;

    ReportCheat("Holdout");
    if (E.WaveRunning())
        ClientMessage("The next wave is a holdout.");
    else
        ClientMessage("Holdout starting in 5 seconds.");
}

// Endless: the next wave's kind (normal, siren, shade, boss or holdout)
exec function NextWave(string Kind)
{
    local KFEndlessGameType E;

    if (!areCheatsEnabled()) return;

    E = KFEndlessGameType(Level.Game);
    if (E == None)
    {
        ClientMessage("NextWave is for Endless mode (SetWave picks the wave elsewhere).");
        return;
    }
    if (!E.ForceNextWave(Kind))
    {
        ClientMessage("NextWave normal, siren, shade, boss or holdout.");
        return;
    }
    ReportCheat("NextWave");
    ClientMessage("The next wave is a "$Kind$" wave.");
}

// Endless: during a holdout, N seconds of spawning left; between waves, how long holdouts last
exec function HoldoutTime(float N)
{
    local KFEndlessGameType E;

    if (!areCheatsEnabled()) return;

    E = KFEndlessGameType(Level.Game);
    if (E == None)
        return;
    N = FMax(N, 0);
    if (E.HoldoutSpawning())
    {
        E.HoldoutEndTime = Level.TimeSeconds + N;
        ClientMessage("This holdout spawns for "$int(N)$" more seconds.");
    }
    else
    {
        E.HoldoutLength = FMax(N, 5);
        ClientMessage("Holdouts last "$int(E.HoldoutLength)$" seconds.");
    }
    ReportCheat("HoldoutTime");
}

// Endless: holdout specimens' health as a share of a normal one's (HoldoutHealth 0.5), from the next ones spawned
exec function HoldoutHealth(float Share)
{
    local KFEndlessGameType E;

    if (!areCheatsEnabled()) return;

    E = KFEndlessGameType(Level.Game);
    if (E == None)
        return;
    E.HoldoutHealthScale = FClamp(Share, 0.05, 5.0);
    ReportCheat("HoldoutHealth");
    ClientMessage("Holdout specimens have "$int(100.0 * E.HoldoutHealthScale)$"% of their health.");
}

// Endless: the holdout stops spawning now (kill the rest to end it)
exec function EndHoldout()
{
    local KFEndlessGameType E;

    if (!areCheatsEnabled()) return;

    E = KFEndlessGameType(Level.Game);
    if (E == None || !E.HoldoutSpawning())
    {
        ClientMessage("No holdout is spawning.");
        return;
    }
    E.HoldoutEndTime = Level.TimeSeconds;
    ReportCheat("EndHoldout");
}

// Endless: every specimen of the river of one kind (RiotZed clot, crawler, gorefast, stalker, wretch, ... or a class
// path), or the wave's own mix (RiotZed mix)
exec function RiotZed(string Kind)
{
    local KFEndlessGameType E;
    local class<Monster> C;

    if (!areCheatsEnabled()) return;

    E = KFEndlessGameType(Level.Game);
    if (E == None)
        return;
    if (Kind == "" || Kind ~= "mix" || Kind ~= "none")
    {
        E.RiotClass = None;
        ClientMessage("Riots of the wave's own mix.");
    }
    else
    {
        if (InStr(Kind, ".") >= 0)
            C = class<Monster>(DynamicLoadObject(Kind, class'Class', true));
        else
            C = class<Monster>(DynamicLoadObject("KFChar.Zombie"$Kind, class'Class', true));
        if (C == None)
        {
            ClientMessage("No specimen called "$Kind$" (try clot, crawler, gorefast, stalker, wretch, bloat, siren, scrake, fleshpound).");
            return;
        }
        E.RiotClass = C;
        ClientMessage("Riots of "$C.Name$" only.");
    }
    ReportCheat("RiotZed");
}

exec function RiotRows(int N)
{
    local KFEndlessGameType E;

    if (!areCheatsEnabled()) return;

    E = KFEndlessGameType(Level.Game);
    if (E == None)
        return;
    E.RiotRowSize = Clamp(N, 1, 8);
    ReportCheat("RiotRows");
    ClientMessage("Riot rows of "$E.RiotRowSize$Pick(E.RiotRowSize == 1, " (one at a time: a plain river)", "")$".");
}

exec function RiotSources(int N)
{
    local KFEndlessGameType E;

    if (!areCheatsEnabled()) return;

    E = KFEndlessGameType(Level.Game);
    if (E == None)
        return;
    E.RiverSources = Clamp(N, 1, 4);
    ReportCheat("RiotSources");
    ClientMessage("Riots from "$E.RiverSources$" source(s).");
}

// Endless: the rows rush in or keep together (Rush on, Rush off, Rush 280 for that speed, Rush alone switches it)
exec function Rush(optional string Arg)
{
    local KFEndlessGameType E;

    if (!areCheatsEnabled()) return;

    E = KFEndlessGameType(Level.Game);
    if (E == None)
        return;
    if (Arg ~= "on")
        E.bRiotRush = true;
    else if (Arg ~= "off")
        E.bRiotRush = false;
    else if (float(Arg) > 0)
    {
        E.bRiotRush = true;
        E.RushSpeed = float(Arg);
    }
    else
        E.bRiotRush = !E.bRiotRush;
    ReportCheat("Rush");
    ClientMessage("Rush "$Pick(E.bRiotRush, "on at "$int(E.RushSpeed), "off")$" (rows let loose from now on).");
}

// Endless: a dense crowd of one kind for the holdouts (rows of eight packed close, one source, a fast steady beat,
// three times Max Specimens at once): Crowd, or Crowd crawler and the like
exec function Crowd(optional string Kind)
{
    local KFEndlessGameType E;
    local float Cap;

    if (!areCheatsEnabled()) return;

    E = KFEndlessGameType(Level.Game);
    if (E == None)
        return;
    if (Kind == "")
        Kind = "clot";
    RiotZed(Kind);
    E.RiotRowSize = 8;
    E.RiotSpacing = 6;
    E.RiverSources = 1;
    E.RiverGap = 0.1;
    E.RiverMinGap = 0.06;
    E.RiverSurge = 0;
    E.HoldoutCapScale = 3.0;
    if (E.HoldoutSpawning())
    {
        Cap = float(E.MaxZombiesOnce) * E.HoldoutCapScale;
        E.MaxMonsters = Clamp(int(Cap), 32, 128);
    }
    ReportCheat("Crowd");
    ClientMessage("Holdouts bring a dense crowd. RiotReset puts the riot back to normal.");
}

// Endless: a horde now in a running holdout (sources afresh round the players, the quick beat)
exec function HordeNow()
{
    local KFEndlessGameType E;

    if (!areCheatsEnabled()) return;

    E = KFEndlessGameType(Level.Game);
    if (E == None || !E.HoldoutSpawning())
    {
        ClientMessage("Hordes come in a running holdout (Holdout starts one).");
        return;
    }
    E.NextHordeTime = 0;
    ReportCheat("HordeNow");
}

// Endless: the pace of every holdout specimen, seen and out of sight (Pace 300 700); the next ones spawned
exec function Pace(float Seen, optional float Hidden)
{
    local KFEndlessGameType E;

    if (!areCheatsEnabled()) return;

    E = KFEndlessGameType(Level.Game);
    if (E == None)
        return;
    E.RushSpeed = FMax(Seen, 0);
    if (Hidden > 0)
        E.RushHiddenSpeed = Hidden;
    ReportCheat("Pace");
    if (E.RushSpeed <= 0)
        ClientMessage("Holdout specimens keep their own speeds (the old speed-up).");
    else
        ClientMessage("Holdout specimens run at "$int(E.RushSpeed)$" seen, "$int(FMax(E.RushSpeed, E.RushHiddenSpeed))$" out of sight.");
}

exec function RiotReset()
{
    local KFEndlessGameType E;

    if (!areCheatsEnabled()) return;

    E = KFEndlessGameType(Level.Game);
    if (E == None)
        return;
    E.RiotClass = class'KFEndlessGameType'.default.RiotClass;
    E.RiotRowSize = class'KFEndlessGameType'.default.RiotRowSize;
    E.RiotSpacing = class'KFEndlessGameType'.default.RiotSpacing;
    E.RiverSources = class'KFEndlessGameType'.default.RiverSources;
    E.RiverGap = class'KFEndlessGameType'.default.RiverGap;
    E.RiverMinGap = class'KFEndlessGameType'.default.RiverMinGap;
    E.RiverSurge = class'KFEndlessGameType'.default.RiverSurge;
    E.HoldoutCapScale = class'KFEndlessGameType'.default.HoldoutCapScale;
    E.bRiotRush = class'KFEndlessGameType'.default.bRiotRush;
    E.RushSpeed = class'KFEndlessGameType'.default.RushSpeed;
    E.RushHiddenSpeed = class'KFEndlessGameType'.default.RushHiddenSpeed;
    ReportCheat("RiotReset");
    ClientMessage("Riot settings back to normal.");
}

function string Pick(bool bFirst, string First, string Second)
{
    if (bFirst)
        return First;
    return Second;
}

exec function Heal()
{
    if (!areCheatsEnabled()) 
        return;
    if( (Pawn == None) )
        return;

    Pawn.GiveHealth(100,Pawn.HealthMax);

    ReportCheat("Heal");
    ClientMessage("Much better.");
}

exec function HealAll()
{
    local KFHumanPawn TeamMatePawn;
    if (!areCheatsEnabled()) 
        return;

    foreach DynamicActors(class'KFHumanPawn', TeamMatePawn)
    {
        if (TeamMatePawn != None)
            TeamMatePawn.GiveHealth(100,TeamMatePawn.HealthMax);
    }

    ReportCheat("Healed All");
    ClientMessage("Much better.");
}

exec function SetHealth(int NewHealth)
{
    if (!areCheatsEnabled()) 
        return;
    if( (Pawn == None) )
        return;

    Pawn.Health = NewHealth;

    ReportCheat("SetHealth");
    ClientMessage("Health set to "$NewHealth);
}

exec function SetHealthAll(int NewHealth)
{
    local KFHumanPawn TeamMatePawn;
    if (!areCheatsEnabled()) 
        return;

    foreach DynamicActors(class'KFHumanPawn', TeamMatePawn)
    {
        if (TeamMatePawn != None)
            TeamMatePawn.Health = NewHealth;
    }

    ReportCheat("SetHealthAll");
    ClientMessage("Health for all set to "$NewHealth);
}

/*
    exec function TimeIsATeacher()
{

  //  if (!areCheatsEnabled()) return;
  //  if( (Level.Netmode!=NM_Standalone) || (Pawn == None) || (Vehicle(Pawn) != None) )
  //      return;

    KFPlayerReplicationInfo(PlayerReplicationInfo).ExperienceLevel += 1.0 ;

    ReportCheat("TimeIsATeacher");
    ClientMessage("+ 1 Experience level");

}
*/

exec function ViewZombie()
{
	local actor first;
	local bool bFound;
	local Controller C;

	bViewBot = true;
	For ( C=Level.ControllerList; C!=None; C=C.NextController )
		if ( C.IsA('KFMonsterController') && (C.Pawn != None) )
	{
		if ( bFound || (first == None) )
		{
			first = C;
			if ( bFound )
				break;
		}
		if ( C == RealViewTarget )
			bFound = true;
	}

	if ( first != None )
	{
		SetViewTarget(first);
		bBehindView = true;
		ViewTarget.BecomeViewTarget();
		FixFOV();
	}
	else
		ViewSelf(true);
}

exec function shownav()
{
    local NavigationPoint N, DN;
    local int i;
    local ReachSpec R;
    local vector DestOffset;
    local color C;

    hidenav();

    DestOffset = vect(0,0,8);
    DN = Level.NavigationPointList;

    for( N=Level.NavigationPointList; N!=None; N=N.nextNavigationPoint )
    {
        N.bHidden = False;

        for( i=0; i!=N.PathList.Length; ++i )
        {
            R = N.PathList[i];

            if( R != None )
            {
                if( R.Start != None && R.End != None )
                {
                    if( (R.reachFlags & 0x1F) != R.reachFlags )
                    {
                        // special flags, special color
                        C.R = 128;
                        C.G = 0;
                        C.B = 255;
                    }
                    else
                    {
                        C.R = 255;
                        C.G = 255;
                        C.B = 255;
                    }

                    DN.DrawStayingDebugLine(R.Start.Location + DestOffset, R.End.Location - DestOffset, C.R,C.G,C.B);
                }
                else
                {
                     //gLog("INVALID REACHSPEC" #GON(N)  #GON(R) #GON(R.Start) #GON(R.End));
                     Log("INVALID REACHSPEC" @N  @R @R.Start @R.End);
                     DN.DrawStayingDebugLine(N.Location, N.Location+vect(0,0,255), 255,0,0);
                }
            }
        }

    }
}

exec function hidenav()
{
    local NavigationPoint N;
    Level.NavigationPointList.ClearStayingDebugLines();
    for( N=Level.NavigationPointList; N!=None; N=N.nextNavigationPoint )
        N.bHidden = True;
}

exec function Cash(optional int Amount)
{
    if (!AreCheatsEnabled()) return;
    if (PlayerReplicationInfo == None) return;

    if (Amount <= 0)
        Amount = 500;

    PlayerReplicationInfo.Score += Amount; // In KF this commonly maps to player cash
    ReportCheat("Cash");
    ClientMessage("Dosh +"$Amount);
}

exec function CashAll(optional int Amount)
{
    local KFPlayerReplicationInfo TeamMatePRI;

    if (!AreCheatsEnabled()) return;

    if (Amount <= 0)
        Amount = 500;

    foreach DynamicActors(class'KFPlayerReplicationInfo', TeamMatePRI)
    {
        if (TeamMatePRI != None)
            TeamMatePRI.Score += Amount; // In KF this commonly maps to player cash
    }

    ReportCheat("CashAll");
    ClientMessage("Dosh +"$Amount$" for all.");
}

exec function Vest()
{
    if (!AreCheatsEnabled()) return;
    if (Pawn == None || Vehicle(Pawn) != None) return;

    Pawn.ShieldStrength = 100;
    ReportCheat("Vest");
    ClientMessage("Armor topped up.");
}

exec function VestAll()
{
    local KFHumanPawn TeamMatePawn;

    if (!AreCheatsEnabled()) return;
    if (Vehicle(Pawn) != None) return;

    foreach DynamicActors(class'KFHumanPawn', TeamMatePawn)
    {
        if (TeamMatePawn != None)
            TeamMatePawn.ShieldStrength = 100;
    }

    ReportCheat("Vest");
    ClientMessage("Armor topped up for all.");
}

exec function Nuke(optional float Radius)
{
    local KFMonster M;
    local int Killed;

    if (!AreCheatsEnabled()) return;

   if (Radius <= 0)
       Radius = 50000.0;

    foreach DynamicActors(class'KFMonster', M)
    {
        if (M != None && VSize(M.Location - Pawn.Location) <= Radius && M.Health > 0 && !M.bDeleteMe)
        {
            M.TakeDamage(10000, Pawn, M.Location, Pawn.Velocity * M.Mass, class'DamTypeFrag');
            ++Killed;
        }
    }

    ReportCheat("Nuke");
    ClientMessage("Nuked zeds in radius "$int(Radius)$"uu: "$Killed);
}

exec function AllAmmo()
{
	local Inventory Inv;
	if (!areCheatsEnabled()) return;

	for( Inv=Pawn.Inventory; Inv!=None; Inv=Inv.Inventory )
		if ( Weapon(Inv)!=None )
			Weapon(Inv).MaxOutAmmo();

	ReportCheat("AllAmmo");
}

exec function AllAmmoAll(optional bool bSuper)
{
	local Inventory Inv;
    local KFHumanPawn TeamMatePawn;

    if (!AreCheatsEnabled()) return;

    foreach DynamicActors(class'KFHumanPawn', TeamMatePawn)
    {
        for( Inv=TeamMatePawn.Inventory; Inv!=None; Inv=Inv.Inventory )
            if ( Weapon(Inv)!=None )
                if (bSuper)
                    Weapon(Inv).SuperMaxOutAmmo();
                else
                    Weapon(Inv).MaxOutAmmo();
    }
    
	ReportCheat("AllAmmoAll");
    ClientMessage("Everyone's ammo maxed out");
}

exec function NadeFull()
{
    local Inventory Inv;
    if (!areCheatsEnabled()) return;

    for( Inv=Pawn.Inventory; Inv!=None; Inv=Inv.Inventory )
        if ( Weapon(Inv)!=None && Frag(Weapon(Inv))!=None )
            Weapon(Inv).MaxOutAmmo();

    ReportCheat("NadeFull");
}

exec function NadeFullAll()
{
    local Inventory Inv;
    local KFHumanPawn TeamMatePawn;

    if (!areCheatsEnabled()) return;

    foreach DynamicActors(class'KFHumanPawn', TeamMatePawn)
    {
        for( Inv=TeamMatePawn.Inventory; Inv!=None; Inv=Inv.Inventory )
            if ( Weapon(Inv)!=None && Frag(Weapon(Inv))!=None )
                Weapon(Inv).MaxOutAmmo();
    }

    ReportCheat("NadeFullAll");
    ClientMessage("Everyone's nades maxed out");
}

exec function GodAll()
{
    local Controller C;

    if (!AreCheatsEnabled()) return;

	For ( C=Level.ControllerList; C!=None; C=C.NextController )
    {
        if ( C.bIsPlayer )
        {
            if(!C.bGodMode)
            {
                C.bGodMode = true;
                if(PlayerController(C) != None)
                    PlayerController(C).ClientMessage("God mode on.");
            }
            else
            {
                C.bGodMode = false;
                if(PlayerController(C) != None)
                    PlayerController(C).ClientMessage("God mode off.");
            }
        }
	}

    ReportCheat("GodAll");
}

exec function SuperMan()
{
    local Inventory Inv;

    if (!areCheatsEnabled()) return;

    // Adjust speed settings
	Pawn.AirControl *= 1.4;
    Pawn.GroundSpeed *= 1.6;
    Pawn.WaterSpeed *= 1.4;
    Pawn.AirSpeed *= 1.4;
    
	// Jump higher
	Pawn.JumpZ *= 1.5;

    for( Inv=Pawn.Inventory; Inv!=None; Inv=Inv.Inventory )
        if ( Weapon(Inv)!=None )
            Weapon(Inv).StartBerserk();
    
    xPawn(Pawn).bBerserk = true;
    
	// Invisible
	xPawn(Pawn).SetInvisibility(120.0);
    
	// UDamage
	Pawn.EnableUDamage(75);

    ReportCheat("SuperMan");
    ClientMessage("Superman mode on! You are now faster, jump higher, invisible, and deal more damage.");
    
}

exec function SuperManAll()
{
    local Controller C;
    local Inventory Inv;

    if (!AreCheatsEnabled()) return;

    For ( C=Level.ControllerList; C!=None; C=C.NextController )
    {
        if ( C.bIsPlayer )
        {
            // Adjust speed settings
            C.Pawn.AirControl *= 1.4;
            C.Pawn.GroundSpeed *= 1.6;
            C.Pawn.WaterSpeed *= 1.4;
            C.Pawn.AirSpeed *= 1.4;
    
            // Jump higher
            C.Pawn.JumpZ *= 1.5;

        for( Inv=Pawn.Inventory; Inv!=None; Inv=Inv.Inventory )
            if ( Weapon(Inv)!=None )
                Weapon(Inv).StartBerserk();
    
            xPawn(C.Pawn).bBerserk = true;
    
            // Invisible
            xPawn(C.Pawn).SetInvisibility(120.0);
    
            // UDamage
            C.Pawn.EnableUDamage(75);

            if(PlayerController(C) != None)
                PlayerController(C).ClientMessage("Superman mode on! You are now faster, jump higher, invisible, and deal more damage.");
        }
    }

    ReportCheat("SuperManAll");
}


defaultproperties
{
     HelpLines(0)="You|God|you cannot be hurt (again to stop)"
     HelpLines(1)="You|Heal|full health"
     HelpLines(2)="You|SetHealth N|your health set to N"
     HelpLines(3)="You|Vest|full armour"
     HelpLines(4)="You|Cash N|N dosh (500 when left out)"
     HelpLines(5)="You|AllAmmo|full ammunition for every weapon you carry"
     HelpLines(6)="You|NadeFull|full grenades"
     HelpLines(7)="You|Arsenal|every weapon, full"
     HelpLines(8)="You|SuperMan|faster, higher jumps, invisible, more damage"
     HelpLines(9)="Everyone|GodAll|every player cannot be hurt (again to stop)"
     HelpLines(10)="Everyone|HealAll|every player at full health"
     HelpLines(11)="Everyone|SetHealthAll N|every player's health set to N"
     HelpLines(12)="Everyone|VestAll|every player in full armour"
     HelpLines(13)="Everyone|CashAll N|N dosh for every player (500 when left out)"
     HelpLines(14)="Everyone|AllAmmoAll|full ammunition for every player (AllAmmoAll 1: beyond full)"
     HelpLines(15)="Everyone|NadeFullAll|full grenades for every player"
     HelpLines(16)="Everyone|SuperManAll|SuperMan for every player"
     HelpLines(17)="Specimens|Summon Class|one of that class in front of you (Summon KFChar.ZombieScrake)"
     HelpLines(18)="Specimens|Summon2 Class N|N of that class round you"
     HelpLines(19)="Specimens|Horde|one random specimen"
     HelpLines(20)="Specimens|Horde2 N|N random specimens round you (16 when left out)"
     HelpLines(21)="Specimens|MopUp|every specimen dies"
     HelpLines(22)="Specimens|Nuke R|every specimen within R units dies (all of them when left out)"
     HelpLines(23)="Specimens|Backup|a friendly soldier"
     HelpLines(24)="Specimens|ViewZombie|watch the specimens one after another (again for the next; ViewSelf to stop)"
     HelpLines(25)="Waves|StartWave|the next wave in 5 seconds"
     HelpLines(26)="Waves|EndWave|the wave ends, every specimen dies"
     HelpLines(27)="Waves|ExtraTime S|S more seconds of trader time (10 when left out)"
     HelpLines(28)="Waves|SetWave N|the next wave is wave N (between waves)"
     HelpLines(29)="Waves|ZedsLeft N|only N more specimens this wave"
     HelpLines(30)="Waves|ZedCap N|at most N specimens at once for the rest of the wave"
     HelpLines(31)="Waves|PauseSpawns|spawning stops (again to go on)"
     HelpLines(32)="Waves|WaveInfo|the wave, specimens alive and to come, holdout settings"
     HelpLines(33)="Endless|Holdout|the next wave is a holdout (in 5 seconds between waves)"
     HelpLines(34)="Endless|NextWave Kind|the next wave's kind: normal, siren, shade, boss or holdout"
     HelpLines(35)="Endless|HoldoutTime S|this holdout spawns for S more seconds; between waves, holdouts last S"
     HelpLines(36)="Endless|HoldoutHealth Share|holdout specimens' health, as a share of a normal one's (0.5)"
     HelpLines(37)="Endless|EndHoldout|the holdout stops spawning (kill the rest to end it)"
     HelpLines(38)="Endless|HordeNow|a horde now, in a running holdout"
     HelpLines(39)="Endless|RiotZed Kind|holdout rows of one kind (clot, crawler, ...) or of the wave's mix (mix)"
     HelpLines(40)="Endless|RiotRows N|holdout rows N wide (1 to 8)"
     HelpLines(41)="Endless|RiotSources N|holdouts come from N places (1 to 4)"
     HelpLines(42)="Endless|Rush X|holdout rows rush in: on, off, a speed, or alone to switch"
     HelpLines(43)="Endless|Crowd Kind|holdouts bring one dense crowd (clot when left out)"
     HelpLines(44)="Endless|Pace Seen Hidden|holdout specimens' speed in sight and out of it"
     HelpLines(45)="Endless|RiotReset|holdout settings back to normal"
     HelpLines(46)="Other|ShowNav|the path network drawn (HideNav to clear)"
}
