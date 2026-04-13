// Zombie Monster for KF Invasion gametype
class ZombieStalker extends KFMonster;

var bool bCloaking;
var float LastCheckTimes;
var float LastUncloakTime;
var KFHumanPawn LocalKFHumanPawn;

#exec OBJ LOAD FILE=KFCharacters.utx
#exec OBJ LOAD FILE=KFCharacterModels.ukx
#exec OBJ LOAD FILE=KFWeaponSound.uax
#exec OBJ LOAD FILE=KFPlayerSound.uax
#exec OBJ LOAD FILE=PlayerSounds.uax
#exec OBJ LOAD FILE=KFX.utx

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	CloakStalker();
}

simulated function PostNetBeginPlay()
{
    local PlayerController PC;

	super.PostNetBeginPlay();

	if( Level.NetMode!=NM_DedicatedServer )
	{
        PC = Level.GetLocalPlayerController();
        if( PC != none && PC.Pawn != none )
        {
            LocalKFHumanPawn = KFHumanPawn(PC.Pawn);
        }
	}
}

simulated function Tick(float DeltaTime)
{
	Super.Tick(DeltaTime);
	if( Level.NetMode==NM_DedicatedServer )
		Return; // Servers aren't intrested in this info.
  
	if( Level.TimeSeconds>LastCheckTimes && Health > 0 )
	{
		LastCheckTimes = Level.TimeSeconds+0.5;
        if( LocalKFHumanPawn != none && LocalKFHumanPawn.Health > 0 && LocalKFHumanPawn.ShowStalkers() &&
            VSize(Location - LocalKFHumanPawn.Location) < 800.f ) 
        {
			bSpotted = True;
		}
		else
		{
			bSpotted = false;
		}
		// Player requested to see stalkers — make visible / glow
		if ( Level.TimeSeconds - LastUncloakTime > 1.2 )
			CloakStalker();
	}
}

// Cloak Functions ( called from animation notifies to save Gibby trouble ;) )

simulated function CloakStalker()
{
	if (bSpotted)
	{
		if( Level.NetMode==NM_DedicatedServer )
			Return;
		Skins[0] = Finalblend 'KFX.StalkerGlow';
		Skins[1] = Finalblend 'KFX.StalkerGlow';
		Visibility = default.Visibility; // So bots know we're visible
		bUnlit = true;
		return;
	}

	if (!bDecapitated && !bAshen && !bCloaked) // No head, no cloak, honey.  updated :  Being charred means no cloak either :D
	{
		bCloaked = true;
		Visibility = 1;
		bUnlit = false; // Regular lighting
		if( Level.NetMode==NM_DedicatedServer )
			Return;
		Skins[0] = Shader 'KFCharacters.StalkerHairShader';
		Skins[1] = Shader'KFCharacters.CloakShader';

		// Invisible - no shadow
		if(PlayerShadow != none)
			PlayerShadow.bShadowActive = false;
		if(RealTimeShadow != none)
			RealTimeShadow.Destroy();

		// Remove/disallow projectors on invisible people
		Projectors.Remove(0, Projectors.Length);
		bAcceptsProjectors = false;
		SetOverlayMaterial(Material'KFX.FBDecloakShader', 0.25, true);
	}
}

simulated function UnCloakStalker()
{
	if( !bAshen && bCloaked )
	{
		LastUncloakTime = Level.TimeSeconds;

		Visibility = default.Visibility;
		bCloaked = false;
		bUnlit = false;
		if( Level.NetMode==NM_DedicatedServer )
			Return;
		Skins[0] = Shader'KFCharacters.Zombie4Shader';
		Skins[1] = FinalBlend'KFCharacters.StalkerHairFB';

		if (PlayerShadow != none)
			PlayerShadow.bShadowActive = true;
 
		bAcceptsProjectors = true;

		SetOverlayMaterial(Material'KFX.FBDecloakShader', 0.25, true);
	}
}

function RemoveHead()
{
	Super.RemoveHead();

	if (!bAshen)
	{
		Skins[0] = Shader'KFCharacters.Zombie4Shader';
		Skins[1] = FinalBlend'KFCharacters.StalkerHairFB';
	}
}

simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
	Super.PlayDying(DamageType,HitLoc);
	
	bUnlit = false;

	if (!bAshen)
	{
		Skins[0] = Shader'KFCharacters.Zombie4Shader';
		Skins[1] = FinalBlend'KFCharacters.StalkerHairFB';
	}
}

// Give her the ability to spring.
function bool DoJump( bool bUpdating )
{
	if ( !bIsCrouched && !bWantsToCrouch && ((Physics == PHYS_Walking) || (Physics == PHYS_Ladder) || (Physics == PHYS_Spider)) )
	{
		if ( Role == ROLE_Authority )
		{
			if ( (Level.Game != None) && (Level.Game.GameDifficulty > 2) )
				MakeNoise(0.1 * Level.Game.GameDifficulty);
			if ( bCountJumps && (Inventory != None) )
				Inventory.OwnerEvent('Jumped');
		}
		if ( Physics == PHYS_Spider )
			Velocity = JumpZ * Floor;
		else if ( Physics == PHYS_Ladder )
			Velocity.Z = 0;
		else if ( bIsWalking )
		{
			Velocity.Z = Default.JumpZ;
			Velocity.X = (Default.JumpZ * 0.6);
		}
		else
		{
			Velocity.Z = JumpZ;
			Velocity.X = (JumpZ * 0.6);
		}
		if ( (Base != None) && !Base.bWorldGeometry )
		{
			Velocity += Base.Velocity;
		}
		SetPhysics(PHYS_Falling);
		return true;
	}
	return false;
}

defaultproperties
{
     MeleeAnims(0)="StalkerSpinAttack"
     MeleeAnims(1)="StalkerAttack1"
     MeleeAnims(2)="JumpAttack"
     MoanVoice(0)=Sound'KFPlayerSound.StalkerVoice1'
     MoanVoice(1)=Sound'KFPlayerSound.StalkerVoice2'
     MoanVoice(2)=Sound'KFPlayerSound.StalkerVoice3'
     MoanVoice(3)=Sound'KFPlayerSound.StalkerVoice4'
     bCannibal=True
     damageRand=5
     damageConst=6
     damageForce=5000
     ZombieDamType(0)=Class'KFMod.DamTypeSlashingAttack'
     ZombieDamType(1)=Class'KFMod.DamTypeSlashingAttack'
     ZombieDamType(2)=Class'KFMod.DamTypeSlashingAttack'
     PuntAnim="ClotPunt"
     HitSound(0)=Sound'KFPlayerSound.StalkerPain1'
     HitSound(1)=Sound'KFPlayerSound.StalkerPain2'
     HitSound(2)=Sound'KFPlayerSound.StalkerPain4'
     HitSound(3)=Sound'KFPlayerSound.StalkerPain3'
     DeathSound(0)=Sound'KFPlayerSound.SirenDeath'
     DeathSound(1)=Sound'KFPlayerSound.SirenDeath'
     DeathSound(2)=Sound'KFPlayerSound.SirenDeath'
     DeathSound(3)=Sound'KFPlayerSound.SirenDeath'
     ScoringValue=2
     SoundGroupClass=Class'KFMod.KFFemaleZombieSounds'
     IdleHeavyAnim="StalkerIdle"
     IdleRifleAnim="StalkerIdle"
     GroundSpeed=200.000000
     WaterSpeed=180.000000
     JumpZ=350.000000
     HealthMax=150
	 Health=150
     MenuName="Stalker"
     MovementAnims(0)="ZombieRun"
     MovementAnims(1)="ZombieRun"
     MovementAnims(2)="ZombieRun"
     MovementAnims(3)="ZombieRun"
     WalkAnims(0)="ZombieRun"
     WalkAnims(1)="ZombieRun"
     WalkAnims(2)="ZombieRun"
     WalkAnims(3)="ZombieRun"
     IdleCrouchAnim="StalkerIdle"
     IdleWeaponAnim="StalkerIdle"
     IdleRestAnim="StalkerIdle"
     AmbientSound=Sound'KFPlayerSound.Zombiesbreath'
     Mesh=SkeletalMesh'KFCharacterModels.InfectedWhiteFemale'
     Skins(0)=Shader'KFCharacters.Zombie4Shader'
     Skins(1)=FinalBlend'KFCharacters.StalkerHairFB'
     RotationRate=(Yaw=45000,Roll=0)
}
