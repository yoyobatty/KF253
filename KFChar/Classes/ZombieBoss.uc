// Zombie Monster for KF Invasion gametype

class ZombieBoss extends KFMonster;

#exec OBJ LOAD FILE=KFBoss.ukx
#exec OBJ LOAD FILE=KFPatch2.utx
var bool bChargingPlayer,bClientCharg,bFireAtWill,bMinigunning,bCanMoveChaingunning;
var float RageStartTime,LastChainGunTime,LastMissileTime,LastSneakedTime;

var bool bClientMiniGunning;

var name ChargingAnim;		// How he runs when charging the player.
var byte SyringeCount,ClientSyrCount,MGFireCounter;

var BossHPNeedle CurrentNeedle;

var vector TraceHitPos;
var Emitter mTracer,mMuzzleFlash;
var bool bClientCloaked;
var float LastCheckTimes;
var KFHumanPawn LocalKFHumanPawn;
var int HealingLevels[3],HealingAmount,MissilesLeft;

var float ChaingunFireInterval;    // starting delay between chaingun shots (seconds)
var float ChaingunMinInterval;     // minimum delay (fastest fire rate)
var float ChaingunRampStep;        // how much the delay decreases per shot
var float ChaingunCurrentInterval; // runtime current interval

replication
{
	reliable if( Role==ROLE_Authority )
		bChargingPlayer,SyringeCount,TraceHitPos,bMinigunning,bCanMoveChaingunning,ChaingunCurrentInterval;
}

simulated function Tick(float DeltaTime)
{
	local KFHumanPawn HP;

	Super.Tick(DeltaTime);
	if( Level.NetMode==NM_DedicatedServer )
		Return; // Servers aren't intrested in this info.
  
	if( bCloaked && Level.TimeSeconds>LastCheckTimes )
	{
		LastCheckTimes = Level.TimeSeconds+0.5;
        if( LocalKFHumanPawn != none && LocalKFHumanPawn.Health > 0 && LocalKFHumanPawn.ShowStalkers() &&
            VSize(Location - LocalKFHumanPawn.Location) < 800.f ) 
        {
			bSpotted = True;
		}
		else
		{
			bSpotted = false;
		}
		// If he's a commando, we've been spotted.
		if( bSpotted )
		{
			// Player requested to see stalkers — make visible / glow
			CloakBoss();
		}
	}
}

simulated function CloakBoss()
{
	local Controller C;

	if( bSpotted )
	{
		Visibility = 120;
		if( Level.NetMode==NM_DedicatedServer )
			Return;
		Skins[0] = Finalblend'KFX.StalkerGlow';
		Skins[1] = Finalblend'KFX.StalkerGlow';
		Skins[2] = Finalblend'KFX.StalkerGlow';
		Skins[3] = Finalblend'KFX.StalkerGlow';
		Skins[4] = Finalblend'KFX.StalkerGlow';
		Skins[5] = Finalblend'KFX.StalkerGlow';
		Skins[6] = Finalblend'KFX.StalkerGlow';
		bUnlit = true;
		return;
	}

	Visibility = 1;
	bCloaked = true;
	if( Level.NetMode!=NM_Client )
	{
		For( C=Level.ControllerList; C!=None; C=C.NextController )
		{
			if( C.bIsPlayer && C.Enemy==Self )
				C.Enemy = None; // Make bots lose sight with me.
		}
	}
	if( Level.NetMode==NM_DedicatedServer )
		Return;

	Skins[0] = Shader'BossCloakShader';
	Skins[1] = Shader'BossCloakShader';
	Skins[2] = Shader'BossCloakShader';
	Skins[3] = Shader'BossCloakShader';
	Skins[4] = Shader'BossCloakShader';
	Skins[5] = Shader'BossCloakShader';
	Skins[6] = Texture'KillingFloorLabTextures.LabCommon.voidtex';

	// Invisible - no shadow
	if(PlayerShadow != none)
		PlayerShadow.bShadowActive = false;

	// Remove/disallow projectors on invisible people
	Projectors.Remove(0, Projectors.Length);
	bAcceptsProjectors = false;
	OverlayMaterial = FinalBlend'BossCloakFizzleFB';
	ClientOverlayTimer = 0.25;
	ClientOverlayCounter = 0.25;
}
simulated function UnCloakBoss()
{
	Visibility = default.Visibility;
	bCloaked = false;
	bSpotted = False;
	bUnlit = False;
	if( Level.NetMode==NM_DedicatedServer )
		Return;
	Skins = Default.Skins;

	if (PlayerShadow != none)
		PlayerShadow.bShadowActive = true;
 
	bAcceptsProjectors = true;
	//OverlayMaterial = FinalBlend'KFPatch2.BossCloakFizzleFB';
	ClientOverlayTimer = 0.25;
	ClientOverlayCounter = 0.25;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if( Role < ROLE_Authority )
    {
        return;
    }

	HealingLevels[0] = Health/1.25; 
	HealingLevels[1] = Health/2.f; 
	HealingLevels[2] = Health/3.2; 
	HealingAmount = Health/4; 
}

