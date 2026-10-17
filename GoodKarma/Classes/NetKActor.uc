//NetKActor as part of the GoodKarma package
//Build 134 Beta 4.5 Release
//By: Jonathan Zepp
//Original code based of the LawDogsKActor code available from unreal wiki (Thank You!)
//Though the current version has been SEVERELY modified, and modified some more.
//This is intended to add full server playability, and make karma a universal tool.
//Changes to bot pathing have also been made to put some sense into their empty heads...

class NetKActor extends KActor
	placeable;

#exec OBJ LOAD FILE="..\Sounds\WeaponSounds.uax"

//Edit in default properties in UnrealEd

var() bool bBlockedPath ;                   //Enables Basic bot-pathing
var() bool bCriticalObject ;                //Will Always function despite server physics detail (not fully functional)
var() float moveDistance ;                  //associated with bBlockedPath, how far the object must move for the bots to pass it
var() array<Sound> HitSounds ;              //A sound to play on impact
var() byte RelativeImpactVolume ;           //The relative sound volume of the hit sound
var() bool bShoveable ;                     //Can the object be shoved by a player?
var() name BlockedPath ;                    //The name of the associated blocked path
var() float ShoveModifier;                  //A multiplier to change how hard the object is shoved
var() bool bPuntable ;                      //Allows a NetKActor to be punted
var() int requiredPuntStrength ;            //A value which must be met by the actor calling the DeclarePunt function for a punt to be accepted
var() bool bEnableSpinProtection ;          //Overrides standard karma features to make shoving the object always work properly, not reccomended on all objects, especially long ones, unless they have trouble.
var() float hitSoundRepeatModifier ;        //How much more often will hit sounds play?

var(Damage) bool bCollisionDamage ;               //Enables damage when colliding with a player/vehicle/thing with health
var(Damage) float DamageSpeed ;                   //Minimum speed to deal damage
var(Damage) class<DamageType> HitDamageType ;     //Damage type associated with bCollisionDamage
var(Damage) float HitDamageScale ;                //Relative impact damage modifier
var(Damage) int initialHealth ;                   //The starting health of an object
var(Damage) int damageAbsorbtionAmount ;          //Absorbs this much damage off each hit.
var(Damage) bool limitDamagingClass ;             //Only allows the constrained class to deal damage (and push it around)
var(Damage) class<Weapon> DamageConstraintClass ; //The constraint class (only allowed class to damage it)

var(Destruction) int explodeDamage ;                   //When dieing, how much damage does it deal to its fragments/people near it
var(Destruction) float explodeRadius ;                 //How close does something have to be to be damaged when dieing
var(Destruction) int explodeForce ;                    //How hard does it push fragments and other objects when dieing
var(Destruction) bool bDestroyable ;                   //Does health and damage apply to this object?
var(Destruction) sound DestructionSound ;              //Sound played when the object is destroyed
var(Destruction) byte DestructionVolume ;              //Volume of the destruction sound
var(Destruction) class <Emitter> DestroyedEffect ;      //The effect created when the object is destroyed
var(Destruction) vector EffectOffset ;                 //Where the effect is in relation to the object when destroyed
var(Destruction) bool bOrientDestructionEffect ;       //Does the destruction effect have the same orientation as the hit which killed it?
var(Destruction) float DestroyedMass ;                 //What the mass is when destroyed
var(Destruction) float DestroyedDamping ;              //What the damping is when destroyed
var(Destruction) float DestroyedFriction ;             //What the friction is when destroyed
var(Destruction) float DestroyedBuoyancy ;             //What the buoyancy is when destroyed
var(Destruction) float DestroyedRestitution ;          //What the restitution is when destroyed
var(Destruction) StaticMesh DestroyedStaticMesh ;      //The static mesh used for the object after it is destroyed (anything but none enables the 5 destroyed karma changing values)

