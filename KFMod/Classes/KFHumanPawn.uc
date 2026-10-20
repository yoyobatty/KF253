//=============================================================================
// KFPawn - Assault
//=============================================================================
class KFHumanPawn extends KFPawn;

#exec OBJ LOAD FILE=KFCharacters.utx
#exec OBJ LOAD FILE=KFSoldiers.ukx

// --- Audio/Visual ---
var Emitter Blood;
var Sound BreathingSound;
var Sound MiscSound;
var() Material InjuredOverlay, CriticalOverlay;

// --- Camera/Effects ---
// How a hit jars the view (rotation in rotator units, offset in world units; a full jar at JarFullDamage)
var() float JarRotateMag, JarRotateRate, JarRotateTime;
var() float JarMoveMag, JarMoveRate, JarMoveTime;
var() float JarFullDamage;

// --- Player State ---
var int ScoreCounter;
var int AlphaAmount;
//var PlayerController PC;
var bool bAimingRifle;

// --- Inventory/Weight ---
var() float MaxCarryWeight;
var float CurrentWeight;
var() HeldWeapon RifleAtt, MeleeAtt;

var() int TorchBatteryLife;
var bool bTorchOn;
var int TempScore;

var() float SprintMulti;
var() float HealthSpeedModifier;
var bool bIsSprinting;

var int SpeedAdjustment;
var float BaseMeleeIncrease;

var float  CrouchEndTime;
var float  GroundTime;                        // seconds on the ground since landing, counted from the moves themselves
var() float JumpCrouchBonus, JumpCrouchTime;
var bool   bCrouchJumped;


//Revive system!! Hopefully this works!
var bool bIsDowned;
var() float DownedSpeedScale;    // Make us slow when down
var() float DownedBleedoutTime;  // Seconds before an downed player dies
var() float DownedRevivedHealth; // Health restored on a successful revive
var float DownedEndTime;

var bool bBeingRevived;
var Pawn Reviver;
var() float ReviveDuration, ReviveRadius;
var float ReviveProgress;

var() string DownedMessage, RevivedMessage, ReviveStartMessage, ReviveInterruptedMessage;
var() sound DownedSound, RevivedSound;

replication
{
    // (not to the player himself: his own machine decides his sprint and sends it with his moves, and the
    // server's copy coming back late would undo a sprint let go in the meantime)
    reliable if (Role == ROLE_Authority && !bNetOwner)
        bIsSprinting;

	reliable if ( bNetDirty && (Role == Role_Authority) )
		bAimingRifle, bIsDowned, bBeingRevived, Reviver;

	reliable if ( bNetDirty && (Role == Role_Authority) && bNetOwner )
		CurrentWeight,MaxCarryWeight,AlphaAmount,bTorchOn,TorchBatteryLife;

	reliable if(RemoteRole == ROLE_AutonomousProxy)
		DoHitCamEffects, ClientSprintDenied;

	reliable if(Role < ROLE_Authority)
		SetAiming,ServerStartSprintKF,ServerStopSprintKF;
}

function CheckCarryWeight()
{
	local Inventory I;

	MaxCarryWeight = Default.MaxCarryWeight+GetVeteran().Static.AddCarryMaxWeight();
	if( CurrentWeight>MaxCarryWeight ) // Now carrying too much, drop something.
	{
		For( I=Inventory; I!=None; I=I.Inventory )
		{
			if( KFWeapon(I)!=None && !KFWeapon(I).bKFNeverThrow )
			{
				I.Velocity = Velocity;
				I.DropFrom(Location+VRand()*10);
				if( CurrentWeight<=MaxCarryWeight )
					Return; // Drop weapons until player is capable of carrying them all.
			}
		}
	}
}

event PreBeginPlay()
{
	Super.PreBeginPlay();
	SetTimer(1.5,true);
}

// A player's walls go to HitWall below (a bot's go to its NotifyHitWall)
function PossessedBy(Controller C)
{
	Super.PossessedBy(C);
	bDirectHitWall = (PlayerController(C)!=None);
}

