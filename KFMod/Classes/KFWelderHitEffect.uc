class KFWelderHitEffect extends KFHitEffect;

simulated function PostNetBeginPlay()
{
	local Vector HitLocation, HitNormal,TDir;
	local Actor Other;

	if( Instigator==None )
	{
		Spawn(Class'KFMod.WelderHitEmitter',,,,RotRand(True));
		Return;
	}
	TDir = Normal(Location-Instigator.Location);
	Other = Instigator.Trace(HitLocation, HitNormal, Location+TDir*32, Location-TDir*10,true);
	
	if( Other==none )
	{
		Spawn(Class'KFMod.WelderHitEmitter',,,,RotRand(True));
		return;
	}
	Spawn(Class'KFMod.WelderHitEmitter',,,HitLocation+HitNormal*4, rotator(HitNormal));
}

defaultproperties
{
}
