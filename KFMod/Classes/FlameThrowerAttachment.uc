class FlameThrowerAttachment extends KFMeleeAttachment;//KFWeaponAttachment;

var KFFlameStream Stream;	// the stream as this machine shows it, fed by each shot

simulated event ThirdPersonEffects()
{
	Super.ThirdPersonEffects();
	if ( Level.NetMode == NM_DedicatedServer || Instigator == None )
		return;
	if ( FlashCount > 0 )
	{
		if ( Stream == None || Stream.bDeleteMe )
			Stream = Spawn(class'KFFlameStream', self);
		if ( Stream != None )
			Stream.Feed();
	}
	else if ( Stream != None && !Stream.bDeleteMe )
		Stream.Release();
}

defaultproperties
{
     TPAnims(0)="FlameThrowerFire"
     WeaponIdleMovementAnim="FlamethrowerIdle"
     Mesh=SkeletalMesh'KFWeaponModels.FlameThrower3P'
     DrawScale=0.450000
}
