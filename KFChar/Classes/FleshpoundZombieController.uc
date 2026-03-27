//-----------------------------------------------------------
//
//-----------------------------------------------------------
class FleshpoundZombieController extends KFMonsterController;

var     float       RageAnimTimeout;    // How long until the RageAnim is completed; Hack so the server doesn't get stuck in idle when its doing the Rage anim
var     float       RageFrustrationTimer;       // Tracks how long we have been walking toward a visible enemy
var     float       RageFrustrationThreshhold;  // Base value for how long the FP should walk torward an enemy without reaching them before getting frustrated and raging


function TimedFireWeaponAtEnemy()
{
	if ( (Enemy == None) || FireWeaponAt(Enemy) )
		SetCombatTimer();
	else
		SetTimer(0.01, True);
}

function ReceiveWarning(Pawn shooter, float projSpeed, vector FireDir)
{
	local float enemyDist;
	local vector X,Y,Z, enemyDir;

	// AI controlled creatures may duck if not falling
	if ( (Pawn.health <= 0) || (Enemy == None) || (Pawn.Physics == PHYS_Falling) || (Pawn.Physics == PHYS_Swimming) )
		return;

	enemyDist = VSize(shooter.Location - Pawn.Location);
	GetAxes(Pawn.Rotation,X,Y,Z);
	enemyDir = (shooter.Location - Pawn.Location)/enemyDist; // Normalize
	if ((enemyDir Dot X) < 0.8) // Less than ~36 degrees
		return;
	//ZombieFleshPound(Pawn).BlockDamage();
	if ( (FireDir Dot Y) > 0 )
	{
		Y *= -1;
		TryToDuck(Y, true);
	}
	else
		TryToDuck(Y, false);
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
	function Tick( float Delta )
	{
		local ZombieFleshPound ZFP;
        Global.Tick(Delta);

        // Make the FP rage if we haven't reached our enemy after a certain amount of time
		if( RageFrustrationTimer < RageFrustrationThreshhold )
		{
            RageFrustrationTimer += Delta;

            if( RageFrustrationTimer >= RageFrustrationThreshhold )
            {
                ZFP = ZombieFleshPound(Pawn);

                if( ZFP != none && !ZFP.bChargingPlayer )
                {
                    ZFP.StartCharging();
                    ZFP.bFrustrated = true;
                }
            }
		}
	}

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

	function BeginState()
	{
        super.BeginState();

        RageFrustrationThreshhold = default.RageFrustrationThreshhold + (Frand() * 5);
        RageFrustrationTimer = 0;
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

function SetPoundRageTimout(float NewRageTimeOut)
{
    RageAnimTimeout = NewRageTimeOut;
}

state WaitForAnim
{
Ignores SeePlayer,HearNoise,Timer,EnemyNotVisible,NotifyBump;

	function BeginState()
	{
        bUseFreezeHack = False;
	}

	// The rage anim has ended, clear the flags and let the AI do its thing
    function RageTimeout()
	{
        if( bUseFreezeHack )
		{
            if( Pawn!=None )
    		{
    			Pawn.AccelRate = Pawn.Default.AccelRate;
    			Pawn.GroundSpeed = Pawn.Default.GroundSpeed;
    		}
    		bUseFreezeHack = False;
    		AnimEnd(0);
		}
	}

	function Tick( float Delta )
	{
		Global.Tick(Delta);

		if( RageAnimTimeout > 0 )
		{
            RageAnimTimeout -= Delta;

            if( RageAnimTimeout <= 0 )
            {
                RageAnimTimeout = 0;
                RageTimeout();
            }
		}

		if( bUseFreezeHack )
		{
			MoveTarget = None;
			MoveTimer = -1;
			Pawn.Acceleration = vect(0,0,0);
			Pawn.GroundSpeed = 1;
			Pawn.AccelRate = 0;
		}
	}
	function EndState()
	{
        if( Pawn!=None )
		{
			Pawn.AccelRate = Pawn.Default.AccelRate;
			Pawn.GroundSpeed = Pawn.Default.GroundSpeed;
		}
		bUseFreezeHack = False;
	}

Begin:
	While( KFM.bShotAnim )
	{
    	Sleep(0.15);
	}
	WhatToDoNext(99);
}


defaultproperties
{
	RageFrustrationThreshhold=10.0
}
