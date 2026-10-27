// A specimen electrocuted to death (KFMonster.bZapDeath): on each machine that draws it, its body seizes where it falls for
// SeizeTime: its hands and feet kicked about by the current every JoltEvery, the whole body bucking up off the floor every
// ArchEvery, both dying away; arcs crawl over it and it buzzes (KFZapBody), then it smokes.
class KFZapDeath extends Actor;

var() float SeizeTime;
var() float JoltEvery, JoltPush;
var() float ArchEvery, ArchPush;
var KFMonster Body;
var KFZapBody Arcs;
var float Age, NextJolt, NextArch;

simulated function PostBeginPlay()
{
	Body = KFMonster(Owner);
	if ( Body == None )
	{
		Destroy();
		return;
	}
	Arcs = Spawn(class'KFZapBody', Body,, Body.Location);
	if ( Arcs != None )
		Arcs.SetBase(Body);
	PlaySound(Sound'KFMod.Zap.ZapStart', SLOT_None, 2.0,, 700, 0.8 + 0.2 * FRand());
	NextArch = 0.15;
}

simulated function Tick( float DT )
{
	local name Bone;
	local float Left;
	local vector Up;

	Age += DT;
	if ( Body == None || Body.bDeleteMe || Age > SeizeTime )
	{
		Finish();
		return;
	}
	Left = 1.0 - Age / SeizeTime;
	if ( Arcs != None && Level.TimeSeconds - Body.LastRenderTime < 1.0 )
		Body.OverBody(Arcs);
	if ( Body.Physics != PHYS_KarmaRagdoll )
		return;
	// a hand or foot kicked about
	if ( Age >= NextJolt )
	{
		NextJolt = Age + JoltEvery * (0.5 + FRand());
		Bone = Body.LimbEnds[Rand(8)];
		Body.KAddImpulse(VRand() * JoltPush * (0.35 + 0.65 * Left), Body.GetBoneCoords(Bone).Origin, Bone);
	}
	// the whole body bucks up off the floor and twists
	if ( Age >= NextArch )
	{
		NextArch = Age + ArchEvery * (0.6 + 0.8 * FRand());
		Up = vect(0,0,1) + 0.35 * VRand();
		Body.KAddImpulse(Up * ArchPush * Left, Body.GetBoneCoords('Bip01 Pelvis').Origin, 'Bip01 Pelvis');
		Body.KAddImpulse((vect(0,0,0.6) + 0.5 * VRand()) * ArchPush * Left, Body.GetBoneCoords('Bip01 Neck').Origin, 'Bip01 Neck');
	}
}

simulated function Finish()
{
	if ( Arcs != None )
	{
		Arcs.AmbientSound = None;
		Arcs.Kill();
		Arcs = None;
	}
	if ( Body != None && !Body.bDeleteMe && !Body.bGibbed && Body.CorpseSmoke == None && Body.CorpseBurnEnd <= 0.0 )
		Body.SmokeBody();
	Destroy();
}

defaultproperties
{
     SeizeTime=3.500000
     JoltEvery=0.060000
     JoltPush=9000.000000
     ArchEvery=0.450000
     ArchPush=14000.000000
     DrawType=DT_None
     bHidden=True
     RemoteRole=ROLE_None
     LifeSpan=6.000000
}
