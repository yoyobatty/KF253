// Zombie Monster for KF Invasion gametype

#exec OBJ LOAD FILE=KFCharacters.utx
#exec OBJ LOAD FILE=KFCharacterModels.ukx
#exec OBJ LOAD FILE=KFWeaponSound.uax
#exec OBJ LOAD FILE=KFPlayerSound.uax
#exec OBJ LOAD FILE=PlayerSounds.uax

class ZombieFleshPoundRange extends KFMonster ;

var () float BlockDamageReduction;
var bool bChargingPlayer;
var int TwoSecondDamageTotal;
var float LastDamagedTime;


simulated function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
  local int BlockSlip;
  local float BlockChance;
  local Vector X,Y,Z, Dir;

  GetAxes(Rotation, X,Y,Z);
  //hitlocation.Z = Location.Z;

  LastDamagedTime = Level.TimeSeconds;
  TwoSecondDamageTotal += Damage;
  
  // He's impervious to small arms fire (non explosives)
  // Frags and LAW rockets will bring him down way faster than bullets and shells.
  if (DamageType != class 'DamTypeFrag')
   Damage *= 0.5;

  // Shut off his "Device" when dead
  if (Damage >= Health)
   Skins[2]=Texture'KillingFloorLabTextures.LabCommon.voidtex' ;

  // Damage Berserk responses...
  // Start a charge.
  // The Lower his health, the less damage needed to trigger this response.


  // Calculate whether the shot was coming from in front.
  Dir = -Normal(Location - hitlocation);
  BlockSlip = rand(5);

  if (AnimAction == 'PoundBlock')
  {
   Damage *= BlockDamageReduction;
   //Log("Blocked!");
  }

  if (Dir Dot X > 0.7 || Dir == vect(0,0,0))
  {
   BlockChance = (Health / HealthMax * 100 ) - Damage * 0.25;
   //Log(BlockChance);
  }


  // We are healthy enough to block the attack, and we succeeded the blockslip.
  // only 40% damage is done in this circumstance.

  //TODO - bring this back?

  /*
  if (BlockChance > Damage && BlockSlip > 2)
  {
    Damage *= BlockDamageReduction;
    //Log("Blocked!");
    SetAnimAction('PoundBlock');
    Controller.bPreparingMove = true;
    Acceleration = vect(0,0,0);


  }
  */
    // Log (Damage);

    if (damageType == class 'DamTypeVomit')
    Damage = 0; // nulled
    //Damage -= (Damage*2); // Heals himself /w vomit.

    if((Health - Damage) > 0)
        Momentum = vect(0,0,0) ;
        Super.takeDamage(Damage, instigatedBy, hitLocation, momentum, damageType) ;



}


simulated event SetAnimAction(name NewAction)
{
//local int meleeAnimIndex;
//  local name TempAction;




    if (!bWaitForAnim)
    {
	    AnimAction = NewAction;

			if ( AnimAction == KFHitFront )
        {
            AnimBlendParams(1, 1.0, 0.0,,'Bip01 Spine1');
            PlayAnim(NewAction,, 0.0, 1);
        }

		else if ( AnimAction == KFHitBack )
        {
            AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
            PlayAnim(NewAction,, 0.0, 1);
        }
		else if ( AnimAction == KFHitRight )
        {
            AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
            PlayAnim(NewAction,, 0.0, 1);
        }
		else if ( AnimAction == KFHitLeft )
        {
            AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
            PlayAnim(NewAction,, 0.0, 1);
        }		
		else if ( AnimAction == 'PoundRage' )
        {
            AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
            PlayAnim(NewAction,, 0.0, 1);
        }

		else if ( AnimAction == 'PoundAttack1' )
        {
            AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
            PlayAnim(NewAction,, 0.0, 1);
        }
		else if ( AnimAction == 'PoundAttack2' )
        {
            AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
            PlayAnim(NewAction,, 0.0, 1);
        }
		else if ( AnimAction == 'ZombieFireGun' )
        {
            AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
            PlayAnim(NewAction,, 0.0, 1);
        }


     		   else if(AnimAction == 'Claw')
        {

    AnimAction=meleeAnims[Rand(3)];
	SetAnimAction(AnimAction);
	return;
	}

  		if(AnimAction=='PoundAttack3')
      fleshpoundZombieController(controller).GotoState('spinattack');
		
		else if(NewAction == 'ZombieFeed')
        {
			AnimAction = NewAction;
			LoopAnim(AnimAction,,0.1);
		 }
		 else
			AnimAction = NewAction;

        if ( PlayAnim(AnimAction,,0.1) && AnimAction != KFHitFront 
        && AnimAction != KFHitBack
        && AnimAction != KFHitLeft
        && AnimAction != KFHitRight
        && AnimAction != 'PoundRage' 
        && AnimAction != 'PoundAttack1' 
        && AnimAction != 'PoundAttack2' 
        && AnimAction != 'ZombieFireGun'
        ) 
		{
		//	if (NewAction == 'Claw')
			//	ClawDamageTarget();
			if ( Physics != PHYS_None )
				bWaitForAnim = true;
		}

	
    }
}

  /*
function bool SameSpeciesAs(Pawn P)
{
     return false;
}

*/

