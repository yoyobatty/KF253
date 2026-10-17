// Zombies mode: Juggernog perk machine. Buying it raises the player's max
// health (so it takes more hits to go down - see KFZombiesGameType's
// PreventDeath / KFHumanPawn.GoDowned for the downed/revive side of this).
// The perk is lost on a real death (KFHumanPawn.Died) and must be re-bought.
class KFJuggernogMachine extends KFPerkMachine
	placeable;

var() float HealthBonus;

function bool HasPerk( KFPlayerReplicationInfo KFPRI )
{
	Return KFPRI.bHasJuggernog;
}

function GivePerk( KFHumanPawnZombies P, KFPlayerReplicationInfo KFPRI )
{
	KFPRI.bHasJuggernog = true;
	P.SetPerkHealthBonus(HealthBonus);
}

defaultproperties
{
	Cost=2500
	HealthBonus=150.000000
	PerkName="Iron Hide"
	AlreadyBoughtMessage="You already have Iron Hide."
	PurchasedMessage="Iron Hide purchased! You can take more hits before going down."
}
