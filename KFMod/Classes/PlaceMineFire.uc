//=============================================================================
// Place Mine Fire
//=============================================================================
class PlaceMineFire extends FragFire;

var     class<KFDropMine>    MountedCalClass;
var     KFDropMine           MountedCalGun;
var     Rotator                 OriginalRotation;

//var float ClickTime;

simulated function bool AllowFire()
{
    return true;
}



function Recoil()
{

}


function DoFireEffect()
{
    local Vector StartProj, StartTrace, X,Y,Z;
    local Rotator Aim;

    Weapon.GetViewAxes(X,Y,Z);

    StartTrace = Instigator.Location + Instigator.EyePosition();// + X*Instigator.CollisionRadius;
    StartProj = StartTrace + X*ProjSpawnOffset.X;

    if ( !Weapon.WeaponCentered() )
        StartProj = StartProj + Weapon.Hand * Y*ProjSpawnOffset.Y + Z*ProjSpawnOffset.Z;

    Aim = AdjustAim(StartProj, AimError);
    SpawnProjectile(StartProj, Aim);
}


// Create a nice shiny mine for our player

function projectile SpawnProjectile(Vector Start, Rotator Dir)
{
    local KFDropMine g;
    //local vector X, Y, Z;
    //local float pawnSpeed;
    //local PlayerController pc;
    local Rotator GunDropRotation;

    // We want the rotation of the placed gun to be relative to the direction the player is facing when he places it.
    GunDropRotation.Yaw = Dir.Yaw ;

    // Drop the Mine from below eye level.
    Start.Z -= 50;

    g = Weapon.Spawn(MountedCalClass,,, Start, GunDropRotation);

    // We've dropped the gun on the floor, now get rid of the Inventory.

   // if ( KFPawn(instigator) != none)
   // KFPawn(instigator).RemoveInventory(Weapon);
   return none;
}

defaultproperties
{
	MountedCalClass=Class'KFMod.KFDropMine'
	bWaitForRelease=False
	TransientSoundVolume=100.000000
	FireLoopAnim=
	FireEndAnim=
	PreFireAnimRate=1.750000
	FireSound=None
	FireRate=1.000000
	AmmoClass=Class'KFMod.PlaceMineAmmo'
	ShakeRotMag=(X=50.000000,Y=50.000000,Z=50.000000)
	ShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
	ShakeOffsetMag=(X=9.000000,Y=9.000000,Z=9.000000)
	ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
	BotRefireRate=1.000000
}
