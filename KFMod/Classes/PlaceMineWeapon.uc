//=============================================================================
// Mine Placeable Inventory class
//=============================================================================
class PlaceMineWeapon extends KFWeapon;

function float GetAIRating()
{
	local Bot B;


	B = Bot(Instigator.Controller);
	if ( (B == None) || (B.Enemy == None) )
		return AIRating;

	return (AIRating + 0.0003 * FClamp(1500 - VSize(B.Enemy.Location - Instigator.Location),0,1000));
}

function byte BestMode()
{
    return 0;
}

// Never select this without ammo
simulated function Weapon PrevWeapon(Weapon CurrentChoice, Weapon CurrentWeapon)
{
    if ( ammoAmount(0) > 0 )
    {
        if ( (CurrentChoice == None) )
        {
            if ( CurrentWeapon != self )
                CurrentChoice = self;
        }
        else if ( InventoryGroup == CurrentWeapon.InventoryGroup )
        {
            if ( (GroupOffset < CurrentWeapon.GroupOffset)
                && ((CurrentChoice.InventoryGroup != InventoryGroup) || (GroupOffset > CurrentChoice.GroupOffset)) )
                CurrentChoice = self;
		}
        else if ( InventoryGroup == CurrentChoice.InventoryGroup )
        {
            if ( GroupOffset > CurrentChoice.GroupOffset )
                CurrentChoice = self;
        }
        else if ( InventoryGroup > CurrentChoice.InventoryGroup )
        {
			if ( (InventoryGroup < CurrentWeapon.InventoryGroup)
                || (CurrentChoice.InventoryGroup > CurrentWeapon.InventoryGroup)
                || ( (CurrentChoice.InventoryGroup == CurrentWeapon.InventoryGroup) && (CurrentChoice.GroupOffset>CurrentWeapon.GroupOffset) ) )
                CurrentChoice = self;
        }
        else if ( (CurrentChoice.InventoryGroup > CurrentWeapon.InventoryGroup || ( (CurrentChoice.InventoryGroup == CurrentWeapon.InventoryGroup) && (CurrentChoice.GroupOffset>CurrentWeapon.GroupOffset) ))
                && (InventoryGroup < CurrentWeapon.InventoryGroup) )
            CurrentChoice = self;
    }

    if ( Inventory == none )
        return CurrentChoice;
    else
        return Inventory.PrevWeapon(CurrentChoice,CurrentWeapon);
}

// Never select this without ammo
simulated function Weapon NextWeapon(Weapon CurrentChoice, Weapon CurrentWeapon)
{
    if ( ammoAmount(0) > 0 )
    {
        if ( (CurrentChoice == None) )
        {
            if ( CurrentWeapon != self )
                CurrentChoice = self;
        }
        else if ( InventoryGroup == CurrentWeapon.InventoryGroup )
        {
            if ( (GroupOffset > CurrentWeapon.GroupOffset)
                && ((CurrentChoice.InventoryGroup != InventoryGroup) || (GroupOffset < CurrentChoice.GroupOffset)) )
                CurrentChoice = self;
        }
        else if ( InventoryGroup == CurrentChoice.InventoryGroup )
        {
			if ( GroupOffset < CurrentChoice.GroupOffset )
                CurrentChoice = self;
        }

        else if ( InventoryGroup < CurrentChoice.InventoryGroup )
        {
            if ( (InventoryGroup > CurrentWeapon.InventoryGroup)
                || (CurrentChoice.InventoryGroup < CurrentWeapon.InventoryGroup)
                || ( (CurrentChoice.InventoryGroup == CurrentWeapon.InventoryGroup) && (CurrentChoice.GroupOffset<CurrentWeapon.GroupOffset) ) )
                CurrentChoice = self;
        }
        else if ( (CurrentChoice.InventoryGroup < CurrentWeapon.InventoryGroup || (CurrentChoice.InventoryGroup == CurrentWeapon.InventoryGroup) && (CurrentChoice.GroupOffset<CurrentWeapon.GroupOffset))
                && (InventoryGroup > CurrentWeapon.InventoryGroup) )
            CurrentChoice = self;
    }

    if ( Inventory == none )
        return CurrentChoice;
    else
        return Inventory.NextWeapon(CurrentChoice,CurrentWeapon);
}

defaultproperties
{
	ClipCount=1
	ReloadAnimRate=1.000000
	FireModeClass(0)=Class'KFMod.PlaceMineFire'
	FireModeClass(1)=Class'KFMod.NoFire'
	PutDownAnim="PutDown"
	SelectSound=Sound'KFPlayerSound.getweaponout'
	AIRating=0.400000
	CurrentRating=0.400000
	bCanThrow=False
	OldCenteredOffsetY=0.000000
	OldPlayerViewOffset=(X=-8.000000,Y=5.000000,Z=-6.000000)
	OldSmallViewOffset=(X=4.000000,Y=11.000000,Z=-12.000000)
	OldPlayerViewPivot=(Pitch=400)
	OldCenteredRoll=3000
	Description="a mine. "
	EffectOffset=(X=100.000000,Y=25.000000,Z=-10.000000)
	DisplayFOV=55.000000
	Priority=5
	SmallViewOffset=(X=15.000000,Y=-50.000000,Z=-10.000000)
	CenteredOffsetY=-5.000000
	CenteredRoll=3000
	CenteredYaw=-1500
	GroupOffset=1
	PickupClass=Class'KFMod.PlaceMinePickup'
	PlayerViewOffset=(X=10.000000,Y=3.000000,Z=-5.000000)
	PlayerViewPivot=(Yaw=17884,Roll=2000)
	BobDamping=8.000000
	AttachmentClass=Class'KFMod.DeagleAttachment'
	IconCoords=(X1=250,Y1=110,X2=330,Y2=145)
	ItemName="Press [FIRE] to drop"
	bUseDynamicLights=True
	Mesh=SkeletalMesh'KFWeaponModels.Mine'
	DrawScale=0.900000
	Skins(0)=Texture'KillingFloorWeapons.Deagle.ArmSkinNew'
	Skins(1)=Texture'KillingFloorWeapons.Deagle.HandSkinNew'
	TransientSoundVolume=1.000000
}
