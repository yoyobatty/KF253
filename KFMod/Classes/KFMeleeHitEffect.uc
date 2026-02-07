class KFMeleeHitEffect extends KFHitEffect;

<<<<<<< HEAD
simulated function SpawnEffects()
{
	local Material SurfaceMat;
	local int HitSurface;
	local Vector HitLocation, HitNormal,TDir;
	local rotator EffectDir;
	local Actor Other;

	if( Instigator==None )
		Return;
	TDir = Normal(Location-Instigator.Location);
	Other = Instigator.Trace(HitLocation, HitNormal, Location+TDir*32, Location-TDir*16,true,,SurfaceMat);
	
	if( Other==none || BlockingVolume(Other)!=None )
		return;

	EffectDir = rotator(HitNormal);

	if(Vehicle(Other) != None && Other.SurfaceType == 0)
		HitSurface = 3;
	else if(Other != None && Other!=Level && Other.SurfaceType != 0)
		HitSurface = Other.SurfaceType;
	else if(SurfaceMat != None)
		HitSurface = SurfaceMat.SurfaceType;
	else if( Other.IsA('KFMonster') || Other.IsA('ExtendedZCollision') )
		HitSurface = 6;
	else
	{
		Destroy();
		return;
	}

	if(PhysicsVolume.bWaterVolume)
		Spawn(class'pclImpactSmoke');
	else Spawn(HitEffectClasses[HitSurface],,,, EffectDir);

	// Don't need to try and spawn decalclasses if we have no decalclasses to spawn
	if(DecalClasses[HitSurface] != None)
		Spawn(DecalClasses[HitSurface]);
}

defaultproperties
{
	HitEffectClasses(0)=Class'KFMod.MeleeDirtHitEmitter'
	HitEffectClasses(1)=Class'KFMod.MeleeRockHitEmitter'
	HitEffectClasses(2)=Class'KFMod.MeleeDirtHitEmitter'
	HitEffectClasses(3)=Class'KFMod.MeleeMetalHitEmitter'
=======
defaultproperties
{
	 HitEffects(0)=(HitDecal=class'DefaultBulletDecal',HitEffect=class'MeleeDirtHitEmitter')       	
	 HitEffects(1)=(HitDecal=class'DefaultBulletDecal',HitEffect=class'MeleeRockHitEmitter')      	
	 HitEffects(2)=(HitDecal=class'SnowBulletDecal',HitEffect=class'MeleeDirtHitEmitter')       	
	 HitEffects(3)=(HitDecal=class'MetalBulletDecal',HitEffect=class'MeleeMetalHitEmitter')    
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
