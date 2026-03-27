class KFWelderHitEffect extends Actor;

#exec OBJ LOAD FILE=KFMaterials.utx
#exec OBJ LOAD FILE=VMParticleTextures.utx
#exec OBJ LOAD FILE=VehicleFX.utx
#exec OBJ LOAD FILE=XGameShadersB.utx
#exec OBJ LOAD FILE=EmitterTextures.utx

var() class<KFHitEmitter> HitEffectClasses[11]; //Effects indexed by surface type.
var() class<KFBulletDecal> DecalClasses[11];

static function StaticPrecache(LevelInfo L)
{
	L.AddPrecacheMaterial(Texture'KFMaterials.pock0_t');
	L.AddPrecacheMaterial(Texture'KFMaterials.pock2_t');
	L.AddPrecacheMaterial(Texture'KFMaterials.pock4_t');
	L.AddPrecacheMaterial(Texture'KFMaterials.GlassMark1');
	L.AddPrecacheMaterial(Texture'KFMaterials.GlassMark2');
	L.AddPrecacheMaterial(Texture'KFMaterials.GlassMark3');
	L.AddPrecacheMaterial(Texture'KFMaterials.MetalMark1');
	L.AddPrecacheMaterial(Texture'KFMaterials.MetalMark2');
	L.AddPrecacheMaterial(Texture'KFMaterials.MetalMark3');
	L.AddPrecacheMaterial(Texture'KFMaterials.SnowMark1');
	L.AddPrecacheMaterial(Texture'KFMaterials.SnowMark2');
	L.AddPrecacheMaterial(Texture'KFMaterials.SnowMark3');
	L.AddPrecacheMaterial(Texture'KFMaterials.WoodMark1');
	L.AddPrecacheMaterial(Texture'KFMaterials.WoodMark2');
	L.AddPrecacheMaterial(Texture'KFMaterials.WoodMark3');

	L.AddPrecacheMaterial(Texture'KFMaterials.GlassChips');
	L.AddPrecacheMaterial(Texture'KFMaterials.WoodChips');
	L.AddPrecacheMaterial(Texture'KFMaterials.PlantBits');
	L.AddPrecacheMaterial(Texture'VMParticleTextures.DirtKICKGROUP.dirtKICKTEX');
	L.AddPrecacheMaterial(Texture'VMParticleTextures.DirtKICKGROUP.snowKICKTEX');
	L.AddPrecacheMaterial(Texture'VehicleFX.Particles.DustyCloud2');
	L.AddPrecacheMaterial(Texture'XGameShadersB.Blood.BloodJetc');
	L.AddPrecacheMaterial(Texture'AW-2004Particles.Energy.SparkHead');
	L.AddPrecacheMaterial(Texture'XEffects.EmitSmoke_t');
	L.AddPrecacheMaterial(Texture'EmitterTextures.MultiFrame.rockchunks02');
	L.AddPrecacheMaterial(Texture'EmitterTextures.MultiFrame.MistTexture');
}

simulated function PostBeginPlay()
{
	SpawnEffects();
}

simulated function SpawnEffects()
{
	local Material SurfaceMat;
	local int HitSurface;
	local Vector HitLocation, HitNormal;
	local rotator EffectDir;
	local Actor Other;

	Other = Trace(HitLocation, HitNormal, Location + vector(Rotation) * 32, Location - vector(Rotation) * 16, true,, SurfaceMat);

	EffectDir = rotator(MirrorVectorByNormal(vector(Rotation), HitNormal));

	if(Vehicle(Other) != None && Other.SurfaceType == 0)
		HitSurface = 3;
	else if(Other != None && !Other.IsA('LevelInfo') && Other.SurfaceType != 0)
		HitSurface = Other.SurfaceType;
	else if(SurfaceMat != None)
		HitSurface = SurfaceMat.SurfaceType;
	else
	{
		Destroy();
		return;
	}

	if(PhysicsVolume.bWaterVolume)
		Spawn(class'pclImpactSmoke');
	else
		Spawn(HitEffectClasses[HitSurface],,,, EffectDir);

	if(Other != None && Other.bWorldGeometry && DecalClasses[HitSurface] != None)
		Spawn(DecalClasses[HitSurface]);
		


}

defaultproperties
{
     HitEffectClasses(0)=Class'KFMod.WelderHitEmitter'
     HitEffectClasses(1)=Class'KFMod.WelderHitEmitter'
     HitEffectClasses(2)=Class'KFMod.WelderHitEmitter'
     HitEffectClasses(3)=Class'KFMod.WelderHitEmitter'
     HitEffectClasses(4)=Class'KFMod.WelderHitEmitter'
     HitEffectClasses(5)=Class'KFMod.WelderHitEmitter'
     HitEffectClasses(6)=Class'KFMod.WelderHitEmitter'
     HitEffectClasses(7)=Class'KFMod.WelderHitEmitter'
     HitEffectClasses(8)=Class'KFMod.WelderHitEmitter'
     HitEffectClasses(9)=Class'KFMod.WelderHitEmitter'
     HitEffectClasses(10)=Class'KFMod.WelderHitEmitter'
     CullDistance=7000.000000
     bHidden=True
     LifeSpan=10.000000
}