var(Respawning) float PreRespawnEffectTime ;          //How long before the object respawns will the respawn effect play?
var(Respawning) bool bRespawnEffect ;                 //Will a respawn effect play?
var(Respawning) class<emitter> RespawnEffect ;        //The effect spawned when the object respawns
var(Respawning) bool bInactivityReset ;               //Will the object reset automatically if moved and then idle?
var(Respawning) float inactivityTimeout ;             //How long of idleness will trigger an inactivity Reset?
var(Respawning) sound RespawnSound ;                  //Sound played when the object is respawned
var(Respawning) byte RespawnVolume ;                  //Volume of the respawning sound
var(Respawning) float AutoRespawnTime ;               //How long after it is destroyed does it wait to respawn on its own (-1 means it dosen't respawn)

//Internal

var bool bPendingPunt, bPendingRespawn, bRespawnEffectPlayed, bInactive, bWaitTillMove, notifyPlayHit, bDead ;
var int StateCount, LastStateCount, Health ;
var actor Punter ;
var float PuntTimeout, respawnClock, inactiveClock, lastShoveTimer, replaySoundClock ;
var rotator startRotation, hitDirection ;
var float initialRest, initialFric, initialMass, initialDampLin, initialDampAng, initialBuoy ;
var StaticMesh initialMesh ;
var byte clientPlay ;                                 //0 for nothing, 1 for death emitters, 2 for respawn emitter

// shadow variables
var Projector Shadow;
var ShadowProjector PlayerShadow;
var globalconfig bool bBlobShadow;
var () bool bKActorShadows;

var vector DieVect;
var vector lasthitlocation;
var pawn lastinstigatedby,LastStander;
// What the server sends about its body. Position and rotation go as they are; a 'vector' goes over the net
// as whole numbers, so the velocities are scaled up to keep their fractions.
struct NetKActorState
{
	var KRBVec	Position;
	var Quat	Quaternion;
	var vector	LinVel;			// x10
	var vector	AngVel;			// x1000
	var int		stateCount;		// one more with every state packed
	var byte	Flags;			// NKF_Rest
	var byte	Moves;			// one more each time the server put the body somewhere in one go
};

const NKF_Rest = 1;				// the server's body has come to rest in this pose

var NetKActorState NKState;			// server to clients
var KRigidBodyState RemoteState;	// the state KUpdateState gives the body next (client: the server's last one)
var KRigidBodyState HomeState;		// server: where the map put the body
var bool bNewNKState;				// RemoteState is waiting for KUpdateState
var bool bSnapState;				// ... and is to be taken as it is, not blended in
var bool bWasAwake;					// server: the body was awake at the last tick
var bool bHaveHome;					// server: HomeState is set
var bool bHaveFloor;				// server: WorldFloorZ is set
var bool bServerRest;				// client: RemoteState is the pose the server's body rests in
var byte LastMoves;					// NKState.Moves of the last state taken (client) or packed (server)
var int RestTries;					// client: corrections since the server's body came to rest
var int StrayStates;				// client: states of a moving body in a row that found ours more than StrayDistance off
var float NextWorldCheck;			// server
var float WorldFloorZ;				// server: height of the lowest navigation point in the map
var() float MaxNetUpdateInterval;	// no longer used
var() float FallLimit;				// this far under the lowest place a player can stand, the body is brought back to its start
var() float SnapDistance;			// client: further than this from a state of a moving body, take the state as it is instead of blending
var() float StrayDistance;			// client: ... and also when further off than this for five states in a row

replication
{
	unreliable if(bNetDirty && Role == ROLE_Authority)
		NKState;
}

simulated function PostBeginPlay()
{
	local KarmaParams KP;

	Super.PostBeginPlay();

	// KarmaParams start out bClientOnly and bHighDetailOnly, and bClientOnly can't be changed in UnrealEd. With
	// either left on, the engine takes the body away on a dedicated server right after the actors have begun
	// play (and bHighDetailOnly does the same below high physics detail): the server then has a fixed lump
	// where its clients have a moving object.
	KP = KarmaParams(KParams);
	if (KP != None)
	{
		KP.bClientOnly = false;
		KP.bHighDetailOnly = false;
	}
}

