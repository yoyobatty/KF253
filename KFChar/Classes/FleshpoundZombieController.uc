//-----------------------------------------------------------
//
//-----------------------------------------------------------
class FleshpoundZombieController extends KFMonsterController;

function TimedFireWeaponAtEnemy()
{
	if ( (Enemy == None) || FireWeaponAt(Enemy) )
		SetCombatTimer();
	else
		SetTimer(0.01, True);
}

function tick(float DeltaTime)
{
  // Set charging timeout . (in case he doesn't reach his target)

  if(pawn != none)
  {
    if(Pawn.IsA('ZombieFleshpound') && ZombieFleshPound(Pawn).bChargingPlayer)
    {
      if (Level.TimeSeconds - ChargeStart > 10)
        ZombieFleshPound(Pawn).StopCharging();
    }
    
  }

  // Reset damagetotal HitTimes;

  if(pawn != none)
  {
    if(Pawn.IsA('ZombieFleshpound') && ZombieFleshPound(Pawn).LastDamagedTime != 0)
    {
      if (Level.TimeSeconds - ZombieFleshPound(Pawn).LastDamagedTime >= 2)
        ZombieFleshPound(Pawn).TwoSecondDamageTotal = 0;
    }
  }

  super.Tick(deltaTime);
}

state Rage
{
  ignores EnemyNotVisible;

  Begin:
    //log("FLESHPOUND SPIN!");
    //Sleep(0.2);

  WaitForAnim:
	if ( Monster(Pawn).bShotAnim )
	{
		Sleep(0.1);
		Goto('WaitForAnim');
	}


	WhatToDoNext(152);
	if ( bSoaking )
		SoakStop("STUCK IN RAGE!!!");
}




state SpinAttack
{
  ignores EnemyNotVisible;

  function DoSpinDamage()
  {

    local Actor A;

    //log("FLESHPOUND DOSPINDAMAGE!");

    foreach CollidingActors(class'actor', A, (ZombieFleshpound(pawn).MeleeRange * 1.5)+pawn.CollisionRadius, pawn.Location)
    {
      //todo: height check?
      zombiefleshpound(pawn).SpinDamage(A);
    }
  }

  Begin:
    //log("FLESHPOUND SPIN!");
    //Sleep(0.2);

  WaitForAnim:
	if ( Monster(Pawn).bShotAnim )
	{
		Sleep(0.1);
		DoSpinDamage();
		Goto('WaitForAnim');
	}


	WhatToDoNext(152);
	if ( bSoaking )
		SoakStop("STUCK IN SPINATTACK!!!");
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

defaultproperties
{
}
