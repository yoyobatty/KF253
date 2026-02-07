class HeldWeapon extends Actor;

var Weapon Weapon;

function PostBeginPlay()
{
	SetTimer(2.0,true);
}
function Timer()
{
	if(Weapon == none)
		Destroy();
}

defaultproperties
{
     DrawType=DT_Mesh
     DrawScale=0.35
     Physics=PHYS_Projectile
     bOwnerNoSee=True
}
