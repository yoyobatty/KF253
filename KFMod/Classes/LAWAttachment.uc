class LAWAttachment extends KFWeaponAttachment;

var byte BlastCount;	// (the shot whose backblast was thrown)

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

// A shot throws a backblast out of the back of the tube (KFBackblast)
simulated event ThirdPersonEffects()
{
	local rotator Aim;

	Super.ThirdPersonEffects();
	if ( Level.NetMode == NM_DedicatedServer || Instigator == None || FlashCount == 0 || FlashCount == BlastCount )
		return;
	BlastCount = FlashCount;
	if ( Level.TimeSeconds - LastRenderTime > 0.2 && Instigator.Controller != Level.GetLocalPlayerController() )
		return;
	Aim = Instigator.GetViewRotation();
	Spawn(class'KFBackblast', self,, Instigator.Location + vect(0,0,1) * Instigator.BaseEyeHeight * 0.8 - vector(Aim) * 45, rotator(-vector(Aim)));
}

defaultproperties
{
     mMuzFlashClass=Class'KFMod.KFFlashLAW'
     TPAnims(0)="LAWFire"
     WeaponIdleMovementAnim="LawIdle"
     bHeavy=True
     Mesh=SkeletalMesh'KFWeaponModels.LAW3P'
     DrawScale=0.350000
     SmokeHeat=0.900000
}
