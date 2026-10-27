class KFHitEffect extends Effects;

#exec OBJ LOAD FILE=KFMaterials.utx
#exec OBJ LOAD FILE=VMParticleTextures.utx
#exec OBJ LOAD FILE=VehicleFX.utx
#exec OBJ LOAD FILE=XGameShadersB.utx
#exec OBJ LOAD FILE=EmitterTextures.utx

struct HitEffectData
{
	var	class<Projector>		HitDecal;
	var	class<Actor>		HitEffect;
};
var()	HitEffectData		HitEffects[11];
var() float		ImpactScale;	// how big a KFImpactEmitter it makes: a pellet's smaller, a Deagle's bigger
var float		CountShare;		// how much of that impact's particles it throws (KFHitEffectPellet: many at once)

simulated function PostNetBeginPlay()
{
	Super.PostNetBeginPlay();

	if ( Role == ROLE_Authority )
	{
		if ( Instigator != None )
			MakeNoise(0.3);
	}
	if ( Level.NetMode != NM_DedicatedServer )
	{
		SpawnEffects();
		// (a shot into the world: giblets lying where it struck)
		if ( Pawn(Owner) == None )
			class'KFGib'.static.Struck(self, Location, ImpactScale);
	}
}

// The surface it struck and the way that faces. Most spawners face it out of the surface, so it is traced into it;
// some face it along the shot, and are traced along that.
simulated function ESurfaceTypes FindSurface( out vector HitNormal )
{
	local vector HitLoc, N;
	local Material HitMat;
	local Actor A;

	A = Trace(HitLoc, N, Location - Vector(Rotation)*5, Location, false,, HitMat);
	if ( A == None )
		A = Trace(HitLoc, N, Location + Vector(Rotation)*5, Location, false,, HitMat);
	if ( A == None )
	{
		HitNormal = vector(Rotation);
		return EST_Default;
	}
	HitNormal = N;
	if ( !A.IsA('LevelInfo') && A.SurfaceType != EST_Default )
		return A.SurfaceType;
	if ( HitMat == None )
		return EST_Default;
	return ESurfaceTypes(HitMat.SurfaceType);
}

simulated function SpawnEffects()
{
	local ESurfaceTypes ST;
	local vector HitNormal;
	local Projector DecalActor;

	ST = FindSurface(HitNormal);

	// (an impact made after BW's throws its dust out of the surface, and is sized by this)
	if ( class<KFImpactEmitter>(HitEffects[ST].HitEffect) != None )
		Spawn(HitEffects[ST].HitEffect, self,, Location, rotator(HitNormal));
	else if (HitEffects[ST].HitEffect != None)
		Spawn(HitEffects[ST].HitEffect);
	
	if(KActor(Owner) != None)
	{
		if (HitEffects[ST].HitDecal != None)
			DecalActor = Spawn(HitEffects[ST].HitDecal,Owner,, Location, rotator(-HitNormal));
		if(DecalActor != None)
		{
			DecalActor.SetBase(Owner);
			DecalActor.bProjectBSP = false;
		}
		return;
	}

	//Level.Game.Broadcast(Self,"Surface type: "$ST);
	if (HitEffects[ST].HitDecal != None)
		Spawn(HitEffects[ST].HitDecal,self,, Location, rotator(-HitNormal));
		
}

defaultproperties
{
	HitEffects(0)=(HitDecal=class'KFMod.DefaultBulletDecal',HitEffect=class'KFMod.KFImpactStone')
	HitEffects(1)=(HitDecal=class'KFMod.DefaultBulletDecal',HitEffect=class'KFMod.KFImpactStone')
	HitEffects(2)=(HitDecal=class'KFMod.SnowBulletDecal',HitEffect=class'KFMod.KFImpactDirt')
	HitEffects(3)=(HitDecal=class'KFMod.MetalBulletDecal',HitEffect=class'KFMod.KFImpactMetal')
	HitEffects(4)=(HitDecal=class'KFMod.WoodBulletDecal',HitEffect=class'KFMod.KFImpactWood')
	HitEffects(5)=(HitDecal=class'KFMod.WoodBulletDecal',HitEffect=class'KFMod.KFImpactDirt')
	HitEffects(6)=(HitDecal=class'KFMod.DefaultBulletDecal',HitEffect=class'KFMod.FleshHitEmitter')       	
	HitEffects(7)=(HitDecal=class'KFMod.DefaultBulletDecal',HitEffect=class'KFMod.KFImpactSnow')
	HitEffects(8)=(HitDecal=class'KFMod.GlassBulletDecal',HitEffect=class'KFMod.KFImpactSnow')
	HitEffects(9)=(HitDecal=class'KFMod.SnowBulletDecal',HitEffect=class'KFMod.WaterHitEmitter')       	
	HitEffects(10)=(HitDecal=class'KFMod.GlassBulletDecal',HitEffect=class'KFMod.GlassHitEmitter')       
	ImpactScale=1.000000
	CountShare=1.000000
	DrawType=DT_None
	LifeSpan=0.500000
}
