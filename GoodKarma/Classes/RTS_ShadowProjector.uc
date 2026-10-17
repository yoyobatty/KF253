class RTS_ShadowProjector extends Projector
		NotPlaceable;

var float FadeSpeed;
var ShadowBitmapMaterial ShadowTexture;
var byte MaxDarkness;
var byte CurrentDarkness;
var bool bFadeOut;
var bool bDisabled;
var Actor ShadowLight;
var float ProjDist, DistMod;
var bool bIsDynamicLight;

var float NextTraceUpdate;

function Tick(float dt);

function PostBeginPlay()
{
        Disable('Tick');
}

function DisableShadow()
{
	DetachProjector();
	
	if (ShadowTexture != None)
	{
		ShadowTexture.Dirty = false;
		ShadowTexture.ShadowActor = None;
	}

	CurrentDarkness = 0;
	bDisabled = true;
}

function InitializeFor(RTS_ShadowController ShadowController)
{
	if ( ShadowController.Owner != None )
	{
		SetOwner(ShadowController.Owner);
		switch (ShadowController.ShadowResolution)
		{
			case Medium:
				ShadowTexture = ShadowBitmapMaterial(Level.ObjectPool.AllocateObject(class'RTS_ShadowBitmapMedium'));
				break;

			case High:
				ShadowTexture = ShadowBitmapMaterial(Level.ObjectPool.AllocateObject(class'RTS_ShadowBitmapHigh'));
				break;

			Default:
				ShadowTexture = ShadowBitmapMaterial(Level.ObjectPool.AllocateObject(class'ShadowBitmapMaterial'));
		}

		ProjTexture = ShadowTexture;
		
		if (ShadowTexture != None)
		{
			ShadowTexture.Invalid = false;
			ShadowTexture.ShadowActor = Owner;
			ShadowTexture.bBlobShadow = false;
			ShadowTexture.CullDistance = CullDistance;
		}
		else
		{
			Log(Name$".InitShadow: Failed to allocate texture");
			Destroy();
		}
	}
	else
	{
		Log(Name$".InitShadow: No actor");
		Destroy();
	}
}

