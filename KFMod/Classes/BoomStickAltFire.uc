//=============================================================================
// BoomStick Fire
//=============================================================================
class BoomStickAltFire extends BoomStickFire;

simulated function bool AllowFire()
{
    if(Instigator.IsHumanControlled()) //hack so bots are only allowed to use it
        return false;
    return Super.AllowFire();
}

function float MaxRange()
{
	return 3000;
}

defaultproperties
{
     ProjPerFire=1
     ProjectileClass=Class'KFMod.BoomStickSlug'
     Spread = 0.010000;
	 SpreadStyle = SS_Line;
}
