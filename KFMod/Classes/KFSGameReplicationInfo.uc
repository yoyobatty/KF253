class KFSGameReplicationInfo extends KFGameReplicationInfo;

var KFSPLevelinfo KFPLevel; // Easier to do it this way.
var int CurrentObjectiveNum;

replication
{
	reliable if( bNetDirty && Role==ROLE_Authority )
		CurrentObjectiveNum;
}

defaultproperties
{
}
