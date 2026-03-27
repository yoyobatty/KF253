class SawZombieController extends KFMonsterController;
// Custom Zombie Thinkerating
// By : Alex


function TimedFireWeaponAtEnemy()
{
	if ( (Enemy == None) || FireWeaponAt(Enemy) )
		SetCombatTimer();
	else
		SetTimer(0.01, True);
}

state ZombieCharge
{
    function bool StrafeFromDamage(float Damage, class<DamageType> DamageType, bool bFindDest)
	{
        return false;
    }

    // I suspect this function causes bloats to get confused
    function bool TryStrafe(vector sideDir)
	{
        return false;
	}

	function Timer()
	{
		Disable('NotifyBump');
		Target = Enemy;
		TimedFireWeaponAtEnemy();
	}

WaitForAnim:


	if ( Monster(Pawn).bShotAnim )
	{
		Goto('Moving');
	}
	if ( !FindBestPathToward(Enemy, false,true) )
		GotoState('ZombieRestFormation');
Moving:
	MoveToward(Enemy);
	WhatToDoNext(17);
	if ( bSoaking )
		SoakStop("STUCK IN CHARGING!");
}

function tick(float DeltaTime)
{
     local ZombieScrake Scrake;

     super.tick(DeltaTime);



    if(pawn != none)
    {
      Scrake = ZombieScrake(pawn);
      //Log("BImpaling "$Scrake.bSawImpaling);

       if (Scrake.bSawImpaling && VSize(Enemy.Location - Pawn.Location) > (Pawn.MeleeRange * 1.25 ))
	{
          Scrake.StopImpaling();
	}

        if(Level.TimeSeconds>(TimeToSet+2.0)&&!ItsSet)
        {
	       if(Pawn.IsA('ZombieScrake'))
                {
			Pawn.SetCollisionSize(38,55);
			ItsSet=true;
                }
                else
			ItsSet=true;
	}
     }
}

defaultproperties
{
}
