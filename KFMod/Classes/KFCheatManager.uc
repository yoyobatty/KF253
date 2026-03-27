class KFCheatManager extends CheatManager;

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
    if( (Level.Netmode!=NM_Standalone) || (Pawn == None) || (Vehicle(Pawn) != None) )
        return;

    Pawn.GiveWeapon("KFmod.Bullpup");
    Pawn.GiveWeapon("KFmod.Winchester");
    Pawn.GiveWeapon("KFmod.Crossbow");
    Pawn.GiveWeapon("KFmod.Deagle");
    Pawn.GiveWeapon("KFmod.Dualies");
    Pawn.GiveWeapon("KFmod.Single");
    Pawn.GiveWeapon("KFmod.Axe");
    Pawn.GiveWeapon("KFmod.Bat");
    Pawn.GiveWeapon("KFmod.Knife");
    Pawn.GiveWeapon("KFmod.Chainsaw");
    Pawn.GiveWeapon("KFmod.PlaceMineWeapon");
    Pawn.GiveWeapon("KFmod.PlaceCalWeapon");
    Pawn.GiveWeapon("KFmod.LAW");
    Pawn.GiveWeapon("KFmod.Frag");
    Pawn.GiveWeapon("KFmod.StunNade");
    Pawn.GiveWeapon("KFmod.Shotgun");
    Pawn.GiveWeapon("KFmod.BoomStick");

    for( Inv=Pawn.Inventory; Inv!=None; Inv=Inv.Inventory )
    {
        if ( Weapon(Inv)!=None )
            Weapon(Inv).SuperMaxOutAmmo();
    }

    ReportCheat("Arsenal");
    ClientMessage("All KF Weapons.");
}

exec function Backup()
{
 local KFSoldierFriendly Soldier;


    if (!areCheatsEnabled()) return;
    if( (Level.Netmode!=NM_Standalone) || (Pawn == None) || (Vehicle(Pawn) != None) )
        return;

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
    if( (Level.Netmode!=NM_Standalone) || (Pawn == None) || (Vehicle(Pawn) != None) )
        return;

    RandomZombieNum = rand(7);

    if (RandomZombieNum == 0)
     ZombieName = "Clot";
    else
    if (RandomZombieNum == 1)
     ZombieName = "Crawler";
    else
    if (RandomZombieNum == 2)
     ZombieName = "Stalker";
    else
    if (RandomZombieNum == 3)
     ZombieName = "Bloat";
    else
    if (RandomZombieNum == 4)
     ZombieName = "Gorefast";
    else
    if (RandomZombieNum == 5)
     ZombieName = "Scrake";
    else
    if (RandomZombieNum == 6)
     ZombieName = "FleshPound";


   if (ZombieName != "")
    ConsoleCommand("Summon KFChar.Zombie"$ZombieName);

    ReportCheat("Horde");
    ClientMessage("You've got company!");
}

exec function MopUp()
{
    local KFMonster LevelMonster;
    local int LevelMonsterTotal;

    if (!areCheatsEnabled()) return;
    if( (Level.Netmode!=NM_Standalone) || (Pawn == None) || (Vehicle(Pawn) != None) )
        return;

   forEach AllActors(class 'KFMonster',LevelMonster)
   {
    LevelMonsterTotal++;
    LevelMonster.KilledBy(Pawn);
   }

    ReportCheat("MopUp");
    ClientMessage("The number of zombies in this map was : "$LevelMonsterTotal);
}


exec function Heal()
{

    if (!areCheatsEnabled()) return;
    if( (Level.Netmode!=NM_Standalone) || (Pawn == None) || (Vehicle(Pawn) != None) )
        return;

    Pawn.GiveHealth(100,Pawn.HealthMax);

    ReportCheat("Heal");
    ClientMessage("Much better.");
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

defaultproperties
{
}
