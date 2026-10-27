//=============================================================================
// CryoFire
// The cryo cannon's shot: one CryoBolt, with the crossbow's thunk and a hiss of escaping coolant.
//=============================================================================
class CryoFire extends CrossbowFire;

#exec OBJ LOAD FILE=..\Sounds\GeneralAmbience.uax

var() Sound HissSound;

function DoFireEffect()
{
	ProjectileClass = default.ProjectileClass;
	Super(KFShotgunFire).DoFireEffect();
}

// (the crossbow's start, short of anything nearer than the muzzle; not KFShotgunFire's own, which heats the fire grid)
function projectile SpawnProjectile(Vector Start, Rotator Dir)
{
	local vector HL, HN;

	if ( Instigator.Trace(HL, HN, Start, Instigator.Location + Instigator.EyePosition(), true) != None )
		Start = HL;
	return Super(FlakFire).SpawnProjectile(Start, Dir);
}

function PlayFiring()
{
	Super.PlayFiring();
	if ( HissSound != None )
		Weapon.PlayOwnedSound(HissSound, SLOT_Misc, 0.8,, 400, 1.3, false);
}

defaultproperties
{
     HissSound=Sound'GeneralAmbience.steamfx1'
     ProjectileClass=Class'KFMod.CryoBolt'
     AmmoClass=Class'KFMod.CryoAmmo'
     FireRate=1.300000
     Spread=0.000000
     BotRefireRate=0.500000
}
