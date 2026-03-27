//=============================================================================
// 9mm Fire
//=============================================================================
class MachinePFire extends SingleFire;

function DoTrace(Vector Start, Rotator Dir)
{
     DamageType = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.static.GetMAC10DamageType();
     Super.DoTrace(Start,Dir);
}

defaultproperties
{
     bWaitForRelease=False
     FireLoopAnim="Fire"
     FireAnimRate=1.500000
     FireRate=0.052000
     AmmoClass=Class'KFMod.MPistolAmmo'
}