function bool MakeGrandEntry()
{
	bShotAnim = true;
	Acceleration = vect(0,0,0);
	SetAnimAction('Entrance');
	Controller.GoToState('WaitForAnim');

	Return True;
}

simulated function Destroyed()
{
	if( mTracer!=None )
		mTracer.Destroy();
	if( mMuzzleFlash!=None )
		mMuzzleFlash.Destroy();
	Super.Destroyed();
}

simulated Function PostNetBeginPlay()
{
    local PlayerController PC;

	Super.PostNetBeginPlay();

	if( Level.NetMode!=NM_DedicatedServer )
	{
        PC = Level.GetLocalPlayerController();
        if( PC != none && PC.Pawn != none )
        {
            LocalKFHumanPawn = KFHumanPawn(PC.Pawn);
        }
	}
	EnableChannelNotify ( 1,1);
	AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
	TraceHitPos = vect(0,0,0);
	bNetNotify = True;
}

function PlayTakeHit(vector HitLocation, int Damage, class<DamageType> DamageType)
{
	if( Level.TimeSeconds - LastPainAnim < MinTimeBetweenPainAnims )
		return;

	if( Damage>=150 || (DamageType.name=='DamTypeStunNade' && rand(5)>3) || (DamageType.name=='DamTypeCrossbowHeadshot' && Damage>=200) )
		PlayDirectionalHit(HitLocation);

	LastPainAnim = Level.TimeSeconds;

	if( Level.TimeSeconds - LastPainSound < MinTimeBetweenPainSounds )
		return;

	LastPainSound = Level.TimeSeconds;
	PlaySound(HitSound[Rand(4)], SLOT_Pain,2*TransientSoundVolume,,400);
}

function bool OnlyEnemyAround( Pawn Other )
{
	local Controller C;

	For( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		if( C.bIsPlayer && C.Pawn!=None && C.Pawn!=Other && ((VSize(C.Pawn.Location-Location)<1500 && FastTrace(C.Pawn.Location,Location))
		 || (VSize(C.Pawn.Location-Other.Location)<1000 && FastTrace(C.Pawn.Location,Other.Location))) )
			Return False;
	}
	Return True;
}

function bool IsCloseEnuf( Actor A )
{
	local vector V;

	if( A==None )
		Return False;
	V = A.Location-Location;
	if( Abs(V.Z)>(CollisionHeight+A.CollisionHeight) )
		Return False;
	V.Z = 0;
	Return (VSize(V)<(CollisionRadius+A.CollisionRadius+25));
}

