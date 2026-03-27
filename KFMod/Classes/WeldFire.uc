// Weld Fire //
class WeldFire extends KnifeFire;

var KFDoorMover LastHitActor;

function PlayFiring()
{
	if ( Weapon.Mesh != None )
	{
		if ( FireCount > 0 )
		{
			if ( Weapon.HasAnim(FireLoopAnim) )
				Weapon.PlayAnim(FireLoopAnim, FireLoopAnimRate, 0.0);
			else Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
		}
	}
	else Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
	Weapon.PlayOwnedSound(FireSound,SLOT_Interact,TransientSoundVolume,,TransientSoundRadius,Default.FireAnimRate/FireAnimRate,false);
	ClientPlayForceFeedback(FireForce);  // jdf
	FireCount++;
}


simulated Function Timer()
{
	local Actor HitActor;
	local vector StartTrace, EndTrace, HitLocation, HitNormal,AdjustedLocation;
	local rotator PointRot;
	local int MyDamage;

	If( !KFWeapon(Weapon).bNoHit )
	{
		MyDamage = damageConst + Rand(MaxAdditionalDamage);
		if( KFPawn(Instigator)!=None )
			MyDamage*=KFPawn(Instigator).GetVeteran().Static.GetVeldSpeedModifier();
		PointRot = Instigator.GetViewRotation();
		StartTrace = Instigator.Location + Instigator.EyePosition();
		EndTrace = StartTrace + vector(PointRot)*weaponRange;

		HitActor = Trace( HitLocation, HitNormal, EndTrace, StartTrace, true);

		LastHitActor = KFDoorMover(HitActor);


		if( LastHitActor!=none )
		{
			AdjustedLocation = Hitlocation;
                        AdjustedLocation.Z = (Hitlocation.Z - 0.15 * Instigator.collisionheight);
                        
                        HitActor.TakeDamage(MyDamage, Instigator, HitLocation , vector(PointRot),hitDamageClass) ;
			Spawn(class'KFWelderHitEffect',,, AdjustedLocation, rotator(HitLocation - (Instigator.Location + Instigator.EyePosition())));
		}
	}
}


function KFDoorMover GetDoor()
{
	local Actor A;
	local vector Dummy,End,Start;

	Start = Instigator.Location+Instigator.EyePosition();
	End = Start+vector(Instigator.GetViewRotation())*40;
	A = Instigator.Trace(Dummy,Dummy,End,Start,True,vect(20,20,20));
	Return KFDoorMover(A);
}

function bool AllowFire()
{
   local KFDoorMover WeldTarget;

        WeldTarget = GetDoor();

        // Can't use welder, if no door.
          if(WeldTarget == none)
         return false;
         
        // if(!WeldTarget.bClosed)
        //  return false;

          if(WeldTarget.bDisallowWeld)
          {
            if( PlayerController(Instigator.controller)!=None )
		PlayerController(Instigator.controller).ClientMessage("You cannot weld this door.", 'CriticalEvent');

            return false;
          }


    return Weapon.AmmoAmount(ThisModeNum) >= AmmoPerFire ;

}

defaultproperties
{
     damageConst=10
     maxAdditionalDamage=0
     hitDamageClass=Class'KFMod.DamTypeWelder'
     TransientSoundVolume=100.000000
     FireRate=0.200000
     AmmoClass=Class'KFMod.WelderAmmo'
     AmmoPerFire=20
}
