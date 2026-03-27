class LAWAttachment extends KFWeaponAttachment;

/*
var() name WeaponIdleMovementAnim; // Custom holding weapon animation.
var Pawn LastInstig;

simulated function PostNetReceive()
{
	if( Instigator!=LastInstig )
	{
		LastInstig = Instigator;
		if( KFPawn(Instigator)!=None )
			KFPawn(Instigator).UpdateClientAnim(WeaponIdleMovementAnim);
	}
}
simulated function PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
	LastInstig = Instigator;
	if( KFPawn(Instigator)!=None )
		KFPawn(Instigator).UpdateClientAnim(WeaponIdleMovementAnim);
	bNetNotify = True;
}
*/

defaultproperties
{
     mMuzFlashClass=Class'KFMod.KFLawMuzzFlash'
     TPAnims(0)="LAWFire"
     WeaponIdleMovementAnim="LawIdle"
     bHeavy=True
     Mesh=SkeletalMesh'KFWeaponModels.LAW3P'
     DrawScale=0.350000
}
