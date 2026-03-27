//=============================================================================
// Dualies Inventory class
//=============================================================================
class DualMachinePistols extends KFWeapon;

var name altFlashBoneName;
var name altTPAnim;
var Actor altThirdPersonActor;
var name altWeaponAttach;


function byte BestMode()
{
    return 0;
}

function bool RecommendRangedAttack()
{
	return true;
}

//TODO: LONG ranged?
function bool RecommendLongRangedAttack()
{
	return false;
}

function float SuggestAttackStyle()
{
    return -0.7;
}

function AttachToPawn(Pawn P)
{
	local name BoneName;

	Super.AttachToPawn(P);

	if(altThirdPersonActor == None)
	{
		altThirdPersonActor = Spawn(AttachmentClass,Owner);
		InventoryAttachment(altThirdPersonActor).InitFor(self);
	}
	else altThirdPersonActor.NetUpdateTime = Level.TimeSeconds - 1;
	BoneName = P.GetOffhandBoneFor(self);
	if(BoneName == '')
	{
		altThirdPersonActor.SetLocation(P.Location);
		altThirdPersonActor.SetBase(P);
	}
	else P.AttachToBone(altThirdPersonActor,BoneName);

	altThirdPersonActor.SetRelativeRotation(rot(0,32768,0));
	altThirdPersonActor.SetRelativeLocation(vect(10,-5,-5));

	if(altThirdPersonActor != None)
		DualiesAttachment(altThirdPersonActor).bIsOffHand = true;
	if(altThirdPersonActor != None && ThirdPersonActor != None)
	{
		DualiesAttachment(altThirdPersonActor).brother = DualiesAttachment(ThirdPersonActor);
		DualiesAttachment(ThirdPersonActor).brother = DualiesAttachment(altThirdPersonActor);
		altThirdPersonActor.LinkMesh(DualiesAttachment(ThirdPersonActor).BrotherMesh);
	}
}

simulated function DetachFromPawn(Pawn P)
{
	Super.DetachFromPawn(P);
	if ( altThirdPersonActor != None )
	{
		altThirdPersonActor.Destroy();
		altThirdPersonActor = None;
	}
}

function Destroyed()
{
	Super.Destroyed();

	if( ThirdPersonActor!=None )
		ThirdPersonActor.Destroy();
	if( altThirdPersonActor!=None )
		altThirdPersonActor.Destroy();
}

simulated function vector GetEffectStart()
{
    local Vector X,Y,Z;

    // jjs - this function should actually never be called in third person views
    // any effect that needs a 3rdp weapon offset should figure it out itself

    // 1st person
    if (Instigator.IsFirstPerson())
    {
        if ( WeaponCentered() )
            return CenteredEffectStart();

        	GetViewAxes(X, Y, Z);

            if (GetFireMode(0).FireAnim != 'FireLeft')
            	return GetBoneCoords('tip').Origin;
            else
               	return GetBoneCoords('tip01').Origin;
    }
    // 3rd person
    else
    {
        return (Instigator.Location +
            Instigator.EyeHeight*Vect(0,0,0.5) +
            Vector(Instigator.Rotation) * 40.0);
    }
}

defaultproperties
{
     altFlashBoneName="tip"
     altTPAnim="DualiesAttackLeft"
     altWeaponAttach="Bone_weapon2"
     ClipCount=80
     ReloadRate=3.500000
     ReloadAnim="Reload"
     ReloadAnimRate=1.000000
     FlashBoneName="tip01"
     Weight=4.000000
     bTorchEnabled=True
     UpKick=400
     FireModeClass(0)=Class'KFMod.DualMachinePistolsFire'
     FireModeClass(1)=Class'KFMod.SingleALTFire'
     PutDownAnim="PutDown"
     SelectSound=Sound'KFPlayerSound.getweaponout'
     AIRating=0.900000
     CurrentRating=0.900000
     bShowChargingBar=True
     OldCenteredOffsetY=0.000000
     OldPlayerViewOffset=(X=-8.000000,Y=5.000000,Z=-6.000000)
     OldSmallViewOffset=(X=4.000000,Y=11.000000,Z=-12.000000)
     OldPlayerViewPivot=(Pitch=400)
     OldCenteredRoll=3000
     Description="A pair of custom 9mm pistols. What they lack in stopping power, they compensate for with a quick refire."
     EffectOffset=(X=100.000000,Y=25.000000,Z=-10.000000)
     DisplayFOV=80.000000
     Priority=4
     SmallViewOffset=(X=15.000000,Y=19.500000,Z=-10.000000)
     CenteredOffsetY=0.000000
     CenteredRoll=3000
     CenteredYaw=-1500
     InventoryGroup=2
     GroupOffset=2
     PickupClass=Class'KFMod.DualMachinePistolsPickup'
     PlayerViewOffset=(X=4.000000,Y=11.500000,Z=-6.000000)
     PlayerViewPivot=(Pitch=400)
     BobDamping=4.000000
     AttachmentClass=Class'KFMod.DualiesAttachment'
     IconCoords=(X1=229,Y1=258,X2=296,Y2=307)
     ItemName="Dual Machine Pistols"
     Mesh=SkeletalMesh'KFWeaponModels.Dualies'
     DrawScale=0.900000
     TransientSoundVolume=1.000000
}
