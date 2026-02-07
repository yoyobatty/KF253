//=============================================================================
// Nade Net Fixed by .:..:
//=============================================================================
class NadeFixed extends Nade;

// Shoot nades in mid-air (only allow eighter zombies take it down, or player itself).
function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
	if( Monster(instigatedBy)!=None || instigatedBy==Instigator )
		Explode(hitlocation,vect(0,0,1));
}

simulated function Destroyed()
{
	if( !bHasExploded )
		Explode(Location,vect(0,0,1));
	Super.Destroyed();
}

function PostNetBeginPlay()
{
	SetTimer(ExplodeTimer, false);
}
function Timer()
{
	Explode(Location, vect(0,0,1));
}

defaultproperties
{
	bNetTemporary=False
}