function RangedAttack(Actor A)
{
	local float D;
	local bool bOnlyE;

	if ( bShotAnim )
		return;
	D = VSize(A.Location-Location);
	bOnlyE = (Pawn(A)!=None && OnlyEnemyAround(Pawn(A)));
	if ( IsCloseEnuf(A) )
	{
		bShotAnim = true;
		Acceleration = (A.Location-Location);
		Controller.MoveTarget = A;
		Controller.MoveTimer = 0.8;
		if( Health>1500 && Pawn(A)!=None && OnlyEnemyAround(Pawn(A)) && FRand()<0.85 )
			SetAnimAction('MeleeImpale');
		else
		{
			SetAnimAction('MeleeClaw');
			PlaySound(sound'Claw2s', SLOT_None);
		}
	}
	else if( LastSneakedTime<Level.TimeSeconds )
	{
		if( FRand()<0.1 )
		{
			LastSneakedTime = Level.TimeSeconds+FRand()*120;
			Return;
		}
		LastSneakedTime = Level.TimeSeconds+30+FRand()*200;
		bShotAnim = true;
		Acceleration = vect(0,0,0);
		SetAnimAction('BossHitF');
		GoToState('SneakAround');
		Controller.GoToState('WaitForAnim');
	}
	else if( bChargingPlayer && (bOnlyE || D<200) )
		Return;
	else if( !bChargingPlayer && (D<300 || (D<700 && bOnlyE)) && FRand()<0.5 )
	{
		bShotAnim = true;
		Acceleration = vect(0,0,0);
		SetAnimAction('BossHitF');
		GoToState('Charging');
		Controller.GoToState('WaitForAnim');
	}
	else if( LastMissileTime<Level.TimeSeconds && D>750 )
	{
		if( !Controller.LineOfSightTo(A) || FRand()>FClamp(D/10000.f,0.40,0.15) )
		{
			LastMissileTime = Level.TimeSeconds+FRand()*5;
			Return;
		}
		LastMissileTime = Level.TimeSeconds+10+FRand()*15;
		bShotAnim = true;
		Acceleration = vect(0,0,0);
		SetAnimAction('PreFireMG');
        // Avoid waiting for anim on dedicated server (no anim notifies there)
        if( Level.NetMode != NM_DedicatedServer )
            Controller.GoToState('WaitForAnim');
		MGFireCounter = Rand(20);
		GoToState('FireMissile');
	}
	else if ( !bWaitForAnim && !bShotAnim && LastChainGunTime<Level.TimeSeconds )
	{
		if( !Controller.LineOfSightTo(A) || FRand()>0.75 )
		{
			LastChainGunTime = Level.TimeSeconds+FRand()*4;
			Return;
		}
		LastChainGunTime = Level.TimeSeconds+10+FRand()*10;
		bShotAnim = true;
		Acceleration = vect(0,0,0);
		SetAnimAction('PreFireMG');
        // Avoid waiting for anim on dedicated server (no anim notifies there)
        if( Level.NetMode != NM_DedicatedServer )
            Controller.GoToState('WaitForAnim');
		MGFireCounter = Rand(20);
		GoToState('FireChaingun');
	}
}

event Bump(actor Other)
{
	Super(Monster).Bump(Other);
	if( Other==none )
		return;

	if( Other.IsA('NetKActor') && Physics != PHYS_Falling && !bShotAnim && Abs(Other.Location.Z-Location.Z)<(CollisionHeight+Other.CollisionHeight) )
	{ // Kill the annoying deco brat.
		Controller.Target = Other;
		Controller.Focus = Other;
		bShotAnim = true;
		Acceleration = (Other.Location-Location);
		SetAnimAction('MeleeClaw');
		PlaySound(sound'Claw2s', SLOT_None);
		Controller.GoToState('WaitForAnim');
	}
}

