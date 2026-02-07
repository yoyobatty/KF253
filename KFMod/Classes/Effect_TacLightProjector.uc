//=============================================================================
// © 2003 Matt 'SquirrelZero' Farber
//=============================================================================
// "UT2k3 Ultimate Flashlight"
// I wrote this using _both_ a dynamic projector and a dynamic light, with the
// dynamic projector as the focal point and lightsource providing general 
// ambient illumination.  Either one by itself is pretty dull, but combine the 
// two and you've got yourself a really nice effect if done correctly.
//=============================================================================
class Effect_TacLightProjector extends DynamicProjector;

// add a light too, there seems to be a problem with the projector darkening terrain sometimes
var Effect_TacLightGlow TacLightGlow;
var Weapon ValidWeapon;

var Pawn LightPawn;
var bool bHasLight;
var WeaponAttachment AssignedAttach;

var byte LightRot[2];

replication
{
	// relevant variables needed by the client
	reliable if (Role == ROLE_Authority)
		LightPawn,bHasLight;
	unreliable if( Role == ROLE_Authority && !bNetOwner && bHasLight )
		LightRot;
}

// setup the pawn and controller variables, spawn the dynamic light
simulated function PostBeginPlay()
{
	SetCollision(True, False, False);
	if (Owner != None)
	{
		LightPawn = Pawn(Owner);
		ValidWeapon = LightPawn.Weapon;
	}
	if( Level.NetMode==NM_DedicatedServer )
		Return;
	if( TacLightGlow==None )
		TacLightGlow = spawn(class'Effect_TacLightGlow');
}
simulated function Destroyed()
{
	Super.Destroyed();
	if( TacLightGlow!=None )
		TacLightGlow.Destroy();
	if( KFWeaponAttachment(AssignedAttach)!=None )
	{
		KFWeaponAttachment(AssignedAttach).TacBeamGone();
		AssignedAttach = None;
	}
}

