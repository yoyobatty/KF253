//=============================================================================
// CrossbowArrowStinger
// A bolt of an upgraded crossbow (Stinger): it strikes as a bolt does, head shots too, sticks in what it struck and
// bursts a second later (CrossbowArrowExplosive, whose own touch struck a body twice)
//=============================================================================
class CrossbowArrowStinger extends CrossbowArrowExplosive;

simulated function ProcessTouch( Actor Other, vector HitLocation )
{
	local vector X;
	local Pawn P;

	if ( Other == None || Other == Instigator || Other.Base == Instigator )
		return;
	P = Pawn(Other);
	if ( ExtendedZCollision(Other) != None && Pawn(Other.Owner) != None )
		P = Pawn(Other.Owner);
	X = Normal(Velocity);
	if ( Level.NetMode != NM_Client )
	{
		if ( P != None )
		{
			PlayhitNoise(P.ShieldStrength > 0);
			if ( P.IsHeadShot(HitLocation, X, 1.0) )
				P.TakeDamage(Damage * HeadShotDamageMult, Instigator, HitLocation, MomentumTransfer * X, DamageTypeHeadShot);
			else
				P.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * X, MyDamageType);
		}
		else
			Other.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * X, MyDamageType);
	}
	if ( P != None )
		Stick(P, HitLocation);
	else
		Stick(Other, HitLocation);
}

defaultproperties
{
	DelayExplode=1.000000
	Damage=300.000000
	HeadShotDamageMult=4.000000
}
