// Custom Bits of Glass for KF!
// By: Alex
// These will respond both to gunfire AND pawn / karma actor encroachment.
// If the encroaching pawn is a KFMonster, the monster will play an attack animation.
// They do not block paths.
class KFGlassMover extends Actor;

var () class <Emitter> GlassBits,BreakGlassBits;  // Stuff to spawn when the Window bit breaks.
var () Material ShatteredTexture; // What to change the skin of the glass to when any part of the pane breaks.
var () int Health;  // How strong is this bit of glass?
var bool bCracked,bClientCracked;
var byte ShardCount,ClientShardCount;	// shards knocked off, counted by the server so network players see them too
var float NextShardTime;
var bool bTraderSolid;					// trader time: players are held back by Blocker (see SetTraderSolid)
var KFGlassBlocker Blocker;

replication
{
	reliable if ( Role == ROLE_Authority )
		bCracked, ShardCount, bTraderSolid;
}

function PostBeginPlay()
{
	// Hack for glass that starts out broken, so you can jump through it.
	if(Health == 1)
		CrackWindow();
}

simulated function PostNetBeginPlay()
{
	bClientCracked = bCracked;
	ClientShardCount = ShardCount;
	if( !bHidden && bCracked )
		CrackWindow();
	bNetNotify = !bHidden;
	UpdateBlocker();
}
simulated function PostNetReceive()
{
	if( bHidden )
	{
		BreakWindow();
		bNetNotify = False;
	}
	else
	{
		UpdateBlocker();
		if( bClientCracked!=bCracked )
		{
			bClientCracked = bCracked;
			CrackWindow();
		}
		if( ClientShardCount!=ShardCount )
		{
			ClientShardCount = ShardCount;
			Spawn(GlassBits);
		}
	}
}
simulated function CrackWindow()
{
	bCracked = true;
	NetUpdateTime = Level.TimeSeconds - 1;
	if( Level.NetMode!=NM_DedicatedServer )
	{
		Skins.Length = Max(1,Skins.Length);
		Skins[0] = ShatteredTexture;
	}
}
simulated function BreakWindow()
{
	SetCollision(false,false,false);
	bHidden = true;
	UpdateBlocker();
	NetUpdateTime = Level.TimeSeconds - 1;
	if( Level.NetMode!=NM_DedicatedServer )
		Spawn(BreakGlassBits);
}
// Shards off the pane: a few a second at most (a specimen pushing on it bumps it every tick, and made a spray each
// time), and seen by network players too (they were made only on the server's own machine)
simulated function ShardWindow()
{
	if( Level.TimeSeconds<NextShardTime )
		return;
	NextShardTime = Level.TimeSeconds+0.25;
	if( Level.NetMode!=NM_DedicatedServer )
		Spawn(GlassBits);
	if( Role==ROLE_Authority && Level.NetMode!=NM_Standalone )
	{
		ShardCount++;
		NetUpdateTime = Level.TimeSeconds - 1;
	}
}

// Between waves players block nothing, so that none can stand in another's way at the trader; and since the glass only
// stops what blocks, they walked through it. For that time the pane gets an unseen stand-in of its own shape that is
// world geometry, which holds back all that collides with the world. (Set by the game; each machine keeps its own.)
function SetTraderSolid( bool bSolid )
{
	if( bSolid==bTraderSolid )
		return;
	bTraderSolid = bSolid;
	NetUpdateTime = Level.TimeSeconds - 1;
	UpdateBlocker();
}

simulated function UpdateBlocker()
{
	local bool bOn;

	bOn = bTraderSolid && !bHidden;
	if( bOn && Blocker==None )
	{
		Blocker = Spawn(class'KFGlassBlocker', Self,, Location, Rotation);
		if( Blocker==None )
			return;
		Blocker.Glass = Self;
		Blocker.SetStaticMesh(StaticMesh);
		Blocker.SetDrawScale(DrawScale);
		Blocker.SetDrawScale3D(DrawScale3D);
	}
	if( Blocker!=None && Blocker.bCollideActors!=bOn )
		Blocker.SetCollision(bOn, true, true);
}

simulated function Destroyed()
{
	if( Blocker!=None )
		Blocker.Destroy();
	Super.Destroyed();
}

// When bumped by player (OR ZOMBIES!!!!). evil things happen ....
function Bump( actor Other )
{
	local KFMonster GlassCrasher;
	local class <DamageType> DummyDam;

	// if our window crasher is a Zombie, he must use his arms to break the glass,
	// and pause for a moment while doing this!
	if( Other.IsA('KFHumanPawn') && !bCracked )
		return;

	// If the incoming object is moving at a speed above our set threshold ..
	if (VSize(Other.Velocity) >= 10 || VSize(Other.Acceleration) >= 10)
	{
		TakeDamage(VSize(Other.Velocity),pawn(Other),location,Other.Velocity,DummyDam);
		ShardWindow();
	}
	if (Other.IsA('KFMonster'))
	{
		GlassCrasher = KFMonster(Other);

        GlassCrasher.HandleBumpGlass();

		TakeDamage(GlassCrasher.damageConst + rand(GlassCrasher.damageRand),GlassCrasher,location,Other.Velocity,DummyDam);
	}
	else if( ExtendedZCollision(Other)!=None &&
        Other.Base != none && KFMonster(Other.Base) != none )
    {
		GlassCrasher = KFMonster(Other.Base);

        GlassCrasher.HandleBumpGlass();

		TakeDamage(GlassCrasher.damageConst + rand(GlassCrasher.damageRand),GlassCrasher,location,Other.Velocity,DummyDam);
	}
}

simulated function SetInitialState();

// Added bHidden for small bit of optimization
function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType)
{
	if( bHidden )
		return;

	Health -= Damage;
	// glass shatters
	if (Health <= 0 )
	{
		if ( instigatedBy!=None && AIController(instigatedBy.Controller)!=None && (instigatedBy.Controller.Focus==self || instigatedBy.Controller.Target==Self) )
			instigatedBy.Controller.StopFiring();
		BreakWindow();
		ShatterOtherWindows();
		TriggerEvent(Event,Self,instigatedBy);
	}
	else ShardWindow();
}

function ShatterOtherWindows()
{
	local KFGlassMover GM;

	if( Tag=='' || Tag==Class.Name )
		Return;
	foreach DynamicActors(class'KFGlassMover',GM,Tag)
	{
		GM.Health = 1;
		GM.CrackWindow();
	}
}
function Trigger( actor Other, pawn EventInstigator )
{
	if( bHidden )
		return;
	Health = 0;
	BreakWindow();
	ShatterOtherWindows();
	TriggerEvent(Event,Self,EventInstigator);
}

defaultproperties
{
     GlassBits=Class'KFMod.WindowGlassEmitter'
     BreakGlassBits=Class 'KFmod.BreakWindowGlassEmitter'
     bShadowCast=False
     bBlockKarma=True
     bPathColliding=False
     bCollideActors=True
     bBlockActors=True

     ShatteredTexture = Shader 'KillingFloorLabTextures.Statics.ShaderCrackedGlass'

     Health = 50

     bStasis = true

     Physics=PHYS_None
     RemoteRole=ROLE_SimulatedProxy

     NetPriority=2.7
     bAlwaysRelevant=true
     NetUpdateFrequency=1
     bNoDelete=true
}
