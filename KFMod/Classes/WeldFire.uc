// Weld Fire //
class WeldFire extends KFMeleeFire;

var Actor LastHitActor;
var float NextMessageTime;

simulated function PlayFiring()
{
	// (the first tick of a press plays Fire: the else was the mesh check's, so it played nothing for 0.2 s)
	if ( Weapon.Mesh != None )
	{
		if ( FireCount > 0 && Weapon.HasAnim(FireLoopAnim) )
			Weapon.PlayAnim(FireLoopAnim, FireLoopAnimRate, 0.0);
		else Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
	}
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
		if( KFPawn(Instigator)!=None && KFPawn(Instigator).GetVeteran()!=None )
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

		LastHitActor = HitActor;

		if( LastHitActor!=none )
		{
			AdjustedLocation = Hitlocation;
			AdjustedLocation.Z = (Hitlocation.Z - 0.15 * Instigator.collisionheight);

			// (only a door: whoever stepped into the beam was burned too, a team-mate at full damage whatever the
			// friendly fire, as the game lets welder damage through)
			if( Level.NetMode!=NM_Client && KFDoorMover(HitActor)!=None )
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

simulated function bool AllowFire()
{
   local KFDoorMover WeldTarget;

	WeldTarget = GetDoor();

	// Can't use welder, if no door.
	if(WeldTarget == none)
		return false;

	if(WeldTarget.bDisallowWeld || KFElevatorTrigger(WeldTarget.MyTrigger)!=None)
	{
		WeldMessage("You cannot weld this door.");
		return false;
	}

	// (an open door took the fuel and the sparks and was never welded)
	if(!WeldTarget.bClosed)
	{
		WeldMessage("Close the door to weld it.");
		return false;
	}

	return Weapon.AmmoAmount(ThisModeNum) >= AmmoPerFire ;
}

// A line to the player holding the welder, on that player's own machine and not every time the button is tried
simulated function WeldMessage(string S)
{
	if( PlayerController(Instigator.Controller)==None || !Instigator.IsLocallyControlled() || Level.TimeSeconds<NextMessageTime )
		return;
	NextMessageTime = Level.TimeSeconds + 2.0;
	PlayerController(Instigator.Controller).ClientMessage(S, 'CriticalEvent');
}

defaultproperties
{
	//FireSound=Sound'PatchSounds.WelderFire'
	WeaponRange=90.000000
	damageConst=10
	maxAdditionalDamage=0
	DamagedelayMin=0.100000
	DamagedelayMax=0.100000
	hitDamageClass=Class'KFMod.DamTypeWelder'
	TransientSoundVolume=100.000000
	FireRate=0.200000
	AmmoClass=Class'KFMod.WelderAmmo'
	AmmoPerFire=20
}
