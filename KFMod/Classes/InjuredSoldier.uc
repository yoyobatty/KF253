// Gavin, Injured soldier in KFS-01
class InjuredSoldier extends Decoration;

simulated function PostBeginPlay()
{
	if( Level.NetMode!=NM_DedicatedServer )
		LoopAnim('Idle');
}

defaultproperties
{
<<<<<<< HEAD
	bStatic=False
	bNoDelete=True
	bStasis=False
	RemoteRole=ROLE_None
	Mesh=SkeletalMesh'KFMapObjects.SoldierInjured'
=======
     bStatic=False
     bNoDelete=True
     bStasis=False
     RemoteRole=ROLE_None
     Mesh=SkeletalMesh'KFMapObjects.SoldierInjured'
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