simulated function AddTraceHitFX( vector HitPos )
{
	local vector Start,SpawnVel,SpawnDir;
	local float hitDist;
	local KFHitEffect H;

	PlaySound(sound'L85Fire',SLOT_Misc,2,,1400,0.9+FRand()*0.2);
	Start = GetBoneCoords('tip').Origin;
	if( mTracer==None )
		mTracer = Spawn(Class'NewTracer',,,Start);
	else mTracer.SetLocation(Start);
	if( mMuzzleFlash==None )
	{
		mMuzzleFlash = Spawn(Class'NewMinigunMFlash');
		AttachToBone(mMuzzleFlash, 'tip');
		mMuzzleFlash.SetRelativeRotation(rot(0,32768,0));
	}
	else mMuzzleFlash.SpawnParticle(1);
	hitDist = VSize(HitPos - Start) - 50.f;

	if( hitDist>10 )
	{
		SpawnDir = Normal(HitPos - Start);
		SpawnVel = SpawnDir * 10000.f;
		mTracer.Emitters[0].StartVelocityRange.X.Min = SpawnVel.X;
		mTracer.Emitters[0].StartVelocityRange.X.Max = SpawnVel.X;
		mTracer.Emitters[0].StartVelocityRange.Y.Min = SpawnVel.Y;
		mTracer.Emitters[0].StartVelocityRange.Y.Max = SpawnVel.Y;
		mTracer.Emitters[0].StartVelocityRange.Z.Min = SpawnVel.Z;
		mTracer.Emitters[0].StartVelocityRange.Z.Max = SpawnVel.Z;
		mTracer.Emitters[0].LifetimeRange.Min = hitDist / 10000.f;
		mTracer.Emitters[0].LifetimeRange.Max = mTracer.Emitters[0].LifetimeRange.Min;
		mTracer.SpawnParticle(1);
	}
	Instigator = Self;
	H = Spawn(Class'KFHitEffect',,,HitPos);
	if( H!=None )
		H.RemoteRole = ROLE_None;
}

simulated function AnimEnd( int Channel )
{
	if( Level.NetMode==NM_Client && bMinigunning )
	{
		PlayAnim('FireMG');
		bWaitForAnim = true;
	}
	else Super.AnimEnd(Channel);
}
State FireChaingun
{
	function RangedAttack(Actor A)
	{
		Controller.Target = A;
		Controller.Focus = A;
	}
	function EndState()
	{
		bChargingPlayer = false;
		TraceHitPos = vect(0,0,0);
		bMinigunning = False;
		bCanMoveChaingunning = False;
		ChaingunCurrentInterval = ChaingunFireInterval;
		bCanStrafe = false;
	}
	function BeginState()
	{
		bChargingPlayer = Rand(2)==0 && SyringeCount >=2;
		bFireAtWill = False;
		Acceleration = vect(0,0,0);
		bMinigunning = True;
		bCanStrafe = true;
		if(SyringeCount >= 1)
			bCanMoveChaingunning = true;
        ChaingunCurrentInterval = ChaingunFireInterval;
		
	}
	function Tick( float Delta )
	{
		Super.Tick(Delta);
		if( bChargingPlayer ) //Run for it!
			SetGroundSpeed(OriginalGroundSpeed * 1.2);
		else SetGroundSpeed(OriginalGroundSpeed * 0.65);
		if(bFireAtWill)
		{
			ChaingunCurrentInterval -= ChaingunRampStep;
			if (ChaingunCurrentInterval < ChaingunMinInterval)
				ChaingunCurrentInterval = ChaingunMinInterval;
		}
	}
	function AnimEnd( int Channel )
	{
		MGFireCounter++;
		if( MGFireCounter>=30 )
		{
			bShotAnim = true;
			Acceleration = vect(0,0,0);
			SetAnimAction('FireEndMG');
			GoToState('');
		}
		else if( bCanMoveChaingunning )
		{
			if( bFireAtWill && Channel!=1 )
				return;
			if( Controller.Target!=None )
				Controller.Focus = Controller.Target;
			bShotAnim = true;
			bFireAtWill = True;
			SetAnimAction('FireMG');
		}
		else
		{
			if( Controller.Enemy!=None )
			{
				if( Controller.LineOfSightTo(Controller.Enemy) )
				{
					Controller.Focus = Controller.Enemy;
					Controller.FocalPoint = Controller.Enemy.Location;
				}
				else Controller.Focus = None;
				Controller.Target = Controller.Enemy;
			} 
			else Controller.Focus = None;
			bFireAtWill = True;
			bShotAnim = true;
			Acceleration = vect(0,0,0);
			PlayAnim('FireMG');
			bWaitForAnim = true;
		}
	}
	function FireMGShot()
	{
		local AvoidMarker ChaingunFear;
		local vector Start,End,HL,HN,Dir;
		local rotator R;
		local Actor A;

		Start = GetBoneCoords('tip').Origin;
		if( Controller.Focus!=None )
			R = rotator(Controller.Focus.Location-Start);
		else R = rotator(Controller.FocalPoint-Start);
		if( NeedToTurnFor(R) )
			R = Rotation;
		if(!bCanMoveChaingunning)
			Dir = Normal(vector(R)+VRand()*0.04);
		else Dir = Normal(vector(R)+VRand()*0.06); // more spread when moving
		End = Start+Dir*10000;
		A = Trace(HL,HN,End,Start,True);
		if( A==None )
			Return;
		TraceHitPos = HL;
		if( Level.NetMode!=NM_DedicatedServer )
			AddTraceHitFX(HL);
		Dir.Z = 0.0;
		if( A!=Level )
			A.TakeDamage(4+Rand(2),Self,HL,Dir*500,Class'DamageType');
		ChaingunFear = spawn(class'AvoidMarker',,,HL);
		ChaingunFear.SetCollisionSize(60,60);
		ChaingunFear.StartleBots();
		ChaingunFear.LifeSpan = 2.f;
	}
	function bool NeedToTurnFor( rotator targ )
	{
		local int YawErr;

		targ.Yaw = DesiredRotation.Yaw & 65535;
		YawErr = (targ.Yaw - (Rotation.Yaw & 65535)) & 65535;
		return !((YawErr < 2000) || (YawErr > 64535));
	}
Begin:
	While( True )
	{
		if(!bCanMoveChaingunning)
			Acceleration = vect(0,0,0);
		if( bFireAtWill )
		{
			FireMGShot();
		}
		Sleep(ChaingunCurrentInterval);
	}
}

