//=============================================================================
// BoomStick Fire
//=============================================================================
class BoomStickSuperFire extends BoomStickFire;

function float MaxRange()
{
	return 3000;
}

function DoFireEffect()
{
    Super.DoFireEffect();
    if(PlayerController(Instigator.Controller) != None && FRand() < 0.05)
        PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'BoomStickKillMessage');
}

                                   
defaultproperties
{
    ProjPerFire=100 //Uh oh lol
    Spread=3500.000000
    ProjectileClass=Class'KFMod.BoomStickSuperBullet'
}
