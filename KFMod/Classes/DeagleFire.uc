//=============================================================================
// Deagle Fire
//=============================================================================
class DeagleFire extends KFFire;

var float ClickTime;



function Recoil()
{
	local Rotator NewRotation;
	local float NewPitch, NewYaw;

	if ( (Instigator != None) && Instigator.IsFirstPerson()){
	NewPitch = int(Frand()*300); NewYaw = int(Frand()*550);
	if (Frand() > 0.5) NewYaw *= -1;
	if (Frand() > 0.5) NewPitch *= -1;
	NewRotation = Instigator.GetViewRotation();
	NewRotation.Pitch += NewPitch;
	NewRotation.Yaw += NewYaw;
	Instigator.SetViewRotation(NewRotation);}
}

//event ModeDoFire()
//{
//	if ( Level.TimeSeconds - LastFireTime > 0.5 )
//		Spread = Default.Spread;
//	else
//		Spread = FMin(Spread+0.02,0.12);
//	LastFireTime = Level.TimeSeconds;
//	Recoil();
//    Super.ModeDoFire();
//}

defaultproperties
{
     DamageType=Class'KFMod.DamTypeDeagle'
     DamageMin=85
     DamageMax=105
     Momentum=20000.000000
     bPawnRapidFireAnim=True
     bAttachSmokeEmitter=True
     TransientSoundVolume=100.000000
     FireLoopAnim=
     FireEndAnim=
     FireAnimRate=0.900000
     FireSound=Sound'KFWeaponSound.50CalFire'
     AmmoClass=Class'KFMod.DeagleAmmo'
     AmmoPerFire=1
     ShakeRotMag=(X=90.000000,Y=90.000000,Z=90.000000)
     ShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
     ShakeRotTime=2.000000
     ShakeOffsetMag=(X=19.000000,Y=19.000000,Z=19.000000)
     ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
     ShakeOffsetTime=2.000000
     BotRefireRate=0.650000
     FlashEmitterClass=Class'KFMod.KFMuzzleFlash1PGeneric'
     aimerror=40.000000
     SpreadStyle=SS_Random
}
