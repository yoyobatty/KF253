<<<<<<< HEAD
class KFHitEffect extends Actor;
=======
class KFHitEffect extends Effects;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

#exec OBJ LOAD FILE=KFMaterials.utx
#exec OBJ LOAD FILE=VMParticleTextures.utx
#exec OBJ LOAD FILE=VehicleFX.utx
#exec OBJ LOAD FILE=XGameShadersB.utx
#exec OBJ LOAD FILE=EmitterTextures.utx

<<<<<<< HEAD
var() class <KFHitEmitter> HitEffectClasses[11]; //Effects indexed by surface type.
var() class <KFBulletDecal> DecalClasses[11];

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

simulated function PostNetBeginPlay()
{
	if( Level.NetMode!=NM_DedicatedServer )
=======
struct HitEffectData
{
	var	class<Projector>		HitDecal;
	var	class<Actor>		HitEffect;
};
var()	HitEffectData		HitEffects[11];

simulated function PostNetBeginPlay()
{
	Super.PostNetBeginPlay();

	if ( Role == ROLE_Authority )
	{
		if ( Instigator != None )
			MakeNoise(0.3);
	}
	if ( Level.NetMode != NM_DedicatedServer )
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		SpawnEffects();
}

simulated function SpawnEffects()
{
<<<<<<< HEAD
	local Material SurfaceMat;
	local int HitSurface;
	local Vector HitLocation, HitNormal,TDir;
	local rotator EffectDir;
	local Actor Other;

	if( Instigator==None )
		Return;
	TDir = Normal(Location-Instigator.Location);
	Other = Instigator.Trace(HitLocation, HitNormal, Location+TDir*32, Location-TDir*16,true,,SurfaceMat);
	
	if( Other==none || BlockingVolume(Other)!=None )
		return;

	EffectDir = rotator(HitNormal);

	if(Vehicle(Other) != None && Other.SurfaceType == 0)
		HitSurface = 3;
	else if(Other != None && Other!=Level && Other.SurfaceType != 0)
		HitSurface = Other.SurfaceType;
	else if(SurfaceMat != None)
		HitSurface = SurfaceMat.SurfaceType;

	if( Other.IsA('KFMonster') || Other.IsA('ExtendedZCollision') )
		HitSurface = 6;

	if(PhysicsVolume.bWaterVolume)
		Spawn(class'WaterSplash');
	else
		Spawn(HitEffectClasses[HitSurface],,,, EffectDir);

	// Don't need to try and spawn decalclasses if we have no decalclasses to spawn
	if(DecalClasses[HitSurface] != None)
		Spawn(DecalClasses[HitSurface]);
=======
	local ESurfaceTypes ST;
	local vector HitLoc, HitNormal;
	local Material HitMat;
	local Projector DecalActor;

	Trace(HitLoc, HitNormal, Location - Vector(Rotation)*5, Location, false,, HitMat);
	if (HitMat == None)
		ST = EST_Default;
	else
		ST = ESurfaceTypes(HitMat.SurfaceType);

    if (HitEffects[ST].HitEffect != None)
    	Spawn(HitEffects[ST].HitEffect);
	
	if(KActor(Owner) != None)
	{
		if (HitEffects[ST].HitDecal != None)
			DecalActor = Spawn(HitEffects[ST].HitDecal,Owner,, Location, rotator(-1 * vector(Rotation)));
		if(DecalActor != None)
		{
			DecalActor.SetBase(Owner);
			DecalActor.bProjectBSP = false;
		}
		return;
	}

	//Level.Game.Broadcast(Self,"Surface type: "$ST);
	if (HitEffects[ST].HitDecal != None)
		Spawn(HitEffects[ST].HitDecal,self,, Location, rotator(-1 * vector(Rotation)));
		
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

defaultproperties
{
<<<<<<< HEAD
	HitEffectClasses(0)=Class'KFMod.DirtHitEmitter'
	HitEffectClasses(1)=Class'KFMod.RockHitEmitter'
	HitEffectClasses(2)=Class'KFMod.DirtHitEmitter'
	HitEffectClasses(3)=Class'KFMod.MetalHitEmitter'
	HitEffectClasses(4)=Class'KFMod.WoodHitEmitter'
	HitEffectClasses(5)=Class'KFMod.PlantHitEmitter'
	HitEffectClasses(6)=Class'KFMod.FleshHitEmitter'
	HitEffectClasses(7)=Class'KFMod.SnowHitEmitter'
	HitEffectClasses(8)=Class'KFMod.SnowHitEmitter'
	HitEffectClasses(9)=Class'KFMod.WaterHitEmitter'
	HitEffectClasses(10)=Class'KFMod.GlassHitEmitter'
	DecalClasses(0)=Class'KFMod.DefaultBulletDecal'
	DecalClasses(1)=Class'KFMod.DefaultBulletDecal'
	DecalClasses(2)=Class'KFMod.SnowBulletDecal'
	DecalClasses(3)=Class'KFMod.MetalBulletDecal'
	DecalClasses(4)=Class'KFMod.WoodBulletDecal'
	DecalClasses(6)=Class'KFMod.WoodBulletDecal'
	DecalClasses(7)=Class'KFMod.GlassBulletDecal'
	DecalClasses(8)=Class'KFMod.SnowBulletDecal'
	DecalClasses(10)=Class'KFMod.GlassBulletDecal'
	DrawType=DT_None
	bNetTemporary=True
	bReplicateInstigator=True
	LifeSpan=1.000000
=======
	 HitEffects(0)=(HitDecal=class'KFMod.DefaultBulletDecal',HitEffect=class'KFMod.DirtHitEmitter')       	
	 HitEffects(1)=(HitDecal=class'KFMod.DefaultBulletDecal',HitEffect=class'KFMod.RockHitEmitter')      	
	 HitEffects(2)=(HitDecal=class'KFMod.SnowBulletDecal',HitEffect=class'KFMod.DirtHitEmitter')       	
	 HitEffects(3)=(HitDecal=class'KFMod.MetalBulletDecal',HitEffect=class'KFMod.MetalHitEmitter')      	
	 HitEffects(4)=(HitDecal=class'KFMod.WoodBulletDecal',HitEffect=class'KFMod.WoodHitEmitter')       	
	 HitEffects(5)=(HitDecal=class'KFMod.WoodBulletDecal',HitEffect=class'KFMod.PlantHitEmitter')      	
	 HitEffects(6)=(HitDecal=class'KFMod.DefaultBulletDecal',HitEffect=class'KFMod.FleshHitEmitter')       	
	 HitEffects(7)=(HitDecal=class'KFMod.DefaultBulletDecal',HitEffect=class'KFMod.SnowHitEmitter')       	
	 HitEffects(8)=(HitDecal=class'KFMod.GlassBulletDecal',HitEffect=class'KFMod.SnowHitEmitter')      	
	 HitEffects(9)=(HitDecal=class'KFMod.SnowBulletDecal',HitEffect=class'KFMod.WaterHitEmitter')       	
	 HitEffects(10)=(HitDecal=class'KFMod.GlassBulletDecal',HitEffect=class'KFMod.GlassHitEmitter')       
     DrawType=DT_None
     LifeSpan=0.500000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
