// Zombie Soldier for KF Invasion gametype
// UPDATED : He now fires off a shotgun at ya !

class ZombieSoldier extends KFMonster;

#exec OBJ LOAD FILE=KFCharacters.utx
#exec OBJ LOAD FILE=KFCharacterModels.ukx
#exec OBJ LOAD FILE=KFWeaponSound.uax
#exec OBJ LOAD FILE=KFPlayerSound.uax
#exec OBJ LOAD FILE=PlayerSounds.uax

function ZombieMoan()
{
	local int MoanSounds;

	MoanSounds = rand(5);
	Switch(MoanSounds)
	{
		Case 0:
			PlaySound(sound'KFPlayerSound.Moan1', SLOT_Misc,255);
			Break;
		Case 1:
			PlaySound(sound'KFPlayerSound.Moan2', SLOT_Misc,255);
			Break;
		Case 2:
			PlaySound(sound'KFPlayerSound.Moan3', SLOT_Misc,255);
			Break;
		Case 3:
			PlaySound(sound'KFPlayerSound.Moan4', SLOT_Misc,255);
			Break;
		Default:
			PlaySound(sound'KFPlayerSound.zombiegrowl1', SLOT_Misc,255);
	}
}

function RangedAttack(Actor A)
{
    //local name Anim;
    //local float frame,rate;
    local int LastFireTime;

    if ( bShotAnim )
        return;

    bShotAnim = true;
    LastFireTime = Level.TimeSeconds;

    if ( Physics == PHYS_Swimming )
        SetAnimAction('Claw');
    else if ( VSize(A.Location - Location) < MeleeRange + CollisionRadius + A.CollisionRadius )
    {
        if ( FRand() < 0.7 )
        {
            SetAnimAction('Claw');
            PlaySound(sound'Spin1s', SLOT_Interact);
            Acceleration = AccelRate * Normal(A.Location - Location);
            return;
        }
        SetAnimAction('Claw');
        PlaySound(sound'Claw2s', SLOT_Interact);
        Controller.bPreparingMove = true;
        Acceleration = vect(0,0,0);
    }
    else if ( Velocity == vect(0,0,0) )
    {
        SetAnimAction('ZombieFireGun');
        Controller.bPreparingMove = true;
        Acceleration = vect(0,0,0);
        //SpawnTwoShots();
    }
    else if (VSize(A.Location - Location) < 400)
    {
      SetAnimAction('ZombieFireGun');
      Controller.bPreparingMove = true;
      Acceleration = vect(0,0,0);
    }

    else
     return;

}

simulated event SetAnimAction(name NewAction)
{
	if ( !bWaitForAnim || (Level.NetMode == NM_Client) )
	{
		// He's never able to fire the shotgun while moving.
                if(NewAction == 'ZombieFireGun')
                {
			Controller.bPreparingMove = true;
                        Acceleration = vect(0,0,0);
                }

                if(NewAction == 'Claw')
			AnimAction = meleeAnims[Rand(3)];
		else
			AnimAction = NewAction;
		if ( PlayAnim(AnimAction,,0.1) )
		{
		//	if (NewAction == 'Claw')
			//	ClawDamageTarget();
			if ( Physics != PHYS_None )
				bWaitForAnim = true;
		}

	}
}



// Change these from bright, glowing green balls, to shotgun pellets or somesuch.

function SpawnTwoShots()
{
    local vector X,Y,Z, FireStart;
    local rotator FireRotation;

    GetAxes(Rotation,X,Y,Z);
    FireStart = GetFireStart(X,Y,Z);
    if ( !SavedFireProperties.bInitialized )
    {
        SavedFireProperties.AmmoClass = MyAmmo.Class;
        SavedFireProperties.ProjectileClass = MyAmmo.ProjectileClass;
        SavedFireProperties.WarnTargetPct = MyAmmo.WarnTargetPct;
        SavedFireProperties.MaxRange = MyAmmo.MaxRange;
        SavedFireProperties.bTossed = MyAmmo.bTossed;
        SavedFireProperties.bTrySplash = MyAmmo.bTrySplash;
        SavedFireProperties.bLeadTarget = MyAmmo.bLeadTarget;
        SavedFireProperties.bInstantHit = MyAmmo.bInstantHit;
        SavedFireProperties.bInitialized = true;
    }
    FireRotation = Controller.AdjustAim(SavedFireProperties,FireStart,600);
    Spawn(MyAmmo.ProjectileClass,,,FireStart,FireRotation);

    FireStart = FireStart - 1.8 * CollisionRadius * Y;
    FireRotation.Yaw += 400;
    spawn(MyAmmo.ProjectileClass,,,FireStart, FireRotation);

    FireStart = FireStart - 1.8 * CollisionRadius * Z;
    FireRotation.Pitch += 400;
    spawn(MyAmmo.ProjectileClass,,,FireStart, FireRotation);

    FireStart = FireStart - 1.8 * CollisionRadius * X;
    FireRotation.Roll += 400;
    spawn(MyAmmo.ProjectileClass,,,FireStart, FireRotation);
}

defaultproperties
{
	MeleeAnims(0)="PoundPunch2"
	MeleeAnims(1)="PoundPunch2"
	MeleeAnims(2)="PoundPunch2"
	damageRand=5
	damageConst=8
	damageForce=5000
	HitSound(0)=Sound'KFPlayerSound.zpain1'
	HitSound(1)=Sound'KFPlayerSound.zpain2'
	HitSound(2)=Sound'KFPlayerSound.zpain3'
	HitSound(3)=Sound'KFPlayerSound.zpain4'
	AmmunitionClass=Class'KFMod.SZombieAmmo'
	ScoringValue=2
	GroundSpeed=105.000000
	WaterSpeed=100.000000
	Health=300
	MenuName="Infected Soldier"
	ControllerClass=Class'KFChar.SoldierZombieController'
	AmbientSound=Sound'KFPlayerSound.Zombiesbreath'
	Mesh=SkeletalMesh'KFCharacterModels.InfectedWhiteSoldier'
	Skins(0)=Shader'KFCharacters.Zombie8Shader'
	Mass=900.000000
	RotationRate=(Yaw=45000,Roll=0)
}
