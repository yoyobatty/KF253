class KFMeleeAttachment extends XWeaponAttachment;

var() array<name> TPAnims,TPAnimsB; // Custom third person animations.
var() name WeaponIdleMovementAnim; // Custom holding weapon animation.
var Pawn LastInstig;

simulated event ThirdPersonEffects()
{
	if ( (Level.NetMode == NM_DedicatedServer) || (Instigator == None) )
		return;

	if ( FlashCount>0 )
	{
		if( KFPawn(Instigator)!=None )
		{
			if (FiringMode == 0)
				KFPawn(Instigator).StartFiringX(bHeavy,bRapidFire,GetThirdPersonAnim());
			else KFPawn(Instigator).StartFiringX(bHeavy,bAltRapidFire,GetThirdPersonAnim());
		}
	}
	else
	{
		GotoState('');
		if( KFPawn(Instigator)!=None )
			KFPawn(Instigator).StopFiring();
	}
}
simulated function name GetThirdPersonAnim()
{
	if( FiringMode==1 && TPAnimsB.Length>0 )
		Return TPAnimsB[Rand(TPAnimsB.Length)];
	if( TPAnims.Length==0 )
		Return '';
	else if( TPAnims.Length==1 )
		Return TPAnims[0];
	Return TPAnims[Rand(TPAnims.Length)];
}
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

defaultproperties
{
<<<<<<< HEAD
	WeaponIdleMovementAnim="Idle_Rifle"
	bHeavy=True
=======
     WeaponIdleMovementAnim="Idle_Rifle"
     bHeavy=True
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
