// Zombie Monster for KF Invasion gametype

#exec OBJ LOAD FILE=KFCharacters.utx
#exec OBJ LOAD FILE=KFCharacterModels.ukx
#exec OBJ LOAD FILE=KFWeaponSound.uax
#exec OBJ LOAD FILE=KFPlayerSound.uax
#exec OBJ LOAD FILE=PlayerSounds.uax

class ZombieBloat extends KFMonster ;

var BileJet BloatJet;
var bool bPlayBileSplash;

// This will go in Fleshpound and Bloat Code to make them Respond to LAW Rockets or Grenades exploding nearby them.

// Important Block of code controlling how the Zombies (excluding the Bloat and Fleshpound who cannot be stunned, respond to damage from the
// various weapons in the game. The basic rule is that any damage amount equal to or greater than 40 points will cause a stun.
// There are exceptions with the fists however, which are substantially under the damage quota but can still cause stuns 50% of the time.
// Why? Cus if they didn't at least have that functionality, they would be fundamentally useless. And anyone willing to take on a hoarde of zombies
// with only the gloves on his hands, deserves more respect than that!

function bool FlipOver()
{
	Return False;
}

function DoorAttack(Actor A)
{
	if ( bShotAnim || Physics == PHYS_Swimming)
		return;
	else if ( A!=None )
	{
		bShotAnim = true;
		if( !bDecapitated )
			SetAnimAction('ZombieBarf');
		else
		{
			SetAnimAction('Claw');
			PlaySound(sound'Claw2s', SLOT_None);
		}
	}
}
function RangedAttack(Actor A)
{
	local int LastFireTime;

	if ( bShotAnim )
		return;

	if ( Physics == PHYS_Swimming )
	{
		SetAnimAction('Claw');
		bShotAnim = true;
		LastFireTime = Level.TimeSeconds;
	}
	else if ( VSize(A.Location - Location) < MeleeRange + CollisionRadius + A.CollisionRadius )
	{
		bShotAnim = true;
		LastFireTime = Level.TimeSeconds;
		SetAnimAction('Claw');
		PlaySound(sound'Claw2s', SLOT_Interact);
		Controller.bPreparingMove = true;
		Acceleration = vect(0,0,0);
	}
	else if( (KFDoorMover(A)!=None || VSize(A.Location-Location)<=250) && !bDecapitated )
	{
		bShotAnim=true;
		SetAnimAction('ZombieBarf');
		Controller.bPreparingMove = true;
		Acceleration = vect(0,0,0);
	}
}


// Barf Time.

function SpawnTwoShots()
{
    local vector X,Y,Z, FireStart;
    local rotator FireRotation;

    if( Controller!=None && KFDoorMover(Controller.Target)!=None )
    {
        Controller.Target.TakeDamage(22,Self,Location,vect(0,0,0),Class'DamTypeVomit');
        return;
    }

    GetAxes(Rotation,X,Y,Z);
    FireStart = Location+(vect(30,0,64) >> Rotation)*DrawScale;
    if ( !SavedFireProperties.bInitialized )
    {
        SavedFireProperties.AmmoClass = MyAmmo.Class;
        SavedFireProperties.ProjectileClass = MyAmmo.ProjectileClass;
        SavedFireProperties.WarnTargetPct = 1;
        SavedFireProperties.MaxRange = 500;
        SavedFireProperties.bTossed = False;
        SavedFireProperties.bTrySplash = False;
        SavedFireProperties.bLeadTarget = True;
        SavedFireProperties.bInstantHit = True;
        SavedFireProperties.bInitialized = True;
    }
    ToggleAuxCollision(false);
    FireRotation = Controller.AdjustAim(SavedFireProperties,FireStart,600);
    Spawn(MyAmmo.ProjectileClass,,,FireStart,FireRotation);

    FireStart-=(0.5*CollisionRadius*Y);
    FireRotation.Yaw -= 1200;
    spawn(MyAmmo.ProjectileClass,,,FireStart, FireRotation);
    FireStart+=(CollisionRadius*Y);
    FireRotation.Yaw += 2400;
    spawn(MyAmmo.ProjectileClass,,,FireStart, FireRotation);
    ToggleAuxCollision(true);
}


simulated function Tick(float deltatime)
{
    local vector BileExplosionLoc;
    local BileExplosion GibBileExplosion;

    Super.tick(deltatime);

    if( Level.NetMode!=NM_DedicatedServer && BloatJet!=None && !bPlayBileSplash )
    {
        BileExplosionLoc = self.Location;
        BileExplosionLoc.z += (CollisionHeight - (CollisionHeight * 0.5));

        GibBileExplosion = Spawn(class 'BileExplosion',self,, BileExplosionLoc );
        bPlayBileSplash = true;
    }
}