// Walking into glass bumps it here, as the engine does not: between waves a player meets the glass's stand-in
// (KFGlassBlocker), which is world geometry and bumps nothing, and a player already up against a pane gets no bump
// for pushing on it
event HitWall( vector HitNormal, actor Wall )
{
	if( Role<ROLE_Authority )
		return;
	if( KFGlassBlocker(Wall)!=None )
		Wall = KFGlassBlocker(Wall).Glass;
	if( KFGlassMover(Wall)!=None )
		Wall.Bump(Self);
}

Simulated function tick(float DeltaTime)
{
	super.Tick(DeltaTime);

	if (Physics != PHYS_Falling && !bIsCrouched && !bWantsToCrouch && BaseEyeHeight < default.BaseEyeHeight)
	{
		BaseEyeHeight = default.BaseEyeHeight;
	}

	if (PlayerController(Controller) != None)
	{
		if (KFPlayerReplicationInfo(PlayerController(Controller).PlayerReplicationInfo).ThreeSecondScore > 0 && AlphaAmount > 0)
			AlphaAmount -=2;

		if (AlphaAmount <= 0)
		{
			KFPlayerReplicationInfo(PlayerController(Controller).PlayerReplicationInfo).ThreeSecondScore = 0;
			ScoreCounter = 0;
		}
	}
}

simulated event PhysicsVolumeChange( PhysicsVolume NewVolume )
{
    Super.PhysicsVolumeChange(NewVolume);
}

function SetAiming(bool IsAiming)
{
	bAimingRifle = IsAiming;
}

function Timer()
{
	local Actor WallActor;
	local KFBloodSplatter Streak;
	local vector WallHit, WallNormal;
	local PlayerController PCC;//,Owner;

	if (BurnDown > 0)
	{
		LastBurnDamage *= 0.5;
        TakeFireDamage(LastBurnDamage, BurnInstigator);
	}
	else
	{
		RemoveFlamingEffects();
		StopBurnFX();
	}

	// Flashlight Drain
	if(Weapon != none && KFWeapon(Weapon).FlashLight != none)
	{
		// Increment / Decrement battery life
		if (KFWeapon(Weapon).FlashLight.bHasLight && TorchBatteryLife > 0)
			TorchBatteryLife -= 10;
		else if (!KFWeapon(Weapon).FlashLight.bHasLight && TorchBatteryLife < default.TorchBatteryLife)
		{
			TorchBatteryLife += 20;
			if ( TorchBatteryLife > default.TorchBatteryLife )
			{
				TorchBatteryLife = default.TorchBatteryLife;
			}
		}
	}
	else if( TorchBatteryLife<default.TorchBatteryLife )
	{
		TorchBatteryLife += 20;
		if ( TorchBatteryLife > default.TorchBatteryLife )
		{
			TorchBatteryLife = default.TorchBatteryLife;
		}
	}

	if (Controller != none)
	{
		PCC = PlayerController(Controller);
		if(PCC != None )
		{
			// Update for the scoreboards.
			if (Health <= 0)
			{
				PlaySound(MiscSound,SLOT_Talk);
				return;
			}
			if ( Health < HealthMax * 0.25 )
			{
				PlaySound(BreathingSound, SLOT_Talk, ((50-Health)/5)*TransientSoundVolume,,TransientSoundRadius,, false);
				WallActor = Trace(WallHit, WallNormal, Location - 50 * Velocity, Location, false);
				Streak= spawn(class 'KFMod.KFBloodSplatter',,,vect(0,0,0), Rotation);
				if (Streak != none)
					Streak.SetRotation(Rotator(Velocity));
			}

			// Accuracy vs. Movement tweakage!  - Alex
			if (KFWeapon(Weapon) != none)
				KFWeapon(Weapon).AccuracyUpdate(vsize(Velocity));
		}

	}

	// TODO: WTF? central here
	// Instantly set the animation to arms at sides Idle if we've got no weapon (rather than Pointing an invisible gun!)
	if (Weapon != none)
	{
		if (WeaponAttachment(Weapon.ThirdPersonActor) == none && VSize(Velocity) <= 0)
			IdleWeaponAnim = IdleRestAnim;
	}
	else if (Weapon == none)
		IdleWeaponAnim = IdleRestAnim;

}

