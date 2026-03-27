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

replication
{
<<<<<<< HEAD
	reliable if(Role == ROLE_Authority)
		ClientGlassBits,ClientBreakGlassBits,Health;
	reliable if (Role < ROLE_Authority)
=======
	reliable if ( Role == ROLE_Authority )
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		bCracked;
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
	if( !bHidden && bCracked )
		CrackWindow();
	bNetNotify = !bHidden;
}
simulated function PostNetReceive()
{
	if( bHidden )
	{
		BreakWindow();
		bNetNotify = False;
	}
	else if( bClientCracked!=bCracked )
	{
		bClientCracked = bCracked;
		CrackWindow();
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
	NetUpdateTime = Level.TimeSeconds - 1;
	if( Level.NetMode!=NM_DedicatedServer )
		Spawn(BreakGlassBits);
}
simulated function ShardWindow()
{
	if( Level.NetMode!=NM_DedicatedServer )
		Spawn(GlassBits);
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
<<<<<<< HEAD
	if (vSize(Other.Velocity) >= 10)
=======
	if (VSize(Other.Velocity) >= 10 || VSize(Other.Acceleration) >= 10)
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	{
		TakeDamage(VSize(Other.Velocity),pawn(Other),location,Other.Velocity,DummyDam);
		ShardWindow();
	}
	if (Other.IsA('KFMonster'))
	{
		GlassCrasher = KFMonster(Other);
<<<<<<< HEAD
  
		GlassCrasher.Acceleration = vect(0,0,0);
		GlassCrasher.Velocity = vect(0,0,0);
  
		GlassCrasher.SetAnimAction(GlassCrasher.MeleeAnims[0]);
		GlassCrasher.bShotAnim = true;
		GlassCrasher.controller.GotoState('WaitForAnim');

		TakeDamage(GlassCrasher.damageConst,pawn(Other),location,Other.Velocity,DummyDam);
=======

        GlassCrasher.HandleBumpGlass();

		TakeDamage(GlassCrasher.damageConst + rand(GlassCrasher.damageRand),GlassCrasher,location,Other.Velocity,DummyDam);
	}
	else if( ExtendedZCollision(Other)!=None &&
        Other.Base != none && KFMonster(Other.Base) != none )
    {
		GlassCrasher = KFMonster(Other.Base);

        GlassCrasher.HandleBumpGlass();

		TakeDamage(GlassCrasher.damageConst + rand(GlassCrasher.damageRand),GlassCrasher,location,Other.Velocity,DummyDam);
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	}
}

simulated function SetInitialState();
<<<<<<< HEAD
simulated function ClientGlassBits();
simulated function ClientBreakGlassBits(); // NOT in use.

// Added bHidden for small bit of optimization
function TakeDamage( int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
=======

// Added bHidden for small bit of optimization
function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType)
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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
<<<<<<< HEAD
	GlassBits=Class'KFMod.WindowGlassEmitter'
	BreakGlassBits=Class'KFMod.BreakWindowGlassEmitter'
	ShatteredTexture=Shader'KillingFloorLabTextures.Statics.ShaderCrackedGlass'
	Health=50
	bNoDelete=True
	bStasis=True
	bAlwaysRelevant=True
	RemoteRole=ROLE_SimulatedProxy
	NetUpdateFrequency=1.000000
	NetPriority=2.700000
	bCollideActors=True
	bBlockActors=True
	bBlockKarma=True
=======
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
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