function UpdateShadow(float dt, int LN, RTS_ShadowController ShadowController)
{
	local Actor NewLight;
	local vector Diff, DiffNorm, DiffNHead, OwnerLoc, HeadLoc, ProjLoc, HeadProjLoc, ProjNorm, LightLoc, AdjustedLoc;
	local float Dist, HeadProjDist, ProjDistMod, LightDistance;
	local rotator LightRotation;

	DetachProjector(true);
	bDisabled = false;

	if ( ShadowTexture == None )
		return;

	if ( ShadowTexture.Invalid )
	{
		Destroy();
		return;
	}

	ShadowTexture.ShadowActor = Owner;
	NewLight = ShadowController.ShadowLights[LN];

	if ( CurrentDarkness == MaxDarkness && bFadeOut )
	{
		ShadowLight = NewLight;
		bFadeOut = false;
	}

	if ( ShadowLight != None )
	{
		if ( ShadowLight != NewLight )
		{
			if ( NewLight != None && NewLight.bDynamicLight ) //Dynamic lights don't fade in, but pop up
			{
				bIsDynamicLight = true;
				bFadeOut = false;
				ShadowLight = NewLight;
			}
			else if ( !bFadeOut )
			{
				if ( !bIsDynamicLight ) //Dynamic lights don't fade out, just disappear immediately
				{
					MaxDarkness = 30; //Make shadows fade in/out faster, 30 is invisible enough
					bFadeOut = true;
				}
				else
				{
					bIsDynamicLight = false;
					ShadowLight = NewLight;
				}
			}
		}
	}
	else
	{
		ShadowLight = NewLight;
		bFadeOut = false;
		CurrentDarkness = 30;

		if ( ShadowLight != None ) //First light on spawn is a dynamic light
			bIsDynamicLight = ShadowLight.bDynamicLight;
	}

	if ( ShadowLight == None )
		return;

	OwnerLoc = Owner.Location;
	HeadLoc = ShadowController.HeadLocation;

	if ( ShadowLight.LightEffect != LE_SunLight )
	{
		if ( xWeaponAttachment(ShadowLight) != None )
			LightLoc = xWeaponAttachment(ShadowLight).GetTipLocation();
		else
			LightLoc = ShadowLight.Location;

		Diff = LightLoc - OwnerLoc; //Direction from center of player, used to set location/rotation of shadow
		Dist = VSize(Diff);

		if ( !bFadeOut )
		{
			if ( !ShadowLight.bCorona )
				MaxDarkness = 125 + 60*FMax(1.0 - Dist/(ShadowLight.LightRadius*32.0), 0.0) + 70*FMin(ShadowLight.LightBrightness/100.0, 1.0);
			else if ( Light(ShadowLight) != None )
				MaxDarkness = 125 + 60*FMax(1.0 - Dist/ShadowLight.LightRadius, 0.0) + 70*FMin(Light(ShadowLight).MaxCoronaSize/100.0, 1.0);
		}
	}
	else
	{
		LightLoc = OwnerLoc - 200*Normal(Vector(ShadowLight.Rotation)); //Add a fake sun at OwnerLoc-200*SunRot, new vector ShadowLocation
		Diff = LightLoc - OwnerLoc;
		Dist = VSize(Diff);

		if ( !bFadeOut )
			MaxDarkness = 225;
	}

	DiffNorm = Normal(Diff);
	LightRotation = Rotator(-DiffNorm);

	if ( !(LightLoc.Z < HeadLoc.Z && LightLoc.Z > OwnerLoc.Z) ) //Use DiffNorm as direction, when light is in between head and center. Projector is placed at the center and thus we can get invalid projection distances for the head.
		DiffNHead = Normal(LightLoc - HeadLoc);
	else
		DiffNHead = DiffNorm;

	//Avoid that shadow detachs from feet when walking
	if ( LightRotation.Pitch > -2000 && (Owner.Physics == PHYS_Walking || Owner.Physics == PHYS_Spider) ) //Special handling for lights that are low to avoid shadows from detaching from feet.
	{
		LightRotation.Pitch = -2000;
		LightLoc = OwnerLoc - Dist*Vector(LightRotation); //New light location at same distance
		Diff = LightLoc - OwnerLoc; //Recalculate for adjusted light position
		DiffNorm = Normal(Diff);

		if ( !(LightLoc.Z < HeadLoc.Z && LightLoc.Z > OwnerLoc.Z) )
			DiffNHead = Normal(LightLoc - HeadLoc);
		else
			DiffNHead = DiffNorm;
	}

	if (ShadowLight.LightEffect == LE_Sunlight)
		LightDistance = ShadowController.MaxLightDistance;
	else
		LightDistance = FMax(Dist, 150.0); //150 is min. distance, otherwise shadow grows too large

	//Don't update this every run, as Traces are slow
	if ( Level.TimeSeconds >= NextTraceUpdate ) //ToDo, ProjDist has to be restored every cycle -> declare ProjDistMod
	{
		Trace(ProjLoc, ProjNorm, OwnerLoc-DiffNorm*CullDistance, OwnerLoc);
		Trace(HeadProjLoc, ProjNorm, HeadLoc-DiffNHead*CullDistance, HeadLoc);
		ProjDist = VSize(ProjLoc - OwnerLoc);
		HeadProjDist = VSize(HeadProjLoc - OwnerLoc); //Using OwnerLoc instead of HeadLoc as ShadowProjector is at the same position
		DistMod = VSize(ProjLoc-HeadProjLoc); //Simple way to avoid shadows being cut on edges

		if ( HeadProjDist > ProjDist ) //Use Head projection distance as reference.
			ProjDist = HeadProjDist;

		NextTraceUpdate = Level.TimeSeconds + 0.1; //10 Times a second seems enough
	}

	ProjDistMod = ProjDist+DistMod;

	FOV = Atan(ShadowController.PawnRadius + 160, LightDistance) * 57.2958; //57.2958 ~ 180/PI
	if ( FOV > 40 ) //Greater distances for larger FOVs
		ProjDistMod *= 0.0075*FOV + 0.7; //Bonus range: 1.0->1.3

	MaxTraceDistance = Clamp(ProjDistMod, 120, 500);

	AdjustedLoc = OwnerLoc;
	if ( ProjDist < 50 && abs(LightRotation.Pitch) > 4096 && abs(LightRotation.Pitch) < 24576 ) //Avoid shadow getting cut when close to a wall
		AdjustedLoc += Min(40-0.8*ProjDist, 20)*DiffNorm; //Set behind to avoid shadow clipping on very close walls

	SetDrawScale(LightDistance * tan(FOV * 0.008727) / (0.5 * ShadowTexture.USize)); //0.008727 ~ PI/360
	SetLocation(AdjustedLoc);
	SetRotation(LightRotation);
	ShadowTexture.LightDirection = DiffNorm;
	ShadowTexture.LightDistance = LightDistance;
	ShadowTexture.LightFOV = FOV;

	if ( CurrentDarkness < MaxDarkness ) // Fade in to
	{
		if ( !bIsDynamicLight ) //Dynamic lights have to pop up
			CurrentDarkness = Min(CurrentDarkness + FadeSpeed*dt, MaxDarkness);
		else
			CurrentDarkness = MaxDarkness;
	}
	else if ( CurrentDarkness > MaxDarkness ) //Fade out to
	{
		if ( !bIsDynamicLight )
			CurrentDarkness = Max(CurrentDarkness - FadeSpeed*dt, MaxDarkness);
		else
			CurrentDarkness = MaxDarkness;
	}

	ShadowTexture.ShadowDarkness = CurrentDarkness;
	ShadowTexture.Dirty = true;
	AttachProjector();
}

function Destroyed()
{
	if (ShadowTexture != None)
	{
		ShadowTexture.ShadowActor = None;
		
		if (!ShadowTexture.Invalid)
			Level.ObjectPool.FreeObject(ShadowTexture);

		ShadowTexture = None;
		ProjTexture = None;
	}

	Super.Destroyed();
}

defaultproperties
{
	FadeSpeed=7000.000000
	bProjectParticles=False
	bProjectActor=False
	bClipBSP=True
	bGradient=True
	bProjectOnAlpha=True
	bProjectOnParallelBSP=True
	bDynamicAttach=True
	bNoProjectOnOwner=True
	CullDistance=1200.000000
	bStatic=False
	bOwnerNoSee=True
}
