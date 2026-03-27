//=============================================================================
// KF Soldier. This guy will follow you and engage enemy zombies.
//=============================================================================
class KFSoldierFriendly extends KFHumanPawn;

event PostBeginPlay()
{
    Super.PostBeginPlay();
    
    if ( (ControllerClass != None) && (Controller == None) )
        Controller = spawn(ControllerClass);
    if ( Controller != None )
    {
        Controller.Possess(self);
    }
}

defaultproperties
{
<<<<<<< HEAD
	RequiredEquipment(0)="none"
	RequiredEquipment(1)="none"
	RequiredEquipment(2)="KFMod.Shotgun"
	Mesh=SkeletalMesh'KFSoldiers.Powers'
	Skins(0)=Texture'KFCharacters.PowersSkin'
=======
     RequiredEquipment(0)="none"
     RequiredEquipment(1)="none"
     RequiredEquipment(2)="KFMod.Shotgun"
     Mesh=SkeletalMesh'KFSoldiers.Powers'
     Skins(0)=Texture'KFCharacters.PowersSkin'
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
