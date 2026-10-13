// Zombie Monster for KF Invasion gametype

class ZombieBoss extends KFMonster;

#exec OBJ LOAD FILE=KFBoss.ukx
#exec OBJ LOAD FILE=KFPatch2.utx
var bool bChargingPlayer,bClientCharg,bFireAtWill,bMinigunning,bCanMoveChaingunning,bIsBossView;
var float RageStartTime,LastChainGunTime,LastMissileTime,LastSneakedTime,LastChargeTime,LastDriveByTime;

var bool bClientMiniGunning;

var name ChargingAnim;		// How he runs when charging the player.
var byte SyringeCount,ClientSyrCount,MGFireCounter,DriveByShots;

var BossHPNeedle CurrentNeedle;

var vector TraceHitPos;
var Emitter mTracer,mMuzzleFlash;
var bool bClientCloaked;
var float LastCheckTimes;
var KFHumanPawn LocalKFHumanPawn;
var int HealingLevels[3],HealingAmount,MissilesLeft;

var float ChaingunFireInterval, ChaingunMinInterval, ChaingunRampStep, ChaingunCurrentInterval;   
var int ChaingunDmg, ChaingunDmgRand;
var int MissileDamage, MissileRadius;

var bool bHealPending,bMissileWindup;
var float NextAttackDecisionTime,NextDriveByTime,NextChargeTime,NextFearTime,MissileWindupEndTime,FlankEndTime;

var() float AttackDecisionInterval;
var() float SneakWeight,DriveByWeight,ChargeWeight,MissileWeight,ChaingunWeight,IdleWeight,ChaingunCloseScale;
var() float SneakMinDist,FlankTimeout,StalkDuration;
var() float MissileInterval,MissileWindupTimeout;
var() float ImpaleHealthPct;

var bool bHealing,bSkipFlank,bWasShotAnim,bEnemyUnreachable;
var float ShotAnimStartTime,LastSawTargetTime,NextRetargetTime,NextThreatCheckTime,NextTargetCheckTime;
var float LastReachTime,ChargeBreakDist,NextTauntTime,CloakFlickerEndTime,NextFlickerTime,NextTargetSwitchTime;
var int KiteDamage;

var() float ShotAnimTimeout,KnockDownTimeout;
var bool bHealSyringeDone,bHealApplied;
var float HealStartTime,EscapeStartTime,EscapeCheckTime;
var vector EscapeCheckPos;
var() float HealSyringeTime,HealApplyTime,HealDuration;
var() float EscapeStuckDist,EscapeStuckTime,EscapeMaxTime;
var() float ChaingunBackoffDist,ChaingunHoldDist,ChaingunLostSightTime,ChaingunRetargetTime,CoverRocketChance,CoverRocketMinDist;
var() float TargetCheckInterval,TargetMinHoldTime,TargetSwitchRatio,TargetVisibleBonus,TargetBusyBonus,TargetIsolatedBonus,TargetWeakBonus,TargetUnreachableScale,UnreachableRangedScale;
var() float SplashOffsets[4];
var() int BarrageClusterCount,BarrageExtra,BarrageMax;
var() float KiteGraceTime,KiteRampTime,KiteDamagePct,KiteWeightScale,KiteChargeRange;
var() float TauntInterval;
var() float CloakFlickerTime,CloakFlickerCooldown;

replication
{
	reliable if( Role==ROLE_Authority )
		bChargingPlayer,SyringeCount,TraceHitPos,bMinigunning,bCanMoveChaingunning,bIsBossView;
}

