//=============================================================================
// 9mm Fire
//=============================================================================
class MachinePFire extends SingleFire;

<<<<<<< HEAD
defaultproperties
{
	FireLoopAnim="Fire"
	FireAnimRate=1.500000
	FireRate=0.100000
	AmmoClass=Class'KFMod.MPistolAmmo'
=======
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
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
