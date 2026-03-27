//=============================================================================
// Chainsaw Inventory class
//=============================================================================
class Chainsaw extends KFMeleeGun;

function WeaponTick(float dt)
{
	local Actor Other;
	local Vector HitNormal, StartTrace, EndTrace, hitLocation ;
	local rotator Aim ;

	hitLocation = vect(0,0,0) ;

	if ( Instigator == None || Instigator.PlayerReplicationInfo == None)
		return;

	if(bCanHit)
	{
		if(THMax < level.TimeSeconds)
		{
			btryHit = false;
			HitObject = none;
			bCanHit = false;
		}
		else if((THMin <= level.TimeSeconds) || (THMax == THMin))
			btryHit = true;
		else bTryHit = false;

		if(bTryHit)
		{
			StartTrace = Instigator.Location;
			Aim = FireMode[0].AdjustAim(StartTrace, FireMode[0].AimError);
			EndTrace = StartTrace + MeleeWeaponRange * Vector(Aim);
			Other = Trace(HitLocation, HitNormal, EndTrace, StartTrace, true);

			if(HitObject == Other && HitObject != none)
				return ;


			if(Other == none)
			return;


			if (((Pawn(Other) != None) || (KActor(Other) != none) || (Other.bWorldGeometry) || (StaticMeshActor(Other) != none) || (Mover(Other) != none)) && (Other != Instigator) )
			{
				HitObject = Other;
				if((KActor(Other) != none))
				{
					HitLocation +=  vect(0,0,25);
					HitObject.TakeDamage(dmg, Instigator, HitLocation, (vector(Aim) + momOffset), hitDamType) ;
					Spawn(class'KFMeleeHitEffect',,, HitLocation, rotator(HitLocation - (Instigator.Location + Instigator.EyePosition())));
				}
				else if((Mover(Other) != none))
				{
					HitLocation +=  vect(0,0,25);
					HitObject.TakeDamage(dmg, Instigator, HitLocation, (vector(Aim) + momOffset), hitDamType) ;
					Spawn(class'KFMeleeHitEffect',,, HitLocation, rotator(HitLocation - (Instigator.Location + Instigator.EyePosition())));
				}
				else if((Other.bWorldGeometry))
				{
					HitLocation +=  vect(0,0,25);
					Spawn(class'KFMeleeHitEffect',,, HitLocation, rotator(HitLocation - (Instigator.Location + Instigator.EyePosition())));
				}
				if((StaticMeshActor(Other) != none))
				{
					HitLocation +=  vect(0,0,25);
					Spawn(class'KFMeleeHitEffect',,, HitLocation, rotator(HitLocation - (Instigator.Location + Instigator.EyePosition())));
				}
				else
				{
					HitLocation -=  vect(0,0,30);
					HitObject.TakeDamage(dmg, Instigator, HitLocation, (vector(Aim) + momOffset), hitDamType) ;
					playServerSound();
				}
			}
			if(THMax == THMin)
				bCanHit = false;
		}
	}
}

defaultproperties
{
     MeleeHitSounds(0)=Sound'KFPawnDamageSound.MeleeDamageSounds.axehitflesh'
     bDoCombos=True
     Weight=8.000000
     FireModeClass(0)=Class'KFMod.ChainsawFire'
     FireModeClass(1)=Class'KFMod.ChainsawAltFire'
     Description="A gas powered industrial strength chainsaw. "
     DisplayFOV=60.000000
     Priority=5
     SmallViewOffset=(X=5.000000,Y=14.000000,Z=-6.000000)
     CenteredOffsetY=-4.000000
     GroupOffset=4
     PickupClass=Class'KFMod.ChainsawPickup'
     PlayerViewOffset=(X=-7.000000,Y=8.000000,Z=0.000000)
     PlayerViewPivot=(Yaw=16884,Roll=200)
     BobDamping=6.000000
     AttachmentClass=Class'KFMod.ChainsawAttachment'
     IconCoords=(X1=169,Y1=39,X2=241,Y2=77)
     ItemName="Chainsaw"
     Mesh=SkeletalMesh'KFWeaponModels.Chainsaw'
     Skins(0)=Texture'KillingFloorWeapons.Deagle.ArmSkinNew'
     Skins(1)=Texture'KillingFloorWeapons.Deagle.HandSkinNew'
}
