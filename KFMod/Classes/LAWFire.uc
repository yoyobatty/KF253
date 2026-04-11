class LAWFire extends KFShotgunFire;//ProjectileFire;

var() float FrontBlastRange;
var() float FrontBlastDamage;
var() float FrontBlastMomentum;
var() float FrontBlastDot;

var() float BackBlastRange;
var() float BackBlastDamage;
var() float BackBlastMomentum;
var() float BackBlastDot;

var() bool bDamageInstigator;

function ModeDoFire()
{
     Super.ModeDoFire();
     ApplyDirectionalLAWBlast();
}

function ApplyDirectionalLAWBlast()
{
     local rotator AimRot;
     local vector ForwardDir;
     local vector BlastOrigin;

     if( Instigator == None )
          return;

     if( Instigator.Controller != None )
          AimRot = Instigator.Controller.Rotation;
     else
          AimRot = Instigator.Rotation;

     ForwardDir = Normal(vector(AimRot));
     BlastOrigin = Instigator.Location + Instigator.EyePosition();

     ApplyConeDamage(BlastOrigin, ForwardDir, FrontBlastRange, FrontBlastDamage, FrontBlastMomentum, FrontBlastDot);
     ApplyConeDamage(BlastOrigin, -ForwardDir, BackBlastRange, BackBlastDamage, BackBlastMomentum, BackBlastDot);
}

function ApplyConeDamage(vector BlastOrigin, vector ConeDir, float ConeRange, float MaxDamage, float MaxMomentum, float DotThreshold)
{
     local actor Victim;
     local vector ToVictim;
     local vector VictimDir;
     local float Dist;
     local float DotValue;
     local float Scale;

     if (Weapon == None)
          return;

     foreach Weapon.VisibleCollidingActors(class 'Actor', Victim, ConeRange, BlastOrigin)
     {
          if( Victim == None || Victim == self || Victim == Weapon || Victim.Role != ROLE_Authority )
               continue;

          if( Victim == Instigator && !bDamageInstigator )
               continue;

          ToVictim = Victim.Location - BlastOrigin;
          Dist = VSize(ToVictim);

          if( Dist > ConeRange || Dist <= 1.0 )
               continue;

          VictimDir = ToVictim / Dist;
          DotValue = VictimDir Dot ConeDir;

          if( DotValue < DotThreshold )
               continue;

          if( !Weapon.FastTrace(Victim.Location, BlastOrigin) )
               continue;

          Scale = FMax(0.1, 1.0 - (Dist / ConeRange));

          Victim.TakeDamage(
               int(MaxDamage * Scale),
               Instigator,
               Victim.Location - 0.5 * (Victim.CollisionHeight + Victim.CollisionRadius) * VictimDir,
               (MaxMomentum * Scale) * VictimDir,
               class'DamTypeLAW'
          );
     }
}

function bool AllowFire()
{
	if( !KFWeapon(Weapon).bAimingRifle && PlayerController(Instigator.Controller)!=None ) // Only disallow this on human players
		return false;
	return ( Weapon.AmmoAmount(ThisModeNum) >= AmmoPerFire);
}
function ServerPlayFiring()
{
	Super.ServerPlayFiring();
	if( KFWeapon(Weapon)!=none )
		KFWeapon(Weapon).bAimingRifle = False;
	if( KFHumanPawn(Instigator)!=None )
		KFHumanPawn(Instigator).SetAiming(False);
}
function PlayFiring()
{
	Super.PlayFiring();
	if( KFWeapon(Weapon)!=none )
		KFWeapon(Weapon).bAimingRifle = False;
	if( KFHumanPawn(Instigator)!=None )
		KFHumanPawn(Instigator).SetAiming(False);
	Weapon.IdleAnim = Weapon.Default.IdleAnim;
	Weapon.GetFireMode(1).bIsFiring = False; // Stop zooming :)
}

defaultproperties
{
     FrontBlastRange=220.000000
     FrontBlastDamage=500.000000
     FrontBlastMomentum=200000.000000
     FrontBlastDot=0.250000
     BackBlastRange=200.000000
     BackBlastDamage=650.000000
     BackBlastMomentum=130000.000000
     BackBlastDot=0.350000
     bDamageInstigator=False
     MaxAccuracyBonus=0.100000
     CrouchedAccuracyBonus=0.100000
     KickMomentum=(X=-45.000000,Z=25.000000)
     bRandomPitchFireSound=False
     ProjPerFire=1
     ProjSpawnOffset=(X=40.000000,Z=0.000000)
     bSplashDamage=True
     bRecommendSplashDamage=True
     bWaitForRelease=True
     PreFireTime=0.000000
     TransientSoundVolume=100.000000
     FireAnim="AimFire"
     FireSound=Sound'KFWeaponSound.LAWFire'
     FireForce="redeemer_shoot"
     FireRate=3.250000
     AmmoClass=Class'KFMod.LAWAmmo'
     ShakeRotMag=(X=100.000000,Y=100.000000,Z=100.000000)
     ShakeOffsetMag=(X=20.000000,Y=20.000000,Z=20.000000)
     ProjectileClass=Class'KFMod.LAWProj'
     BotRefireRate=0.500000
     FlashEmitterClass=Class'KFMod.ShotgunMuzzFlash'
     Spread=0.050000
     WarnTargetPct=0.900000
     AimError=1.000000
}
