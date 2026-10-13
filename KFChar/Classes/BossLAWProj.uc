class BossLAWProj extends LAWProj;

simulated function ProcessTouch(Actor Other, Vector HitLocation)
{
	// Don't hit ourselves :-) also don't hit zeds (or their extended collision)
	if ( Other==none || Other==Instigator || Other.Base==Instigator || ExtendedZCollision(Other)!=None || Monster(Other)!=None )
		return;

	Explode(HitLocation,Normal(HitLocation-Other.Location));
}

function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> DamageType);

simulated function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
	local ZombieBoss B;
	local int Before;

	if( Role==ROLE_Authority )
		B = ZombieBoss(Instigator);
	if( B!=None )
		Before = B.CountLivingHumans();
	Super.HurtRadius(DamageAmount, DamageRadius, DamageType, Momentum, HitLocation);
	if( B!=None && B.CountLivingHumans()<Before )
		B.Taunt(3);
}


defaultproperties
{
    Damage=350.000000
	DamageRadius=400.000000
}
