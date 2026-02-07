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
<<<<<<< HEAD
	mMuzFlashClass=Class'KFMod.KFLawMuzzFlash'
	TPAnims(0)="LAWFire"
	WeaponIdleMovementAnim="LawIdle"
	bHeavy=True
	Mesh=SkeletalMesh'KFWeaponModels.LAW3P'
	DrawScale=0.350000
=======
     mMuzFlashClass=Class'KFMod.KFLawMuzzFlash'
     TPAnims(0)="LAWFire"
     WeaponIdleMovementAnim="LawIdle"
     bHeavy=True
     Mesh=SkeletalMesh'KFWeaponModels.LAW3P'
     DrawScale=0.350000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
