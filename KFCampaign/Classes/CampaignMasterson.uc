// Sergeant Masterson, the campaign's last fight (KFMod 1.0's KFHumanPawnEnemy), on KFMod254's soldier AI.
class CampaignMasterson extends KFHumanPawnEnemy;

// (1.0's mesh on KFMod254's animation set, as the squad's soldiers)
simulated function BeginPlay()
{
	LinkSkelAnim(MeshAnimation'KFSoldiers.BipedMaleA');
	Super.BeginPlay();
}

defaultproperties
{
	SoldierOrders=ORDER_Hunt
	AttitudeToPlayer=ATTITUDE_Hate
	AttitudeToSpecimen=ATTITUDE_Ignore
	Accuracy=0.500000
	WeaponType=Class'KFMod.BullpupDM'
	HealthMod=1300
	HealthMax=1300.000000
	Health=1300
	ShieldStrengthMax=500.000000
	BreathingSound=None
	bCanDodgeDoubleJump=True
	bCanDoubleJump=True
	bCanWallDodge=True
	MaxMultiJump=2
	GroundSpeed=270.000000
	JumpZ=400.000000
	Mesh=SkeletalMesh'KF10Soldiers.Masterson'
	Skins(0)=Texture'KF10Characters.Masterson'
	ControllerClass=Class'KFCampaign.CampaignSoldierAI'
}
