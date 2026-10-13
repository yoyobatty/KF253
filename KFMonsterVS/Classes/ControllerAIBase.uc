Class ControllerAIBase extends KFMonsterController;

static final function bool StaticFindNewEnemy( KFMonster M, KFMonsterController K )
{
	local Pawn BestEnemy;
	local bool bSeeNew, bSeeBest;
	local float BestDist, NewDist;
	local Controller PC;
	local KFHumanPawn C;

	if( M.bNoAutoHuntEnemies )
		Return False;

	for ( PC=M.Level.ControllerList; PC!=None; PC=PC.NextController )
	{
		C = KFHumanPawn(PC.Pawn);
		if( C==None || C.Health<=0 )
			Continue;
		if ( BestEnemy == None )
		{
			BestEnemy = C;
			BestDist = VSize(BestEnemy.Location - M.Location);
			bSeeBest = K.CanSee(C);
		}
		else
		{
			NewDist = VSize(C.Location - M.Location);
			if ( !bSeeBest || (NewDist < BestDist) )
			{
				bSeeNew = K.CanSee(C);
				if ( NewDist < BestDist)
				{
					BestEnemy = C;
					BestDist = NewDist;
					bSeeBest = bSeeNew;
				}
			}
		}
	}

	if ( BestEnemy == K.Enemy )
		return false;

	if ( BestEnemy != None )
	{
		K.ChangeEnemy(BestEnemy,K.CanSee(BestEnemy));
		return true;
	}
	return false;
}
static final function bool StaticSetEnemy( KFMonster M, KFMonsterController K, Pawn NewEnemy, optional bool bHateMonster )
{
	local bool bMonster;
	local float EnemyDist;

	if ( (NewEnemy == None) || (NewEnemy.Health <= 0) || (NewEnemy.Controller == None) || (NewEnemy == K.Enemy) )
		return false;

	if( !bHateMonster && KFHumanPawnEnemy(NewEnemy)!=None && KFHumanPawnEnemy(NewEnemy).AttitudeToSpecimen<=ATTITUDE_Ignore )
		Return False; // In other words, dont attack human pawns as long as they dont damage me or hates me.
	bMonster = (Monster(NewEnemy)!=None);
	if( M.Intelligence>=BRAINS_Mammal && K.Enemy!=None && NewEnemy!=None && NewEnemy!=K.Enemy && NewEnemy.Controller!=None && !bMonster )
	{
		if( K.LineOfSightTo(K.Enemy) && VSize(K.Enemy.Location-M.Location)<VSize(NewEnemy.Location-M.Location) )
			Return False;
		K.Enemy = None;
	}
	if( bHateMonster && bMonster && NewEnemy.Controller!=None && FRand()<0.15
	 && NewEnemy.Health>0 && VSize(NewEnemy.Location-M.Location)<1500 && K.LineOfSightTo(NewEnemy) ) // Get pissed at this fucker..
	{
		K.ChangeEnemy(NewEnemy,K.CanSee(NewEnemy));
		return true;
	}

	if ( !bHateMonster && bMonster )
		return false;

	if ( !K.CanSee(NewEnemy) )
		return false;

	EnemyDist = VSize(K.Enemy.Location - M.Location);
	if ( EnemyDist < M.MeleeRange )
		return false;

	if ( EnemyDist > 1.7 * VSize(NewEnemy.Location - M.Location) )
	{
		K.ChangeEnemy(NewEnemy,K.CanSee(NewEnemy));
		return true;
	}
	Return False;
}

function bool FindNewEnemy()
{
	return StaticFindNewEnemy(KFM,Self);
}
function bool SetEnemy( Pawn NewEnemy, optional bool bHateMonster )
{
	return StaticSetEnemy(KFM,Self,NewEnemy,bHateMonster);
}

defaultproperties
{
}