State FireMissile
{
	function BeginState()
	{
		Acceleration = vect(0,0,0);
		MissilesLeft = 3;
	}
	function RangedAttack(Actor A)
	{
		if( MissilesLeft>1 )
		{
			Controller.Target = A;
			Controller.Focus = A;
		}
	}
	function AnimEnd( int Channel )
	{
		local vector Start;
		local Rotator R;

		Start = GetBoneCoords('tip').Origin;
		if ( !SavedFireProperties.bInitialized )
		{
			SavedFireProperties.AmmoClass = MyAmmo.Class;
			SavedFireProperties.ProjectileClass = MyAmmo.ProjectileClass;
			SavedFireProperties.WarnTargetPct = 0.15;
			SavedFireProperties.MaxRange = 10000;
			SavedFireProperties.bTossed = False;
			SavedFireProperties.bLeadTarget = True;
			SavedFireProperties.bInitialized = true;
		}
		R = AdjustAim(SavedFireProperties,Start,100);
		PlaySound(Sound'KFWeaponSound.LAWFire', SLOT_Interact);
		Spawn(SavedFireProperties.ProjectileClass,,,Start,R);
		bShotAnim = true;
		Acceleration = vect(0,0,0);
		SetAnimAction('FireEndMG');
		if( --MissilesLeft==0 )
			GoToState('');
		else GoToState(,'FireMore');
	}
Begin:
	While( True )
	{
		Acceleration = vect(0,0,0);
		Sleep(0.1);
	}
FireMore:
	Acceleration = vect(0,0,0);
	Sleep(1.5);
	AnimEnd(0);
}

function bool MeleeDamageTarget(int hitdamage, vector pushdir)
{
	local bool RetVal;

	MeleeRange*=7;    //MeleeRange*=7;
	if( Controller.Target!=None && Controller.Target.IsA('NetKActor') )
		pushdir = Normal(Controller.Target.Location-Location)*100000; // Fly bitch!
	RetVal = Super.MeleeDamageTarget(hitdamage, pushdir);
	MeleeRange = Default.MeleeRange;
	return RetVal;
}

State Charging
{
   	function bool CanSpeedAdjust()
    {
        return false;
    }

	function BeginState()
	{
		bChargingPlayer = True;
		if( Level.NetMode!=NM_DedicatedServer )
			PostNetReceive();
	}
	function EndState()
	{
		SetGroundSpeed(OriginalGroundSpeed);
		bChargingPlayer = False;
		if( Level.NetMode!=NM_DedicatedServer )
			PostNetReceive();
	}
	function Tick( float Delta )
	{
		SetGroundSpeed(OriginalGroundSpeed * 2.5);
		Global.Tick(Delta);
	}
	function bool MeleeDamageTarget(int hitdamage, vector pushdir)
	{
		local bool RetVal;

		RetVal = Global.MeleeDamageTarget(hitdamage*1.5, pushdir*1.5);
		if( RetVal )
			GoToState('');
		return RetVal;
	}
	function RangedAttack(Actor A)
	{
		if( VSize(A.Location-Location)>700 )
			GoToState('');
		Global.RangedAttack(A);
	}
Begin:
	Sleep(6);
	GoToState('');
}

