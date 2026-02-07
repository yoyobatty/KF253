// Spawns Trail on PostBeginPlay.

class ClotGibLeg extends KFGib;

simulated function PostBeginPlay()
{
   SpawnTrail();
}

defaultproperties
{
<<<<<<< HEAD
	GibGroupClass=Class'KFMod.KFHumanGibGroup'
	TrailClass=Class'KFMod.KFGibJet'
	DampenFactor=0.250000
	DrawType=DT_StaticMesh
	StaticMesh=StaticMesh'22Patch.ClotGibLeg'
	Skins(0)=Texture'22CharTex.GibletsSkin'
	bUnlit=False
	TransientSoundVolume=25.000000
	CollisionRadius=5.000000
	CollisionHeight=2.500000
=======
     GibGroupClass=Class'KFMod.KFHumanGibGroup'
     TrailClass=Class'KFMod.KFGibJet'
     DampenFactor=0.250000
     DrawType=DT_StaticMesh
     StaticMesh=StaticMesh'22Patch.ClotGibLeg'
     Skins(0)=Texture'22CharTex.GibletsSkin'
     bUnlit=False
     TransientSoundVolume=25.000000
     CollisionRadius=5.000000
     CollisionHeight=2.500000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
