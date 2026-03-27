// Zombie Monster for KF Invasion gametype
class ZombieClotFriend extends ZombieClot;

function bool SameSpeciesAs(Pawn P)
{
	return ( (KFHumanPawn(P) != None) || (ZombieClotFriend(P) != None) );
}

defaultproperties
{
     bCannibal=False
     damageRand=6
     damageConst=7
     ScoringValue=0
     MeleeRange=30.000000
     GroundSpeed=125.000000
     WaterSpeed=125.000000
     HealthMax=400.000000
     Health=400
     MenuName="Clot Friendly"
     ControllerClass=class'KFMod.FriendlyMonsterAI'
}
