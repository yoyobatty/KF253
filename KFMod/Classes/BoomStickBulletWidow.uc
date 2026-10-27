//=============================================================================
// BoomStickBulletWidow
// A pellet of an upgraded double barrel (Widowmaker): a light specimen it strikes is thrown off its feet and back, a
// heavy one stumbles (KFMonster.KnockBack)
//=============================================================================
class BoomStickBulletWidow extends BoomStickBullet;

simulated function ProcessTouch( Actor Other, vector HitLocation )
{
	local KFMonster M;

	M = KFMonster(Other);
	if ( M == None && ExtendedZCollision(Other) != None )
		M = KFMonster(Other.Owner);
	Super.ProcessTouch(Other, HitLocation);
	if ( Role == ROLE_Authority && M != None && M.Health > 0 && Instigator != None )
		M.KnockBack(Instigator.Location, 320 * Normal((M.Location - Instigator.Location) * vect(1,1,0)) + vect(0,0,160));
}
