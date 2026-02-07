class LAW extends KFWeaponShotgun;

// Killing Floor's Light Anti Tank Weapon.
// This is probably about as badass as things get....

simulated event WeaponTick(float dt)
{ 
	if(AmmoAmount(0) == 0)
		Clipleft = 0;
	super.Weapontick(dt);
}

simulated function PlayAnimZoom( bool bZoomNow )
{
	if( bZoomNow )
	{
		IdleAnim = 'AimIdle';
		PlayAnim('Raise');
	}
	else if( IdleAnim!=Default.IdleAnim )
	{
		IdleAnim = Default.IdleAnim;
		TweenAnim(IdleAnim,0.5);
	}
}

simulated function PlayIdle()
{
	if( ClientState==WS_BringUp && Clipleft==0 && AmmoAmount(0)>0 )
	{
		PlayAnim('AimFire');
		FireMode[0].bIsFiring = True;
		FireMode[0].NextFireTime = Level.TimeSeconds+FireMode[0].FireRate;
		ServerSpawnLight();
	}
	else Super.PlayIdle();
}
function ServerSpawnLight()
{
	if( Clipleft==0 && AmmoAmount(0)>0 && !FireMode[0].bIsFiring )
	{
		Clipleft = 1;
		FireMode[0].bIsFiring = True;
		FireMode[0].NextFireTime = Level.TimeSeconds+FireMode[0].FireRate;
	}
}

defaultproperties
{
	ClipCount=1
	ReloadRate=3.000000
	MinimumFireRange=300
	Weight=15.000000
	UpKick=300
	FireModeClass(0)=Class'KFMod.LAWFire'
	FireModeClass(1)=Class'KFMod.KFZoom'
	PutDownAnim="PutDown"
	SelectSound=Sound'KFPlayerSound.getweaponout'
	SelectForce="SwitchToRocketLauncher"
	AIRating=1.500000
	CurrentRating=1.500000
	Description="The Light Anti Tank Weapon is, as its name suggests, a military grade heavy weapons platform designed to disable or outright destroy armored vehicles."
	EffectOffset=(X=50.000000,Y=1.000000,Z=10.000000)
	DisplayFOV=75.000000
	Priority=10
	HudColor=(G=0)
	SmallViewOffset=(X=20.000000,Y=20.000000)
	CustomCrosshair=-1
	CustomCrossHairColor=(B=0,G=0,R=0,A=0)
	CustomCrossHairTextureName=
	InventoryGroup=4
	GroupOffset=1
	PickupClass=Class'KFMod.LAWPickup'
	PlayerViewOffset=(Z=-3.000000)
	PlayerViewPivot=(Pitch=-400)
	BobDamping=7.000000
	AttachmentClass=Class'KFMod.LAWAttachment'
	IconCoords=(X1=429,Y1=212,X2=508,Y2=251)
	ItemName="L.A.W"
	Mesh=SkeletalMesh'KFWeaponModels.LAW'
	DrawScale=0.900000
	AmbientGlow=2
}
