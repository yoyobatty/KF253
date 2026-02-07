//=============================================================================
// Winchester Fire
//=============================================================================
class WinchesterFire extends KFFire;

//var float HeadShotDamageMult;
//var class<DamageType> DamageTypeHeadShot;

var float ClickTime;

var float AimedAmount;

var name FireAimingAnim;



function Recoil()
{
    local Rotator NewRotation;
    local float NewPitch, NewYaw;

    if ( (Instigator != None) && Instigator.IsFirstPerson()){
    NewPitch = int(Frand()*300); NewYaw = int(Frand()*550);
    if (Frand() > 0.5) NewYaw *= -1;
    if (Frand() > 0.5) NewPitch *= -1;
    NewRotation = Instigator.GetViewRotation();
    NewRotation.Pitch += NewPitch;
    NewRotation.Yaw += NewYaw;
    Instigator.SetViewRotation(NewRotation);}
}

function AimingSpeed()
{
	FireAnim = FireAimingAnim;
}

function NormalSpeed()
{
	FireAnim = default.FireAnim;
}

event ModeDoFire()
{
	local vector X,Y,Z;
	local rotator ViewRotation;

	if (!AllowFire())
		return;

	if (MaxHoldTime > 0.0)
		HoldTime = FMin(HoldTime, MaxHoldTime);

	// server
	if (Weapon.Role == ROLE_Authority)
	{
		Weapon.ConsumeAmmo(ThisModeNum, Load);
		DoFireEffect();
		HoldTime = 0;   // if bot decides to stop firing, HoldTime must be reset first
		if ( (Instigator == None) || (Instigator.Controller == None) )
			return;

		if ( AIController(Instigator.Controller) != None )
			AIController(Instigator.Controller).WeaponFireAgain(BotRefireRate, true);

		Instigator.DeactivateSpawnProtection();
	}

	// client
	if (Instigator.IsLocallyControlled())
	{
		ShakeView();
		PlayFiring();
		FlashMuzzleFlash();
		StartMuzzleSmoke();
	}
	else // server
	{
		ServerPlayFiring();
	}

	Weapon.IncrementFlashCount(ThisModeNum);

	// set the next firing time. must be careful here so client and server do not get out of sync
	if (bFireOnRelease)
	{
		if (bIsFiring)
			NextFireTime += MaxHoldTime + FireRate;
		else NextFireTime = Level.TimeSeconds + FireRate;
	}
	else
	{
		NextFireTime += FireRate;
		NextFireTime = FMax(NextFireTime, Level.TimeSeconds);
	}

	Load = AmmoPerFire;
	HoldTime = 0;

	if (Instigator.PendingWeapon != Weapon && Instigator.PendingWeapon != None)
	{
		bIsFiring = false;
		Weapon.PutDown();
	}
    
	if (Weapon.Owner != none && AllowFire())
	{
		if (FireRate > 0.25)
			Weapon.Owner.Velocity *= 0.1;
		else Weapon.Owner.Velocity *= 0.5;
	}
    
	// UpKick
	if( Weapon.GetFireMode(0).bIsFiring && PlayerController(Instigator.Controller)!=None && !PlayerController(Instigator.Controller).bBehindView )
	{
		UpKick = KFWeapon(Weapon).UpKick + (3 * VSize(Instigator.Velocity));

		GetAxes(Weapon.Owner.Rotation,X,Y,Z);
		ViewRotation = Instigator.Controller.GetViewRotation();
		ViewRotation.Pitch += UpKick;

		// Update rotation.
		Instigator.Controller.SetRotation(ViewRotation);
	}
}

defaultproperties
{
	FireAimingAnim="AimFire"
	UpKick=700
	DamageType=Class'KFMod.DamTypeWinchester'
	DamageMin=110
	DamageMax=140
	Momentum=18000.000000
	bPawnRapidFireAnim=True
	bModeExclusive=False
	bAttachSmokeEmitter=True
	TransientSoundVolume=100.000000
	FireLoopAnim=
	FireEndAnim=
	FireSound=Sound'KFWeaponSound.WinchesterFire'
	FireForce="ShockRifleFire"
	FireRate=1.100000
	AmmoClass=Class'KFMod.WinchesterAmmo'
	AmmoPerFire=1
	ShakeRotMag=(X=100.000000,Y=500.000000,Z=100.000000)
	ShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
	ShakeRotTime=2.000000
	ShakeOffsetMag=(X=12.000000,Y=12.000000,Z=12.000000)
	ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
	ShakeOffsetTime=2.000000
	BotRefireRate=0.650000
	FlashEmitterClass=Class'KFMod.ShotgunMuzzFlash'
	aimerror=0.000000
}
