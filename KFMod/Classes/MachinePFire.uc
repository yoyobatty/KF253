//=============================================================================
// 9mm Fire
//=============================================================================
class MachinePFire extends SingleFire;

function DoTrace(Vector Start, Rotator Dir)
{
     if ( KFPawn(Instigator) != None )
          DamageType = KFPawn(Instigator).GetVeteran().static.GetMAC10DamageType();
     Super.DoTrace(Start,Dir);
}

defaultproperties
{
	MechSound=Sound'KFWeaponSound.Berettaslideback'
	MechVolume=0.220000
	MechPitch=1.800000
     FlashEmitterClass=None
     FlashFXClass=Class'KFMod.KFFlashMP'
     bWaitForRelease=False
     FireLoopAnim="Fire"
     FireAnimRate=1.500000
     FireRate=0.052000
     AmmoClass=Class'KFMod.MPistolAmmo'
}