// updates the taclight projector and dynamic light positions
simulated function Tick(float DeltaTime)
{
	local vector StartTrace,EndTrace,X,HitLocation,HitNormal,AdjustedLocation;
	local float BeamLength;
	local rotator R;

	if( Level.NetMode==NM_DedicatedServer )
	{
		if( LightPawn==none || LightPawn.Weapon==None || LightPawn.Weapon!=ValidWeapon )
		{
			Destroy();
			return;
		}
		SetLocation(LightPawn.Location);
		if( !bHasLight || LightPawn.Controller==None )
			Return;
		LightRot[0] = LightPawn.Controller.Rotation.Yaw/256;
		LightRot[1] = LightPawn.Controller.Rotation.Pitch/256;
		Return;
	}
	if (TacLightGlow == None)
		return;

	if( Level.NetMode!=NM_Client && (LightPawn == none || LightPawn.Weapon==None || LightPawn.Weapon!=ValidWeapon) )
	{
		DetachProjector();
		Destroy();
		return;
	}

	// we're changing its location and rotation, so detach it
	DetachProjector();

	// fallback
	if( LightPawn==None || !bHasLight )
	{
		if (TacLightGlow != None)
			TacLightGlow.bDynamicLight = false;
		if( AssignedAttach!=None )
		{
			if( KFWeaponAttachment(AssignedAttach)!=None )
				KFWeaponAttachment(AssignedAttach).TacBeamGone();
			AssignedAttach = None;
		}
		return;
	}

	if( Level.NetMode!=NM_Client || PlayerController(LightPawn.Controller)!=None )
	{
		if( PlayerController(LightPawn.Controller)==None || PlayerController(LightPawn.Controller).bBehindView || LightPawn.Weapon==None )
		{
			if( XPawn(LightPawn)!=None && XPawn(LightPawn).WeaponAttachment!=None )
				StartTrace = XPawn(LightPawn).WeaponAttachment.Location;
			else StartTrace = LightPawn.Location+LightPawn.EyePosition();
		}
		else StartTrace = LightPawn.Location+LightPawn.CalcDrawOffset(LightPawn.Weapon);
		R = LightPawn.Controller.Rotation;
		if( Level.NetMode!=NM_Client )
		{
			LightRot[0] = R.Yaw/256;
			LightRot[1] = R.Pitch/256;
		}
		X = vector(R);
	}
	else
	{
		if( XPawn(LightPawn)!=None && XPawn(LightPawn).WeaponAttachment!=None && (Level.TimeSeconds-LightPawn.LastRenderTime)<1 )
			StartTrace = XPawn(LightPawn).WeaponAttachment.Location;
		else StartTrace = LightPawn.Location+LightPawn.EyePosition();
		R.Yaw = LightRot[0]*256;
		R.Pitch = LightRot[1]*256;
		X = vector(R);
	}

	// not too far out, we don't want a flashlight that can shine across the map
	EndTrace = StartTrace + 1800*X;

	if( Trace(HitLocation,HitNormal,EndTrace,StartTrace,true)==None )
		HitLocation = EndTrace;

	// find out how far the first hit was
	BeamLength = VSize(StartTrace-HitLocation);

	// this makes a neat focus effect when you get close to a wall
	if (BeamLength <= 90)
		SetDrawScale(FMax(0.02,(BeamLength/90))*Default.DrawScale);
	else SetDrawScale(Default.DrawScale);
	SetLocation(StartTrace);
	SetRotation(R);

	// reattach it
	AttachProjector();

	// turns the dynamic light on if it's off
	if (!TacLightGlow.bDynamicLight)
		TacLightGlow.bDynamicLight = true;

	// again, neat focus effect up close, starts earlier than the dynamic projector
	if (BeamLength <= 100)
	{
		TacLightGlow.LightBrightness = TacLightGlow.Default.LightBrightness * (1.0 + (1.0 - (BeamLength/100)));
		TaclightGlow.LightRadius = TacLightGlow.Default.LightRadius * FMax(0.3,(BeamLength/100));
	} // else we scale its radius and brightness depending on distance from the material
	else
	{
		// fades the lightsource out as it moves farther away
		if (BeamLength >= 1300)
			TacLightGlow.LightBrightness = TacLightGlow.Default.LightBrightness * ((1800-BeamLength)/500);
		else // else normal brightness
			TacLightGlow.LightBrightness = TacLightGlow.Default.LightBrightness;

		// this makes the light act more like a spotlight, resizing depending on distance
		TacLightGlow.LightRadius = TacLightGlow.Default.LightRadius + (4.5 * (BeamLength/1900));
	}
	AdjustedLocation = HitLocation;
	AdjustedLocation.Z += 0.5 * LightPawn.CollisionHeight;
	TacLightGlow.SetLocation(AdjustedLocation - 50*X );
	if( XPawn(LightPawn)!=None && XPawn(LightPawn).WeaponAttachment!=AssignedAttach )
	{
		if( KFWeaponAttachment(AssignedAttach)!=None )
			KFWeaponAttachment(AssignedAttach).TacBeamGone();
		AssignedAttach = XPawn(LightPawn).WeaponAttachment;
	}
	if( KFWeaponAttachment(AssignedAttach)!=None )
		KFWeaponAttachment(AssignedAttach).UpdateTacBeam(BeamLength);
}

defaultproperties
{
	MaterialBlendingOp=PB_Modulate
	FrameBufferBlendingOp=PB_Add
	ProjTexture=Texture'KillingFloorWeapons.Dualies.LightCircle'
	FOV=1
	MaxTraceDistance=1600
	bClipBSP=True
	bProjectOnUnlit=True
	bGradient=True
	bProjectOnAlpha=True
	bProjectOnParallelBSP=True
	bNoProjectOnOwner=True
	DrawType=DT_None
	bLightChanged=True
	bHidden=False
	bSkipActorPropertyReplication=True
	RemoteRole=ROLE_SimulatedProxy
	DrawScale=0.610000
}
