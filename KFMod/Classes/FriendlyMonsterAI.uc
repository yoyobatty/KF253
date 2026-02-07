class FriendlyMonsterAI extends KFMonsterController;

function bool FindNewEnemy()
{
    local Pawn BestEnemy;
    local bool bSeeNew, bSeeBest;
    local float BestDist, NewDist;
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
                }
            }
        }
    }

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
}

defaultproperties
{
}
