// Weld Fire //
class WeldFire extends KFMeleeFire;

<<<<<<< HEAD
var KFDoorMover LastHitActor;
=======
var Actor LastHitActor;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

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

<<<<<<< HEAD

=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
simulated Function Timer()
{
	local Actor HitActor;
	local vector StartTrace, EndTrace, HitLocation, HitNormal,AdjustedLocation;
	local rotator PointRot;
	local int MyDamage;

	If( !KFWeapon(Weapon).bNoHit )
	{
		MyDamage = damageConst + Rand(MaxAdditionalDamage);
<<<<<<< HEAD
		if( KFPawn(Instigator)!=None )
=======
		if( KFPawn(Instigator)!=None && KFPawn(Instigator).GetVeteran()!=None )
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
			MyDamage*=KFPawn(Instigator).GetVeteran().Static.GetVeldSpeedModifier();
		PointRot = Instigator.GetViewRotation();
		StartTrace = Instigator.Location + Instigator.EyePosition();
		if( AIController(Instigator.Controller)!=None && Instigator.Controller.Target!=None )
		{
			EndTrace = StartTrace + vector(PointRot)*weaponRange;
			HitActor = Trace( HitLocation, HitNormal, EndTrace, StartTrace, true);
			if( HitActor==None )
			{
				EndTrace = Instigator.Controller.Target.Location;
				HitActor = Trace( HitLocation, HitNormal, EndTrace, StartTrace, true);
			}
			if( HitActor==None )
				HitLocation = Instigator.Controller.Target.Location;
			HitActor = Instigator.Controller.Target;
		}
		else
		{
			EndTrace = StartTrace + vector(PointRot)*weaponRange;
			HitActor = Trace( HitLocation, HitNormal, EndTrace, StartTrace, true);
		}

<<<<<<< HEAD
		LastHitActor = KFDoorMover(HitActor);
=======
		LastHitActor = HitActor;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

		if( LastHitActor!=none && Level.NetMode!=NM_Client )
		{
			AdjustedLocation = Hitlocation;
			AdjustedLocation.Z = (Hitlocation.Z - 0.15 * Instigator.collisionheight);
                        
			HitActor.TakeDamage(MyDamage, Instigator, HitLocation , vector(PointRot),hitDamageClass);
			Spawn(class'KFWelderHitEffect',,, AdjustedLocation, rotator(HitLocation - StartTrace));
		}
	}
}


function KFDoorMover GetDoor()
{
	local Actor A;
	local vector Dummy,End,Start;

	if( AIController(Instigator.Controller)!=None )
		Return KFDoorMover(Instigator.Controller.Target);
	Start = Instigator.Location+Instigator.EyePosition();
	End = Start+vector(Instigator.GetViewRotation())*weaponRange;
	A = Instigator.Trace(Dummy,Dummy,End,Start,True);
	Return KFDoorMover(A);
}

function bool AllowFire()
{
   local KFDoorMover WeldTarget;

<<<<<<< HEAD
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

=======
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
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

defaultproperties
{
<<<<<<< HEAD
	damageConst=10
	maxAdditionalDamage=0
	DamagedelayMin=0.100000
	DamagedelayMax=0.100000
	hitDamageClass=Class'KFMod.DamTypeWelder'
	TransientSoundVolume=100.000000
	FireRate=0.200000
	AmmoClass=Class'KFMod.WelderAmmo'
	AmmoPerFire=20
=======
	 WeaponRange=90.000000
     damageConst=10
     maxAdditionalDamage=0
     DamagedelayMin=0.100000
     DamagedelayMax=0.100000
     hitDamageClass=Class'KFMod.DamTypeWelder'
     UpSwingRot=(Pitch=0,Yaw=0)
     UpSwingTime=0.000000
     DownSwingRot=(Pitch=0,Yaw=0)
     DownSwingTime=0.000000
     TransientSoundVolume=100.000000
     FireRate=0.200000
     AmmoClass=Class'KFMod.WelderAmmo'
     AmmoPerFire=20
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
