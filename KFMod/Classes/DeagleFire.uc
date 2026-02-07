//=============================================================================
// Deagle Fire
//=============================================================================
class DeagleFire extends KFFire;

var float ClickTime;

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

function DoTrace(Vector Start, Rotator Dir)
{
	local Vector X,Y,Z, End, HitLocation, HitNormal, ArcEnd;
	local Actor Other,TraceStartA;
	local byte HitCount,HCounter;
	local float HitDamage;
	local Actor IgnoredHitActor;

	MaxRange();

	Weapon.GetViewAxes(X, Y, Z);
	if ( Weapon.WeaponCentered() )
		ArcEnd = (Instigator.Location + Weapon.EffectOffset.X * X + 1.5 * Weapon.EffectOffset.Z * Z);
	else ArcEnd = (Instigator.Location + Instigator.CalcDrawOffset(Weapon) + Weapon.EffectOffset.X * X +
		 Weapon.Hand * Weapon.EffectOffset.Y * Y + Weapon.EffectOffset.Z * Z);

	X = Vector(Dir);
	End = Start + TraceRange * X;
	TraceStartA = Weapon;
	HitDamage = DamageMax;
	While( (HitCount++)<10 )
	{
		Other = TraceStartA.Trace(HitLocation, HitNormal, End, Start, true);
		if( Other==None )
			Break;
		else if( Other==Instigator || Other==IgnoredHitActor )
		{
			TraceStartA = Other;
			Start = HitLocation;
			Continue;
		}
		if( ExtendedZCollision(Other)!=None && Other.Owner!=None )
		{
			if( Other.Owner==IgnoredHitActor )
			{
				Start = HitLocation;
				TraceStartA = Other;
				Continue;
			}
			IgnoredHitActor = Other.Owner;
		}
		if ( !Other.bWorldGeometry && Other!=Level )
		{
			if( KFMonster(Other)!=None )
				IgnoredHitActor = Other;
			Other.TakeDamage(int(HitDamage), Instigator, HitLocation, Momentum*X, DamageType);
			Weapon.Spawn(class'KFHitEffect',,, HitLocation);
			if( (HCounter++)>=4 || Pawn(Other)==None )
				Break;
			HitDamage/=2;
			Start = HitLocation;
			TraceStartA = Other;
		}
		else if ( HitScanBlockingVolume(Other)==None )
		{
			Weapon.Spawn(class'KFHitEffect',,, HitLocation);
			Break;
		}
	}
}

defaultproperties
{
	DamageType=Class'KFMod.DamTypeDeagle'
	DamageMin=85
	DamageMax=105
	Momentum=20000.000000
	bPawnRapidFireAnim=True
	bAttachSmokeEmitter=True
	TransientSoundVolume=100.000000
	FireLoopAnim=
	FireEndAnim=
	FireAnimRate=0.900000
	FireSound=Sound'KFWeaponSound.50CalFire'
	AmmoClass=Class'KFMod.DeagleAmmo'
	AmmoPerFire=1
	ShakeRotMag=(X=90.000000,Y=90.000000,Z=90.000000)
	ShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
	ShakeRotTime=2.000000
	ShakeOffsetMag=(X=19.000000,Y=19.000000,Z=19.000000)
	ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
	ShakeOffsetTime=2.000000
	BotRefireRate=0.650000
	FlashEmitterClass=Class'KFMod.KFMuzzleFlash1PGeneric'
	aimerror=0.000000
	SpreadStyle=SS_Random
}
