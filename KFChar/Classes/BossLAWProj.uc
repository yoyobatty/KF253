class BossLAWProj extends LAWProj;

<<<<<<< HEAD
defaultproperties
{
	Damage=400.000000
=======
simulated function ProcessTouch(Actor Other, Vector HitLocation)
{
	// Don't let it hit this player, or blow up on another player
	if ( Other==none || Other==Instigator || Other.Base==Instigator || ExtendedZCollision(Other)!=None || Monster(Other)!=None )
		return;

	Explode(HitLocation,Normal(HitLocation-Other.Location));
}

function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> DamageType);

defaultproperties
{
    Damage=400.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
