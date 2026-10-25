//=============================================================================
// KFFlameFireControl
// The harm of the flamethrower's ground fires (FlameGroundFire), on the server: every BurnInterval each one in reach
// of any of them takes the harm of the worst once, however many it stands in (each fire's own HurtRadius hurt it
// once for every fire). Otherwise as HurtRadius: less towards the edge, by the fire's starter.
//=============================================================================
class KFFlameFireControl extends Info;

var array<FlameGroundFire>	Fires;
var array<Actor>			Hit;
var array<float>			HitHarm;
var array<FlameGroundFire>	HitBy;

static function Add( FlameGroundFire F )
{
	local KFFlameFireControl C;

	foreach F.DynamicActors(class'KFFlameFireControl', C)
		break;
	if ( C == None )
		C = F.Spawn(class'KFFlameFireControl');
	if ( C != None )
		C.Fires[C.Fires.Length] = F;
}

function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(class'FlameGroundFire'.default.BurnInterval, true);
}

function Timer()
{
	local int i, j;
	local FlameGroundFire F;
	local Actor A;
	local float D, Harm;
	local vector Dir;

	Hit.Length = 0;
	HitHarm.Length = 0;
	HitBy.Length = 0;
	for ( i = Fires.Length - 1; i >= 0; i-- )
	{
		F = Fires[i];
		if ( F == None || F.bDeleteMe || F.bDyingDown )
		{
			Fires.Remove(i, 1);
			continue;
		}
		if ( F.PhysicsVolume.bWaterVolume )
			continue;
		foreach F.VisibleCollidingActors(class'Actor', A, F.DamageRadius, F.Location)
		{
			if ( A == F || A.Role != ROLE_Authority || A.IsA('FluidSurfaceInfo') )
				continue;
			D = FMax(1, VSize(A.Location - F.Location));
			Harm = (1 - FMax(0, (D - A.CollisionRadius) / F.DamageRadius)) * F.FlameDamage;
			for ( j = 0; j < Hit.Length; j++ )
				if ( Hit[j] == A )
					break;
			if ( j == Hit.Length )
			{
				Hit[j] = A;
				HitHarm[j] = Harm;
				HitBy[j] = F;
			}
			else if ( Harm > HitHarm[j] )
			{
				HitHarm[j] = Harm;
				HitBy[j] = F;
			}
		}
	}
	for ( j = 0; j < Hit.Length; j++ )
	{
		A = Hit[j];
		F = HitBy[j];
		if ( A == None || A.bDeleteMe || F == None )
			continue;
		Dir = Normal(A.Location - F.Location);
		A.TakeDamage(HitHarm[j], F.Instigator, A.Location - 0.5 * (A.CollisionHeight + A.CollisionRadius) * Dir, vect(0,0,0), class'DamTypeFlamethrower');
	}
}

defaultproperties
{
}
