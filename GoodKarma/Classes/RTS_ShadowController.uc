class RTS_ShadowController extends ShadowProjector
		NotPlaceable;

var array<Actor> ShadowLights;
var array<Actor> StaticLights;
var array<Actor> DynamicLights;
var array<float> BestPriorities;
var array<Actor> SurroundingLights;

var array<RTS_ShadowProjector> Shadows;
var class<RTS_ShadowProjector> ShadowClass;

var byte MaxShadows;
var float MaxLightDistance;
var SunLight SunLightActor;
var float NextUpdateTime;
var bool bSunShadows;
var bool bDynamicShadows;
var bool bRagdollShadows;
var float PawnRadius;
var vector LastLocation;
var Vector HeadLocation;
var float NextTimer;

var enum EShadowResolution
{
	Low,
	Medium,
	High
}ShadowResolution;

var RealtimeShadowsMut RTSMutator;

function UpdateShadow();
function InitShadow();

function Initialize(optional RealtimeShadowsMut M)
{
	local Plane BoundingSphere;

	if ( M != None )
	{
		if ( Owner == None || M == None )
		{
			Destroy();
			return;
		}

		RTSMutator = M;
		StaticLights = RTSMutator.StaticLights;
		bSunShadows = RTSMutator.bSunShadows;
		bDynamicShadows = RTSMutator.bDynamicLightShadows;
		bRagdollShadows = RTSMutator.bRagdollShadows;
		ShadowResolution = EShadowResolution(Clamp(RTSMutator.ShadowResolution, 0, 2));
		MaxShadows = Clamp(RTSMutator.ShadowsPerPawn, 1, 3);

		BoundingSphere = Owner.GetRenderBoundingSphere();
		PawnRadius = BoundingSphere.W*2;

		Shadows.Insert(0, MaxShadows);
		ShadowLights.Insert(0, MaxShadows);
		BestPriorities.Insert(0, MaxShadows);

		NextTimer = 0.25;
		Timer();
	}
	else
	{
		log(Name$".Initialize: Realtime Shadows Mutator not found! Using max settings lol.");
		//Destroy();
		if ( Owner == None )
		{
			Destroy();
			return;
		}

		//StaticLights = False;
		bSunShadows = True;
		bDynamicShadows = True;
		bRagdollShadows = True;
		ShadowResolution = High;
		MaxShadows = 3;

		BoundingSphere = Owner.GetRenderBoundingSphere();
		PawnRadius = BoundingSphere.W*2;

		Shadows.Insert(0, MaxShadows);
		ShadowLights.Insert(0, MaxShadows);
		BestPriorities.Insert(0, MaxShadows);

		NextTimer = 0.25;
		Timer();
	}
}