simulated function PostNetBeginPlay()
{
    //Super.PostNetBeginPlay();
    // (no one looks at a dedicated server's shadows, and each projector is one more actor to tick)
    if ( bKActorShadows && Level.NetMode != NM_DedicatedServer )
    {

        PlayerShadow = Spawn(class'ShadowProjector',Self,'',Location);
        PlayerShadow.ShadowActor = self;
        PlayerShadow.bBlobShadow = bBlobShadow;
        PlayerShadow.LightDirection = Normal(vect(1,1,3));
        PlayerShadow.LightDistance = 450;
        PlayerShadow.MaxTraceDistance = 550;
        PlayerShadow.InitShadow();

        PlayerShadow.bShadowActive = true;
    }
}

simulated function Tick(float Delta)
{
	local bool bAwake;

	if (Role < ROLE_Authority)
	{
		Disable('Tick');			// a client works from PostNetReceive and Timer
		return;
	}
	if (Physics != PHYS_Karma)
		return;
	if (!bHaveHome)
	{
		KGetRigidBodyState(HomeState);
		HomeState.LinVel = KRBVecFromVector(vect(0,0,0));
		HomeState.AngVel = HomeState.LinVel;
		bHaveHome = true;
	}
	bAwake = KIsAwake();
	if (!bAwake && !bWasAwake)
		return;						// at rest, and its resting pose has gone out

	if ((!bAwake || Level.TimeSeconds >= NextWorldCheck) && !bNewNKState)
	{
		NextWorldCheck = Level.TimeSeconds + 1.0;
		if (LeftTheWorld())
		{
			GoHome();
			return;
		}
	}
	if (Level.NetMode != NM_Standalone)
		PackState(bAwake);
	bWasAwake = bAwake;
}

// Hit hard enough, a light body goes through a floor and then falls for ever. True once it is below the zone's
// kill height, or FallLimit under both its own start and the lowest navigation point of the map.
function bool LeftTheWorld()
{
	local NavigationPoint N;

	if (Region.Zone != None && Location.Z < Region.Zone.KillZ)
		return true;
	if (Location.Z > HomeState.Position.Z - FallLimit)
		return false;
	if (!bHaveFloor)
	{
		WorldFloorZ = HomeState.Position.Z;
		for (N = Level.NavigationPointList; N != None; N = N.nextNavigationPoint)
			WorldFloorZ = FMin(WorldFloorZ, N.Location.Z);
		bHaveFloor = true;
	}
	return Location.Z < WorldFloorZ - FallLimit;
}

// Put the body back where the map had it.
function GoHome()
{
	Log(Name @ "left the world at" @ Location $ ": put back where it started");
	RemoteState = HomeState;
	bNewNKState = true;
	bSnapState = true;
	NKState.Moves++;
	KWake();
}

// Server: copy the body's state into NKState for the clients.
function PackState(bool bAwake)
{
	local KRigidBodyState RB;
	local NetKActorState S;
	local KarmaParams KP;
	local float Speed;

	if (bNewNKState)
		return;						// a move of our own hasn't reached the body yet

	KGetRigidBodyState(RB);
	S.Position = RB.Position;
	S.Quaternion = RB.Quaternion;
	S.Moves = NKState.Moves;
	if (bAwake)
	{
		S.LinVel.X = 10.0 * RB.LinVel.X;
		S.LinVel.Y = 10.0 * RB.LinVel.Y;
		S.LinVel.Z = 10.0 * RB.LinVel.Z;
		S.AngVel.X = 1000.0 * RB.AngVel.X;
		S.AngVel.Y = 1000.0 * RB.AngVel.Y;
		S.AngVel.Z = 1000.0 * RB.AngVel.Z;

		// A hit sets the speed at once and the engine only brings it down to the body's limits after the next
		// step. Don't hand clients a speed the server's own body won't keep.
		KP = KarmaParams(KParams);
		if (KP != None)
		{
			Speed = VSize(S.LinVel);
			if (Speed > 10.0 * KP.KMaxSpeed)
				S.LinVel *= 10.0 * KP.KMaxSpeed / Speed;
			Speed = VSize(S.AngVel);
			if (Speed > 1000.0 * KP.KMaxAngularSpeed)
				S.AngVel *= 1000.0 * KP.KMaxAngularSpeed / Speed;
		}

		// Awake but going nowhere (a body that trembles instead of going to sleep): nothing worth sending.
		if (S.Moves == LastMoves && VSize(S.LinVel) < 20.0 && VSize(S.AngVel) < 50.0
			&& Abs(RB.Position.X - NKState.Position.X) < 0.25 && Abs(RB.Position.Y - NKState.Position.Y) < 0.25
			&& Abs(RB.Position.Z - NKState.Position.Z) < 0.25
			&& Abs(RB.Quaternion.X * NKState.Quaternion.X + RB.Quaternion.Y * NKState.Quaternion.Y
				+ RB.Quaternion.Z * NKState.Quaternion.Z + RB.Quaternion.W * NKState.Quaternion.W) > 0.99999)
			return;
	}
	else
		S.Flags = NKF_Rest;
	LastMoves = S.Moves;
	S.stateCount = NKState.stateCount + 1;

	// Assigning the variable as a whole is what marks the actor as changed for replication. Setting the members
	// of NKState one at a time does not, and then nothing is sent after the first packet of a channel.
	NKState = S;
}

