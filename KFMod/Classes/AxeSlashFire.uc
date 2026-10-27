//=============================================================================
// AxeSlashFire
// The upgraded axe's other button (the Executioner): always the sideways swing, and as the blade crosses the view its
// edge flies on through the air flat (KFAxeSlash; AxeFire throws it upright). The axe as it comes does nothing on this
// button.
//=============================================================================
class AxeSlashFire extends AxeFire;

simulated function bool AllowFire()
{
	return Upgraded() && Super.AllowFire();
}

defaultproperties
{
     SlashAnim="Fire2"
     bSlashUpright=False
     Swings(0)=(Anim="Fire2",From=0.650000,To=0.780000,StartYaw=40.000000,StartPitch=14.000000,EndYaw=-40.000000,EndPitch=-2.000000,Across=24.000000,DamageScale=1.000000,BodyAnim="AxeAttack",BodyFrom=0.560000,BodyTo=0.720000,Lunge=6.000000)
     FireRate=1.100000
     BotRefireRate=1.100000
}