simulated function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
	local int HealthWas;
	local float ArmourWas;
	local vector HitDir;

	if( Role<ROLE_Authority )
		return;
	if( Controller!=None && Controller.bGodMode )
		return;

	// Berserkers resist knockback from monsters
	if( InstigatedBy != none && ((KFMonster(instigatedBy)!=None && ClassIsChildOf(GetVeteran(),class'KFVetBerserker')) || KFHumanPawn(instigatedBy)!=None) )
		momentum = vect(0,0,0);

	HealthWas = Health;
	ArmourWas = ShieldStrength;
	Super.TakeDamage(Damage,instigatedBy,hitlocation,momentum,damageType);
	//log("TakeDamage: "$self$" Damage: "$Damage$" InstigatedBy: "$instigatedBy$" HitLocation: "$hitlocation$" Momentum: "$momentum$" DamageType: "$damageType);
	//Bloody Overlays
	if ((Health-Damage) <= 0.5*HealthMax)
		SetOverlayMaterial(InjuredOverlay,0, true);

	if( Controller==none || PlayerController(Controller)==None )
		return;

	// The view shakes and blurs only for a hit that got through (not friendly fire the game took away). What it
	// took is read off health and armour: this used to ask the game's damage rules a second time, so every rule a
	// mutator adds saw each hit on a player twice. The blur goes by the health lost.
	if( Health<HealthWas || ShieldStrength<ArmourWas )
	{
		// The jar goes the way the hit pushed, else away from whoever dealt it (a Berserker's push from specimens is
		// taken away above); burning and damage from nobody do not jar the view
		HitDir = momentum;
		if( HitDir==vect(0,0,0) && instigatedBy!=None && instigatedBy!=self && !ClassIsChildOf(damageType, class'Burned') )
			HitDir = Location - instigatedBy.Location;
		DoHitCamEffects(HitDir, Max(HealthWas-Health,0));
	}
}

function TakeBileDamage()
{
	local int RandBileDamage, HealthWas;
	local float ArmourWas;
	local vector BileVect;

	RandBileDamage = BileTick(2+Rand(2));

	HealthWas = Health;
	ArmourWas = ShieldStrength;
    Super(XPawn).TakeDamage(RandBileDamage, BileInstigator, Location, vect(0,0,0), class'DamTypeVomit');
    healthtoGive-=5;

	// (as in TakeDamage: what it took is read off health and armour)
	if( Health>=HealthWas && ShieldStrength>=ArmourWas )
		return;

	//TODO: move this sanity check to DoHitCamEffect?
	if(Controller == none || PlayerController(Controller) == None)
		return;

	if(Controller.bGodMode)
		return;

	BileVect.X=frand()*400.0-200.0;
	BileVect.Y=frand()*200.0-100.0;
	BileVect.Z=frand()*400.0-200.0;
	DoHitCamEffects( BileVect, Max(HealthWas-Health,0) );
}