// Client: a new state from the server.
simulated event PostNetReceive()
{
	local int Turned;
	local float Err;

	if (NKState.stateCount == LastStateCount)
		return;
	LastStateCount = NKState.stateCount;

	RemoteState.Position = NKState.Position;
	RemoteState.Quaternion = NKState.Quaternion;
	// W isn't sent: it is worked out from X, Y and Z on arrival, and comes out as not-a-number when rounding
	// has left those a hair over 1 in all (a body turned half way round). The engine would refuse the state.
	if (RemoteState.Quaternion.W != RemoteState.Quaternion.W)
		RemoteState.Quaternion.W = 0.0;
	RemoteState.LinVel.X = 0.1 * NKState.LinVel.X;
	RemoteState.LinVel.Y = 0.1 * NKState.LinVel.Y;
	RemoteState.LinVel.Z = 0.1 * NKState.LinVel.Z;
	RemoteState.AngVel.X = 0.001 * NKState.AngVel.X;
	RemoteState.AngVel.Y = 0.001 * NKState.AngVel.Y;
	RemoteState.AngVel.Z = 0.001 * NKState.AngVel.Z;

	bServerRest = (NKState.Flags & NKF_Rest) != 0;
	bSnapState = (NKState.Moves != LastMoves);
	LastMoves = NKState.Moves;
	if (bServerRest)
	{
		// A resting pose is taken as it is. (Blending works by giving the body a speed towards the pose: that
		// cannot lift a copy that fell off something back up, it only makes it hop.)
		bSnapState = true;
		RestTries = 0;
		StrayStates = 0;
		SetTimer(0.3, true);
	}
	else
	{
		// Moving: let the engine blend small errors away, but don't leave a copy that has gone astray to it.
		// Blending gives the body a speed towards the state, which gravity beats: a copy that missed the thing
		// the server's body landed on, or went through a floor, stays down. (The engine itself only sets a
		// state directly beyond some 220 uu.) So: far off, or a little off for several states running.
		Err = PoseError(RemoteState, Turned);
		if (Err > StrayDistance)
			StrayStates++;
		else
			StrayStates = 0;
		if (Err > SnapDistance || StrayStates >= 5)
		{
			bSnapState = true;
			StrayStates = 0;
		}
		SetTimer(0.0, false);
	}

	bNewNKState = true;
	// A sleeping body isn't stepped, but physKarma still asks KUpdateState and wakes it for the new state.
	KWake();
}

// How far our body is from a state, in uu. Turned is set when it is rotated more than a degree or two off it.
simulated function float PoseError(KRigidBodyState Want, out int Turned)
{
	local KRigidBodyState RB;
	local float Dot;

	KGetRigidBodyState(RB);
	Dot = RB.Quaternion.X * Want.Quaternion.X + RB.Quaternion.Y * Want.Quaternion.Y
		+ RB.Quaternion.Z * Want.Quaternion.Z + RB.Quaternion.W * Want.Quaternion.W;
	Turned = 0;
	if (1.0 - Abs(Dot) > 0.0001)
		Turned = 1;
	return VSize(KRBVecToVector(RB.Position) - KRBVecToVector(Want.Position));
}

