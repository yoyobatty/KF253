//=============================================================================
// Flashlight
//=============================================================================
class SingleALTFire extends KFFire;

<<<<<<< HEAD
var float ClickTime;
=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
var name FireAnim2;

simulated function ModeDoFire()
{
	if (Weapon != none && KFPlayerController(pawn(Weapon.Owner).Controller) != none )
	{
		KFPlayerController(pawn(Weapon.Owner).Controller).ToggleTorch();
<<<<<<< HEAD
		KFWeapon(Weapon).AdjustLightGraphic();
=======
          KFWeapon(Weapon).AdjustLightGraphic();
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	}
	Super.ModeDoFire();
}

function DoTrace(Vector Start, Rotator Dir)
{

}

// Sends a value to the 9mm attachment telling whether the light is being used.
function bool LightFiring()
{
	return bIsFiring;
}

simulated function bool AllowFire()
{
	if(KFWeapon(Weapon).bIsReloading || KFPawn(Instigator).SecondaryItem!=none || KFPawn(Instigator).bThrowingNade )
		return false;
	if(Level.TimeSeconds - LastClickTime > FireRate)
		return true;
}

<<<<<<< HEAD
defaultproperties
{
	bFiringDoesntAffectMovement=True
	DamageType=Class'KFMod.DamTypeDualies'
	Momentum=0.000000
	bPawnRapidFireAnim=True
	bAttachSmokeEmitter=True
	TransientSoundVolume=50.000000
	FireAnim="LightOn"
	FireSound=Sound'KFWeaponSound.closechamber'
	FireForce="AssaultRifleFire"
	AmmoClass=Class'KFMod.SingleAmmo'
	BotRefireRate=0.500000
	aimerror=0.000000
=======
function HandleRecoil(){}

defaultproperties
{
     bFiringDoesntAffectMovement=True
     DamageType=Class'KFMod.DamTypeDualies'
     Momentum=0.000000
     DamageMin=0
     DamageMax=0
     bPawnRapidFireAnim=True
     bAttachSmokeEmitter=True
     TransientSoundVolume=50.000000
     FireAnim="LightOn"
     FireSound=Sound'KFWeaponSound.closechamber'
     FireForce="AssaultRifleFire"
     AmmoClass=Class'KFMod.SingleAmmo'
     ShakeRotMag=(X=0.000000,Y=0.000000,Z=0.000000)
     ShakeRotRate=(X=0.000000,Y=0.000000,Z=0.000000)
     ShakeRotTime=0.000000
     ShakeOffsetMag=(X=0.000000,Y=0.000000,Z=0.000000)
     ShakeOffsetRate=(X=0.000000,Y=0.000000,Z=0.000000)
     ShakeOffsetTime=0.000000
     BotRefireRate=0.500000
     AmmoPerFire=0
     aimerror=0.000000
     Spread=0.00
     SpreadStyle=SS_None
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