// Every hit jars the view away from it, as Killing Floor itself does: seen from the player's own view, a hit from in
// front or behind nods the view and one from the side tilts it; harder hits jar further. HitDir is in world space
// (the player's machine turns it into his view).
simulated function DoHitCamEffects(vector HitDir, optional int Damage)
{
	local KFScreenFX FX;
	local PlayerController PC;
	local rotator ViewYaw;
	local vector Dir, RotMag, RotRate, MoveMag, MoveRate;
	local float Jar;

	PC = PlayerController(Controller);

	// the view goes out of focus by how hard the hit was (KFScreenFX clears it again by itself)
	FX = class'KFFrameTap'.static.GetFX(PC);
	if( FX!=None )
		FX.HitBlur(Damage);

	HitDir.Z = 0;
	if( PC==None || HitDir==vect(0,0,0) )
		return;
	ViewYaw.Yaw = PC.Rotation.Yaw;
	Dir = Normal(HitDir) << ViewYaw;
	Jar = FClamp(float(Damage) / JarFullDamage, 0.1, 1.0);

	RotMag.X = -Dir.X * JarRotateMag * Jar;
	RotMag.Z = Dir.Y * JarRotateMag * Jar;
	MoveMag = Dir * JarMoveMag * Jar;
	RotRate = JarRotateRate * (2.0 - Jar) * vect(1,1,1);
	MoveRate = JarMoveRate * (2.0 - Jar) * vect(1,1,1);

	// (the engine's shake sets off at the rate's sign and turns at the peak's, so each rate takes its peak's sign)
	if( RotMag.X<0 )
		RotRate.X *= -1;
	if( RotMag.Z<0 )
		RotRate.Z *= -1;
	if( MoveMag.X<0 )
		MoveRate.X *= -1;
	if( MoveMag.Y<0 )
		MoveRate.Y *= -1;

	PC.ShakeView(RotMag, RotRate, JarRotateTime, MoveMag, MoveRate, JarMoveTime);
}

simulated function PrevWeapon()
{
    if ( Level.Pauser != None )
        return;

    if ( Weapon == None && Controller != None )
    {
        Controller.SwitchToBestWeapon();
        return;
    }

    if ( PendingWeapon != None )
    {
        if ( PendingWeapon.bForceSwitch )
            return;
        PendingWeapon = Inventory.PrevWeapon(None, PendingWeapon);
    }
    else
    {
        PendingWeapon = Inventory.PrevWeapon(None, Weapon);
    }

    if ( PendingWeapon != None )
        Weapon.PutDown();
}

/* NextWeapon()
- switch to next inventory group weapon
*/
simulated function NextWeapon()
{
    if ( Level.Pauser != None )
        return;

    if ( Weapon == None && Controller != None )
    {
        Controller.SwitchToBestWeapon();
        return;
    }

    if ( PendingWeapon != None )
    {
        if ( PendingWeapon.bForceSwitch )
            return;
        PendingWeapon = Inventory.NextWeapon(None, PendingWeapon);
    }
    else
    {
        PendingWeapon = Inventory.NextWeapon(None, Weapon);
    }
    if ( PendingWeapon != None && Weapon != none )
        Weapon.PutDown();
}

function bool AddInventory( inventory NewItem )
{
	if( !super.AddInventory(NewItem) )
		return false;

	if(KFWeapon(NewItem)!=none)
		CurrentWeight += KFWeapon(NewItem).Weight;
	return true;
}

// Remove Item from this pawn's inventory, if it exists.
function DeleteInventory( inventory Item )
{
	local Inventory I;
	local bool bFoundItem;

	if ( Role != ROLE_Authority )
	{
		return;
	}

	for ( I = Inventory; I != none; I = I.Inventory )
	{
		if ( I == Item )
		{
			bFoundItem = true;
		}
	}

	if ( bFoundItem )
	{
        if ( KFWeapon(Item) != none )
		{
			CurrentWeight -= KFWeapon(Item).Weight;
		}
	}

	super.DeleteInventory(Item);
}

