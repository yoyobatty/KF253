//=============================================================================
// KFPawn Enemy version

// Note : This guy is going to be used as Sergeant Masterson, the final boss in the SP game.
//=============================================================================
class KFHumanPawnEnemy extends KFHumanPawn;

simulated function PostNetBeginPlay()
{

}

defaultproperties
{
     BreathingSound=None
     bCanDodgeDoubleJump=True
     ShieldStrengthMax=500.000000
     MaxMultiJump=2
     RequiredEquipment(0)="KFmod.BullpupDM"
     bCanDoubleJump=True
     bCanWallDodge=True
     GroundSpeed=270.000000
     WaterSpeed=250.000000
     AirSpeed=250.000000
     JumpZ=400.000000
     MaxFallSpeed=6000.000000
     BaseEyeHeight=50.000000
     EyeHeight=50.000000
     HealthMax=1300.000000
     Health=1300
     ControllerClass=Class'KFMod.KFFriendSoldierController'
     Mesh=SkeletalMesh'KFSoldiers.Masterson'
     Skins(0)=Texture'KFCharacters.Masterson'
}
