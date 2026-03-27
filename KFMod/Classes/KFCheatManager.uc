class KFCheatManager extends CheatManager;

var bool  bTurbo;
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

    if(!KFGameType(Level.Game).bWaveInProgress)
        KFGameType(Level.Game).WaveCountDown = 6;
    else return;

    ReportCheat("StartWave");
    ClientMessage("Wave starting in 5 seconds.");
}

exec function EndWave()
{
    local KFMonster LevelMonster;

    if (!areCheatsEnabled()) return;

    if(!KFGameType(Level.Game).bWaveInProgress)
        return;

    forEach DynamicActors(class 'KFMonster', LevelMonster)
        LevelMonster.KilledBy(Pawn);

    KFGameType(Level.Game).DoWaveEnd();

    ReportCheat("EndWave");
    ClientMessage("Wave ended.");
}

exec function ExtraTime(optional float ExtraSeconds)
{
    if (!areCheatsEnabled()) return;

    if(KFGameType(Level.Game).WaveCountDown >= 1)
        KFGameType(Level.Game).WaveCountDown += ExtraSeconds;
    else return;

    if (ExtraSeconds <= 0)
        ExtraSeconds = 10.0;

    ReportCheat("ExtraTime");
    ClientMessage("Extra "$ExtraSeconds$" seconds of trader time!");
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
}
