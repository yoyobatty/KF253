// Custom code to make the Gorefast act abit more interesting.
class GorefastController extends KFMonsterController;

// Sprint lead: while sprinting straight at its victim it runs for where the victim is going
var() float SprintLeadShare;	// share of the full lead (0 runs straight at the victim, as before)
var() float SprintLeadMaxTime;	// seconds ahead it looks at most
var() float SprintLeadMinDist;	// nearer than this it goes straight in
var() float SprintLeadCheck;	// seconds between fresh looks at where the victim is going
var vector SprintLead;			// the lead last found, from the victim's place
var float NextSprintLeadCheck;

// Called by the sprinting Gorefast every tick, after this controller has steered it straight at its victim
function SteerSprint()
{
	local vector Dir;

	if( KFM==None || Enemy==None || MoveTarget!=Enemy || bAdjusting || Pawn.Physics!=PHYS_Walking || KFM.bShotAnim
	 || VSize(Pawn.Acceleration)<1 || VSize(Enemy.Location-Pawn.Location)<SprintLeadMinDist )
	{
		NextSprintLeadCheck = 0;
		Return;
	}
	if( Level.TimeSeconds>=NextSprintLeadCheck )
	{
		NextSprintLeadCheck = Level.TimeSeconds + SprintLeadCheck;
		SprintLead = InterceptSpot(Enemy, Pawn.GroundSpeed, SprintLeadMaxTime, SprintLeadShare) - Enemy.Location;
	}
	Dir = Enemy.Location + SprintLead - Pawn.Location;
	Dir.Z = 0;
	if( VSize(Dir)>1 )
		Pawn.Acceleration = Normal(Dir)*VSize(Pawn.Acceleration);
}

defaultproperties
{
     StrafingAbility=0.500000
     SprintLeadShare=0.500000
     SprintLeadMaxTime=0.750000
     SprintLeadMinDist=120.000000
     SprintLeadCheck=0.100000
}
