<<<<<<< HEAD
// KFMeleeFire
=======
// KFMeleeFireto
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
class KFMeleeFire extends WeaponFire;

var int damageConst;
var int maxAdditionalDamage;
var float ProxySize;

var int NumConHits; // Number of successful strikes before a combo.
var bool bComboTime; // Are we combo-ing?
var int LastComboStartTime;
var int LastConHitTime;
var float ComboConDecay;

var float StopFireTime;
var float f;
var float StartFireTime;

var int dmg;
var int i;

var Name IdleAnim;
var float IdleAnimRate;
var float weaponRange;

var float DamagedelayMin;
var float DamagedelayMax;

var bool bCanHit ;
var Vector EndTraceS;

var class<damageType> hitDamageClass;

var() vector ImpactShakeRotMag;		   // how far to rot view
var() vector ImpactShakeRotRate;		  // how fast to rot view
var() float  ImpactShakeRotTime;		  // how much time to rot the instigator's view
var() vector ImpactShakeOffsetMag;		// max view offset vertically
var() vector ImpactShakeOffsetRate;	   // how fast to offset view vertically
var() float  ImpactShakeOffsetTime;	   // how much time to offset view

<<<<<<< HEAD
var Vector SpawnTrace;
var Bool bTrigger;
var Actor SpawnActor;

=======
var vector SpawnTrace;
var Bool bTrigger;
var Actor SpawnActor;

var float WideDamageMinHitAngle; // The angle to do sweeping strikes in front of the player. If zero do no strikes

//Our swing variables
var() rotator UpSwingRot;
var() float UpSwingTime;
var() rotator DownSwingRot;
var() float DownSwingTime;