function AddDefaultInventory()
{
	local int i;

	if( KFSPGameType(Level.Game)!=None )
	{
		Level.Game.AddGameSpecificInventory(self);
		if ( inventory != None )
			inventory.OwnerEvent('LoadOut');
		Return;
	}
	if ( IsLocallyControlled() )
	{
		for ( i=0; i<16; i++ )
			if ( RequiredEquipment[i] != "" )
				CreateInventory(RequiredEquipment[i]);

		for ( i=0; i<16; i++ )
			if ( (SelectedEquipment[i] == 1) && (OptionalEquipment[i] != "") )
				CreateInventory(OptionalEquipment[i]);

		Level.Game.AddGameSpecificInventory(self);
	}
	else
	{
		Level.Game.AddGameSpecificInventory(self);

		for ( i=15; i>=0; i-- )
			if ( (SelectedEquipment[i] == 1) && (OptionalEquipment[i] != "") )
				CreateInventory(OptionalEquipment[i]);

		for ( i=15; i>=0; i-- )
			if ( RequiredEquipment[i] != "" )
				CreateInventory(RequiredEquipment[i]);
	}

	// HACK FIXME
	if ( inventory != None )
		inventory.OwnerEvent('LoadOut');

	Controller.ClientSwitchToBestWeapon();
}
function bool CanCarry( float Weight )
{
	return ((CurrentWeight+Weight)<=MaxCarryWeight);
}

function bool PerformDodge(eDoubleClickDir DoubleClickMove, vector Dir, vector Cross)
{
	return false;
}

function bool ShowStalkers()
{
	if ( KFPlayerReplicationInfo(PlayerReplicationInfo) != none && KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill != none )
	{
		return KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.Static.ShowStalkers();
	}

	return false;
}

//
// Compute offset for drawing an inventory item.
//
simulated function vector CalcDrawOffset(inventory Inv)
{
	local vector DrawOffset;

	if ( Controller == None )
		return (Inv.PlayerViewOffset >> Rotation) + BaseEyeHeight * vect(0,0,1);

	DrawOffset = ((0.9/Weapon.DisplayFOV * 100 * ModifiedPlayerViewOffset(Inv)) >> GetViewRotation() );
	if ( !IsLocallyControlled() )
		DrawOffset.Z += BaseEyeHeight;
	else
	{
		DrawOffset.Z += EyeHeight;
		DrawOffset += CameraShake();
	}
	return DrawOffset;
}


// Whether the server lets a network player sprint who says he does
function bool MaySprint()
{
	return true;
}

// The player's pace as his health, his load, his sprint and his perk make it
simulated function UpdateSpeed()
{
    local float HealthMod, SprintMod, WeightMod;
	local float EncumbrancePercentage;
	local KFWeapon KFW;

	// Calculate encumbrance, but cap it to the maxcarryweight so when we use dev weapon cheats we don't move mega slow
	EncumbrancePercentage = (FMin(CurrentWeight, MaxCarryWeight)/MaxCarryWeight);
	// Calculate the weight modifier to speed
	WeightMod = (1.0 - (EncumbrancePercentage * 0.13));
	// Calculate the health modifier to speed
	HealthMod = ((Health/HealthMax) * HealthSpeedModifier) + (1.0 - HealthSpeedModifier);
	// (in the air a player keeps the pace he left the ground at: a jump is not a sprint)
	if (bIsSprinting && !bIsCrouched)
		SprintMod = SprintMulti;
	else
		SprintMod = 1.0;
	GroundSpeed = default.GroundSpeed * HealthMod;
	GroundSpeed *= WeightMod;
	GroundSpeed *= SprintMod;
	if( bIsDowned )
		GroundSpeed *= DownedSpeedScale;
	AccelRate = default.AccelRate * SprintMod;

	if ( KFPlayerReplicationInfo(PlayerReplicationInfo) != none && KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill != none )
	{
		GroundSpeed *= KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.GetMovementSpeedModifier();
		KFW = KFWeapon(Weapon);
		if(KFW != none && KFW.bMeleeWeapon)
			GroundSpeed += (default.GroundSpeed * (BaseMeleeIncrease + KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.GetMeleeMovementSpeedModifier()));
	}
}

