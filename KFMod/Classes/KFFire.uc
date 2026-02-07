class KFFire extends InstantFire
    abstract;

var float LastClickTime;
var float LastFireTime;

var() Name EmptyAnim;
var() float EmptyAnimRate;
var() Name EmptyFireAnim;
var() float EmptyFireAnimRate;
var bool Empty;
var () bool bFiringDoesntAffectMovement;

var int UpKick;

function float GetFireSpeed()
{
	if( KFPawn(Instigator)!=None )
		Return KFPawn(Instigator).GetVeteran().Static.GetFireSpeedMod(Weapon);
	Return 1;
}
simulated function bool AllowFire()
{
	if(KFWeapon(Weapon).bIsReloading)
		return false;
	if(KFPawn(Instigator).SecondaryItem!=none)
		return false;
	if(KFPawn(Instigator).bThrowingNade)
		return false;

	if(KFWeapon(Weapon).ClipLeft < 1)
	{
		if(Level.TimeSeconds - LastClickTime > FireRate)
		{
			Weapon.PlayOwnedSound(NoAmmoSound, SLOT_Interact, TransientSoundVolume,,,, false);
			LastClickTime = Level.TimeSeconds;
			if(Weapon.HasAnim(EmptyAnim))
				weapon.PlayAnim(EmptyAnim, EmptyAnimRate, 0.0);
		}
		if( AIController(Instigator.Controller)!=None )
			KFWeapon(Weapon).ReloadMeNow();
		return false;
	}
	LastClickTime = Level.TimeSeconds;
	return Super.AllowFire();
}

function StartBerserk();

function StopBerserk();

simulated function InitEffects()
{
    Super.InitEffects();
    if ( FlashEmitter != None )
        Weapon.AttachToBone(FlashEmitter, KFWeapon(Weapon).FlashBoneName);
}

function FlashMuzzleFlash()
{
    local rotator r;
    r.Roll = Rand(65536);


    Weapon.SetBoneRotation('Bone_Flash', r, 0, 1.f);


   //log(r);

    Super.FlashMuzzleFlash();
}

event ModeDoFire()
{
	local vector X,Y,Z;
	local rotator ViewRotation;
	local float Rec;

	if (!AllowFire())
		return;

	if( Instigator==None || Instigator.Controller==none )
		return; 

	if ( Level.TimeSeconds - LastFireTime > 0.5 )
		Spread = Default.Spread;
	else Spread = FMin(Spread+0.02,0.12);
	Rec = GetFireSpeed();
	FireRate = default.FireRate/Rec;
	FireAnimRate = default.FireAnimRate*Rec;
	ReloadAnimRate = default.ReloadAnimRate*Rec;
	Rec = 1;
	if( KFPawn(Instigator)!=None )
		Spread*=KFPawn(Instigator).GetVeteran().Static.ModifyRecoilSpread(Self,Rec);

	LastFireTime = Level.TimeSeconds;

	if (Weapon.Owner != none && AllowFire() && !bFiringDoesntAffectMovement)
	{
		if (FireRate > 0.25)
		{
			Weapon.Owner.Velocity.x *= 0.1;
			Weapon.Owner.Velocity.y *= 0.1;
		}
		else
		{
			Weapon.Owner.Velocity.x *= 0.5;
			Weapon.Owner.Velocity.y *= 0.5;
		} 
	}
    
	// UpKick
	if( PlayerController(Instigator.Controller)!=None && (Weapon.GetFireMode(0).bIsFiring || (DeagleAltFire(Weapon.GetFireMode(1))!=none
	 && DeagleAltFire(Weapon.GetFireMode(1)).bIsFiring)) && !PlayerController(Instigator.Controller).bBehindView )
	{
		UpKick = KFWeapon(Weapon).UpKick + (VSize(Weapon.Owner.Velocity)* 3) + (Instigator.HealthMax / Instigator.Health * 5);

		GetAxes(Instigator.Rotation,X,Y,Z);
		ViewRotation = Instigator.GetViewRotation();
		ViewRotation.Pitch += UpKick*Rec;
		// Update rotation.
		Instigator.Controller.SetRotation(ViewRotation);
		PlayerController(Instigator.Controller).UpdateRotation(1, 1);
	}  
	Super.ModeDoFire();
}

function float MaxRange()
{
	if (Instigator.Region.Zone.bDistanceFog)
		TraceRange = FClamp(Instigator.Region.Zone.DistanceFogEnd, 8000, default.TraceRange);
	else TraceRange = default.TraceRange;
	return TraceRange;
}

function DoTrace(Vector Start, Rotator Dir)
{
	local Vector X,Y,Z, End, HitLocation, HitNormal, ArcEnd;
	local Actor Other;

	MaxRange();

	Weapon.GetViewAxes(X, Y, Z);
	if ( Weapon.WeaponCentered() )
		ArcEnd = (Instigator.Location + Weapon.EffectOffset.X * X + 1.5 * Weapon.EffectOffset.Z * Z);
	else ArcEnd = (Instigator.Location + Instigator.CalcDrawOffset(Weapon) + Weapon.EffectOffset.X * X + Weapon.Hand * Weapon.EffectOffset.Y * Y +
		 Weapon.EffectOffset.Z * Z);

	X = Vector(Dir);
	End = Start + TraceRange * X;
	Other = Weapon.Trace(HitLocation, HitNormal, End, Start, true);

	if ( Other != None && (Other != Instigator) )
	{
		if ( !Other.bWorldGeometry )
			Other.TakeDamage(DamageMax, Instigator, HitLocation, Momentum*X, DamageType);
		else HitLocation = HitLocation + 2.0 * HitNormal;
	}
	else
	{
		HitLocation = End;
		HitNormal = Normal(Start - End);
	}
	if( KFWeaponAttachment(Weapon.ThirdPersonActor)!=None )
		KFWeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other,HitLocation,HitNormal);
	else if ( (HitNormal != Vect(0,0,0)) && (HitScanBlockingVolume(Other) == None) )
		Weapon.Spawn(class'KFHitEffect',,, HitLocation, rotator(-1 * HitNormal));
}

// Accuracy update based on pawn velocity

simulated function AccuracyUpdate(float Velocity)
{
  if (KFWeapon(Weapon).bSteadyAim)
   return;

 if (Pawn(Weapon.Owner).bIsCrouched)
  Velocity *= 0.6;

  AimError = ((default.AimError * 0.75) + (Velocity * 4 ));   //2
  Spread = ((default.Spread * 0.75) + (Velocity * 0.0010 ));   //.0005



}

defaultproperties
{
	EmptyAnim="Empty"
	EmptyAnimRate=1.000000
	EmptyFireAnim="EmptyFire"
	EmptyFireAnimRate=1.000000
}
