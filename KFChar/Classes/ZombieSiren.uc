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

simulated event SetAnimAction(name NewAction)
{
	if ( !bWaitForAnim || (Level.NetMode == NM_Client) )
	{
		// He's never able to barf while moving
                if(NewAction == 'Siren_Scream')
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

	Super.SetAnimAction(NewAction);
}
function bool FlipOver()
{
	Return False;
}
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
    else if (VSize(A.Location - Location) <= 700 && !bDecapitated)
    {
      bShotAnim=true;
      SetAnimAction('Siren_Scream');
      Controller.bPreparingMove = true;
      Acceleration = vect(0,0,0);
    }


}

// Scream Time

function SpawnTwoShots()
{
      // Shake nearby players screens

    local Controller        C;
    local PlayerController  LocalPlayer;

     LocalPlayer = Level.GetLocalPlayerController();
    if ( (LocalPlayer != None) && (VSize(Location - LocalPlayer.ViewTarget.Location) < ScreamRadius) )
        LocalPlayer.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);

    for ( C=Level.ControllerList; C!=None; C=C.NextController )
        if ( (PlayerController(C) != None) && (C != LocalPlayer)
            && (VSize(Location - PlayerController(C).ViewTarget.Location) < ScreamRadius) )
            C.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);

    // Deal Actual Damage.

    HurtRadius(ScreamDamage ,ScreamRadius, ScreamDamageType, ScreamForce, Location) ;

}

simulated function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
    local actor Victims;
    local float damageScale, dist;
    local vector dir;

    if( bHurtEntry )
        return;

    bHurtEntry = true;
    foreach VisibleCollidingActors( class 'Actor', Victims, DamageRadius, HitLocation )
    {
        // don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
        // Or Karma actors in this case. Self inflicted Death due to flying chairs is uncool for a zombie of your stature.
        if( (Victims != self) && (Victims.Role == ROLE_Authority) && (!Victims.IsA('FluidSurfaceInfo')) && (!Victims.IsA('KFMonster')) )
        {
            dir = Victims.Location - HitLocation;
            dist = FMax(1,VSize(dir));
            dir = dir/dist;
            damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);

            if (!Victims.IsA('KFHumanPawn')) // If it aint human, don't pull the vortex crap on it.
             Momentum = 0;

            if (Victims.IsA('KFGlassMover'))   // Hack for shattering in interesting ways.
             DamageAmount = Mover(Victims).DamageThreshold * rand ((Mover(Victims).DamageThreshold * 0.4)) ;

            Victims.TakeDamage
            (
                damageScale * DamageAmount,
                Instigator,
                Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,
                (damageScale * Momentum * dir),
                DamageType
            );
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
KilledBy(LastDamagedBy);
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
     ScreamDamage=10
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
