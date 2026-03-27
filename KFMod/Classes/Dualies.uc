//=============================================================================
// Dualies Inventory class
//=============================================================================
class Dualies extends KFWeapon;

var name altFlashBoneName;
var name altTPAnim;
var Actor altThirdPersonActor;
var name altWeaponAttach;

function bool HandlePickupQuery( pickup Item )
{
	if ( Item.InventoryType==Class'Single' )
		return True;
	Return Super.HandlePickupQuery(Item);
}

function float GetAIRating()
{
	local Bot B;

	B = Bot(Instigator.Controller);
	if ( (B == None) || (B.Enemy == None) )
		return AIRating;
	return (AIRating + 0.00092 * FMin(800 - VSize(B.Enemy.Location - Instigator.Location),650));
}

function byte BestMode()
{
    return 0;
}

function bool RecommendRangedAttack()
{
	return true;
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
    else
   		altThirdPersonActor.NetUpdateTime = Level.TimeSeconds - 1;
	BoneName = P.GetOffhandBoneFor(self);
	if(BoneName == '')
	{
	    altThirdPersonActor.SetLocation(P.Location);
	    altThirdPersonActor.SetBase(P);
	    //log("OFFHANDBONEBROKE!");
    } else
    {
        if(!P.AttachToBone(altThirdPersonActor,BoneName))
            //log("BONEATTACHBROKE!");
    }
    altThirdPersonActor.SetRelativeRotation(rot(0,32768,0));
    altThirdPersonActor.SetRelativeLocation(vect(10,-5,-5));

    if(altThirdPersonActor != None)
        DualiesAttachment(altThirdPersonActor).bIsOffHand = true;
    if(altThirdPersonActor != None && ThirdPersonActor != None)
    {
        DualiesAttachment(altThirdPersonActor).brother = DualiesAttachment(ThirdPersonActor);
        DualiesAttachment(ThirdPersonActor).brother = DualiesAttachment(altThirdPersonActor);
        DualiesAttachment(altThirdPersonActor).LinkMesh(DualiesAttachment(ThirdPersonActor).BrotherMesh);
    } else
        log("DUALIES ATTACHMENT(S) UNABLE TO SPAWN",'KFError');
}

/*function AttachToPawn(Pawn P)
{
	if ( bDualMode )
	{
		BoneName = P.GetOffHandBoneFor(self);
		if ( BoneName == '' )
			return;
		if ( OffhandActor == None )
		{
			OffhandActor = AssaultAttachment(Spawn(AttachmentClass,Owner));
			OffhandActor.InitFor(self);
		}
		P.AttachToBone(OffhandActor,BoneName);
		if ( OffhandActor.AttachmentBone == '' )
			OffhandActor.Destroy();
		else
		{
			ThirdPersonActor.SetDrawScale(0.3);
			OffhandActor.SetDrawScale(0.3);
			OffhandActor.bDualGun = true;
			OffhandActor.TwinGun = AssaultAttachment(ThirdPersonActor);
			if ( Mesh == OldMesh )
			{
			    OffhandActor.SetRelativeRotation(rot(0,32768,0));
			    OffhandActor.SetRelativeLocation(vect(20,-10,-5));
			}
			else
			{
			    OffhandActor.SetRelativeRotation(rot(0,0,32768));
			    OffhandActor.SetRelativeLocation(vect(40,-3,-7));
			}
			AssaultAttachment(ThirdPersonActor).TwinGun = OffhandActor;
		}
	}
}   */

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
            return (Instigator.Location +
                Instigator.CalcDrawOffset(self) +        // Main hand.
                SmallEffectOffset.X * X  +
                SmallEffectOffset.Y * Y * Hand +
                SmallEffectOffset.Z * Z);
            else
              if (GetFireMode(0).FireAnim == 'FireLeft')                  // Off hand firing.  Moves tracer to the left.
               return (Instigator.Location +
                Instigator.CalcDrawOffset(self) +
                SmallEffectOffset.X * X  +
                -(SmallEffectOffset.Y * Y * 4) +
                SmallEffectOffset.Z * Z);


    }
    // 3rd person
    else
    {
        return (Instigator.Location +
            Instigator.EyeHeight*Vect(0,0,0.5) +
            Vector(Instigator.Rotation) * 40.0);
    }
}
function GiveTo( pawn Other, optional Pickup Pickup )
{
	local Inventory I;

	For( I=Other.Inventory; I!=None; I=I.Inventory )
	{
		if( Single(I)!=None )
		{
			if( WeaponPickup(Pickup)!=None )
				WeaponPickup(Pickup).AmmoAmount[0]+=Weapon(I).AmmoAmount(0);
			I.Destroy();
			Break;
		}
	}
	Super.GiveTo(Other,Pickup);
}
function DropFrom(vector StartLocation)
{
	local int m;
	local Pickup Pickup;
	local Inventory I;

	if (!bCanThrow || !HasAmmo())
		return;

	ClientWeaponThrown();

	for (m = 0; m < NUM_FIRE_MODES; m++)
	{
		if (FireMode[m].bIsFiring)
			StopFire(m);
	}

	if ( Instigator != None )
		DetachFromPawn(Instigator);

	if( Instigator.Health>0 )
	{
		I = Spawn(Class'Single');
		I.GiveTo(Instigator);
		Ammo[0] = None;
		AmmoCharge[0] = 0;
	}
	Pickup = Spawn(PickupClass,,, StartLocation);
	if ( Pickup != None )
	{
		Pickup.InitDroppedPickupFor(self);
		Pickup.Velocity = Velocity;
		if (Instigator.Health > 0)
			WeaponPickup(Pickup).bThrown = true;
	}
	Destroy();
}