static final function vector GetAimPos( Actor Other )
{
	local KFMonster P;
	local Coords C;

	P = KFMonster(Other);
	if( P==None || P.Health<=0 )
		return Other.Location;
	if( P.HeadBone=='' || SkeletalMesh(P.Mesh)==None )
		return P.Location + vect(0,0,0.9)*P.CollisionHeight;

	C = P.GetBoneCoords(P.HeadBone);
	return C.Origin + (P.HeadHeight * P.HeadScale * C.XAxis);
}

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
simulated Function Timer()
{
	local Actor HitActor;
	local vector StartTrace, EndTrace, HitLocation, HitNormal;
	local rotator PointRot;
	local int MyDamage;

<<<<<<< HEAD
	MyDamage = damageConst + Rand(MaxAdditionalDamage);

	If( !KFWeapon(Weapon).bNoHit )
	{
		MyDamage = damageConst + Rand(MaxAdditionalDamage);
		StartTrace = Instigator.Location + Instigator.EyePosition();
		if( Instigator.Controller!=None && PlayerController(Instigator.Controller)==None && Instigator.Controller.Enemy!=None )
			PointRot = rotator(Instigator.Controller.Enemy.Location-StartTrace); // Give aimbot for bots.
		else PointRot = Instigator.GetViewRotation();
=======
	local Pawn Victims;
	local vector dir, lookdir;
	local float DiffAngle, VictimDist;

	MyDamage = damageConst + Rand(MaxAdditionalDamage);
	
	KFWeapon(Weapon).NewSwingPhase = 1.0;
	//KFWeapon(Weapon).SwingRot = rot(-80,-40,0);
	KFWeapon(Weapon).SwingRot = DownSwingRot;
	//KFWeapon(Weapon).SwingTime = 0.2;
	KFWeapon(Weapon).SwingTime = DownSwingTime;

	If( Weapon!=None && Instigator!=None && !KFWeapon(Weapon).bNoHit )
	{
		MyDamage = damageConst + Rand(MaxAdditionalDamage);
		StartTrace = Instigator.Location + Instigator.EyePosition();
		if( Instigator.Controller!=None && !Instigator.IsHumanControlled() && Instigator.Controller.Target!=None )
			PointRot = rotator(GetAimPos(Instigator.Controller.Target)-StartTrace); // Give aimbot for bots.
		else 
			PointRot = Instigator.GetViewRotation();
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		EndTrace = StartTrace + vector(PointRot)*weaponRange;
		HitActor = Instigator.Trace( HitLocation, HitNormal, EndTrace, StartTrace, true);
	
		if (HitActor!=None)  
		{
			ImpactShakeView();

<<<<<<< HEAD
=======
			if( HitActor.IsA('ExtendedZCollision') && HitActor.Base != none &&
                HitActor.Base.IsA('KFMonster') )
            {
                HitActor = HitActor.Base;
            }

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
			if ( (HitActor.IsA('KFMonster') || HitActor.IsA('KFHumanPawn')) && KFMeleeGun(Weapon).BloodyMaterial!=none )
			{
				Weapon.Skins[KFMeleeGun(Weapon).BloodSkinSwitchArray] = KFMeleeGun(Weapon).BloodyMaterial;
				Weapon.texture = Weapon.default.Texture;
			}
			if( Level.NetMode==NM_Client ) Return;
<<<<<<< HEAD
			if( HitActor.IsA('Pawn') && !HitActor.IsA('Vehicle')
			 && (Normal(HitActor.Location-Instigator.Location) Dot vector(HitActor.Rotation))<0 )
				MyDamage*=2; // Backstab >:P
=======
			if( HitActor.IsA('Pawn') && !HitActor.IsA('Vehicle') && (Normal(HitActor.Location-Instigator.Location) Dot vector(HitActor.Rotation)) > 0 )
			{
				MyDamage*=2; // Backstab >:P
				//Level.Game.Broadcast(Instigator, "Backstabbed enemy");
			}
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
			if( (KFMonster(HitActor)!=none) )
			{
			//	log(VSize(Instigator.Velocity));

<<<<<<< HEAD
                                HitActor.TakeDamage(MyDamage, Instigator, HitLocation, vector(PointRot), hitDamageClass) ;
=======
                HitActor.TakeDamage(MyDamage, Instigator, HitLocation, vector(PointRot), hitDamageClass) ;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
				Spawn(class'KFMeleeHitEffect',,, HitLocation, rotator(HitLocation - (Instigator.Location + Instigator.EyePosition())));
				KFMeleeGun(Weapon).playServerSound();

				if(VSize(Instigator.Velocity) > 300 && KFMonster(HitActor).Mass <= Instigator.Mass)
<<<<<<< HEAD
				 KFMonster(HitActor).FlipOver();
=======
					KFMonster(HitActor).FlipOver();
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

			}
			else
			{
				HitActor.TakeDamage(MyDamage, Instigator, HitLocation, vector(PointRot), hitDamageClass) ;
				Spawn(class'KFMeleeHitEffect',,, HitLocation, rotator(HitLocation - StartTrace));
			}
		}
<<<<<<< HEAD
	}
}
=======
		if( WideDamageMinHitAngle > 0 )
		{
            foreach Weapon.VisibleCollidingActors( class 'Pawn', Victims, (weaponRange * 3), StartTrace ) //, RadiusHitLocation
    		{
			if( Victims==HitActor || Victims.Health<=0 || Victims==Instigator )
				continue;

				VictimDist = Vsize(Instigator.Location - Victims.Location);

				if( VictimDist > ((weaponRange * 1.1) + Victims.CollisionRadius) )
					continue;

				lookdir = Normal(Vector(Instigator.GetViewRotation()));
				dir = Normal(Victims.Location - Instigator.Location);

				DiffAngle = lookdir dot dir;

				if( DiffAngle > WideDamageMinHitAngle )
				{
					//Instigator.DrawStayingDebugLine( Victims.Location + vect(0,0,10), Instigator.Location,255, 0, 0);
					//log("Shot would hit "$Victims$" DiffAngle = "$DiffAngle$" WideDamageMinHitAngle = "$WideDamageMinHitAngle$" for damage of: "$(MyDamage*DiffAngle));
					Victims.TakeDamage(MyDamage*DiffAngle, Instigator, (Victims.Location + Victims.CollisionHeight * vect(0,0,0.7)), vector(PointRot), hitDamageClass) ;

					//HitActor.TakeDamage(MyDamage, Instigator, HitLocation, vector(PointRot), hitDamageClass) ;
					Spawn(class'KFMeleeHitEffect',,, (Victims.Location + Victims.CollisionHeight * vect(0,0,0.7)), rotator(Victims.Location - (Instigator.Location + Instigator.EyePosition())));
					KFMeleeGun(Weapon).playServerSound();
				}
				//else
				//{
				//    Instigator.DrawStayingDebugLine( Victims.Location, Instigator.Location,255, 255, 0);
				//    log("Shot would miss "$Victims$" DiffAngle = "$DiffAngle$" WideDamageMinHitAngle = "$WideDamageMinHitAngle);
				//}
    			
    		}
		}
	}
}

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
function float GetFireSpeed()
{
	if( KFPawn(Instigator)!=None )
		Return KFPawn(Instigator).GetVeteran().Static.GetFireSpeedMod(Weapon);
	Return 1;
}
<<<<<<< HEAD
=======

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
simulated event ModeDoFire()
{
	local float Rec;

	if (!AllowFire())
		return;

	Rec = GetFireSpeed();
	SetTimer(DamagedelayMin/Rec, False);
	FireRate = default.FireRate/Rec;
	FireAnimRate = default.FireAnimRate*Rec;
	ReloadAnimRate = default.ReloadAnimRate*Rec;

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
		ClientPlayForceFeedback(FireForce);
	}
	else // server
		ServerPlayFiring();

	Weapon.IncrementFlashCount(ThisModeNum);

	// set the next firing time. must be careful here so client and server do not get out of sync
	if (bFireOnRelease)
	{
		if (bIsFiring)
			NextFireTime += MaxHoldTime + FireRate;
		else
			NextFireTime = Level.TimeSeconds + FireRate;
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

<<<<<<< HEAD

=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	Weapon.Owner.Velocity.x *= KFMeleeGun(Weapon).ChopSlowRate;
	Weapon.Owner.Velocity.y *= KFMeleeGun(Weapon).ChopSlowRate;
}

