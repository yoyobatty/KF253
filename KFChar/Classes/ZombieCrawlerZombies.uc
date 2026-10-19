// Zombies gametype-specific Crawler. Scaffolding for KFZombiesGameType tuning.
class ZombieCrawlerZombies extends ZombieCrawler;

simulated function AnimEnd(int Channel)
{
	AnimAction = '';
	if ( bShotAnim && Channel==ExpectingChannel )
	{
		bShotAnim = false;
		if( Controller!=None )
			Controller.bPreparingMove = false;
	}
	if( !bPhysicsAnimUpdate && Channel==0 )
		bPhysicsAnimUpdate = Default.bPhysicsAnimUpdate;
	// (not Skaarj's: it goes on to Monster's, which lets the specimen go at the end of any animation, a flinch's too)
	Super(xPawn).AnimEnd(Channel);
}

defaultproperties
{
	GroundSpeed=110.000000
	CollisionRadius=20.000000
	ScoringValue=3
}
