// A soldier of the tactical squad (KFMod 1.0): stands his ground and shoots specimens with the gun the map gives him.
class KFHumanPawnEnemy2 extends KFHumanPawnEnemy;

// (1.0's mesh on KFMod254's animation set: the same skeleton, every 1.0 sequence and the weapon ones KFMod254's code plays)
simulated function BeginPlay()
{
	LinkSkelAnim(MeshAnimation'KFSoldiers.BipedMaleA');
	Super.BeginPlay();
}

function GiveDefaultWeapon()
{
	if( RequiredEquipment[0]!="" && RequiredEquipment[0]!="none" )
		WeaponType = class<Weapon>(DynamicLoadObject(RequiredEquipment[0], class'Class', true));
	if( WeaponType==None )
		WeaponType = default.WeaponType;
	Super.GiveDefaultWeapon();
}

defaultproperties
{
	SoldierOrders=ORDER_Guarding
	AttitudeToPlayer=ATTITUDE_Friendly
	bStationaryCombat=True
	WeaponType=Class'KFMod.BullpupDM'
	RequiredEquipment(0)=""
	RequiredEquipment(1)=""
	RequiredEquipment(2)=""
	RequiredEquipment(3)=""
	RequiredEquipment(4)=""
	HealthMod=100
	HealthMax=100.000000
	Health=100
	bCanCrouch=False
	bCanDoubleJump=False
	bCanWallDodge=False
	MaxMultiJump=0
	GroundSpeed=0.000000
	Mesh=SkeletalMesh'KF10Soldiers.Soldier'
	Skins(0)=FinalBlend'KF10Characters.GasMaskFinal'
	ControllerClass=Class'KFCampaign.CampaignSoldierAI'
}