function RangedAttack(Actor A)
{
    //local name Anim;
    //local float frame,rate;
    local int LastFireTime;

    if ( bShotAnim )
        return;

    if ( Physics == PHYS_Swimming )
    {
        SetAnimAction('Claw');
        bShotAnim = true;
        LastFireTime = Level.TimeSeconds;
    }
    //TODO - why is melee stuff in ranged attack anyway?
    //       are we better off having melee code, thus saving
    //       us from having to check rangedattack stuff unless
    //       we actually have a ranged attack
    else if ( VSize(A.Location - Location) < MeleeRange + CollisionRadius + A.CollisionRadius )
    {
      bShotAnim = true;
      LastFireTime = Level.TimeSeconds;

      // TODO: random chance of not barfing?
      // TODO: make controller specify barf,charge or stationary attack?

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
    else if (VSize(A.Location - Location) <= 1200 && !bDecapitated)
    {
      bShotAnim=true;
      SetAnimAction('ZombieFireGun');
      bWaitForAnim = false;
      //Controller.bPreparingMove = true;
      //Acceleration = vect(0,0,0);

      //Controller.GotoState(,'WaitForAnim');

    }

    /*
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
    else if ( Velocity == vect(0,0,0) &&  !bDecapitated )
    {
        SetAnimAction('ZombieBarf');
        Controller.bPreparingMove = true;
        Acceleration = vect(0,0,0);
        //SpawnTwoShots();
    }
    else if (VSize(A.Location - Location) <= 250)
    {
      SetAnimAction('ZombieBarf');
      Controller.bPreparingMove = true;
      Acceleration = vect(0,0,0);
    }

    else
     return;
     */

}


function vector GetFireStart(vector X, vector Y, vector Z)
{
    return Location + 0.5 * CollisionRadius * (X+Z-Y);
}


// Barf Time.

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
    FireRotation = Controller.AdjustAim(SavedFireProperties,FireStart,1200);
    Spawn(MyAmmo.ProjectileClass,,,FireStart,FireRotation);

    /*
    FireStart = FireStart - 1.8 * CollisionRadius * Y;
    FireRotation.Yaw += 400;
    spawn(MyAmmo.ProjectileClass,,,FireStart, FireRotation);

    FireStart = FireStart - 1.8 * CollisionRadius * Z;
    FireRotation.Pitch += 400;
    spawn(MyAmmo.ProjectileClass,,,FireStart, FireRotation);

    FireStart = FireStart - 1.8 * CollisionRadius * X;
    FireRotation.Roll += 400;
    spawn(MyAmmo.ProjectileClass,,,FireStart, FireRotation);
    */

}

defaultproperties
{
     MeleeAnims(0)="ZombieFireGun"
     MeleeAnims(1)="ZombieFireGun"
     MeleeAnims(2)="ZombieFireGun"
     damageRand=15
     damageConst=25
     damageForce=150000
     bFatAss=True
     KFRagdollName="FleshPoundRag"
     bBoss=True
     HitSound(0)=Sound'KFPlayerSound.zpain1'
     HitSound(1)=Sound'KFPlayerSound.zpain2'
     HitSound(2)=Sound'KFPlayerSound.zpain3'
     HitSound(3)=Sound'KFPlayerSound.zpain4'
     AmmunitionClass=Class'KFMod.SZombieAmmo'
     ScoringValue=10
     IdleHeavyAnim="PoundIdle"
     IdleRifleAnim="PoundIdle"
     RagDeathVel=100.000000
     RagDeathUpKick=100.000000
     MeleeRange=60.000000
     GroundSpeed=100.000000
     WaterSpeed=90.000000
     Health=1000
     MenuName="Flesh Pounder"
     MovementAnims(0)="PoundWalk"
     MovementAnims(1)="PoundWalk"
     MovementAnims(2)="PoundWalk"
     MovementAnims(3)="PoundWalk"
     WalkAnims(0)="PoundWalk"
     WalkAnims(1)="PoundWalk"
     WalkAnims(2)="PoundWalk"
     WalkAnims(3)="PoundWalk"
     IdleCrouchAnim="PoundIdle"
     IdleWeaponAnim="PoundIdle"
     IdleRestAnim="PoundIdle"
     AmbientSound=Sound'KFPlayerSound.Zombiesbreath'
     Mesh=SkeletalMesh'KFCharacterModels.RangedPound'
     Skins(0)=Texture'KFCharacters.GunPoundSkin'
     Skins(1)=Shader'KFCharacters.PoundBitsShader'
     Skins(2)=Texture'KFCharacters.AutoTurretGunTex1'
     CollisionRadius=40.000000
     CollisionHeight=64.000000
     Mass=600.000000
     RotationRate=(Yaw=45000,Roll=0)
}