function BeginHealing()
{
	MonsterController(Controller).WhatToDoNext(55);
}

State Escaping extends Charging // Got hurt and running away...
{
	function BeginHealing()
	{
		bShotAnim = true;
		Acceleration = vect(0,0,0);
		SetAnimAction('Heal');
		MonsterController(Controller).WhatToDoNext(56);
		GoToState('');
	}
	function RangedAttack(Actor A)
	{
		if ( bShotAnim )
			return;
		else if ( IsCloseEnuf(A) )
		{
			if( bCloaked )
				UnCloakBoss();
			bShotAnim = true;
			Acceleration = vect(0,0,0);
			Acceleration = (A.Location-Location);
			SetAnimAction('MeleeClaw');
			PlaySound(sound'Claw2s', SLOT_None);
		}
	}
	function bool MeleeDamageTarget(int hitdamage, vector pushdir)
	{
		return Global.MeleeDamageTarget(hitdamage*2, pushdir*1.5);
	}
	function EndState()
	{
		SetGroundSpeed(OriginalGroundSpeed);
		bChargingPlayer = False;
		if( Level.NetMode!=NM_DedicatedServer )
			PostNetReceive();
		if( bCloaked )
			UnCloakBoss();
	}
Begin:
	CloakBoss();
	While( True )
	{
		Sleep(0.5);
		if( !bCloaked && !bShotAnim )
			CloakBoss();
		if( !Controller.IsInState('SyrRetreat') )
			Controller.GoToState('SyrRetreat');
	}
}
State SneakAround extends Escaping // Attempt to sneak around.
{
	function BeginHealing()
	{
		MonsterController(Controller).WhatToDoNext(56);
		GoToState('');
	}
Begin:
	CloakBoss();
	BossZombieController(Controller).FindPathAround();
	While( True )
	{
		Sleep(0.5);
		if( !bCloaked && !bShotAnim )
			CloakBoss();
		if (!Controller.IsInState('PatFindWay'))
        {
			if( !Controller.IsInState('RunSomewhere') )
				Controller.GoToState('RunSomewhere');
		}
	}
}

simulated function DropNeedle()
{
	if( CurrentNeedle!=None )
	{
		DetachFromBone(CurrentNeedle);
		CurrentNeedle.SetLocation(GetBoneCoords('Bip01 R Finger0').Origin);
		CurrentNeedle.DroppedNow();
		CurrentNeedle = None;
	}
}
simulated function NotifySyringeA()
{
	if( Level.NetMode!=NM_Client )
	{
		if( SyringeCount<3 )
			SyringeCount++;
		if( Level.NetMode!=NM_DedicatedServer )
			PostNetReceive();
	}
	if( Level.NetMode!=NM_DedicatedServer )
	{
		DropNeedle();
		CurrentNeedle = Spawn(Class'BossHPNeedle');
		AttachToBone(CurrentNeedle,'Bip01 R Finger0');
	}
}
function NotifySyringeB()
{
	if( Level.NetMode!=NM_Client )
		Health+=HealingAmount;
}
simulated function NotifySyringeC()
{
	if( Level.NetMode!=NM_DedicatedServer && CurrentNeedle!=None )
	{
		CurrentNeedle.Velocity = vect(-45,300,-90) >> Rotation;
		DropNeedle();
	}
}