// Client: while the server's body is at rest, keep ours on the server's resting pose. A client simulates its
// own copy, and with no more states coming nothing else would bring a copy that drifted off back.
simulated function Timer()
{
	local float Err;
	local int Turned;

	if (Role == ROLE_Authority || !bServerRest || Physics != PHYS_Karma)
	{
		SetTimer(0.0, false);
		return;
	}
	if (bNewNKState)
		return;						// the last correction hasn't reached the body yet

	Err = PoseError(RemoteState, Turned);
	if (Err < 2.0 && Turned == 0)
	{
		// On it. Once asleep, look again only now and then, in case something on this client moves it.
		if (!KIsAwake())
			SetTimer(2.0 + 2.0 * FRand(), true);
		return;
	}
	if (RestTries == 20)
		SetTimer(3.0 + 2.0 * FRand(), true);	// something here keeps pushing it off: stop fighting over it
	RestTries++;
	bSnapState = true;
	bNewNKState = true;
	KWake();
}

simulated event bool KUpdateState(out KRigidBodyState newState)
{
	if (!bNewNKState)
		return false;

	bNewNKState = false;
	newState = RemoteState;
	// physKarma reads this right after the call. On: small errors are blended away over a second or so, large
	// ones are set directly. Off: the state is set as it is.
	bSmoothKarmaStateUpdates = !bSnapState;
	bSnapState = false;
	return true;
}

// Only called for bodies with bDestroyOnWorldPenetrate. The body used to be hidden and switched off here, on the
// server alone: clients kept an object the server no longer had.
simulated event FellOutOfWorld(eKillZType KillType)
{
	if (Role == ROLE_Authority && bHaveHome)
		GoHome();
}

defaultproperties
{
	bBlockedPath=True
	moveDistance=50.000000
	RelativeImpactVolume=127
	bShoveable=True
	ShoveModifier=1.500000
	bEnableSpinProtection=True
	hitSoundRepeatModifier=1.000000
	DamageSpeed=10000000.000000
	HitDamageType=Class'GoodKarma.DamTypeBludgeon'
	HitDamageScale=1.000000
	initialHealth=200
	damageAbsorbtionAmount=25
	explodeRadius=15.000000
	bDestroyable=True
	DestructionVolume=200
	bOrientDestructionEffect=True
	DestroyedMass=0.500000
	DestroyedDamping=1.000000
	DestroyedFriction=0.700000
	DestroyedBuoyancy=0.300000
	DestroyedRestitution=0.100000
	PreRespawnEffectTime=1.000000
	inactivityTimeout=15.000000
	RespawnVolume=180
	AutoRespawnTime=-1.000000
	bRespawnEffectPlayed=True
	Health=200
	bKActorShadows=True
	MaxNetUpdateInterval=0.200000
	FallLimit=1000.000000
	SnapDistance=48.000000
	StrayDistance=12.000000
	StaticMesh=StaticMesh'GKStaticMeshes.basicShapes.BasicCube'
	bUseDynamicLights=True
	bDetailAttachment=True
	RemoteRole=ROLE_SimulatedProxy
	bHardAttach=True
	bNetNotify=True
	bSmoothKarmaStateUpdates=True
	NetUpdateFrequency=10.000000
	NetPriority=1.000000
	bSkipActorPropertyReplication=True
	bOnlyDirtyReplication=True
	Begin Object Class=KarmaParams Name=KarmaParams0
		bHighDetailOnly=False
		bClientOnly=False
		bKDoubleTickRate=True
		KFriction=0.500000
		KRestitution=0.200000
		KImpactThreshold=1.000000
	End Object
	KParams=KarmaParams'GoodKarma.NetKActor.KarmaParams0'

}
