//Dont wonder why I made this..
//If I cant see it, its not there!

//Slinky- Whoever made some of this stuff is on crack.  Still trying to decipher
//poorly documented crap.

class InvisBullet extends Projectile;

function BlowUp(vector HitLocation)
{
	HurtRadius(Damage, DamageRadius, MyDamageType, MomentumTransfer, HitLocation );
}

defaultproperties
{
     Speed=10000.000000
     MaxSpeed=10100.000000
     MomentumTransfer=70000.000000
     LifeSpan=1.000000
}
