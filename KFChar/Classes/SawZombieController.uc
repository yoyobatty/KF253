class SawZombieController extends KFMonsterController;
// Custom Zombie Thinkerating
// By : Alex

function TimedFireWeaponAtEnemy()
{
	if ( (Enemy == None) || FireWeaponAt(Enemy) )
		SetCombatTimer();
	else SetTimer(0.01, True);
}

state ZombieCharge
{
	function bool StrafeFromDamage(float Damage, class<DamageType> DamageType, bool bFindDest)
	{
		return false;
	}
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

	While( Monster(Pawn).bShotAnim )
		Sleep(0.25);
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
