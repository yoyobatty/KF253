// Axe Fire //
class AxeFire extends KFMeleeFire;

// Down from the right shoulder, with the width of a two-handed swing; then flat across from the right. Upgraded (the
// Executioner) this button always swings down from the shoulder and the blade's edge flies on, upright (KFAxeSlash);
// the other button swings across and throws it flat (AxeSlashFire).

var() class<KFAxeSlash>	SlashClass;
var() name				SlashAnim;		// the swing the upgraded axe always swings on this button
var() bool				bSlashUpright;	// ...and its cut flies upright
var float				LaunchAt;		// when the cut leaves the blade: as it crosses the middle of the view
var() float				UprightSide;	// how far right of the eye an upright cut leaves, where the overhead swing comes down

simulated function bool Upgraded()
{
	return KFWeapon(Weapon) != None && KFWeapon(Weapon).bUpgraded && SlashClass != None;
}

simulated function StartSwing()
{
	local Swing S;
	local int k;

	// (upgraded: always the one swing, whatever came before)
	if ( Upgraded() )
		for ( k = 0; k < Swings.Length; k++ )
			if ( Swings[k].Anim == SlashAnim )
			{
				if ( k == 0 )
					LastSwingTime = -1000.0;
				else
				{
					SwingIndex = k - 1;
					LastSwingTime = Level.TimeSeconds;
				}
				break;
			}
	Super.StartSwing();
	if ( Upgraded() )
	{
		S = Swings[SwingIndex];
		LaunchAt = Level.TimeSeconds + TweenTime + 0.5 * (S.From + S.To) / FireAnimRate;
	}
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
	local vector X, Y, Z, Eye, Start;
	local rotator Aim;

	if ( Instigator == None || Instigator.Health <= 0 )
		return;
	// (the view's own axes: rolled upright, its up would point to one side)
	Aim = Instigator.GetViewRotation();
	GetAxes(Aim, X, Y, Z);
	Eye = Instigator.Location + Instigator.EyePosition();
	if ( bSlashUpright )
	{
		Start = Eye + X * 30.0 + Y * UprightSide - Z * 16.0;
		Aim.Roll = 16384;
	}
	else
		Start = Eye + X * 30.0 - Z * 30.0;
	Weapon.Spawn(SlashClass, Instigator,, Start, Aim);
}

defaultproperties
{
     SlashClass=Class'KFMod.KFAxeSlash'
     SlashAnim="Fire"
     bSlashUpright=True
     UprightSide=18.000000
     MeleeKind=1
     bSweep=True
     Swings(0)=(Anim="Fire",From=0.650000,To=0.790000,StartYaw=14.000000,StartPitch=38.000000,EndYaw=-8.000000,EndPitch=-26.000000,Across=36.000000,DamageScale=1.000000,BodyAnim="AxeAttack",BodyFrom=0.560000,BodyTo=0.720000,Lunge=10.000000)
     Swings(1)=(Anim="Fire2",From=0.650000,To=0.780000,StartYaw=40.000000,StartPitch=14.000000,EndYaw=-40.000000,EndPitch=-2.000000,Across=24.000000,DamageScale=1.000000,BodyAnim="AxeAttack",BodyFrom=0.560000,BodyTo=0.720000,Lunge=4.000000)
     ChainTime=1.500000
     HitPunch=150.000000
     HitPause=0.025000
     CamSway=4.000000
     damageConst=175
     maxAdditionalDamage=50
     ProxySize=0.150000
     weaponRange=100.000000
     DamagedelayMin=0.800000
     DamagedelayMax=0.800000
     hitDamageClass=Class'KFMod.DamTypeAxe'
     WideDamageMinHitAngle=0.500000
     FireRate=1.100000
     BotRefireRate=0.850000
     UpgradeSideDamageScale=1.000000
}
