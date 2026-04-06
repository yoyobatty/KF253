//=============================================================================
 //L85 Fire
//=============================================================================
class BullpupFire extends KFFire;

var float ClickTime;
var vector  KickMomentum;
var bool bZoomed;

var() Sound FireSounds[10];

/* 
function DoTrace(Vector Start, Rotator Dir)
{
    DamageType = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.static.GetMAC10DamageType();
	Super.DoTrace(Start,Dir);
}
*/
event ModeDoFire()
{
    DamageType = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.static.GetMAC10DamageType();
    Super.ModeDoFire();
}

function PlayFiring()
{
	if ( Weapon.Mesh != None )
	{
		if ( FireCount > 0 )
		{
			if ( Weapon.HasAnim(FireLoopAnim) )
				Weapon.PlayAnim(FireLoopAnim, FireLoopAnimRate, 0.0);
			else Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
		}
		else Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
	}
	Weapon.PlayOwnedSound(FireSounds[rand(10)],SLOT_Interact,TransientSoundVolume,,TransientSoundRadius,Default.FireAnimRate/FireAnimRate,false);
	ClientPlayForceFeedback(FireForce);  // jdf
	FireCount++;
}

//// server propagation of firing ////
function ServerPlayFiring()
{
	Weapon.PlayOwnedSound(FireSounds[rand(10)],SLOT_Interact,TransientSoundVolume,,TransientSoundRadius,,false);
}

defaultproperties
{
    FireSounds(0)=Sound'KFWeaponSound.L85Fire'
    FireSounds(1)=Sound'KFWeaponSound.L85Fire1'
    FireSounds(2)=Sound'KFWeaponSound.L85Fire2'
    FireSounds(3)=Sound'KFWeaponSound.L85Fire3'
    FireSounds(4)=Sound'KFWeaponSound.L85Fire4'
    FireSounds(5)=Sound'KFWeaponSound.L85Fire5'
    FireSounds(6)=Sound'KFWeaponSound.L85Fire6'
    FireSounds(7)=Sound'KFWeaponSound.L85Fire7'
    FireSounds(8)=Sound'KFWeaponSound.L85Fire8'
    FireSounds(9)=Sound'KFWeaponSound.L85Fire9'
    DamageType=Class'KFMod.DamTypeBullpup'
    DamageMin=30
    DamageMax=35
    Momentum=8500.000000
    bPawnRapidFireAnim=True
    TransientSoundVolume=30.000000
    FireLoopAnim="Fire"
    FireForce="AssaultRifleFire"
    FireRate=0.100000
    AmmoClass=Class'KFMod.BullpupAmmo'
    AmmoPerFire=1
    ShakeRotMag=(X=25.000000,Y=25.000000,Z=25.000000)
    ShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
    ShakeRotTime=0.500000
    ShakeOffsetMag=(X=3.000000,Y=3.000000,Z=3.000000)
    ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
    ShakeOffsetTime=1.000000
    BotRefireRate=0.960000 // 96% chance to fire again
    FlashEmitterClass=Class'KFMod.MGMuzzFlash'
    aimerror=42.000000
    Spread=0.008500
    SpreadStyle=SS_Random
}