event Timer() //Fill lights
{
	local int i, j, k;
	local float Diff, PriorityCurrent;
	local bool bSunAdded;
	local RTS_ShadowProjector Swap;

	if ( Owner == None || ( !bRagdollShadows && Pawn(Owner).Health <= 0 ) ) //Destroy for dead/dying pawns
	{
		Destroy();
		return;
	}

	for ( i=0; i<MaxShadows; i++ ) //Clear ShadowLights and priorities
	{
		BestPriorities[i] = 0.0; //Clear priorities
		ShadowLights[i] = None;
	}

	SetLocation(Owner.Location); //Use Location from now on!

	if ( !bShadowActive )
		return;

	if ( LastLocation == vect(0,0,0) || VSize(Location - LastLocation) >= 250 ) //Get surrounding light, so we don't have to go through all lights every run, update every 250 length units
	{
		LastLocation = Location;
		SurroundingLights.Remove(0, SurroundingLights.Length);

		for ( i=StaticLights.Length-1; i>=0; i-- )
		{
			Diff = VSize(StaticLights[i].Location - Location);
			if ( Diff < MaxLightDistance + 250 )
			{
				SurroundingLights[k] = StaticLights[i];
				k++;
			}
			else if ( Diff < MaxLightDistance && Diff > (Owner.CollisionRadius*0.5) && FastTrace(StaticLights[i].Location, Location) ) //Same as below, do this here directly to save some iterations.
			{
				PriorityCurrent = LightPriority(StaticLights[i], Diff);

				for ( j=0; j<MaxShadows; j++ )
				{
					if ( PriorityCurrent > BestPriorities[j] )
					{
						for ( k=MaxShadows-1; k>j; k-- )
						{
							BestPriorities[k] = BestPriorities[k-1];
							ShadowLights[k] = ShadowLights[k-1];
						}

						BestPriorities[j] = PriorityCurrent;
						ShadowLights[j] = StaticLights[i];
						break;
					}
				}
			}
		}
	}
	else
	{
		for ( i=SurroundingLights.Length-1; i>=0; i-- ) //Find all possible lights around us, in order to get the highest priorized of them
		{
			Diff = VSize(SurroundingLights[i].Location - Location);
			if ( Diff < MaxLightDistance && Diff > (Owner.CollisionRadius*0.5) && FastTrace(SurroundingLights[i].Location, Location) )
			{
				PriorityCurrent = LightPriority(SurroundingLights[i], Diff);

				for ( j=0; j<MaxShadows; j++ )
				{
					if ( PriorityCurrent > BestPriorities[j] )
					{
						for ( k=MaxShadows-1; k>j; k-- )
						{
							BestPriorities[k] = BestPriorities[k-1];
							ShadowLights[k] = ShadowLights[k-1];
						}

						BestPriorities[j] = PriorityCurrent;
						ShadowLights[j] = SurroundingLights[i];
						break;
					}
				}
			}
		}
	}

	if ( bDynamicShadows ) //Find dynamic lights around us
	{
		DynamicLights = RTSMutator.DynamicLights;
		for ( i=DynamicLights.Length-1; i>=0; i-- )
		{
			if ( DynamicLights[i] == None ) //Some might have been destroyed since the last update in the mutator.
				continue;

			Diff = VSize(DynamicLights[i].Location - Location);
			if ( Diff < MaxLightDistance && DynamicLights[i].LightRadius >= (Diff*0.01) && Diff > (Owner.CollisionRadius*0.5) && FastTrace(DynamicLights[i].Location, Location) )
			{
				PriorityCurrent = LightPriority(DynamicLights[i], Diff);

				for ( j=0; j<MaxShadows; j++ )
				{
					if ( PriorityCurrent > BestPriorities[j] )
					{
						for ( k=MaxShadows-1; k>j; k-- )
						{
							BestPriorities[k] = BestPriorities[k-1];
							ShadowLights[k] = ShadowLights[k-1];
						}

						BestPriorities[j] = PriorityCurrent;
						ShadowLights[j] = DynamicLights[i];
						break;
					}
				}
			}
		}
	}

	//We'll use the sunlight as the very lowest priority of lights
	for ( i=0; i<MaxShadows; i++ )
	{
		if ( bSunShadows && !bSunAdded )
		{
			if ( ShadowLights[i] == None )
			{
				ShadowLights[i] = CheckForSuns();
				bSunAdded = true;
			}
		}

		if ( Shadows[i] != None && ShadowLights[i] != None && ShadowLights[i] != Shadows[i].ShadowLight )
		{
			for ( j=0; j<MaxShadows; j++ ) //Adjust shadow order to avoid redrawing of shadows whose order has changed.
			{
				if ( Shadows[j] != None && ShadowLights[i] == Shadows[j].ShadowLight ) //Order changed: abc -> bca
				{
					Swap = Shadows[i];
					Shadows[i] = Shadows[j];
					Shadows[j] = Swap;
				}
			}
		}
	}

	SetTimer(NextTimer, false);
}

function float LightPriority(Actor Light, float Distance) //Function for determining the priority of a light
{
	local float Priority;

	if ( !Light.bCorona )
		Priority = Light.LightBrightness*100/Distance;
	else if ( Light(Light) != None )
		Priority = Light(Light).MaxCoronaSize*120/Distance;
	else
		return 0.0;

	if ( Distance < 0.1 * MaxLightDistance ) //Extra bonus for close lights
		Priority *= 1.3;

	if ( Light.bDynamicLight ) //Prefer dynamic lights
		Priority *= 1.5;
	
	return Priority;
}

