class FriendlyMonsterAI extends KFMonsterController;

<<<<<<< HEAD

=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
function bool FindNewEnemy()
{
    local Pawn BestEnemy;
    local bool bSeeNew, bSeeBest;
    local float BestDist, NewDist;
<<<<<<< HEAD
    local KFMonsterController C;
    //local KFOBJMover Bashdoor;

    if ( Level.Game.bGameEnded )
        return false;             

     ForEach AllActors(class 'KFMonsterController', C)
    {
        if ((C.Pawn != None) && (C.Pawn.Health > 0) && C.Pawn != class 'KFHumanPawn' && C != self )
        {
            if ( BestEnemy == None )
            {
                BestEnemy = C.Pawn;
                BestDist = VSize(BestEnemy.Location - Pawn.Location);
                bSeeBest = CanSee(BestEnemy);
            }
            else
            {
                NewDist = VSize(C.Pawn.Location - Pawn.Location);
                if ( !bSeeBest || (NewDist < BestDist) )
                {
                    bSeeNew = CanSee(C.Pawn);
                    if ( NewDist < BestDist)
                    {
                        BestEnemy = C.Pawn;
                        BestDist = NewDist;
                        bSeeBest = bSeeNew;
                    }
=======
    local Controller PC;
    local Monster M;

    if (KFM.bNoAutoHuntEnemies)
        return false;

    for (PC = Level.ControllerList; PC != None; PC = PC.NextController)
    {
        // Only consider pawns that are monsters, not self, and not dead
        M = Monster(PC.Pawn);
        if (M == None || M == Pawn || M.Health <= 0)
            continue;

        // Optionally: Don't attack monsters of the same class (if you want)
        // if (M.Class == Pawn.Class)
        //     continue;

        if (BestEnemy == None)
        {
            BestEnemy = M;
            BestDist = VSize(M.Location - Pawn.Location);
            bSeeBest = CanSee(M);
        }
        else
        {
            NewDist = VSize(M.Location - Pawn.Location);
            if (!bSeeBest || (NewDist < BestDist))
            {
                bSeeNew = CanSee(M);
                if (NewDist < BestDist)
                {
                    BestEnemy = M;
                    BestDist = NewDist;
                    bSeeBest = bSeeNew;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
                }
            }
        }
    }

<<<<<<< HEAD

    if ( BestEnemy == Enemy )
      return false;


    if ( BestEnemy != None )
    {
        ChangeEnemy(BestEnemy,CanSee(BestEnemy));
        return true;
    }

    return false;
}


function bool SetEnemy( Pawn NewEnemy, optional bool bHateMonster )
{
    local float EnemyDist;
    local bool bNewMonsterEnemy;

    if ( (NewEnemy == None) || (NewEnemy.Health <= 0) || (NewEnemy.Controller == None) || (NewEnemy == Enemy) )
        return false;

    bNewMonsterEnemy = bHateMonster && (Level.Game.NumPlayers < 4) && !Monster(Pawn).SameSpeciesAs(NewEnemy) && !NewEnemy.Controller.bIsPlayer;
  
    if ( NewEnemy == class 'KFHumanPawn' )
            return false;

    if ( (bNewMonsterEnemy && LineOfSightTo(NewEnemy)) || (Enemy == None) || !EnemyVisible() )
    {
        ChangeEnemy(NewEnemy,CanSee(NewEnemy));
        return true;
    }

    if ( !CanSee(NewEnemy) )
        return false;

    if ( !bHateMonster && (Monster(Enemy) != None) && NewEnemy.Controller.bIsPlayer )
        return false;

    EnemyDist = VSize(Enemy.Location - Pawn.Location);
    if ( EnemyDist < Pawn.MeleeRange )
        return false;

    if ( EnemyDist > 1.7 * VSize(NewEnemy.Location - Pawn.Location))
    {
        ChangeEnemy(NewEnemy,CanSee(NewEnemy));
        return true;
    }
    return false;
}

event SeePlayer(Pawn SeenPlayer)
{
   
    if ( Enemy == SeenPlayer )
    {
        Enemy = none;
        GotoState('ZombieRestFormation', 'Begin');
    }
=======
    if (BestEnemy == Enemy)
        return false;

    if (BestEnemy != None)
    {
        ChangeEnemy(BestEnemy, bSeeBest);
        return true;
    }
    return false;
}

function bool SetEnemy( Pawn NewEnemy, optional bool bHateMonster )
{
	local float EnemyDist;

	if ( (NewEnemy == None) || (NewEnemy.Health <= 0) || (NewEnemy.Controller == None) || (NewEnemy == Enemy) )
		return false;

	if ( (Enemy == None) || !EnemyVisible() )
	{
		ChangeEnemy(NewEnemy,CanSee(NewEnemy));
		return true;
	}

	if ( !CanSee(NewEnemy) )
		return false;

    if (Monster(NewEnemy) == None)
        return false;

	EnemyDist = VSize(Enemy.Location - Pawn.Location);
	if ( EnemyDist < Pawn.MeleeRange )
		return false;

	if ( EnemyDist > 1.7 * VSize(NewEnemy.Location - Pawn.Location))
	{
		ChangeEnemy(NewEnemy,CanSee(NewEnemy));
		return true;
	}
	return false;
}

function bool SameTeamAs( Controller C )
{
    // Friendly monsters are not on the same team as any other monster
    if (KFPlayerController(C) != None)
        return true;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

defaultproperties
{
}
