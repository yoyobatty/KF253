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

simulated function PostNetBeginPlay()
{
	Super.PostNetBeginPlay();

	if ( Role == ROLE_Authority )
	{
		if ( Instigator != None )
			MakeNoise(0.3);
	}
	if ( Level.NetMode != NM_DedicatedServer )
		SpawnEffects();
}

simulated function SpawnEffects()
{
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
		
}

defaultproperties
{
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
}