simulated function PostNetReceive()
{
	if( bClientMiniGunning != bMinigunning )
	{
        bClientMiniGunning = bMinigunning;
        // Hack so Patriarch won't go out of MG Firing to play his idle anim online
        if( bMinigunning )
        {
        	IdleHeavyAnim='FireMG';
        	IdleRifleAnim='FireMG';
        	IdleCrouchAnim='FireMG';
        	IdleWeaponAnim='FireMG';
        	IdleRestAnim='FireMG';
        }
        else
        {
        	IdleHeavyAnim='BossIdle';
        	IdleRifleAnim='BossIdle';
        	IdleCrouchAnim='BossIdle';
        	IdleWeaponAnim='BossIdle';
        	IdleRestAnim='BossIdle';
        }
	} 
	if( bClientCharg!=bChargingPlayer )
	{
		bClientCharg = bChargingPlayer;
		if (bChargingPlayer)
		{
			MovementAnims[0] = ChargingAnim;
			MovementAnims[1] = ChargingAnim;
			MovementAnims[2] = ChargingAnim;
			MovementAnims[3] = ChargingAnim;
		}
		else if( !bChargingPlayer )
		{
			MovementAnims[0] = default.MovementAnims[0];
			MovementAnims[1] = default.MovementAnims[1];
			MovementAnims[2] = default.MovementAnims[2];
			MovementAnims[3] = default.MovementAnims[3];
		}
	}
	else if( ClientSyrCount!=SyringeCount )
	{
		ClientSyrCount = SyringeCount;
		Switch( SyringeCount )
		{
			Case 1:
				SetBoneScale(3,0,'SyringeBoneOne');
				Break;
			Case 2:
				SetBoneScale(3,0,'SyringeBoneOne');
				SetBoneScale(4,0,'SyringeBoneTwo');
				Break;
			Case 3:
				SetBoneScale(3,0,'SyringeBoneOne');
				SetBoneScale(4,0,'SyringeBoneTwo');
				SetBoneScale(5,0,'SyringeBoneThree');
				Break;
			Default: // WTF? reset...?
				SetBoneScale(3,1,'SyringeBoneOne');
				SetBoneScale(4,1,'SyringeBoneTwo');
				SetBoneScale(5,1,'SyringeBoneThree');
				Break;
		}
	}
	else if( TraceHitPos!=vect(0,0,0) )
	{
		AddTraceHitFX(TraceHitPos);
		TraceHitPos = vect(0,0,0);
	}
	else if( bClientCloaked!=bCloaked )
	{
		bClientCloaked = bCloaked;
		bCloaked = !bCloaked;
		if( bCloaked )
			UnCloakBoss();
		else CloakBoss();
		bCloaked = bClientCloaked;
	}
}

simulated function int DoAnimAction( name AnimName )
{
	if( AnimName=='MeleeImpale' || AnimName=='MeleeClaw' || AnimName=='BossHitF' )
	{
		AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
		PlayAnim(AnimName,, 0.0, 1);
		Return 1;
	}
	if( AnimName=='FireMG' && bCanMoveChaingunning )
	{
		AnimBlendParams(1, 1.0, 0.0,, FireRootBone, True);
		PlayAnim('FireMG',, 0.f, 1);
		return 1;
	}
	else if( AnimName=='FireEndMG' )
	{
		//SetBoneDirection(FireRootBone,rot(0,0,0),,0,0);
		AnimBlendParams(1, 0);
	}
	Return Super.DoAnimAction(AnimName);
}

simulated function HandleBumpGlass()
{
}

function bool FlipOver()
{
	Return False;
}
function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
	Super.TakeDamage(Damage,instigatedBy,hitlocation,vect(0,0,0),damageType);
	if( Health<=0 || SyringeCount==3 || IsInState('Escaping') || bShotAnim )
		Return;
	if( (SyringeCount==0 && Health<HealingLevels[0]) || (SyringeCount==1 && Health<HealingLevels[1]) || (SyringeCount==2 && Health<HealingLevels[2]) )
	{
		bShotAnim = true;
		Acceleration = vect(0,0,0);
		SetAnimAction('KnockDown');
		Controller.GoToState('WaitForAnim');
		GoToState('Escaping');
	}
}
function DoorAttack(Actor A)
{
	if ( bShotAnim )
		return;
	else if ( A!=None )
	{
		Controller.Target = A;
		bShotAnim = true;
		Acceleration = vect(0,0,0);
		SetAnimAction('PreFireMG');
        // Avoid waiting for anim on dedicated server (no anim notifies there)
        if( Level.NetMode != NM_DedicatedServer )
            Controller.GoToState('WaitForAnim');
		MGFireCounter = Rand(20);
		GoToState('FireMissile');
	}
}
function RemoveHead();
function PlayDirectionalHit(Vector HitLoc);
function bool SameSpeciesAs(Pawn P)
{
	return False;
}

