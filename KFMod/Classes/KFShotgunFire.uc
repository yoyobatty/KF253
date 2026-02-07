class KFShotgunFire extends FlakFire;

var float LastClickTime;

var() Name EmptyAnim;
var() float EmptyAnimRate;

var() float MaxAccuracyBonus,CrouchedAccuracyBonus;  // Lower number = higher bonus .  1.0  =  no bonus  ,   0.1   =  90% bonus.

var() float EffectiveRange;

var() vector KickMomentum;
var() bool bFiringDoesntAffectMovement;

var() int UpKick;


function DoFireEffect()
{
	Super.DoFireEffect();

	if (!AllowFire())
		return;

	if (Instigator != None)
		Instigator.AddVelocity(KickMomentum >> Instigator.GetViewRotation());
}

function Recoil( float Multi )
{
	local Rotator NewRotation;
	local float NewPitch, NewYaw;

	if ( (Instigator != None) && Instigator.IsFirstPerson())
	{
		NewPitch = int(Frand()*755); NewYaw = int(Frand()*910);
		if (Frand() > 0.5)
			NewYaw *= -1;
		if (Frand() > 0.5)
			NewPitch *= -1;
		NewRotation = Instigator.GetViewRotation();
		NewRotation.Pitch += NewPitch*Multi;
		NewRotation.Yaw += NewYaw*Multi;
		Instigator.SetViewRotation(NewRotation);
	}
}

event ModeDoFire()
{
	local vector X,Y,Z;
	local rotator ViewRotation;
	local float Rec;

	if (!AllowFire())
		return;

	Spread = Default.Spread;
	Rec = 1;
	if( KFPawn(Instigator)!=None )
		Spread*=KFPawn(Instigator).GetVeteran().Static.ModifyRecoilSpread(Self,Rec);
	Recoil(Rec);

	if( !bFiringDoesntAffectMovement )
	{
		if (FireRate > 0.25)
		{
			Instigator.Velocity.x *= 0.1;
			Instigator.Velocity.y *= 0.1;
		}
		else
		{
			Instigator.Velocity.x *= 0.5;
			Instigator.Velocity.y *= 0.5;
		}
	}
    
	// UpKick
	if ( Weapon.GetFireMode(0).bIsFiring && PlayerController(Instigator.Controller)!=none && !PlayerController(Instigator.Controller).bBehindView )
	{
		UpKick = KFWeapon(Weapon).UpKick + (3 * VSize(Instigator.Velocity));
		
	      if( KFPawn(Instigator)!=None )
		UpKick*=KFPawn(Instigator).GetVeteran().Static.ModifyRecoilSpread(Self,Rec);

		GetAxes(Instigator.Rotation,X,Y,Z);
		ViewRotation = Instigator.Controller.GetViewRotation();

		ViewRotation.Pitch += UpKick*Rec;

		// Update rotation.
		Instigator.Controller.SetRotation(ViewRotation);
	}
	Super.ModeDoFire();
}

simulated function bool AllowFire()
{
	if( KFWeaponShotgun(Weapon).bIsReloading )
		return false;
        
	if( KFPawn(Instigator).bThrowingNade )
		return false;

	// Can't shoot guns off shotguns in mid air. No john woo shit here :P   This also prevents "shotgun jumping"
	if(KFPawn(Instigator).Physics == PHYS_Falling)
		return false;

	if( KFWeaponShotgun(Weapon).ClipLeft<1 )
	{
		if( Level.TimeSeconds - LastClickTime>FireRate )
		{
			Weapon.PlayOwnedSound(NoAmmoSound, SLOT_Interact, TransientSoundVolume,,,, false);
			LastClickTime = Level.TimeSeconds;
			if( Weapon.HasAnim(EmptyAnim) )
				weapon.PlayAnim(EmptyAnim, EmptyAnimRate, 0.0);
		}
		return false;
	}

	LastClickTime = Level.TimeSeconds;

	return Super.AllowFire();
}

// TODO: Maybe provide more control? So there's a 'if you're desparate, you MIGHT
//       do something at this range, but here's the recommended dist
//       Currently, bots won't fire past this recommendation no matter what
//       We'll see if desperation long-range fire is needed

//TODO: Also, check the effectiverange for all subclasses to make sure it is
//      appropriate
function float MaxRange()
{
	if (Instigator.Region.Zone.bDistanceFog)
		return FClamp(Instigator.Region.Zone.DistanceFogEnd, 1500, EffectiveRange);
	else return 1500;
}

// Accuracy update based on pawn velocity
simulated function AccuracyUpdate(float Velocity)
{
	if (KFWeapon(Weapon).bSteadyAim)
		return;

	if (Pawn(Weapon.Owner).bIsCrouched)
		Velocity *= CrouchedAccuracyBonus;

	Spread = ((default.Spread * MaxAccuracyBonus) + (Velocity * 10 ));

	ShakeRotMag.x = ((default.ShakeRotMag.x * MaxAccuracyBonus) + (Velocity * 5));     //5
	ShakeRotMag.y = ((default.ShakeRotMag.y * MaxAccuracyBonus) + (Velocity * 5 ));
	ShakeRotMag.z = ((default.ShakeRotMag.z * MaxAccuracyBonus) + (Velocity * 5 ));
}

function ShakeView()
{
	if (!AllowFire())
		return;
	Super.ShakeView();
}

defaultproperties
{
	MaxAccuracyBonus=0.750000
	CrouchedAccuracyBonus=0.600000
	EffectiveRange=700.000000
	ShakeRotMag=(X=50.000000,Y=600.000000,Z=50.000000)
	ShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
	ShakeOffsetMag=(X=10.000000,Y=10.000000,Z=10.000000)
	ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
	Spread=3000.000000
}
