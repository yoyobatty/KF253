// Zombie Monster for KF Invasion gametype

class ZombieSiren extends KFMonster ;

var () int ScreamRadius; // AOE for scream attack.

var () class <DamageType> ScreamDamageType;
var () int ScreamForce;

var() vector RotMag;            // how far to rot view
var() vector RotRate;           // how fast to rot view
var() float  RotTime;           // how much time to rot the instigator's view
var() vector OffsetMag;         // max view offset vertically
var() vector OffsetRate;        // how fast to offset view vertically
var() float  OffsetTime;        // how much time to offset view

var bool bAboutToDie;
var float DeathTimer;

function bool FlipOver()
{
	Return False;
}
function DoorAttack(Actor A)
{
	if ( bShotAnim || Physics == PHYS_Swimming || bDecapitated || A==None )
		return;
	bShotAnim = true;
	SetAnimAction('Siren_Scream');
}
function RangedAttack(Actor A)
{
	local int LastFireTime;

	if ( bShotAnim || bDecapitated )
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
	else if(VSize(A.Location - Location) <= 700 && !bDecapitated)
	{
		bShotAnim=true;
		SetAnimAction('Siren_Scream');
		Controller.bPreparingMove = true;
		Acceleration = vect(0,0,0);
	}
}

// Scream Time
simulated function SpawnTwoShots()
{
      // Shake nearby players screens
	local PlayerController LocalPlayer;

	LocalPlayer = Level.GetLocalPlayerController();
	if ( LocalPlayer!=None && (VSize(Location-LocalPlayer.ViewTarget.Location)<ScreamRadius) && FastTrace(Location,LocalPlayer.ViewTarget.Location) )
		LocalPlayer.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);

	if( Level.NetMode!=NM_Client )
	{
		// Deal Actual Damage.
		HurtRadius(ScreamDamage ,ScreamRadius, ScreamDamageType, ScreamForce, Location);
		if( Controller!=None && KFDoorMover(Controller.Target)!=None )
			Controller.Target.TakeDamage(ScreamDamage*0.9,Self,Location,vect(0,0,0),ScreamDamageType);
	}
}

simulated function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
	local actor Victims;
	local float damageScale, dist, dotDmg;
	local vector dir,lookdir,pwndir;

	if( bHurtEntry )
		return;

	bHurtEntry = true;
	lookdir = vector(Rotation);
	foreach VisibleCollidingActors( class 'Actor', Victims, DamageRadius, HitLocation )
	{
		// don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
		// Or Karma actors in this case. Self inflicted Death due to flying chairs is uncool for a zombie of your stature.
		if( Victims!=self && !Victims.IsA('FluidSurfaceInfo') && Victims.Class!=Class && !Victims.IsA('ExtendedZCollision') )
		{
			dir = Victims.Location - HitLocation;
			pwndir = dir;
			pwndir.Z = 0;

			// Only wipe out everything in 90 degrees in looking direction.
			dotDmg = (Normal(pwndir) Dot lookdir);
			if( dotDmg<0.45 )
				continue;
			dotDmg = FMin(1.f,dotDmg+0.15);
			dist = FMax(1,VSize(dir));
			dir = dir/dist;
			damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);

			if (!Victims.IsA('KFHumanPawn')) // If it aint human, don't pull the vortex crap on it.
				Momentum = 0;

			if (Victims.IsA('KFGlassMover'))   // Hack for shattering in interesting ways.
				DamageAmount = Mover(Victims).DamageThreshold * rand ((Mover(Victims).DamageThreshold * 0.4)) ;

			Victims.TakeDamage(damageScale * DamageAmount*dotDmg,Instigator,
			 Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,(damageScale * Momentum * dir)*dotDmg,DamageType);
			if (Instigator != None && Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
				Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, Instigator.Controller, DamageType, Momentum, HitLocation);
		}
	}
	bHurtEntry = false;
}

// When siren loses her head she's got nothin' Kill her.

function RemoveHead()
{
	Super.RemoveHead();
	if( FRand()<0.5 )
		KilledBy(LastDamagedBy);
	else
	{
		bAboutToDie = True;
		MeleeRange = -500;
		DeathTimer = Level.TimeSeconds+10*FRand();
	}
}

