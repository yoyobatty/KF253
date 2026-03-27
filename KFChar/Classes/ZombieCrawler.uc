// Zombie Monster for KF Invasion gametype

class ZombieCrawler extends KFMonster ;

#exec OBJ LOAD FILE=KFCharacters.utx
#exec OBJ LOAD FILE=KFCharacterModels.ukx
#exec OBJ LOAD FILE=KFWeaponSound.uax
#exec OBJ LOAD FILE=KFPlayerSound.uax
#exec OBJ LOAD FILE=PlayerSounds.uax

var float PounceSpeed;
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
	local vector X,Y,Z;

	if ( bIsCrouched || bWantsToCrouch || (Physics != PHYS_Walking) ||
  VSize(Location - Controller.Target.Location) > (MeleeRange * 5) )
		return false;

    GetAxes(Rotation,X,Y,Z);
	//if (DoubleClickMove == DCLICK_Forward)
		Velocity = PounceSpeed*X + (Velocity dot Y)*Y;
	//else if (DoubleClickMove == DCLICK_Back)
	//	Velocity = -1.5*GroundSpeed*X + (Velocity Dot Y)*Y;
	//else if (DoubleClickMove == DCLICK_Left)
	//	Velocity = 1.5*GroundSpeed*Y + (Velocity Dot X)*X;
	//else if (DoubleClickMove == DCLICK_Right)
	//	Velocity = -1.5*GroundSpeed*Y + (Velocity Dot X)*X;

	Velocity.Z = JumpZ;
	//CurrentDir = DoubleClickMove;
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

simulated event SetAnimAction(name NewAction)
{
  Super.SetAnimAction(NewAction);

 	   if ( AnimAction == 'ZombieLeapAttack' || AnimAction == 'LeapAttack3'
            || AnimAction == 'ZombieLeapAttack')
	    {
	      AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
	      PlayAnim(NewAction,, 0.0, 1);
	    }

}

/*

function rotator rTurn(rotator rHeading,rotator rTurnAngle)
{
    // Generate a turn in object coordinates
    //     this should handle any gymbal lock issues

    local vector vForward,vRight,vUpward;
    local vector vForward2,vRight2,vUpward2;
    local rotator T;
    local vector  V;

    GetAxes(rotation,vForward,vRight,vUpward);
    //  rotate in plane that contains vForward&vRight
    T.Yaw=rTurnAngle.Yaw; V=vector(T);
    vForward2=V.X*vForward + V.Y*vRight;
    vRight2=V.X*vRight - V.Y*vForward;
    vUpward2=vUpward;

    // rotate in plane that contains vForward&vUpward
    T.Yaw=rTurnAngle.Pitch; V=vector(T);
    vForward=V.X*vForward2 + V.Y*vUpward2;
    vRight=vRight2;
    vUpward=V.X*vUpward2 - V.Y*vForward2;

    // rotate in plane that contains vUpward&vRight
    T.Yaw=rTurnAngle.Roll; V=vector(T);
    vForward2=vForward;
    vRight2=V.X*vRight + V.Y*vUpward;
    vUpward2=V.X*vUpward - V.Y*vRight;

    T=OrthoRotation(vForward2,vRight2,vUpward2);

   return(T);
}
*/

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
     bStunImmune=True
     bCannibal=True
     damageRand=4
     damageConst=8
     damageForce=5000
     KFRagdollName="CrawlerRag"
     HitSound(0)=Sound'KFPlayerSound.zpain1'
     HitSound(1)=Sound'KFPlayerSound.zpain2'
     HitSound(2)=Sound'KFPlayerSound.zpain3'
     HitSound(3)=Sound'KFPlayerSound.zpain4'
     ScoringValue=1
     IdleHeavyAnim="ZombieLeapIdle"
     IdleRifleAnim="ZombieLeapIdle"
     GroundSpeed=140.000000
     WaterSpeed=130.000000
     JumpZ=350.000000
     HealthMax=110.000000
     Health=110
     MenuName="Crawler"
     ControllerClass=Class'KFChar.CrawlerController'
     MovementAnims(0)="ZombieScuttle"
     MovementAnims(1)="ZombieScuttle"
     MovementAnims(2)="ZombieScuttle"
     MovementAnims(3)="ZombieScuttle"
     TurnLeftAnim="ZombieLeapIdle"
     TurnRightAnim="ZombieLeapIdle"
     WalkAnims(0)="ZombieLeap"
     WalkAnims(1)="ZombieLeap"
     WalkAnims(2)="ZombieLeap"
     WalkAnims(3)="ZombieLeap"
     AirAnims(0)="ZombieLeap"
     AirAnims(1)="ZombieLeap"
     AirAnims(2)="ZombieLeap"
     AirAnims(3)="ZombieLeap"
     TakeoffAnims(0)="ZombieLeap"
     TakeoffAnims(1)="ZombieLeap"
     TakeoffAnims(2)="ZombieLeap"
     TakeoffAnims(3)="ZombieLeap"
     LandAnims(0)="ZombieLeapIdle"
     LandAnims(1)="ZombieLeapIdle"
     LandAnims(2)="ZombieLeapIdle"
     LandAnims(3)="ZombieLeapIdle"
     AirStillAnim="ZombieLeapIdle"
     TakeoffStillAnim="ZombieLeap"
     IdleCrouchAnim="ZombieLeapIdle"
     IdleWeaponAnim="ZombieLeapIdle"
     IdleRestAnim="ZombieLeapIdle"
     bOrientOnSlope=True
     Mesh=SkeletalMesh'KFCharacterModels.Shade'
     Skins(0)=Shader'KFCharacters.Zombie9Shader'
     Skins(1)=FinalBlend'KFCharacters.CrawlerHairFB'
     CollisionHeight=25.000000
}
