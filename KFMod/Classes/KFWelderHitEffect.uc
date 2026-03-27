class KFWelderHitEffect extends KFHitEffect;

<<<<<<< HEAD
simulated function SpawnEffects()
=======
simulated function PostNetBeginPlay()
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
{
	local Vector HitLocation, HitNormal,TDir;
	local Actor Other;

	if( Instigator==None )
	{
<<<<<<< HEAD
		Spawn(HitEffectClasses[0],,,,RotRand(True));
=======
		Spawn(Class'KFMod.WelderHitEmitter',,,,RotRand(True));
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		Return;
	}
	TDir = Normal(Location-Instigator.Location);
	Other = Instigator.Trace(HitLocation, HitNormal, Location+TDir*32, Location-TDir*10,true);
	
	if( Other==none )
	{
<<<<<<< HEAD
		Spawn(HitEffectClasses[0],,,,RotRand(True));
		return;
	}
	Spawn(HitEffectClasses[0],,,HitLocation+HitNormal*4, rotator(HitNormal));
=======
		Spawn(Class'KFMod.WelderHitEmitter',,,,RotRand(True));
		return;
	}
	Spawn(Class'KFMod.WelderHitEmitter',,,HitLocation+HitNormal*4, rotator(HitNormal));
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

defaultproperties
{
<<<<<<< HEAD
	HitEffectClasses(0)=Class'KFMod.WelderHitEmitter'
=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