simulated function Tick( float Delta )
{
	Super.Tick(Delta);
	if( bAboutToDie && Level.TimeSeconds>DeathTimer )
	{
		if( Health>0 && Level.NetMode!=NM_Client )
			KilledBy(LastDamagedBy);
		bAboutToDie = False;
	}
}
function PlayDyingSound()
{
	if( !bAboutToDie )
		Super.PlayDyingSound();
}

defaultproperties
{
	ScreamRadius=800
	ScreamDamageType=Class'KFMod.SirenScreamDamage'
	ScreamForce=-300000
	RotMag=(X=200.000000,Y=200.000000,Z=200.000000)
	RotRate=(X=500.000000,Y=500.000000,Z=500.000000)
	RotTime=3.500000
	OffsetMag=(X=45.000000,Y=45.000000,Z=45.000000)
	OffsetRate=(X=500.000000,Y=500.000000,Z=500.000000)
	OffsetTime=3.500000
	MeleeAnims(0)="Siren_Bite"
	MeleeAnims(1)="Siren_Bite"
	MeleeAnims(2)="Siren_Bite"
	HitAnims(0)="HitReactionF"
	HitAnims(1)="HitReactionF"
	HitAnims(2)="HitReactionF"
	MoanVoice(0)=Sound'KFPlayerSound.SirenVoice1'
	MoanVoice(1)=Sound'KFPlayerSound.SirenVoice2'
	MoanVoice(2)=Sound'KFPlayerSound.SirenVoice3'
	MoanVoice(3)=Sound'KFPlayerSound.SirenVoice4'
	bDurableHead=True
	damageRand=7
	damageConst=10
	damageForce=5000
	KFRagdollName="SirenRag"
	ZombieDamType(0)=Class'KFMod.DamTypeSlashingAttack'
	ZombieDamType(1)=Class'KFMod.DamTypeSlashingAttack'
	ZombieDamType(2)=Class'KFMod.DamTypeSlashingAttack'
	ScreamDamage=9
	bCanDistanceAttackDoors=True
	HitSound(0)=Sound'KFPlayerSound.StalkerPain1'
	HitSound(1)=Sound'KFPlayerSound.StalkerPain2'
	HitSound(2)=Sound'KFPlayerSound.StalkerPain4'
	HitSound(3)=Sound'KFPlayerSound.StalkerPain3'
	DeathSound(0)=Sound'KFPlayerSound.SirenDie'
	DeathSound(1)=Sound'KFPlayerSound.SirenDie'
	DeathSound(2)=Sound'KFPlayerSound.SirenDie'
	DeathSound(3)=Sound'KFPlayerSound.SirenDie'
	ScoringValue=4
	SoundGroupClass=Class'KFMod.KFFemaleZombieSounds'
	IdleHeavyAnim="Siren_Idle"
	IdleRifleAnim="Siren_Idle"
	MeleeRange=45.000000
	GroundSpeed=100.000000
	WaterSpeed=80.000000
	HealthMax=350.000000
	Health=350
	MenuName="Siren"
	MovementAnims(0)="Siren_Walk"
	MovementAnims(1)="Siren_Walk"
	MovementAnims(2)="Siren_Walk"
	MovementAnims(3)="Siren_Walk"
	WalkAnims(0)="Siren_Walk"
	WalkAnims(1)="Siren_Walk"
	WalkAnims(2)="Siren_Walk"
	WalkAnims(3)="Siren_Walk"
	IdleCrouchAnim="Siren_Idle"
	IdleWeaponAnim="Siren_Idle"
	IdleRestAnim="Siren_Idle"
	AmbientSound=Sound'KFPlayerSound.Zombiesbreath'
	Mesh=SkeletalMesh'KFCharacterModels.InfectedWhiteMale2'
	Skins(0)=Texture'KFCharacters.SirenSkin'
	Skins(1)=FinalBlend'KFCharacters.SirenHairFB'
	RotationRate=(Yaw=45000,Roll=0)
}
