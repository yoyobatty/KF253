//=============================================================================
// Dualies Fire
//=============================================================================
class DualiesFire extends KFFire;

var() xEmitter FlashEmitter2;

var float ClickTime;
var name FireAnim2;
var name fa;
//var bool bFlashLeft;

simulated function InitEffects()
{
  
  Super.InitEffects();

    if ( FlashEmitter2 != None )
        Weapon.AttachToBone(FlashEmitter2, 'tip01');


    // don't even spawn on server
    if ( (Level.NetMode == NM_DedicatedServer) || (AIController(Instigator.Controller) != None) )
        return;
    if ( (FlashEmitterClass != None) && ((FlashEmitter == None) || FlashEmitter.bDeleteMe) )
    {
        FlashEmitter = Weapon.Spawn(FlashEmitterClass);
    }
    if ( (FlashEmitterClass != None) && ((FlashEmitter2 == None) || FlashEmitter2.bDeleteMe) )
    {
        FlashEmitter2 = Weapon.Spawn(FlashEmitterClass);
    }
    if ( (SmokeEmitterClass != None) && ((SmokeEmitter == None) || SmokeEmitter.bDeleteMe) )
    {
        SmokeEmitter = Weapon.Spawn(SmokeEmitterClass);
    }
}

function FlashMuzzleFlash()
{
   Super.FlashMuzzleFlash();

   // z.Roll = Rand(65536);


   // log(FireAnim);
   
   if (FlashEmitter2 == none || FlashEmitter == none)
    return;


    if(FireAnim == 'FireLeft')
    {
        FlashEmitter2.Trigger(Weapon, Instigator);
       // bFlashLeft = true;
    }
    else
    {
       FlashEmitter.Trigger(Weapon, Instigator);
      // bFlashLeft = false;
    }

    //  log(Weapon.GetBoneRotation('tip'));
    //  log(Weapon.GetBoneRotation('tip01'));

    //  z.Yaw = 16000;
    //  z.Pitch = 16000;

}
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

event ModeDoFire()
{
	local name bn;

	bn = Dualies(Weapon).altFlashBoneName;
	Dualies(Weapon).altFlashBoneName = Dualies(Weapon).FlashBoneName;
	Dualies(Weapon).FlashBoneName = bn;

	Super.ModeDoFire();

	fa = FireAnim2;
	FireAnim2 = FireAnim;
	FireAnim = fa;
	InitEffects();
}

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
	FireRate = default.FireRate * 1.5/Level.GRI.WeaponBerserk;
	FireAnimRate = default.FireAnimRate * 0.667 * Level.GRI.WeaponBerserk;
	DamageMin = default.DamageMin * 1.5;
	DamageMax = default.DamageMax * 1.5;
	if (AssaultRifle(Weapon) != None && AssaultRifle(Weapon).bDualMode)
		FireRate *= 0.55;
}


function DoFireEffect()
{
    local Vector StartTrace;
    local Rotator R, Aim;

    Instigator.MakeNoise(1.0);

    if(FireAnim == 'FireLeft')
    {
      StartTrace = Instigator.Location + Instigator.EyePosition();
      StartTrace.Y  += (rand(30)+ 5);
    }
    else
    {
     StartTrace = Instigator.Location + Instigator.EyePosition();
    }

    Aim = AdjustAim(StartTrace, AimError);
    R = rotator(vector(Aim) + VRand()*FRand()*Spread);
    DoTrace(StartTrace, R);
}

defaultproperties
{
	FireAnim2="FireLeft"
	DamageType=Class'KFMod.DamTypeDualies'
	DamageMin=25
	DamageMax=35
	Momentum=10500.000000
	bPawnRapidFireAnim=True
	bAttachSmokeEmitter=True
	TransientSoundVolume=50.000000
	FireAnim="FireRight"
	FireLoopAnim=
	FireEndAnim=
	FireSound=Sound'PatchSounds.9mmShot'
	FireForce="AssaultRifleFire"
	FireRate=0.250000
	AmmoClass=Class'KFMod.SingleAmmo'
	AmmoPerFire=1
	ShakeRotMag=(X=90.000000,Y=90.000000,Z=90.000000)
	ShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
	ShakeRotTime=2.000000
	ShakeOffsetMag=(X=15.000000,Y=15.000000,Z=15.000000)
	ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
	ShakeOffsetTime=2.000000
	BotRefireRate=0.250000
	FlashEmitterClass=Class'KFMod.KFMuzzleFlash1PGeneric'
	aimerror=30.000000
	Spread=0.015000
	SpreadStyle=SS_Random
}