simulated event ModifyVelocity(float DeltaTime, vector OldVelocity)
{
	local float Speed2D, FrictionBlend, Drop, NewSpeed, SpeedFraction;

    Super.ModifyVelocity(DeltaTime, OldVelocity);

	if (Controller == none)
		return;

	UpdateSpeed();

	if (Physics == PHYS_Walking)
	{
		// (by the moves, not by the clock: the server and a network player's own machine then agree on it)
		GroundTime = FMin(GroundTime + DeltaTime, 10.0);

		if (Acceleration.X * Acceleration.X + Acceleration.Y * Acceleration.Y < 1.0)
		{
			Speed2D = Sqrt(Velocity.X * Velocity.X + Velocity.Y * Velocity.Y);
			SpeedFraction = FClamp(Speed2D / FMax(default.GroundSpeed, 1.0), 0.0, 2.0);

			if (GroundTime < 0.3)
			{
				FrictionBlend = 0.93 - GroundTime * 0.20;
			}
			else
			{
				FrictionBlend = FMin(0.80 + 0.10 * SpeedFraction, 0.93);
			}

			Velocity.X += (OldVelocity.X - Velocity.X) * FrictionBlend;
			Velocity.Y += (OldVelocity.Y - Velocity.Y) * FrictionBlend;

			Speed2D = Sqrt(Velocity.X * Velocity.X + Velocity.Y * Velocity.Y);
			if (Speed2D > 1.0)
			{
				Drop = Speed2D * 4.0 * DeltaTime;
				NewSpeed = FMax(Speed2D - Drop, 0.0) / Speed2D;
				Velocity.X *= NewSpeed;
				Velocity.Y *= NewSpeed;
			}
		}
	}

	if(VSize(Velocity) < 1.f && Bot(Controller) == None) //Hack to make it so bots don't unsprint if they bumped into a wall or something
	{
		if( bIsSprinting && Role<ROLE_Authority )
			ServerStopSprintKF();
		bIsSprinting = False;
	}
}

event Landed(vector HitNormal)
{
    bCrouchJumped = false;
    Super.Landed(HitNormal);
    GroundTime = 0;
}

event StartCrouch(float HeightAdjust)
{
    bJustLanded = false;
    bLandRecovery = false;
    Super.StartCrouch(HeightAdjust);
}

event EndCrouch(float HeightAdjust)
{
    CrouchEndTime = Level.TimeSeconds;
    Super.EndCrouch(HeightAdjust);
}

//Player Jumped
function bool DoJump( bool bUpdating )
{
	if ( ((Physics == PHYS_Walking) || (Physics == PHYS_Ladder) || (Physics == PHYS_Spider)) )
	{
		if ( Role == ROLE_Authority )
		{
			if ( (Level.Game != None) && (Level.Game.GameDifficulty > 2) )
				MakeNoise(0.1 * Level.Game.GameDifficulty);
			if ( bCountJumps && (Inventory != None) )
				Inventory.OwnerEvent('Jumped');
		}
		if ( Physics == PHYS_Spider )
			Velocity = JumpZ * Floor;
		else if ( Physics == PHYS_Ladder )
			Velocity.Z = 0;
		else if ( bIsWalking )
			Velocity.Z = Default.JumpZ;
		else
			Velocity.Z = JumpZ;
		if ( (Base != None) && !Base.bWorldGeometry )
			Velocity += Base.Velocity;

        if( bIsCrouched || bWantsToCrouch || Level.TimeSeconds - CrouchEndTime < JumpCrouchTime )
		{
            Velocity.Z -= JumpZ * JumpCrouchBonus;
			bCrouchJumped = true;
		}
		
		SetPhysics(PHYS_Falling);
		if ( !bUpdating )
			PlayOwnedSound(GetSound(EST_Jump), SLOT_Pain, GruntVolume,,80);
        return true;
	}
    return false;
}

simulated function StartSprintKF()
{
	if(!bIsSprinting && !bIsCrouched)
		bIsSprinting = True;
	ServerStartSprintKF();
}

function ServerStartSprintKF()
{
	if(!bIsSprinting && !bIsCrouched)
		bIsSprinting = True;
	else if(!bIsSprinting)
		ClientSprintDenied();
}