defaultproperties
{
     altFlashBoneName="tip"
     altTPAnim="DualiesAttackLeft"
     altWeaponAttach="Bone_weapon2"
     ClipCount=30
     ReloadRate=3.500000
     ReloadAnim="Reload"
     ReloadAnimRate=1.000000
     FlashBoneName="tip01"
     Weight=4.000000
     bTorchEnabled=True
     UpKick=400
     FireModeClass(0)=Class'KFMod.DualiesFire'
     FireModeClass(1)=Class'KFMod.SingleALTFire'
     PutDownAnim="PutDown"
     SelectSound=Sound'KFPlayerSound.getweaponout'
     AIRating=0.440000
     CurrentRating=0.440000
     bShowChargingBar=True
     OldCenteredOffsetY=0.000000
     OldPlayerViewOffset=(X=-8.000000,Y=5.000000,Z=-6.000000)
     OldSmallViewOffset=(X=4.000000,Y=11.000000,Z=-12.000000)
     OldPlayerViewPivot=(Pitch=400)
     OldCenteredRoll=3000
     Description="A pair of custom 9mm pistols. What they lack in stopping power, they compensate for with a quick refire."
     EffectOffset=(X=100.000000,Y=25.000000,Z=-10.000000)
     DisplayFOV=70.000000
     Priority=7
     SmallViewOffset=(X=15.000000,Y=19.000000,Z=-10.000000)
     CenteredOffsetY=0.000000
     CenteredRoll=3000
     CenteredYaw=-1500
     CustomCrosshair=-1
     CustomCrossHairColor=(B=0,G=0,R=0,A=0)
     CustomCrossHairTextureName=
     InventoryGroup=2
     GroupOffset=2
     PickupClass=Class'KFMod.DualiesPickup'
     PlayerViewOffset=(X=4.000000,Y=5.500000,Z=-6.000000)
     PlayerViewPivot=(Pitch=400)
     BobDamping=7.000000
     AttachmentClass=Class'KFMod.DualiesAttachment'
     IconCoords=(X1=229,Y1=258,X2=296,Y2=307)
     ItemName="Dual 9mms"
     Mesh=SkeletalMesh'KFWeaponModels.Dualies'
     DrawScale=0.900000
     TransientSoundVolume=1.000000
}