function BileBomb()
{
	local bool AttachSucess;

	BloatJet = spawn(class'BileJet', self,,,);

	AttachSucess=AttachToBone(BloatJet,'Bip01 Spine');

	if(!AttachSucess)
		BloatJet.SetBase(self);
	BloatJet.SetRelativeRotation(rot(0,-4096,0));
}

function PlayDyingAnimation(class<DamageType> DamageType, vector HitLoc)
{
  local bool AttachSucess;

  super.PlayDyingAnimation(DamageType, HitLoc);
  
  if(BloatJet!=none)
  {
    AttachSucess=AttachToBone(BloatJet,'Bip01 Spine');
   // else
     // AttachSucess=AttachToBone(BloatJet,'Bip01 Spine1');

    if(!AttachSucess)
    {
      log("DEAD Bloaty Bile didn't like the Boning :o");
      BloatJet.SetBase(self);
    }
    BloatJet.SetRelativeRotation(rot(0,-4096,0));
  }
}

State Dying
{
  function tick(float deltaTime)
  {
   if (BloatJet != none)
   {
    BloatJet.SetLocation(location);

    BloatJet.SetRotation(GetBoneRotation('Bip01 Spine'));
   }
    super.tick(deltaTime);
  }
}

function RemoveHead()
{
	bCanDistanceAttackDoors = False;
	Super.RemoveHead();
}
function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
	// Bloats are volatile. They burn faster than other zeds.
	if (DamageType == class 'Burned')
		Damage *= 1.5;
	if( damageType==Class'DamTypeVomit' )
		return;

	// Bile bomb on lethal hit
	if( (Health - Damage) <= 0 && BloatJet == None )
	{
		BileBomb();
	}

  Super.TakeDamage(Damage,instigatedBy,hitlocation,momentum,damageType);
}

function TakeBileDamage()
{
}

defaultproperties
{
  MeleeAnims(0)="BloatChop2"
  MeleeAnims(1)="BloatChop2"
  MeleeAnims(2)="BloatChop2"
  MoanVoice(0)=Sound'KFPlayerSound.BloatVoice1'
  MoanVoice(1)=Sound'KFPlayerSound.BloatVoice3'
  MoanVoice(2)=Sound'KFPlayerSound.BloatVoice4'
  damageRand=8
  damageConst=10
  damageForce=70000
  bFatAss=True
  KFRagdollName="BloatRag"
  PuntAnim="BloatPunt"
  Intelligence=BRAINS_Stupid
  bCanDistanceAttackDoors=True
  bUseExtendedCollision=True
  ColOffset=(Z=60)//(Z=42)
  ColRadius=27
  ColHeight=22//40
  HitSound(0)=Sound'KFPlayerSound.zpain1'
  HitSound(1)=Sound'KFPlayerSound.zpain2'
  HitSound(2)=Sound'KFPlayerSound.zpain3'
  HitSound(3)=Sound'KFPlayerSound.zpain4'
  ChallengeSound(0)=Sound'KFPlayerSound.BloatVoice1'
  ChallengeSound(1)=Sound'KFPlayerSound.BloatVoice3'
  ChallengeSound(2)=Sound'KFPlayerSound.BloatVoice3'
  ChallengeSound(3)=Sound'KFPlayerSound.BloatVoice4'
  AmmunitionClass=Class'KFMod.BZombieAmmo'
  ScoringValue=2
  IdleHeavyAnim="BloatIdle"
  IdleRifleAnim="BloatIdle"
  MeleeRange=55.000000
  GroundSpeed=75.000000
  WaterSpeed=102.000000
  HealthMax=500.000000
  Health=500
  HeadHeight=2.5
  HeadScale=1.5
  MenuName="Bloat"
  ControllerClass=Class'KFChar.BloatZombieController'
  MovementAnims(0)="WalkBloat"
  MovementAnims(1)="WalkBloat"
  MovementAnims(2)="WalkBloat"
  MovementAnims(3)="WalkBloat"
  WalkAnims(0)="WalkBloat"
  WalkAnims(1)="WalkBloat"
  WalkAnims(2)="WalkBloat"
  WalkAnims(3)="WalkBloat"
  IdleCrouchAnim="BloatIdle"
  IdleWeaponAnim="BloatIdle"
  IdleRestAnim="BloatIdle"
  AmbientSound=Sound'KFPlayerSound.Zombiesbreath'
  Mesh=SkeletalMesh'KFCharacterModels.Bloat'
  PrePivot=(Z=8.000000)
  Skins(0)=Shader'KFCharacters.Zombie7Shader'
  Skins(1)=Texture'KFCharacters.BloatCleaverSkin'
  Mass=400.000000
  RotationRate=(Yaw=45000,Roll=0)
}
