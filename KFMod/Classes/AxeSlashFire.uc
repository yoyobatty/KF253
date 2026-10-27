//=============================================================================
// AxeSlashFire
// The upgraded axe's other swing (the Executioner): the sideways swing, and as the blade crosses the view its edge
// flies on through the air (KFAxeSlash), flat; swung again, the overhead swing, and the cut flies upright. The axe as
// it comes does nothing on this button.
//=============================================================================
class AxeSlashFire extends AxeFire;

var() class<KFAxeSlash>	SlashClass;
var float				LaunchAt;		// when the cut leaves the blade: as it crosses the middle of the view

simulated function bool AllowFire()
{
	return KFWeapon(Weapon) != None && KFWeapon(Weapon).bUpgraded && Super.AllowFire();
}

simulated function StartSwing()
{
	local Swing S;

	Super.StartSwing();
	S = Swings[SwingIndex];
	LaunchAt = Level.TimeSeconds + TweenTime + 0.5 * (S.From + S.To) / FireAnimRate;
}

event ModeTick( float DT )
{
	Super.ModeTick(DT);
	if ( LaunchAt > 0.0 && Level.TimeSeconds >= LaunchAt )
	{
		LaunchAt = 0.0;
		if ( Weapon.Role == ROLE_Authority )
			Launch();
	}
}

// (the server) The cut, from just under the eye, along the aim
function Launch()
{
	local vector X, Y, Z, Eye;
	local rotator Aim;

	if ( Instigator == None || Instigator.Health <= 0 )
		return;
	Aim = Instigator.GetViewRotation();
	// (the overhead swing throws it upright)
	if ( Swings[SwingIndex].Anim == 'Fire' )
		Aim.Roll = 16384;
	GetAxes(Aim, X, Y, Z);
	Eye = Instigator.Location + Instigator.EyePosition();
	Weapon.Spawn(SlashClass, Instigator,, Eye + X * 30.0 - Z * 30.0, Aim);
}

defaultproperties
{
     SlashClass=Class'KFMod.KFAxeSlash'
     Swings(0)=(Anim="Fire2",From=0.650000,To=0.780000,StartYaw=40.000000,StartPitch=14.000000,EndYaw=-40.000000,EndPitch=-2.000000,Across=24.000000,DamageScale=1.000000,BodyAnim="AxeAttack",BodyFrom=0.560000,BodyTo=0.720000,Lunge=6.000000)
     Swings(1)=(Anim="Fire",From=0.650000,To=0.790000,StartYaw=14.000000,StartPitch=38.000000,EndYaw=-8.000000,EndPitch=-26.000000,Across=36.000000,DamageScale=1.000000,BodyAnim="AxeAttack",BodyFrom=0.560000,BodyTo=0.720000,Lunge=10.000000)
     ChainTime=2.200000
     FireRate=1.500000
     BotRefireRate=1.500000
}