simulated function Tick(float DeltaTime)
{
    local PlayerController PC;
	local bool bWasSpotted;

	Super.Tick(DeltaTime);

	if( Role==ROLE_Authority )
		ServerUpkeep();

	if( Level.NetMode==NM_DedicatedServer )
		Return; // Servers aren't intrested in this info.

	bSpecialCalcView = bIsBossView;

    if( LocalKFHumanPawn == None || LocalKFHumanPawn.Health <= 0 )
    {
        PC = Level.GetLocalPlayerController();
        if( PC != None && PC.Pawn != None )
            LocalKFHumanPawn = KFHumanPawn(PC.Pawn);
    }

	if( bCloaked && Level.TimeSeconds>LastCheckTimes )
	{
		LastCheckTimes = Level.TimeSeconds+0.5;
		bWasSpotted = bSpotted;
		bSpotted = ( LocalKFHumanPawn != none && LocalKFHumanPawn.Health > 0 && LocalKFHumanPawn.ShowStalkers()
			&& VSize(Location - LocalKFHumanPawn.Location) < 800.f );
		if( bSpotted!=bWasSpotted )
			CloakBoss();
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
	bUnlit = false;
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
    Super.PostBeginPlay();

    if( Role < ROLE_Authority )
        return;

	MissileDamage = Level.Game.GameDifficulty * 25 + 125; // 150 damage on easy, 200 on normal, 250 on skilled
	MissileRadius = Level.Game.GameDifficulty * 10 + 300; // 315 radius on easy, 330 on normal, 350 on skilled

	ChaingunDmg = Level.Game.GameDifficulty * 1 + 3; // 4.5 damage on easy, 6 on normal, 7 on skilled
	ChaingunDmgRand = Level.Game.GameDifficulty * 1 + 2; // 3 damage random on easy, 4 on normal, 5 on skilled

	if(Level.Game.GameDifficulty <= 3.0)
		ChaingunMinInterval = 0.06;
	else if(Level.Game.GameDifficulty <= 5.0)
		ChaingunMinInterval = 0.045;
	else
		ChaingunMinInterval = 0.04;

	HealingLevels[0] = Health/1.5; 
	HealingLevels[1] = Health/2.f; 
	HealingLevels[2] = Health/3.5; 
	HealingAmount = Health/3; 
	LastReachTime = Level.TimeSeconds;
}

function bool MakeGrandEntry()
{
    bShotAnim = true;
    Acceleration = vect(0,0,0);
    SetAnimAction('Entrance');
    Controller.GoToState('WaitForAnim');
    GoToState('StalkingEntry');

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

function bool NeedsHeal()
{
	Return Health>0 && !bHealing && SyringeCount<3 && Health<HealingLevels[SyringeCount];
}

function bool IsHealRetreating()
{
	Return IsInState('Escaping') && !IsInState('SneakAround');
}

function StartHealEscape()
{
	bHealPending = false;
	bHealing = false;
	ResetKite();
	bShotAnim = true;
	Acceleration = vect(0,0,0);
	SetAnimAction('KnockDown');
	Controller.GoToState('WaitForAnim');
	Taunt(2);
	GoToState('Escaping');
}

function ServerUpkeep()
{
	if( Health<=0 || bIsBossView )
		Return;

	if( bShotAnim )
	{
		if( !bWasShotAnim )
			ShotAnimStartTime = Level.TimeSeconds;
		else if( !bHealing && !IsInState('FireMissile') && ((IsHealRetreating() && Level.TimeSeconds-ShotAnimStartTime>KnockDownTimeout)
			|| Level.TimeSeconds-ShotAnimStartTime>ShotAnimTimeout) )
		{
			bShotAnim = false;
			bWaitForAnim = false;
			if( Controller!=None )
			{
				Controller.bPreparingMove = false;
				if( Controller.IsInState('WaitForAnim') )
					MonsterController(Controller).WhatToDoNext(99);
			}
		}
	}
	bWasShotAnim = bShotAnim;

	if( bHealing )
	{
		bShotAnim = true;
		bPhysicsAnimUpdate = false;
		Acceleration = vect(0,0,0);
		if( Level.TimeSeconds-HealStartTime>=HealSyringeTime )
			CountSyringe();
		if( Level.TimeSeconds-HealStartTime>=HealApplyTime )
			ApplyHeal();
		if( Level.TimeSeconds-HealStartTime>=HealDuration )
			FinishHeal();
	}

	if( bHealPending && !bShotAnim )
	{
		bHealPending = false;
		if( NeedsHeal() && !IsHealRetreating() )
			StartHealEscape();
	}

	if( CloakFlickerEndTime>0 && Level.TimeSeconds>=CloakFlickerEndTime )
	{
		CloakFlickerEndTime = 0;
		if( !bCloaked && !bShotAnim && WantsCloak() )
			CloakBoss();
	}

	if( Level.TimeSeconds>=NextTargetCheckTime )
	{
		NextTargetCheckTime = Level.TimeSeconds+TargetCheckInterval;
		if( Controller!=None && Health>0 && !bShotAnim && GetStateName()==Class.Name )
			ChooseTarget();
	}
}

function CountSyringe()
{
	if( bHealSyringeDone )
		Return;
	bHealSyringeDone = true;
	if( SyringeCount<3 )
		SyringeCount++;
	if( Level.NetMode!=NM_DedicatedServer )
		PostNetReceive();
}

function ApplyHeal()
{
	if( bHealApplied )
		Return;
	bHealApplied = true;
	Health += HealingAmount;
}

function FinishHeal()
{
	bHealing = false;
	bShotAnim = false;
	bWaitForAnim = false;
	bPhysicsAnimUpdate = Default.bPhysicsAnimUpdate;
	if( Controller!=None )
	{
		Controller.bPreparingMove = false;
		if( Controller.IsInState('WaitForAnim') )
			MonsterController(Controller).WhatToDoNext(99);
	}
}

function bool WantsCloak()
{
	Return IsInState('Escaping') || IsInState('StalkingEntry') || IsInState('DriveByRetreat');
}

function Taunt( int i )
{
	if( Health<=0 || Level.TimeSeconds<NextTauntTime || i>=MoanVoice.Length || MoanVoice[i]==None )
		Return;
	NextTauntTime = Level.TimeSeconds+TauntInterval;
	PlaySound(MoanVoice[i], SLOT_Talk, 2*TransientSoundVolume,, 1200);
}

function CheckKill( Actor A )
{
	if( KFHumanPawn(A)!=None && Pawn(A).Health<=0 )
		Taunt(3);
}

function int CountLivingHumans()
{
	local Controller C;
	local int n;

	For( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		if( C.bIsPlayer && KFHumanPawn(C.Pawn)!=None && C.Pawn.Health>0 )
			n++;
	}
	Return n;
}

function ResetKite()
{
	LastReachTime = Level.TimeSeconds;
	KiteDamage = 0;
}

function float KitePressure()
{
	Return FClamp((Level.TimeSeconds-LastReachTime-KiteGraceTime)/KiteRampTime, 0.0, 1.0)
		* FClamp(float(KiteDamage)/(HealthMax*KiteDamagePct), 0.0, 1.0);
}

function bool IsIsolated( Pawn P )
{
	local Controller C;

	For( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		if( C.bIsPlayer && C.Pawn!=None && C.Pawn!=P && C.Pawn.Health>0 && KFHumanPawn(C.Pawn)!=None && VSize(C.Pawn.Location-P.Location)<500 )
			Return False;
	}
	Return True;
}

function float RateTarget( KFHumanPawn P )
{
	local float S;

	S = FClamp(1500.f/FMax(VSize(P.Location-Location),1.f), 0.4, 3.0);
	if( Controller.LineOfSightTo(P) )
		S *= TargetVisibleBonus;
	if( (KFWeapon(P.Weapon)!=None && KFWeapon(P.Weapon).bIsReloading) || Syringe(P.Weapon)!=None || Welder(P.Weapon)!=None )
		S *= TargetBusyBonus;
	if( P.Health<50 )
		S *= TargetWeakBonus;
	if( IsIsolated(P) )
		S *= TargetIsolatedBonus;
	Return S;
}

function bool CanReach( Pawn P )
{
	Return Controller.ActorReachable(P) || Controller.FindPathToward(P)!=None;
}

function ChooseTarget()
{
	local Controller C;
	local KFHumanPawn P,Best;
	local float S,BestS,CurS;
	local bool bBestUnreachable;

	For( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		P = KFHumanPawn(C.Pawn);
		if( !C.bIsPlayer || P==None || P.Health<=0 || P.bIsDowned )
			continue;
		if( P!=Controller.Enemy && !Controller.LineOfSightTo(P) )
			continue;
		S = RateTarget(P);
		if( P==Controller.Enemy )
			CurS = S;
		if( Best==None || S>BestS )
		{
			Best = P;
			BestS = S;
		}
	}
	if( Best==None )
		Return;

	if( KFHumanPawn(Controller.Enemy)!=None && Controller.Enemy.Health>0 )
	{
		bEnemyUnreachable = !CanReach(Controller.Enemy);
		if( bEnemyUnreachable )
			CurS *= TargetUnreachableScale;
	}
	else CurS = 0;
	if( Best==Controller.Enemy || (CurS>0 && Level.TimeSeconds<NextTargetSwitchTime) )
		Return;

	bBestUnreachable = !CanReach(Best);
	if( bBestUnreachable )
		BestS *= TargetUnreachableScale;
	if( BestS>CurS*TargetSwitchRatio )
	{
		MonsterController(Controller).ChangeEnemy(Best, Controller.CanSee(Best));
		bEnemyUnreachable = bBestUnreachable;
		NextTargetSwitchTime = Level.TimeSeconds+TargetMinHoldTime;
	}
}

function Pawn FindMeleeThreat()
{
	local Controller C;

	For( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		if( C.bIsPlayer && KFHumanPawn(C.Pawn)!=None && C.Pawn.Health>0 && !KFHumanPawn(C.Pawn).bIsDowned && IsCloseEnuf(C.Pawn) )
			Return C.Pawn;
	}
	Return None;
}

function int CountClustered( Actor Centre )
{
	local Controller C;
	local int n;

	if( Centre==None )
		Return 0;
	For( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		if( C.bIsPlayer && KFHumanPawn(C.Pawn)!=None && C.Pawn.Health>0 && VSize(C.Pawn.Location-Centre.Location)<MissileRadius )
			n++;
	}
	Return n;
}

function bool FindSplashPoint( Pawn T, vector Start, out vector P )
{
	local vector Lead,Feet,Side,C,HL,HN;
	local int i;

	if( FastTrace(T.Location, Start) )
	{
		if( T.Physics!=PHYS_Walking )
			Return False;
		Lead = T.Location + T.Velocity*FMin(VSize(T.Location-Start)/class'BossLAWProj'.default.Speed, 1.0);
		Feet = Lead - vect(0,0,1)*T.CollisionHeight;
		if( !FastTrace(Feet, Start) )
			Return False;
		P = Feet;
		Return True;
	}

	Side = Normal((T.Location-Start) Cross vect(0,0,1));
	for( i=0; i<ArrayCount(SplashOffsets); i++ )
	{
		C = T.Location + Side*SplashOffsets[i];
		if( Trace(HL,HN,C-vect(0,0,300),C,false)==None )
			continue;
		HL.Z += 8;
		if( VSize(HL-T.Location)<MissileRadius*0.8 && FastTrace(HL, Start) && FastTrace(T.Location, HL) )
		{
			P = HL;
			Return True;
		}
	}
	Return False;
}

function SetMissileCooldown()
{
	LastMissileTime = Level.TimeSeconds + (10 + FRand() * 10)
		* FClamp(1.0 - Level.Game.GameDifficulty * 0.06 - FMax(Level.Game.NumPlayers - 1, 0) * 0.04, 0.3, 1.0);
}

function StartMissileAttack()
{
	bShotAnim = true;
	Acceleration = vect(0,0,0);
	SetAnimAction('PreFireMG');
	Controller.GoToState('WaitForAnim');
	Taunt(0);
	GoToState('FireMissile');
}

function SpawnChaingunFear( vector HL )
{
	local AvoidMarker Fear;

	if( Level.TimeSeconds<NextFearTime )
		Return;
	NextFearTime = Level.TimeSeconds+0.25;
	Fear = Spawn(class'AvoidMarker',,, HL);
	if( Fear==None )
		Return;
	Fear.SetCollisionSize(60, 60);
	Fear.StartleBots();
	Fear.LifeSpan = 2.f;
}

function RangedAttack(Actor A)
{
	local float D,Total,Pick,Pressure;
	local float W[5];
	local bool bOnlyE,bLOS;
	local int i;

	if ( bShotAnim )
		return;
	D = VSize(A.Location-Location);
	if ( IsCloseEnuf(A) )
	{
		LastReachTime = Level.TimeSeconds;
		bShotAnim = true;
		Acceleration = (A.Location-Location);
		Controller.MoveTarget = A;
		Controller.MoveTimer = 0.8;
		if( Health>HealthMax*ImpaleHealthPct && Pawn(A)!=None && OnlyEnemyAround(Pawn(A)) && FRand()<0.85 )
			SetAnimAction('MeleeImpale');
		else
		{
			SetAnimAction('MeleeClaw');
			PlaySound(sound'Claw2s', SLOT_None);
		}
		return;
	}

	if( Level.TimeSeconds<NextAttackDecisionTime )
		return;
	NextAttackDecisionTime = Level.TimeSeconds+AttackDecisionInterval;

	bOnlyE = (Pawn(A)!=None && OnlyEnemyAround(Pawn(A)));
	if( bChargingPlayer && (bOnlyE || D<200) )
		return;
	bLOS = Controller.LineOfSightTo(A);
	Pressure = KitePressure();

	if( LastSneakedTime<Level.TimeSeconds && D>=SneakMinDist )
		W[0] = SneakWeight;
	if( !bChargingPlayer && D>500 && D<1500 && NextDriveByTime<Level.TimeSeconds )
		W[1] = DriveByWeight*(1.0+Pressure*KiteWeightScale);
	if( !bChargingPlayer && !bEnemyUnreachable && NextChargeTime<Level.TimeSeconds
	 && (D<300 || (D<700 && bOnlyE) || (Pressure>=1.0 && D<KiteChargeRange && bLOS)) )
		W[2] = ChargeWeight*(1.0+Pressure*KiteWeightScale);
	if( LastMissileTime<Level.TimeSeconds && D>500 && bLOS )
		W[3] = MissileWeight*FClamp(0.25 + Level.Game.GameDifficulty * 0.05 + FMax(Level.Game.NumPlayers - 1, 0) * 0.05, 0.25, 0.85);
	if( LastChainGunTime<Level.TimeSeconds && bLOS )
	{
		W[4] = ChaingunWeight;
		if( W[2]>0 )
			W[4] *= ChaingunCloseScale;
	}
	if( bEnemyUnreachable )
	{
		W[3] *= UnreachableRangedScale;
		W[4] *= UnreachableRangedScale;
	}

	Total = IdleWeight;
	for( i=0; i<ArrayCount(W); i++ )
		Total += W[i];
	Pick = FRand()*Total;
	for( i=0; i<ArrayCount(W); i++ )
	{
		if( Pick<W[i] )
			break;
		Pick -= W[i];
	}

	switch( i )
	{
		case 0:
			bShotAnim = true;
			Acceleration = vect(0,0,0);
			SetAnimAction('BossHitF');
			GoToState('SneakAround');
			Controller.GoToState('WaitForAnim');
			break;
		case 1:
			ResetKite();
			bShotAnim = true;
			Acceleration = vect(0,0,0);
			SetAnimAction('PreFireMG');
			Controller.GoToState('WaitForAnim');
			GoToState('DriveByAttack');
			break;
		case 2:
			ResetKite();
			ChargeBreakDist = FMax(800.f, D+300.f);
			bShotAnim = true;
			Acceleration = vect(0,0,0);
			SetAnimAction('BossHitF');
			Taunt(1);
			GoToState('Charging');
			Controller.GoToState('WaitForAnim');
			break;
		case 3:
			SetMissileCooldown();
			StartMissileAttack();
			break;
		case 4:
			LastChainGunTime = Level.TimeSeconds+10+FRand()*8;
			bShotAnim = true;
			Acceleration = vect(0,0,0);
			SetAnimAction('PreFireMG');
			Controller.GoToState('WaitForAnim');
			MGFireCounter = Rand(20);
			GoToState('FireChaingun');
			break;
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
    local name Sequence;
    local float Frame, Rate;

    if( Level.NetMode==NM_Client && bMinigunning )
    {
		GetAnimParams(Channel, Sequence, Frame, Rate);
        if (Sequence != 'PreFireMG' && Sequence != 'FireMG')
        {
            // SetBoneDirection(FireRootBone,rot(0,0,0),,0,0);
            super(KFMonster).AnimEnd(Channel);
            return;
		}
        if( bCanMoveChaingunning )
            DoAnimAction('FireMG');
        else
        {
            PlayAnim('FireMG');
			bWaitForAnim = true;
            bShotAnim = true;
            IdleTime = Level.TimeSeconds;
        }
        //bWaitForAnim = true;
    }
    else Super.AnimEnd(Channel);
}

State StalkingEntry
{
    function bool CanSpeedAdjust()
    {
        return false;
    }
    function RangedAttack(Actor A)
    {
        // Uncloak and attack once close to a player
        if( VSize(A.Location - Location) < 600 )
        {
            UnCloakBoss();
            GoToState('');
            Global.RangedAttack(A);
        }
    }
    function EndState()
    {
        // Prevent immediate re-sneaking after initial stalk
        LastSneakedTime = Level.TimeSeconds + 20.0 + FRand() * 30.0;
        ResetKite();
    }
    function Tick(float Delta)
    {
        Global.Tick(Delta);
        SetGroundSpeed(OriginalGroundSpeed * 2.0);
    }
Begin:
    // Wait for entrance animation to finish
    While( bShotAnim )
        Sleep(0.25);
Stalk:
    CloakBoss();
    Sleep(StalkDuration);
    // Timeout - uncloak and fight normally
    UnCloakBoss();
    GoToState('');
}
State FireChaingun
{
	function bool CanSpeedAdjust()
	{
		return false;
	}
	function RangedAttack(Actor A)
	{
		if( Pawn(Controller.Target)==None || Pawn(Controller.Target).Health<=0 )
			Controller.Target = A;
		Controller.Focus = Controller.Target;
	}
	function EndState()
	{
		bChargingPlayer = false;
		TraceHitPos = vect(0,0,0);
		bMinigunning = False;
		bCanMoveChaingunning = False;
		bFireAtWill = False;
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
		SavedFireProperties.bInitialized = false; // Reset saved properties
		if(SyringeCount >= 1)
			bCanMoveChaingunning = true;
        ChaingunCurrentInterval = ChaingunFireInterval;
		LastSawTargetTime = Level.TimeSeconds;
		NextRetargetTime = Level.TimeSeconds+ChaingunRetargetTime;
		MissileWindupEndTime = Level.TimeSeconds+MissileWindupTimeout;
	}
	function Tick( float Delta )
	{
		local vector Away,HL,HN;
		local float D;

		Super(KFMonster).Tick(Delta);
		if( !bFireAtWill || !bCanMoveChaingunning )
			Acceleration = vect(0,0,0);
		if( bChargingPlayer ) //Run for it!
			SetGroundSpeed(OriginalGroundSpeed * 2.1);
		else SetGroundSpeed(OriginalGroundSpeed * 1.15);
		if(bFireAtWill)
		{
			ChaingunCurrentInterval -= ChaingunRampStep * (Delta / 0.01667);
			if (ChaingunCurrentInterval < ChaingunMinInterval)
				ChaingunCurrentInterval = ChaingunMinInterval;
			if( Controller.Target!=None )
				Controller.Focus = Controller.Target;
			if( bCanMoveChaingunning && !bChargingPlayer && Controller.Enemy!=None )
			{
				Away = Location-Controller.Enemy.Location;
				Away.Z = 0;
				D = VSize(Away);
				if( D<ChaingunBackoffDist )
				{
					Away = Normal(Away);
					if( Trace(HL,HN,Location+Away*80-vect(0,0,1)*(CollisionHeight+60),Location+Away*80,false)!=None )
						Acceleration = Away*AccelRate;
					else Acceleration = vect(0,0,0);
				}
				else if( D<ChaingunHoldDist )
					Acceleration = vect(0,0,0);
			}
		}
	}
	function AnimEnd( int Channel )
	{
		if( bFireAtWill && bCanMoveChaingunning )
		{
			if( Channel!=1 )
				return;
		}
		else if( Channel!=0 )
			return;
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
			if( bFireAtWill )
			{
				// Firing phase — loop FireMG directly on channel 1
				// Don't use SetAnimAction, it re-sets bWaitForAnim and freezes walk anim
				SetAnimAction('FireMG');
				bPhysicsAnimUpdate = Default.bPhysicsAnimUpdate;
			}
			else
			{
				// PreFireMG ended — free controller for movement, start firing
				bShotAnim = false;
				bWaitForAnim = false;
				bFireAtWill = True;
				LastSawTargetTime = Level.TimeSeconds;
				if( Controller.Target != None )
					Controller.Focus = Controller.Target;
				bPhysicsAnimUpdate = Default.bPhysicsAnimUpdate;
				// Play FireMG directly on channel 1 — leaves bWaitForAnim false
				// so the movement system can start walk anim on channel 0 next tick
				SetAnimAction('FireMG');
			}
		}
		else
		{
			// Stationary firing (original behavior)
			if( !bFireAtWill )
				LastSawTargetTime = Level.TimeSeconds;
			bFireAtWill = True;
			bShotAnim = true;
			Acceleration = vect(0,0,0);
			PlayAnim('FireMG');
			bWaitForAnim = true;
		}
	}
	function PickChaingunTarget()
	{
		local Controller C;
		local KFHumanPawn P,Best;
		local vector Start;
		local float S,BestS;

		Start = GetBoneCoords('tip').Origin;
		For( C=Level.ControllerList; C!=None; C=C.NextController )
		{
			P = KFHumanPawn(C.Pawn);
			if( !C.bIsPlayer || P==None || P.Health<=0 || P.bIsDowned || P==Controller.Target || !FastTrace(P.Location,Start) )
				continue;
			S = RateTarget(P)*(0.5+FRand());
			if( Best==None || S>BestS )
			{
				Best = P;
				BestS = S;
			}
		}
		if( Best!=None )
		{
			Controller.Target = Best;
			Controller.Focus = Best;
			LastSawTargetTime = Level.TimeSeconds;
		}
	}
	function bool ChaingunThink()
	{
		local Pawn T,Threat;

		if( Level.TimeSeconds>=NextThreatCheckTime )
		{
			NextThreatCheckTime = Level.TimeSeconds+0.2;
			Threat = FindMeleeThreat();
			if( Threat!=None )
			{
				bShotAnim = false;
				bWaitForAnim = false;
				GoToState('');
				MonsterController(Controller).ChangeEnemy(Threat, true);
				Controller.Target = Threat;
				Controller.Focus = Threat;
				if( Controller.IsInState('WaitForAnim') )
					MonsterController(Controller).WhatToDoNext(99);
				RangedAttack(Threat);
				Return False;
			}
		}

		T = Pawn(Controller.Target);
		if( T!=None && T.Health>0 && FastTrace(T.Location, GetBoneCoords('tip').Origin) )
			LastSawTargetTime = Level.TimeSeconds;
		if( Level.TimeSeconds>=NextRetargetTime || T==None || T.Health<=0 || Level.TimeSeconds-LastSawTargetTime>0.4 )
		{
			NextRetargetTime = Level.TimeSeconds+ChaingunRetargetTime;
			PickChaingunTarget();
		}

		if( Level.TimeSeconds-LastSawTargetTime>ChaingunLostSightTime )
		{
			if( FRand()<CoverRocketChance && Controller.Target!=None && VSize(Controller.Target.Location-Location)>CoverRocketMinDist )
			{
				SetMissileCooldown();
				StartMissileAttack();
			}
			else
			{
				bShotAnim = true;
				Acceleration = vect(0,0,0);
				SetAnimAction('FireEndMG');
				GoToState('');
			}
			Return False;
		}
		Return True;
	}
	function FireMGShot()
	{
		local vector Start, End, HL, HN, Dir;
		local rotator Aim;
		local Actor A;

		Start = GetBoneCoords('tip').Origin;

		if ( !SavedFireProperties.bInitialized )
		{
			SavedFireProperties.AmmoClass = MyAmmo.Class;
			SavedFireProperties.ProjectileClass = None;       // no projectile - this is hitscan
			SavedFireProperties.WarnTargetPct = 0.55f;
			SavedFireProperties.MaxRange = 10000;
			SavedFireProperties.bTossed = False;
			SavedFireProperties.bLeadTarget = False;          // instant hit, no lead
			SavedFireProperties.bInstantHit = True;           // CRITICAL - enables InstantWarnTarget
			SavedFireProperties.bInitialized = true;
		}

        Aim = AdjustAim(SavedFireProperties, Start, 100);
        Dir = Normal(vector(Aim) + VRand() * 0.07);
        End = Start + Dir * 10000;
        A = Trace(HL, HN, End, Start, True);
		if ( A == None )
			Return;

		TraceHitPos = HL;
		if ( Level.NetMode != NM_DedicatedServer )
			AddTraceHitFX(HL);

		Dir.Z = 0.0;
		if ( A != Level )
		{
			A.TakeDamage(ChaingunDmg + Rand(ChaingunDmgRand), Self, HL, Dir * 500, Class'DamTypeBossChaingun');
			CheckKill(A);
		}

		SpawnChaingunFear(HL);
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
        if( !bFireAtWill && Level.TimeSeconds>MissileWindupEndTime )
            AnimEnd(0);
        if( bFireAtWill && ChaingunThink() )
            FireMGShot();
        Sleep(ChaingunCurrentInterval);
    }
}

State FireMissile
{
	function Tick( float Delta )
	{
		Global.Tick(Delta);
		Acceleration = vect(0,0,0);
	}
	function BeginState()
	{
		Acceleration = vect(0,0,0);
		if(SyringeCount>=2)
			MissilesLeft = 3 + int(Level.Game.NumPlayers > 4);
		else if(Level.Game.GameDifficulty >= 5.0 || Level.Game.NumPlayers >= 4)
			MissilesLeft = 2 + Rand(2);
		else MissilesLeft = 1 + Rand(2);
		if( CountClustered(Controller.Target)>=BarrageClusterCount )
			MissilesLeft = Min(MissilesLeft+BarrageExtra, BarrageMax);
		bMissileWindup = true;
		MissileWindupEndTime = Level.TimeSeconds+MissileWindupTimeout;
		SavedFireProperties.bInitialized = false; // Reset saved properties
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
		if( bMissileWindup && Channel==0 )
			FireMissileNow();
	}
	function FireMissileNow()
	{
		local Vector Start,Splash;
		local Rotator R;
		local Projectile P;

		bMissileWindup = false;
		Start = GetBoneCoords('tip').Origin;
		if ( !SavedFireProperties.bInitialized )
		{
			SavedFireProperties.AmmoClass = MyAmmo.Class;
			SavedFireProperties.ProjectileClass = MyAmmo.ProjectileClass;
			SavedFireProperties.WarnTargetPct = 0.95f;
			SavedFireProperties.MaxRange = 10000;
			SavedFireProperties.bTossed = False;
			SavedFireProperties.bLeadTarget = True;
			SavedFireProperties.bInitialized = true;
		}
		R = AdjustAim(SavedFireProperties,Start,80);
		if( Pawn(Controller.Target)!=None && FindSplashPoint(Pawn(Controller.Target), Start, Splash) )
			R = rotator(Splash-Start);
		PlaySound(Sound'KFWeaponSound.LAWFire', SLOT_Interact);
		P = Spawn(SavedFireProperties.ProjectileClass,,,Start,R);
		if( P != None )
		{
			P.Damage = MissileDamage;
			P.DamageRadius = MissileRadius;
		}
		bShotAnim = true;
		Acceleration = vect(0,0,0);
		SetAnimAction('FireEndMG');
		if( --MissilesLeft<=0 )
			GoToState('');
		else GoToState(,'FireMore');
	}
Begin:
	While( True )
	{
		Acceleration = vect(0,0,0);
		Sleep(0.1);
		if( bMissileWindup && Level.TimeSeconds>MissileWindupEndTime )
			FireMissileNow();
	}
FireMore:
	Acceleration = vect(0,0,0);
	Sleep(MissileInterval);
	FireMissileNow();
}

function bool MeleeDamageTarget(int hitdamage, vector pushdir)
{
	local bool RetVal;

	if( Controller==None )
		Return False;
	MeleeRange*=7;    //MeleeRange*=7;
	if( Controller.Target!=None && Controller.Target.IsA('NetKActor') )
		pushdir = Normal(Controller.Target.Location-Location)*100000; // Fly bitch!
	if( CurrentDamtype==None )
		CurrentDamtype = ZombieDamType[0];
	RetVal = Super.MeleeDamageTarget(hitdamage, pushdir);
	MeleeRange = Default.MeleeRange;
	if( RetVal )
	{
		ResetKite();
		CheckKill(Controller.Target);
	}
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
		NextChargeTime = Level.TimeSeconds+5.0+5.0*FRand();
	}
	function Tick( float Delta )
	{
		SetGroundSpeed(OriginalGroundSpeed * 3.0);
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
		if( VSize(A.Location-Location)>ChargeBreakDist )
			GoToState('');
		Global.RangedAttack(A);
	}
Begin:
	Sleep(7);
	GoToState('');
}

function BeginHealing()
{
	MonsterController(Controller).WhatToDoNext(55);
}

State Escaping extends Charging // Got hurt and running away...
{
	function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
	{
		// He's takes less damage while escaping
		Damage *= 0.5;
		Super.TakeDamage(Damage,instigatedBy,hitlocation,vect(0,0,0),damageType);
	}
	function BeginHealing()
	{
		bHealing = true;
		bSkipFlank = true;
		bHealSyringeDone = false;
		bHealApplied = false;
		HealStartTime = Level.TimeSeconds;
		bShotAnim = true;
		Acceleration = vect(0,0,0);
		SetAnimAction('Heal');
		//MonsterController(Controller).WhatToDoNext(56);
		Controller.GoToState('WaitForAnim');
		GoToState('SneakAround');
	}
	event Bump(actor Other) //GTFO!!!
    {
        local Pawn P;
        local vector PushDir;

        P = Pawn(Other);
        if ( P != None && P.Health > 0 && Velocity dot (P.Location - Location) > 0 ) // Only push if running toward them
        {
            PushDir = P.Location - Location;
            PushDir.Z = 0;
            PushDir = Normal(PushDir);
            P.Velocity += PushDir * 400 + vect(0,0,100);
            if ( P.Physics == PHYS_Walking )
                P.SetPhysics(PHYS_Falling);
            P.TakeDamage(5, Self, P.Location, PushDir * 10000, class'KFMod.ZombieMeleeDamage');
            return;
        }
        Global.Bump(Other);
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
	EscapeStartTime = Level.TimeSeconds;
	EscapeCheckTime = Level.TimeSeconds;
	EscapeCheckPos = Location;
	While( True )
	{
		Sleep(0.5);
		if( !bCloaked && !bShotAnim && CloakFlickerEndTime==0 )
			CloakBoss();
		if( !Controller.IsInState('SyrRetreat') )
			Controller.GoToState('SyrRetreat');
		if( !bShotAnim )
		{
			if( VSize(Location-EscapeCheckPos)>EscapeStuckDist )
			{
				EscapeCheckPos = Location;
				EscapeCheckTime = Level.TimeSeconds;
			}
			if( Level.TimeSeconds-EscapeCheckTime>EscapeStuckTime || Level.TimeSeconds-EscapeStartTime>EscapeMaxTime )
				BeginHealing();
		}
	}
}
State SneakAround extends Escaping // Attempt to sneak around.
{
	function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
	{
		Global.TakeDamage(Damage,instigatedBy,hitlocation,momentum,damageType);
	}
	function BeginHealing()
	{
		MonsterController(Controller).WhatToDoNext(56);
		GoToState('');
	}
	function EndState()
	{
		super.EndState();
		LastSneakedTime = Level.TimeSeconds+20.f+FRand()*30.f;
		if( Controller!=None && Controller.IsInState('PatFindWay') )
			Controller.GoToState('ZombieHunt');
	}
Begin:
    // Wait for heal animation to finish before sneaking
    While( bShotAnim || bHealing )
        Sleep(0.25);
    CloakBoss();
    if( bSkipFlank )
    {
        bSkipFlank = false;
        GoToState('StalkingEntry','Stalk');
    }
    BossZombieController(Controller).FindPathAround();
    FlankEndTime = Level.TimeSeconds+FlankTimeout;
    While( Controller.IsInState('PatFindWay') && Level.TimeSeconds<FlankEndTime )
    {
		Sleep(0.5);
		if( !bCloaked && !bShotAnim )
			CloakBoss();
	}
    GoToState('StalkingEntry','Stalk');
}

State DriveByAttack
{
    function bool CanSpeedAdjust()
    {
        return false;
    }
    function BeginState()
    {
		UnCloakBoss();
        bChargingPlayer = True;
        bMinigunning = True;
        bCanMoveChaingunning = True;
        bFireAtWill = False;
        DriveByShots = 0;
		SavedFireProperties.bInitialized = false; // Reset saved properties 
        if( Level.NetMode!=NM_DedicatedServer )
            PostNetReceive();
    }
    function EndState()
    {
        SetGroundSpeed(OriginalGroundSpeed);
        bChargingPlayer = False;
        bMinigunning = False;
        bCanMoveChaingunning = False;
        bFireAtWill = False;
        TraceHitPos = vect(0,0,0);
        if( Level.NetMode!=NM_DedicatedServer )
            PostNetReceive();
        if( bCloaked )
            UnCloakBoss();
        NextDriveByTime = Level.TimeSeconds+15.0+7.0*FRand();
    }
    function Tick( float Delta )
    {
        Super(KFMonster).Tick(Delta);
        if( bShotAnim && !bFireAtWill )
            Acceleration = vect(0,0,0);
        SetGroundSpeed(OriginalGroundSpeed * 2.5);
    }
    function RangedAttack(Actor A)
    {
        Controller.Target = A;
        Controller.Focus = A;
    }
    function AnimEnd( int Channel )
    {
        if( bFireAtWill )
        {
            // Firing phase — keep looping the chaingun anim on upper body
            if( Channel==1 )
            {
                bShotAnim = true;
                SetAnimAction('FireMG');
            }
            bPhysicsAnimUpdate = Default.bPhysicsAnimUpdate;
        }
        else
        {
            // Approach phase — PreFireMG ended, free up movement
            bShotAnim = false;
            bWaitForAnim = false;
            bPhysicsAnimUpdate = Default.bPhysicsAnimUpdate;
        }
    }
    function FireDriveByShot()
    {
        local vector Start, End, HL, HN, Dir;
        local rotator Aim;
        local Actor A;

        Start = GetBoneCoords('tip').Origin;
        if ( !SavedFireProperties.bInitialized )
        {
            SavedFireProperties.AmmoClass = MyAmmo.Class;
            SavedFireProperties.ProjectileClass = None;
            SavedFireProperties.WarnTargetPct = 0.55f;
            SavedFireProperties.MaxRange = 10000;
            SavedFireProperties.bTossed = False;
            SavedFireProperties.bLeadTarget = False;
            SavedFireProperties.bInstantHit = True;
            SavedFireProperties.bInitialized = true;
        }
        Aim = AdjustAim(SavedFireProperties, Start, 100);
        Dir = Normal(vector(Aim) + VRand() * 0.07);
        End = Start + Dir * 10000;
        A = Trace(HL, HN, End, Start, True);
        if ( A == None )
            Return;
        TraceHitPos = HL;
        if ( Level.NetMode != NM_DedicatedServer )
            AddTraceHitFX(HL);
        Dir.Z = 0.0;
        if ( A != Level )
        {
            A.TakeDamage(ChaingunDmg + Rand(ChaingunDmgRand), Self, HL, Dir * 500, Class'DamTypeBossChaingun');
            CheckKill(A);
        }
        SpawnChaingunFear(HL);
    }
Begin:
    if( Controller.Enemy == None )
    {
        bShotAnim = true;
        SetAnimAction('FireEndMG');
        Sleep(0.3);
        GoToState('');
    }
    // Approach phase — sprint toward enemy until close enough or have LOS
    While( Controller.Enemy != None &&
           (VSize(Controller.Enemy.Location - Location) > 800 || !Controller.LineOfSightTo(Controller.Enemy)) )
    {
        if( Controller.Enemy != None )
        {
            Controller.Target = Controller.Enemy;
            Controller.Focus = Controller.Enemy;
        }
        Sleep(0.2);
        DriveByShots++;
        if( DriveByShots > 20 || Controller.Enemy == None )
        {
            bShotAnim = true;
            SetAnimAction('FireEndMG');
            Sleep(0.3);
            GoToState('');
        }
    }
    DriveByShots = 0;
    While( DriveByShots < 15 )
    {
        if( !bFireAtWill )
        {
            bFireAtWill = True;
            bShotAnim = true;
            SetAnimAction('FireMG');
        }
        FireDriveByShot();
        DriveByShots++;
        Sleep(0.09);
    }
    // Burst done — end the chaingun anim and flee
    bShotAnim = true;
    SetAnimAction('FireEndMG');
    Sleep(0.3);
    GoToState('DriveByRetreat');
}

State DriveByRetreat
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
        if( bCloaked )
            UnCloakBoss();
        NextDriveByTime = Level.TimeSeconds+15.0+7.0*FRand();
        if( Controller!=None && Controller.IsInState('RunSomewhere') )
            Controller.GoToState('ZombieHunt');
    }
    function RangedAttack(Actor A)
    {
        // Don't attack while fleeing
    }
    function Tick( float Delta )
    {
        Global.Tick(Delta);
        SetGroundSpeed(OriginalGroundSpeed * 2.5);
    }
Begin:
    CloakBoss();
    Controller.GoToState('RunSomewhere');
    // Flee cloaked for a few seconds, then reappear
    Sleep(3 + FRand() * 3);
    UnCloakBoss();
    GoToState('');
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
		CountSyringe();
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
		ApplyHeal();
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
	if( ClientSyrCount!=SyringeCount )
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
	if( TraceHitPos!=vect(0,0,0) )
	{
		AddTraceHitFX(TraceHitPos);
		TraceHitPos = vect(0,0,0);
	}
	if( bClientCloaked!=bCloaked )
	{
		bClientCloaked = bCloaked;
		if( bCloaked )
			CloakBoss();
		else UnCloakBoss();
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
		AnimBlendParams(1, 1.0, 0.0,, FireRootBone);
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
	// He's a bit tanky
	if (DamageType == class 'DamTypeFrag' || DamageType == class 'DamTypeLAW')
		Damage *= 0.5;
	else Damage *= 0.75;

	if( ZombieBoss(InstigatedBy)==None ) // ignore damage from other patriarch and own rockets
		Super.TakeDamage(Damage,instigatedBy,hitlocation,vect(0,0,0),damageType);
	if( Health<=0 )
		Return;
	if( KFHumanPawn(instigatedBy)!=None )
		KiteDamage += Damage;
	if( bCloaked && Damage>0 && Level.TimeSeconds>=NextFlickerTime )
	{
		NextFlickerTime = Level.TimeSeconds+CloakFlickerTime+CloakFlickerCooldown;
		CloakFlickerEndTime = Level.TimeSeconds+CloakFlickerTime;
		UnCloakBoss();
	}
	if( IsHealRetreating() || !NeedsHeal() )
		Return;
	if( bShotAnim && !IsInState('FireChaingun') && !IsInState('FireMissile') && !IsInState('DriveByAttack') )
		bHealPending = true;
	else StartHealEscape();
}
function DoorAttack(Actor A)
{
	if ( bShotAnim )
		return;
	else if ( A!=None )
	{
		Controller.Target = A;
		StartMissileAttack();
	}
}
function RemoveHead();
function PlayDirectionalHit(Vector HitLoc);
function bool SameSpeciesAs(Pawn P)
{
	return False;
}

// Creapy endgame camera when the evil wins.
function bool SetBossLaught()
{
	local Controller C;

	GoToState('');
	bShotAnim = true;
	Acceleration = vect(0,0,0);
	SetAnimAction('VictoryLaugh');
	Controller.GoToState('WaitForAnim');
	bIsBossView = True;
	bSpecialCalcView = True;
	For( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		if( PlayerController(C)!=None )
		{
			PlayerController(C).SetViewTarget(Self);
			PlayerController(C).ClientSetViewTarget(Self);
			PlayerController(C).ClientSetBehindView(True);
		}
	}
	Return True;
}
simulated function bool SpectatorSpecialCalcView(PlayerController Viewer, out Actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
{
	Viewer.bBehindView = True;
	ViewActor = Self;
	CameraRotation.Yaw = Rotation.Yaw-32768;
	CameraRotation.Pitch = 0;
	CameraRotation.Roll = Rotation.Roll;
	CameraLocation = Location + (vect(80,0,80) >> Rotation);
	Return True;
}

// Overridden to do a cool slomo death view of the patriarch dying
function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	local Controller C;

    super.Died(Killer,damageType,HitLocation);

    KFGameType(Level.Game).DoBossDeath();

	For( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		if( PlayerController(C)!=None )
		{
			PlayerController(C).SetViewTarget(Self);
			PlayerController(C).ClientSetViewTarget(Self);
			PlayerController(C).bBehindView = true;
			PlayerController(C).ClientSetBehindView(True);
		}
	}
}

defaultproperties
{
	AttackDecisionInterval=0.400000
	SneakWeight=1.000000
	DriveByWeight=2.000000
	ChargeWeight=6.000000
	MissileWeight=5.000000
	ChaingunWeight=3.000000
	IdleWeight=10.000000
	ChaingunCloseScale=0.350000
	SneakMinDist=700.000000
	StalkDuration=20.000000
	MissileInterval=1.500000
	MissileWindupTimeout=3.000000
	ImpaleHealthPct=0.190000
	FlankTimeout=10.000000
	ShotAnimTimeout=7.000000
	KnockDownTimeout=2.000000
	HealSyringeTime=2.300000
	HealApplyTime=3.600000
	HealDuration=5.100000
	EscapeStuckDist=100.000000
	EscapeStuckTime=3.000000
	EscapeMaxTime=12.000000
	ChaingunBackoffDist=300.000000
	ChaingunHoldDist=550.000000
	ChaingunLostSightTime=1.500000
	ChaingunRetargetTime=1.500000
	CoverRocketChance=0.600000
	CoverRocketMinDist=400.000000
	TargetCheckInterval=2.000000
	TargetMinHoldTime=5.000000
	TargetSwitchRatio=1.500000
	TargetVisibleBonus=1.500000
	TargetBusyBonus=1.600000
	TargetIsolatedBonus=1.400000
	TargetWeakBonus=1.300000
	TargetUnreachableScale=0.300000
	UnreachableRangedScale=2.000000
	SplashOffsets(0)=160.000000
	SplashOffsets(1)=-160.000000
	SplashOffsets(2)=260.000000
	SplashOffsets(3)=-260.000000
	BarrageClusterCount=3
	BarrageExtra=2
	BarrageMax=5
	KiteGraceTime=8.000000
	KiteRampTime=10.000000
	KiteDamagePct=0.080000
	KiteWeightScale=3.000000
	KiteChargeRange=1200.000000
	TauntInterval=6.000000
	CloakFlickerTime=0.500000
	CloakFlickerCooldown=2.500000
	ChargingAnim="RunF"
	HealingLevels(0)=5600
	HealingLevels(1)=3500
	HealingLevels(2)=2187
	HealingAmount=1750
	MoanVoice(0)=Sound'WoodBreakFX.RocketArm'
	MoanVoice(1)=Sound'WoodBreakFX.ToldHerh'
	MoanVoice(2)=Sound'WoodBreakFX.NotRight'
	MoanVoice(3)=Sound'WoodBreakFX.Laugh'
	damageRand=25
	damageConst=50 //100 is too brutal
	ChaingunDmg=5
	ChaingunDmgRand=3
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
	GroundSpeed=130.000000
	WaterSpeed=130.000000
	HealthMax=8000.000000
	GibScale=1.400000
	Health=8000
	HeadHealth=8000
	ChaingunFireInterval=0.20
	ChaingunMinInterval=0.03
	ChaingunRampStep=0.001
	FireRootBone='Bip01 Spine1'
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
