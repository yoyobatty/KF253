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

state SpinAttack
{
ignores EnemyNotVisible;

	function DoSpinDamage()
	{
		local Actor A;

		//log("FLESHPOUND DOSPINDAMAGE!");
		foreach CollidingActors(class'actor', A, (ZombieFleshpound(pawn).MeleeRange * 1.5)+pawn.CollisionRadius, pawn.Location)
			zombiefleshpound(pawn).SpinDamage(A);
	}

Begin:

WaitForAnim:
	While( KFM.bShotAnim )
	{
		Sleep(0.1);
		DoSpinDamage();
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