function DoFireEffect()
{
	local KFMeleeGun kf;
	local int damage ;

	if(KFMeleeGun(Weapon) == none)
		return;

	kf = KFMeleeGun(Weapon);
<<<<<<< HEAD
	damage = damageConst + Rand(MaxAdditionalDamage) ;
=======

	damage = damageConst + Rand(MaxAdditionalDamage) ;

	kf.NewSwingPhase = 1.0;
	//kf.SwingRot = rot(50,20,0);
	kf.SwingRot = UpSwingRot;
	//kf.SwingTime = 0.4;
	kf.SwingTime = UpSwingTime;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}


simulated function ShakeView()
{
	local PlayerController P;

	if (Instigator == None)
		return;

	P = PlayerController(Instigator.Controller);
	if (P != None )
		P.WeaponShakeView(ShakeRotMag, ShakeRotRate, ShakeRotTime, ShakeOffsetMag, ShakeOffsetRate, ShakeOffsetTime);
}

function SlowDown();

function SpeedUp();

function ResetRate();

function ImpactShakeView()
{
	local PlayerController P;

	P = PlayerController(Instigator.Controller);
	if ( P != None )
		P.WeaponShakeView(ImpactShakeRotMag, ImpactShakeRotRate, ImpactShakeRotTime,ImpactShakeOffsetMag,ImpactShakeOffsetRate,ImpactShakeOffsetTime);
}

defaultproperties
{
<<<<<<< HEAD
	maxAdditionalDamage=5
	ProxySize=0.200000
	IdleAnim="Idle"
	IdleAnimRate=1.000000
	weaponRange=70.000000
	DamagedelayMin=0.300000
	DamagedelayMax=0.400000
	hitDamageClass=Class'KFMod.DamTypeMelee'
	ImpactShakeRotMag=(X=50.000000,Y=50.000000,Z=50.000000)
	ImpactShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
	ImpactShakeRotTime=2.000000
	ImpactShakeOffsetMag=(X=10.000000,Y=10.000000,Z=10.000000)
	ImpactShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
	ImpactShakeOffsetTime=2.000000
	FireEndAnim=
	FireForce="ShockRifleFire"
	aimerror=100.000000
=======
     maxAdditionalDamage=5
     ProxySize=0.200000
     IdleAnim="Idle"
     IdleAnimRate=1.000000
     weaponRange=75.000000
     DamagedelayMin=0.300000
     DamagedelayMax=0.400000
     hitDamageClass=Class'KFMod.DamTypeMelee'
     ImpactShakeRotMag=(X=50.000000,Y=50.000000,Z=50.000000)
     ImpactShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
     ImpactShakeRotTime=2.000000
     ImpactShakeOffsetMag=(X=10.000000,Y=10.000000,Z=10.000000)
     ImpactShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
     ImpactShakeOffsetTime=2.000000
     UpSwingRot=(Pitch=50,Yaw=20)
     UpSwingTime=0.400000
     DownSwingRot=(Pitch=-80,Yaw=-40)
     DownSwingTime=0.200000
     FireEndAnim=
     FireForce="ShockRifleFire"
     aimerror=100.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
