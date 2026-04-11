// Zombie Monster for KF Invasion gametype

class ZombieCrawler extends KFMonster;

#exec OBJ LOAD FILE=KFCharacters.utx
#exec OBJ LOAD FILE=KFCharacterModels.ukx
#exec OBJ LOAD FILE=KFWeaponSound.uax
#exec OBJ LOAD FILE=KFPlayerSound.uax
#exec OBJ LOAD FILE=PlayerSounds.uax

var() float PounceSpeed;
var bool bPouncing;

function ZombieMoan()
{
	local int MoanSounds;

	MoanSounds = rand(4);
	Switch(Moansounds)
	{
		Case 0:
			PlaySound(sound'KFPlayerSound.CrawlerShriek1', SLOT_Misc,255);
			Break;
		Case 1:
			PlaySound(sound'KFPlayerSound.CrawlerShriek2', SLOT_Misc,255);
			Break;
		Case 2:
			PlaySound(sound'KFPlayerSound.CrawlerShriek3', SLOT_Misc,255);
			Break;
		Default:
			PlaySound(sound'KFPlayerSound.CrawlerShriek4', SLOT_Misc,255);
	}
}

function bool DoPounce()
{
	if ( bIsCrouched || bWantsToCrouch || (Physics != PHYS_Walking) || VSize(Location - Controller.Target.Location) > (MeleeRange * 5) )
		return false;

	Velocity = Normal(Controller.Target.Location-Location)*PounceSpeed;
	Velocity.Z = JumpZ;
	SetPhysics(PHYS_Falling);
	ZombieSpringAnim();
	bPouncing=true;
	return true;
}

simulated function ZombieSpringAnim()
{
	SetAnimAction('ZombieSpring');
}

event Landed(vector HitNormal)
{
	bPouncing=false;
	super.Landed(HitNormal);
}

event Bump(actor Other)
{
	// TODO: is there a better way
	if(bPouncing && KFHumanPawn(Other)!=none )
	{
		KFHumanPawn(Other).TakeDamage(damageConst + rand(damageRand), self ,self.Location,self.velocity, class 'KFmod.ZombieMeleeDamage');
		if (KFHumanPawn(Other).Health <=0)
		{
			//TODO - move this to humanpawn.takedamage? Also see KFMonster.MeleeDamageTarget
			KFHumanPawn(Other).SpawnGibs(self.rotation, 1);
		}
		//After impact, there'll be no momentum for further bumps
		bPouncing=false;
	}
}

// Blend his attacks so he can hit you in mid air.
simulated function int DoAnimAction( name AnimName )
{
	if( AnimName=='ZombieLeapAttack' || AnimName=='LeapAttack3' || AnimName=='ZombieLeapAttack' )
	{
		AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
		PlayAnim(AnimName,, 0.0, 1);
		Return 1;
	}
	Return Super.DoAnimAction(AnimName);
}

function bool FlipOver()
{
	Return False;
}

defaultproperties
{
     PounceSpeed=330.000000
     MeleeAnims(0)="ZombieLeapAttack"
     MeleeAnims(1)="ZombieLeapAttack"
     MeleeAnims(2)="LeapAttack3"
     HitAnims(0)="ZombieSpring"
     HitAnims(1)="ZombieSpring"
     HitAnims(2)="ZombieSpring"
     KFHitFront="ZombieSpring"
     KFHitBack="ZombieSpring"
     KFHitLeft="ZombieSpring"
     KFHitRight="ZombieSpring"
     RunAnim=""
     bStunImmune=True
     bCannibal=True
     damageRand=4
     damageConst=4
     damageForce=5000
     KFRagdollName="CrawlerRag"
     Intelligence=BRAINS_Mammal
     HitSound(0)=Sound'KFPlayerSound.zpain1'
     HitSound(1)=Sound'KFPlayerSound.zpain2'
     HitSound(2)=Sound'KFPlayerSound.zpain3'
     HitSound(3)=Sound'KFPlayerSound.zpain4'
     ScoringValue=1
     IdleHeavyAnim="ZombieLeapIdle"
     IdleRifleAnim="ZombieLeapIdle"
     bCrawler=True
     GroundSpeed=140.000000
     WaterSpeed=130.000000
     JumpZ=350.000000
     Health=100
     MenuName="Crawler"
     ControllerClass=Class'KFChar.CrawlerController'
     MovementAnims(0)="ZombieScuttle"
     MovementAnims(1)="ZombieScuttle"
     MovementAnims(2)="ZombieScuttle"
     MovementAnims(3)="ZombieScuttle"
     TurnLeftAnim="ZombieLeapIdle"
     TurnRightAnim="ZombieLeapIdle"
     WalkAnims(0)="ZombieScuttle"
     WalkAnims(1)="ZombieScuttle"
     WalkAnims(2)="ZombieScuttle"
     WalkAnims(3)="ZombieScuttle"
     AirAnims(0)="ZombieSpring"
     AirAnims(1)="ZombieSpring"
     AirAnims(2)="ZombieSpring"
     AirAnims(3)="ZombieSpring"
     TakeoffAnims(0)="ZombieSpring"
     TakeoffAnims(1)="ZombieSpring"
     TakeoffAnims(2)="ZombieSpring"
     TakeoffAnims(3)="ZombieSpring"
     LandAnims(0)="ZombieLeapIdle"
     LandAnims(1)="ZombieLeapIdle"
     LandAnims(2)="ZombieLeapIdle"
     LandAnims(3)="ZombieLeapIdle"
     AirStillAnim="ZombieSpring"
     TakeoffStillAnim="ZombieLeap"
     IdleCrouchAnim="ZombieLeapIdle"
     IdleWeaponAnim="ZombieLeapIdle"
     IdleRestAnim="ZombieLeapIdle"
     SpineBone1=
     SpineBone2=
     bOrientOnSlope=True
     Mesh=SkeletalMesh'KFCharacterModels.Shade'
     Skins(0)=Shader'KFCharacters.Zombie9Shader'
     Skins(1)=FinalBlend'KFCharacters.CrawlerHairFB'
     CollisionHeight=25.000000
}
