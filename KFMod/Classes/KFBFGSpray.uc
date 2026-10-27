//=============================================================================
// KFBFGSpray
// The BFG's tracers as seen (BFGBall.Tracers): the server sends where they struck once; each machine that draws it
// throws a green bolt from the blast to each, and a green burst there.
//=============================================================================
class KFBFGSpray extends Actor;

var vector	Ends[16];
var byte	NumEnds;
var bool	bShown;

replication
{
	reliable if ( bNetInitial && Role == ROLE_Authority )
		Ends, NumEnds;
}

simulated function Tick( float DT )
{
	local int i;
	local KFBFGBolt B;
	local Emitter E;

	if ( bShown || Level.NetMode == NM_DedicatedServer )
		return;
	bShown = true;
	for ( i = 0; i < NumEnds && i < ArrayCount(Ends); i++ )
	{
		B = Spawn(class'KFBFGBolt',,, Location);
		if ( B != None )
			B.Span(Location, Ends[i], 0.5);
		E = Spawn(class'KFBFGHitFX',,, Ends[i]);
		class'KFGib'.static.Line(self, Location, Ends[i], 22.0);
	}
}

defaultproperties
{
     DrawType=DT_None
     bHidden=True
     RemoteRole=ROLE_SimulatedProxy
     bNetTemporary=True
     NetPriority=2.500000
     LifeSpan=1.500000
     bCollideActors=False
     bBlockActors=False
}
