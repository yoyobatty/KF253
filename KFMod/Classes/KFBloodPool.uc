//=============================================================================
// KFBloodPool
// Blood pooling under a fresh body (KFMonster.PlayDying): after the body has come to rest, a dark stain under its
// middle that spreads slowly to its full size, and stays. Not under a burnt one. KFX's own splat textures; a few at a
// time at most.
//=============================================================================
class KFBloodPool extends Projector;

#exec OBJ LOAD FILE=KFX.utx

var() float		StartDelay, GrowTime, StartScale, FullScale, StepEvery;
var() int		MostPools;
var() array<Texture>	Stains;
var float		Age, NextStep;
var bool		bLaid;
var vector		Spot;

simulated function PostBeginPlay()
{
	local KFBloodPool P;
	local int n;

	foreach DynamicActors(class'KFBloodPool', P)
		n++;
	if ( n > MostPools || Level.NetMode == NM_DedicatedServer )
	{
		Destroy();
		return;
	}
	ProjTexture = Stains[Rand(Stains.Length)];
	// (not attached yet: Projector's own PostBeginPlay would lay it where it was made)
}

simulated function Tick( float DT )
{
	local KFMonster M;
	local float K;

	Age += DT;
	M = KFMonster(Owner);
	if ( !bLaid )
	{
		if ( Age < StartDelay )
			return;
		if ( M == None || M.bDeleteMe || M.bGibbed || M.CharLevel >= 0.5 || !FindFloor(M) )
		{
			Destroy();
			return;
		}
		bLaid = true;
		NextStep = Age;
	}
	if ( Age < NextStep )
		return;
	NextStep = Age + StepEvery;
	K = FMin((Age - StartDelay) / GrowTime, 1.0);
	DetachProjector();
	SetDrawScale(StartScale + (FullScale - StartScale) * Sqrt(K));
	AttachProjector();
	if ( K >= 1.0 )
		Disable('Tick');
}

// The floor under the body's middle
simulated function bool FindFloor( KFMonster M )
{
	local vector From, HL, HN;
	local rotator R;

	From = M.GetBoneCoords('Bip01 Pelvis').Origin + vect(0,0,10);
	if ( Trace(HL, HN, From - vect(0,0,140), From, false) == None || HN.Z < 0.7 )
		return false;
	R = rotator(-HN);
	R.Roll = Rand(65536);
	SetLocation(HL + HN * 24);
	SetRotation(R);
	FullScale *= FClamp(M.CollisionRadius / 26.0, 0.8, 1.8);
	return true;
}

// Laid on the world only, never on a physics prop (see NetKActor.ShedDecal)
simulated function AttachProjector(optional float FadeInTime)
{
	Super.AttachProjector(FadeInTime);
	class'NetKActor'.static.ShedDecal(self);
}

defaultproperties
{
     StartDelay=1.400000
     GrowTime=9.000000
     StartScale=0.120000
     FullScale=0.420000
     StepEvery=0.400000
     MostPools=14
     Stains(0)=Texture'KFX.BloodSplat1'
     Stains(1)=Texture'KFX.BloodSplat2'
     Stains(2)=Texture'KFX.BloodSplat3'
     ProjTexture=Texture'KFX.BloodSplat1'
     FOV=1
     MaxTraceDistance=60
     bProjectActor=False
     bProjectParticles=False
     bClipBSP=True
     bClipStaticMesh=True
     GradientTexture=Texture'Engine.GRADIENT_Clip'
     CullDistance=5000.000000
     bStatic=False
     bGameRelevant=True
     DrawScale=0.120000
     LifeSpan=90.000000
     RemoteRole=ROLE_None
}
