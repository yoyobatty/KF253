// Zombie Monster for KF Invasion gametype
class ZombieClot extends KFMonster;

#exec OBJ LOAD FILE=KFCharacters.utx
#exec OBJ LOAD FILE=KFCharacterModels.ukx
#exec OBJ LOAD FILE=KFWeaponSound.uax
#exec OBJ LOAD FILE=KFPlayerSound.uax
#exec OBJ LOAD FILE=PlayerSounds.uax

var KFPawn DisabledPawn;
var     bool    bGrappling;             // This zombie is grappling someone
var     float   GrappleEndTime;         // When the current grapple should be over
var()   float   GrappleDuration;        // How long a grapple by this zombie should last

replication
{
	reliable if(bNetDirty && Role == ROLE_Authority)
		bGrappling;
}

function BreakGrapple()
{
	if( DisabledPawn != none )
	{
	     DisabledPawn.bMovementDisabled = false;
	     DisabledPawn = none;
	}
}

function ClawDamageTarget()
{
	local vector PushDir;
	local KFPawn KFP;
  
	Super.ClawDamageTarget();

	// If zombie has latched onto us...
	if ( MeleeDamageTarget( (damageConst + rand(damageRand) ), PushDir))
	{
		KFP = KFPawn(Controller.Target);

        if( !bDecapitated && KFP != none )
        {
			if ( KFPlayerReplicationInfo(KFP.PlayerReplicationInfo) == none ||
				 KFP.GetVeteran().static.CanBeGrabbed(self))
			{
				if( DisabledPawn != none )
				{
				     DisabledPawn.bMovementDisabled = false;
				}

				KFP.DisableMovement(GrappleDuration);
				DisabledPawn = KFP;
			}
		}
	}
}

function RangedAttack(Actor A)
{
	if ( bShotAnim || Physics == PHYS_Swimming )
		return;
	else if ( CanAttack(A) )
	{
		bShotAnim = true;
		SetAnimAction('Claw');
          return;
		//PlaySound(sound'Claw2s', SLOT_None); Unsuitable sound for here.
          /* 
		Acceleration = Normal(A.Location-Location)*600;
		Controller.GoToState('WaitForAnim');
		Controller.MoveTarget = A;
		Controller.MoveTimer = 1.5;
          */
	}
}
function RemoveHead()
{
	Super.RemoveHead();
	MeleeAnims[0] = 'Claw';
	MeleeAnims[1] = 'Claw';
	MeleeAnims[2] = 'Claw2';
	
    damageRand *= 2;
    damageConst *= 2;
    MeleeRange *= 2;
}

simulated function int DoAnimAction( name AnimName )
{
	if( AnimName=='ClotGrapple' )
	{
          AnimBlendParams(1, 1.0, 0.1,, FireRootBone);
          PlayAnim(AnimName,, 0.1, 1);

          bGrappling = true;
          GrappleEndTime = Level.TimeSeconds + GrappleDuration;

		return 1;
	}

	return super.DoAnimAction( AnimName );
}

simulated function Tick(float DeltaTime)
{
    super.Tick(DeltaTime);

	if( bShotAnim && Role == ROLE_Authority && Controller != None )
	{
		if( Controller.MoveTarget!=None )
		{
		    Acceleration = AccelRate * Normal(Controller.MoveTarget.Location - Location);
		}
    }

	if( Role == ROLE_Authority && bGrappling )
	{
		if( Level.TimeSeconds > GrappleEndTime )
		{
		    bGrappling = false;
		}
    }

    // if we move out of melee range, stop doing the grapple animation
    if( bGrappling && Controller != None && Controller.MoveTarget != none )
    {
        if( VSize(Controller.MoveTarget.Location - Location) > MeleeRange + CollisionRadius + Controller.MoveTarget.CollisionRadius )
        {
            bGrappling = false;
            AnimEnd(1);
        }
    }
}

defaultproperties
{
     GrappleDuration=1.500000
     MeleeAnims(0)="ClotGrapple"
     MeleeAnims(1)="ClotGrapple"
     MeleeAnims(2)="ClotGrapple"
     MoanVoice(0)=Sound'KFPlayerSound.ClotVoice1'
     MoanVoice(1)=Sound'KFPlayerSound.ClotVoice2'
     MoanVoice(2)=Sound'KFPlayerSound.ClotVoice3'
     MoanVoice(3)=Sound'KFPlayerSound.ClotVoice4'
     MoanVoice(4)=Sound'KFPlayerSound.ClotVoice5'
     bCannibal=True
     damageRand=2
     damageConst=3
     damageForce=5000
     KFRagdollName="ClotRag"
     PuntAnim="ClotPunt"
     AdditionalWalkAnims(0)="ClotWalk2"
     Intelligence=BRAINS_Mammal
     HitSound(0)=Sound'KFPlayerSound.zpain1'
     HitSound(1)=Sound'KFPlayerSound.zpain2'
     HitSound(2)=Sound'KFPlayerSound.zpain3'
     HitSound(3)=Sound'KFPlayerSound.zpain4'
     ScoringValue=1
     MeleeRange=30.000000
     GroundSpeed=105.000000
     WaterSpeed=105.000000
     HealthMax=200.000000
     Health=200
     MenuName="Clot"
     MovementAnims(0)="ClotWalk"
     WalkAnims(0)="ClotWalk"
     WalkAnims(1)="ClotWalk"
     WalkAnims(2)="ClotWalk"
     WalkAnims(3)="ClotWalk"
     AmbientSound=Sound'KFPlayerSound.Zombiesbreath'
     Mesh=SkeletalMesh'KFCharacterModels.InfectedWhiteMale1'
     Skins(0)=Shader'KFCharacters.Zombie1Shader'
     RotationRate=(Yaw=45000,Roll=0)
}