defaultproperties
{
	ChargingAnim="RunF"
	HealingLevels(0)=5600
	HealingLevels(1)=3500
	HealingLevels(2)=2187
	HealingAmount=1750
	MoanVoice(0)=Sound'WoodBreakFX.RocketArm'
	MoanVoice(1)=Sound'WoodBreakFX.ToldHerh'
	MoanVoice(2)=Sound'WoodBreakFX.NotRight'
	MoanVoice(3)=Sound'WoodBreakFX.Laugh'
	damageRand=50
	damageConst=50 //100 is too brutal
	damageForce=170000
	bFatAss=True
	KFRagdollName="BossRag"
	bMeleeStunImmune=True
	bCanDistanceAttackDoors=True
	bUseExtendedCollision=True
	ColOffset=(Z=50.000000)
	ColRadius=27.000000
	ColHeight=40.000000
	bBoss=True
	HitSound(0)=Sound'WoodBreakFX.BossHurt1'
	HitSound(1)=Sound'WoodBreakFX.BossHurt2'
	HitSound(2)=Sound'WoodBreakFX.BossHurt1'
	HitSound(3)=Sound'WoodBreakFX.BossHurt2'
	ScoringValue=80
	IdleHeavyAnim="BossIdle"
	IdleRifleAnim="BossIdle"
	RagDeathVel=80.000000
	RagDeathUpKick=100.000000
	MeleeRange=10.000000
	GroundSpeed=120.000000
	WaterSpeed=120.000000
	HealthMax=8000.000000
	Health=8000
	HeadHealth=7000
	ChaingunFireInterval=0.20
	ChaingunMinInterval=0.03
	ChaingunRampStep=0.001
	MenuName="Patriarch"
	ControllerClass=Class'KFChar.BossZombieController'
	MovementAnims(0)="WalkF"
	MovementAnims(1)="WalkF"
	MovementAnims(2)="WalkF"
	MovementAnims(3)="WalkF"
	TurnLeftAnim="BossHitF"
	TurnRightAnim="BossHitF"
	AirAnims(0)="JumpInAir"
	AirAnims(1)="JumpInAir"
	AirAnims(2)="JumpInAir"
	AirAnims(3)="JumpInAir"
	TakeoffAnims(0)="JumpTakeOff"
	TakeoffAnims(1)="JumpTakeOff"
	TakeoffAnims(2)="JumpTakeOff"
	TakeoffAnims(3)="JumpTakeOff"
	LandAnims(0)="JumpLanded"
	LandAnims(1)="JumpLanded"
	LandAnims(2)="JumpLanded"
	LandAnims(3)="JumpLanded"
	AirStillAnim="JumpInAir"
	TakeoffStillAnim="JumpTakeOff"
	IdleCrouchAnim="BossIdle"
	IdleWeaponAnim="BossIdle"
	IdleRestAnim="BossIdle"
	AmbientSound=Sound'KFPlayerSound.Zombiesbreath'
	Mesh=SkeletalMesh'KFBoss.Boss'
	PrePivot=(Z=9.000000)
	Skins(0)=FinalBlend'KFPatch2.BossHairFB'
	Skins(1)=Texture'KFPatch2.BossBits'
	Skins(2)=Texture'KFPatch2.GunPoundSkin'
	Skins(3)=Texture'KFPatch2.BossGun'
	Skins(4)=Texture'KFPatch2.BossBits'
	Skins(5)=Texture'KFPatch2.BossBits'
	Skins(6)=Shader'KFPatch2.LaserShader'
	bNetNotify=False
	Mass=1000.000000
	RotationRate=(Yaw=36000,Roll=0)
	AmmunitionClass=Class'KFChar.BossAmmo'
}
