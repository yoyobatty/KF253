//=============================================================================
// 9mm Fire
//=============================================================================
class SingleFire extends KFFire;

var float ClickTime;
var name FireAnim2;

/*
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
*/


function StartBerserk()
{
	DamageMin = default.DamageMin * 1.33;
	DamageMax = default.DamageMax * 1.33;
}

function StopBerserk()
{
	DamageMin = default.DamageMin;
	DamageMax = default.DamageMax;
}

function StartSuperBerserk()
{

}

defaultproperties
{
     bRandomPitchFireSound=True
     DamageType=Class'KFMod.DamTypeDualies'
     DamageMin=30
     DamageMax=40
     Momentum=10000.000000
     bPawnRapidFireAnim=True
     bWaitForRelease=True
     bAttachSmokeEmitter=True
     TransientSoundVolume=50.000000
     FireSound=Sound'PatchSounds.9mmShot'
     FireForce="AssaultRifleFire"
     FireRate=0.250000
     FireAnimRate=1.200000
     AmmoClass=Class'KFMod.SingleAmmo'
     AmmoPerFire=1
     ShakeRotMag=(X=50.000000,Y=50.000000,Z=50.000000)
     ShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
     ShakeRotTime=2.000000
     ShakeOffsetMag=(X=6.000000,Y=6.000000,Z=6.000000)
     ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
     ShakeOffsetTime=2.000000
     BotRefireRate=0.750000
     FlashEmitterClass=Class'KFMod.KFMuzzleFlash1PGeneric'
     aimerror=25.000000
     Spread=0.007500
     SpreadStyle=SS_Random
}