function Actor CheckForSuns() //Find a sun, dont use sun location as indicator, but rotation
{
	local int i, j;
	local Actor Traced;
	local Vector Loc, Norm;

	for ( i=RTSMutator.ZoneSuns.Length-1; i>=0; i-- )
	{
		if ( Owner.Region.Zone == RTSMutator.ZoneSuns[i].Zone )
		{
			Traced = Trace(Loc, Norm, Location-32768*RTSMutator.ZoneSuns[i].DirNorm, Location);

			if ( Traced == None || (LevelInfo(Traced) != None && VSize(Loc-Location) > 1024) )
				return RTSMutator.ZoneSuns[i].Sun;

			return None;
		}
	}

	for ( i=RTSMutator.SkySuns.Length-1; i>=0; i-- )
	{
		for ( j=RTSMutator.SkySuns[i].Zones.Length-1; j>=0; j-- )
		{
			if ( Owner.Region.Zone == RTSMutator.SkySuns[i].Zones[j] )
			{
				Traced = Trace(Loc, Norm, Location-32768*RTSMutator.SkySuns[i].DirNorm, Location);

				if ( Traced == None || (LevelInfo(Traced) != None && VSize(Loc-Location) > 1024) )
					return RTSMutator.SkySuns[i].Sun;

				return None;
			}
		}
	}

	return None;
}

event Tick(float deltaTime)
{
	if ( Level.TimeSeconds >= NextUpdateTime )
        {
		if ( bDynamicShadows )
		{
			if ( RTSMutator.bDynLightsDetected && NextTimer > 0.1  )
			{
				NextTimer = 0.1;
				Timer();
			}
			else
				NextTimer = 0.25;
		}

		UpdateShadows(deltaTime);

		if ( Level.TimeDilation == Level.Default.TimeDilation )
			NextUpdateTime = Level.TimeSeconds + 0.04;  //Save performance, limit to ~24fps, depending on deltatime
		else
			NextUpdateTime = FMax(0.04*Level.TimeDilation, 0.1);
        }
}

function UpdateShadows(float dt)
{
	local int i;
	local bool bSetInactive;

	bSetInactive = (Owner == None || Owner.bHidden || (Level.TimeSeconds - Owner.LastRenderTime >= 3) );
	HeadLocation = Owner.GetBoneCoords(Pawn(Owner).HeadBone).Origin;

	for ( i=0; i<MaxShadows; i++ )
	{
		if ( bShadowActive && !bSetInactive )
		{
			if ( Shadows[i] != None )
			{
				if ( ShadowLights[i] == None )
				{
					//Update each shadow until it has faded out
					if ( Shadows[i].CurrentDarkness > 30 )
						Shadows[i].UpdateShadow(dt, i, self);
				}
				else
					Shadows[i].UpdateShadow(dt, i, self);
			}
			else
			{
				Shadows[i] = Spawn(ShadowClass, Owner,, Location);
				Shadows[i].InitializeFor(self);

				if ( Shadows[i] != None )
					Shadows[i].UpdateShadow(dt, i, self);
			}
		}
		else  //Disable the shadow attached to this slot
		{
			if ( Shadows[i] != None && !Shadows[i].bDisabled )
				Shadows[i].DisableShadow();
		}
	}
}

function Destroyed()
{
	local int i;

	if ( Shadows.Length > 0 )
	{
		for ( i=0; i<MaxShadows; i++ )
		{
			if ( Shadows[i] != None )
				Shadows[i].Destroy();
		}
	}
}

defaultproperties
{
	MaxLightDistance=1300.000000
	ShadowResolution=Medium
	FrameBufferBlendingOp=PB_None
	MaxTraceDistance=0
	bProjectBSP=False
	bProjectTerrain=False
	bProjectStaticMesh=False
	bProjectParticles=False
	DrawType=DT_None
	bDirectional=False
}
