// The versus match as every machine sees it: the half, which team plays the survivors, the teams' scores, the break
class VSGRI extends KFGameReplicationInfo;

var byte Half;				// 1 or 2
var byte SurvivorSquad;		// the team playing the survivors this half (0 Team A, 1 Team B)
var int SquadScore[2];		// each team's points, from its half as the survivors
var byte SquadWaves[2];		// the waves each team cleared as the survivors
var byte HalfTimeLeft;		// seconds left of the break between the halves (0: none)
var byte WinnerSquad;		// at the end: 0 or 1, 2 a draw (255 until then)

var localized string SquadNames[2], RoleNames[2], DrawText;

replication
{
	reliable if( bNetDirty && Role==ROLE_Authority )
		Half, SurvivorSquad, SquadScore, SquadWaves, HalfTimeLeft, WinnerSquad;
}

simulated function string SquadName( byte S )
{
	return SquadNames[Min(S,1)];
}

// "Survivors" or "Specimens" for a team this half
simulated function string RoleOf( byte S )
{
	if( S==SurvivorSquad )
		return RoleNames[0];
	return RoleNames[1];
}

defaultproperties
{
     Half=1
     WinnerSquad=255
     SquadNames(0)="Team A"
     SquadNames(1)="Team B"
     RoleNames(0)="Survivors"
     RoleNames(1)="Specimens"
     DrawText="DRAW"
}
