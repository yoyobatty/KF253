//=============================================================================
// Place Cal Fire
//=============================================================================
class PlaceCalFire extends FragFire;

var     class<MountedCal>    MountedCalClass;
var     MountedCal           MountedCalGun;
var     Rotator                 OriginalRotation;

//var float ClickTime;

simulated function bool AllowFire()
{
    return true;
}

function Recoil()
{

}

// Create a nice shiny .50 Cal for our player
function projectile SpawnProjectile(Vector Start, Rotator Dir)
{
	local MountedCal g;
	local Rotator GunDropRotation;

	// We want the rotation of the placed gun to be relative to the direction the player is facing when he places it.
	GunDropRotation.Yaw = Dir.Yaw ;

	// Drop the Gun from below eye level.
	Start.Z -= 30;

	g = Weapon.Spawn(MountedCalClass,,, Start, GunDropRotation);

	// We've dropped the gun on the floor, now get rid of the Inventory.
	if ( KFPawn(instigator) != none)
		Weapon.Destroy();
	return none;
}

defaultproperties
{
     MountedCalClass=Class'KFMod.MountedCal'
     bWaitForRelease=False
     TransientSoundVolume=100.000000
     FireLoopAnim=
     FireEndAnim=
     PreFireAnimRate=1.750000
     FireSound=None
     FireRate=1.000000
     AmmoClass=Class'KFMod.PlaceCalAmmo'
     ShakeRotMag=(X=50.000000,Y=50.000000,Z=50.000000)
     ShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
     ShakeOffsetMag=(X=9.000000,Y=9.000000,Z=9.000000)
     ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
     BotRefireRate=1.000000
}