simulated function ClientSprintDenied()
{
	bIsSprinting = False;
}

simulated function StopSprintKF()
{
	if(bIsSprinting)
		bIsSprinting = False;
	ServerStopSprintKF();
}

function ServerStopSprintKF()
{
	if(bIsSprinting)
		bIsSprinting = False;
}

// No more File cabinet surfing bots please!
singular event BaseChange()
{
	Super.BaseChange();
	if ( AIController(Controller)!=None && KActor(Base)!=None )
		JumpOffPawn();
	else if ( KFPlayerController(Controller)!=None )
		KFPlayerController(Controller).UndoPropTurn();
}

simulated function DisplayDebug(Canvas Canvas, out float YL, out float YPos)
{
	super.DisplayDebug(Canvas, YL, YPos);

    Canvas.SetDrawColor(255,128,0);
    Canvas.DrawText("CrouchedPct: " @ CrouchedPct @ " Sprinting: " @ bIsSprinting @ " GroundSpeed: " @ GroundSpeed);
    YPos += YL;
    Canvas.SetPos(4,YPos);
}



// For a shot in flight: is Other a player on the shooter's side? The shooter's team while he has one, else the team noted when
// the shot was fired, so the shot of a player who has just died still passes his team-mates.
static function bool OnShootersTeam( Actor Other, Pawn Shooter, int FiredTeam )
{
	local int T;

	if ( KFHumanPawn(Other) == None )
		return false;
	T = FiredTeam;
	if ( Shooter != None && Shooter.GetTeamNum() != 255 )
		T = Shooter.GetTeamNum();
	return T != 255 && KFHumanPawn(Other).GetTeamNum() == T;
}

defaultproperties
{
	JarRotateMag=1000.000000
	JarRotateRate=10000.000000
	JarRotateTime=2.000000
	JarMoveMag=12.000000
	JarMoveRate=200.000000
	JarMoveTime=2.000000
	JarFullDamage=10.000000
	BreathingSound=Sound'KFPlayerSound.Malebreath'
	BaseMeleeIncrease=0.200000
	MaxCarryWeight=15.000000
	InjuredOverlay=Shader'KFCharacters.BloodiedShader'
	CriticalOverlay=Shader'KFCharacters.BloodiedShader'
	TorchBatteryLife=500
	GruntVolume=10.000000
	RequiredEquipment(0)="KFMod.Knife"
	RequiredEquipment(1)="KFMod.Single"
	RequiredEquipment(2)="KFMod.Frag"
	RequiredEquipment(3)="KFMod.Syringe"
	RequiredEquipment(4)="KFMod.Welder"
	bCanDodgeDoubleJump=False
	bCanDoubleJump=False
	bCanWallDodge=False
	bCanWalkOffLedges=True
	MultiJumpRemaining=0
	MaxMultiJump=0
	GroundSpeed=200.000000
	WaterSpeed=200.000000
	AirSpeed=400.000000
	JumpZ=325.000000
	AirControl=0.150000
	MaxFallSpeed=700.000000
	BaseEyeHeight=48.000000
	EyeHeight=48.000000
	CrouchHeight=28.000000
	AccelRate=1500.000000
	SprintMulti=1.400000
	CrouchedPct=0.500000
	JumpCrouchBonus=0.350000
	JumpCrouchTime=0.300000
	GroundTime=1.000000
	HealthSpeedModifier=0.300000
	ControllerClass=Class'KFMod.KFInvasionBot'
	CrouchTurnRightAnim="CrouchR"
	CrouchTurnLeftAnim="CrouchL"
	bDramaticLighting=False
	Mesh=SkeletalMesh'KFSoldiers.Soldier'
	Skins(0)=Texture'KFCharacters.DavinSkin'
	Skins(1)=Shader'KFCharacters.GasMaskShader'
	CollisionHeight=50.000000
}
