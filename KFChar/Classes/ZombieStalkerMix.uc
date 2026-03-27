// Zombie Monster for KF Invasion gametype
class ZombieStalkerMix extends ZombieStalker;

simulated function BeginPlay()
{
	LinkSkelAnim(MeshAnimation'InfectedWhiteMale1');
	Super.BeginPlay();
}
simulated function UnCloakStalker()
{
	if( !bAshen && bCloaked )
	{
		Visibility = default.Visibility;
		bCloaked = false;
		if( Level.NetMode==NM_DedicatedServer )
			Return;
		Skins = Default.Skins;

		if (PlayerShadow != none)
			PlayerShadow.bShadowActive = true;
 
		bAcceptsProjectors = true;

		SetOverlayMaterial(Material'KFX.FBDecloakShader', 0.25, true);
	}
}
function RemoveHead()
{
	Super(KFMonster).RemoveHead();

	if (!bAshen)
		Skins = Default.Skins;
}

simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
	Super(KFMonster).PlayDying(DamageType,HitLoc);
	
	if(bUnlit)
		bUnlit=!bUnlit;

	if (!bAshen)
		Skins = Default.Skins;
}

defaultproperties
{
     Mesh=SkeletalMesh'KFCharacterModels.Bloat'
     DrawScale=0.800000
     Skins(0)=Texture'KFCharacters.BloatSkin'
     Skins(1)=Texture'KFCharacters.BloatCleaverSkin'
}
