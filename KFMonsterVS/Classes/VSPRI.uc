Class VSPRI extends KFPlayerReplicationInfo;

var byte VSTeam;					// the player's versus team (0 Team A, 1 Team B; 255 none yet, and for bots)
var int SpecimenDamage;			// damage done to survivors as a specimen
var class<KFMonster> SpawnClass;	// the specimen this player rises as next
var byte SpawnWait;				// seconds before they may rise
var byte Patience;				// a heavy's patience left, 0 to 100: at 0 the AI takes it over

replication
{
	reliable if( bNetDirty && Role==ROLE_Authority )
		VSTeam, SpecimenDamage;
	reliable if( bNetDirty && bNetOwner && Role==ROLE_Authority )
		SpawnClass, SpawnWait, Patience;
}

// (a specimen's health as a share of its own, for the scoreboard)
function Timer()
{
	local Controller C;

	Super.Timer();
	C = Controller(Owner);
	if( C!=None && C.Pawn!=None && C.Pawn.HealthMax!=100 )
		PlayerHealth = (float(C.Pawn.Health)/C.Pawn.HealthMax)*100.f;
}

defaultproperties
{
     VSTeam=255
}
