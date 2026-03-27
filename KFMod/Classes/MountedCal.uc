//=============================================================================
// 50Cal.
//=============================================================================

class MountedCal extends ASTurret_Minigun;

var int AmmoStored;


simulated function bool DrawCrosshair( Canvas C, out vector ScreenPos )
{
  return true;
}

static function StaticPrecache(LevelInfo L)
{

}

simulated function UpdatePrecacheStaticMeshes()
{

}


simulated function UpdatePrecacheMaterials()
{

}

function PreBeginPlay()
{

}


simulated function PostBeginPlay()
{
    //local controller NewController;

    // Glue a shadow projector on
        VehicleShadow = Spawn(class'ShadowProjector', self, '', Location);
        VehicleShadow.ShadowActor       = Self;
        VehicleShadow.bBlobShadow       = false;
        VehicleShadow.LightDirection    = Normal(vect(1,1,6));
        VehicleShadow.LightDistance     = 1200;
        VehicleShadow.MaxTraceDistance  = ShadowMaxTraceDist;
        VehicleShadow.CullDistance      = ShadowCullDistance;
        VehicleShadow.InitShadow();


    if ( Role == Role_Authority )
        OriginalRotation = Rotation;    // Save original Rotation to place client versions well...

    super.PostBeginPlay();

}

simulated event PostNetBeginPlay()
{
   //local Vector TurretBaseSpawnLoc ;

    // Static (non rotating) base
 //   if ( TurretBaseClass != None )


     //   TurretBaseSpawnLoc = Location;
      //  TurretBaseSpawnLoc -=  vect(0,0,100);

      //  TurretBase = Spawn(TurretBaseClass, Self,, TurretBaseSpawnLoc , OriginalRotation);


   // super.PostNetBeginPlay();
}

// Dont draw the green health bar

simulated function DrawHealthInfo( Canvas C, PlayerController PC )
{

}

function GiveWeapon(string aClassName )
{
    local class<Weapon> WeaponClass;
    local Weapon NewWeapon;

    WeaponClass = class<Weapon>(DynamicLoadObject(aClassName, class'Class'));

    if( FindInventoryType(WeaponClass) != None )
        return;
    newWeapon = Spawn(WeaponClass);
    if( newWeapon != None )
    {
        newWeapon.GiveTo(self);
    }

}

function PossessedBy(Controller C)
{
   // Level.Game.DiscardInventory( Self );

    super.PossessedBy( C );

    NetUpdateTime = Level.TimeSeconds - 1;
    bStasis = false;
    C.Pawn  = Self;

    if ( Weapon != None )
    {
        Weapon.NetUpdateTime = Level.TimeSeconds - 1;
        Weapon.Instigator = Self;
        PendingWeapon = None;
        Weapon.BringUp();
    }
}

function UnPossessed()
{
    if ( Weapon != None )
    {
       // Weapon.PawnUnpossessed();
        Weapon.ImmediateStopFire();
        Weapon.ServerStopFire( 0 );
        Weapon.ServerStopFire( 1 );
    }
    NetUpdateTime = Level.TimeSeconds - 1;
    super.UnPossessed();
}


// Called from the PlayerController when player wants to get out.
event bool KDriverLeave( bool bForceLeave )
{
    local Controller C;
    local PlayerController  PC;
    local bool havePlaced;

    bForceLeave = true;


     if (Weapon != none && Driver.Controller.PlayerReplicationInfo != none)
    {
      KFPlayerReplicationInfo(Driver.Controller.PlayerReplicationInfo).MGAmmo = Weapon.AmmoAmount(0);
     //Log("your ammo is: ");
     // Log(KFPlayerReplicationInfo(C.PlayerReplicationInfo).MGAmmo);
    }



    if( !bForceLeave && !Level.Game.CanLeaveVehicle(self, Driver) )
        return false;

    if ( (PlayerReplicationInfo != None) && (PlayerReplicationInfo.HasFlag != None) )
        Driver.HoldFlag(PlayerReplicationInfo.HasFlag);

    // Do nothing if we're not being driven
    if (Controller == None )
        return false;

    // Before we can exit, we need to find a place to put the driver.
    // Iterate over array of possible exit locations.

    if ( (Driver != None) && (!bRemoteControlled || bHideRemoteDriver) )
    {
        Driver.bHardAttach = false;
        Driver.bCollideWorld = true;
        Driver.SetCollision(true, true);
        havePlaced = PlaceExitingDriver();

        // If we could not find a place to put the driver, leave driver inside as before.
        if (!havePlaced && !bForceLeave )
        {
            Driver.bHardAttach = true;
            Driver.bCollideWorld = false;
            Driver.SetCollision(false, false);
            return false;
        }
    }

    bDriving = False;

    // Reconnect Controller to Driver.
    C = Controller;
    if (C.RouteGoal == self)
        C.RouteGoal = None;
    if (C.MoveTarget == self)
        C.MoveTarget = None;
    C.bVehicleTransition = true;
    Controller.UnPossess();

    if ( (Driver != None) && (Driver.Health > 0) )
    {
        Driver.SetOwner( C );
        C.Possess( Driver );

        PC = PlayerController(C);
        if ( PC != None )
            PC.ClientSetViewTarget( Driver ); // Set playercontroller to view the person that got out

        Driver.StopDriving( Self );
    }
    C.bVehicleTransition = false;

    if ( C == Controller )  // If controller didn't change, clear it...
        Controller = None;

    Level.Game.DriverLeftVehicle(self, Driver);

    // Car now has no driver
    Driver = None;

    DriverLeft();


    // Put brakes on before you get out :)
    Throttle    = 0;
    Steering    = 0;
    Rise        = 0;

    return true;



}



function KDriverEnter(Pawn P)
{
    local Controller C;

    bDriving = True;
    StuckCount = 0;



    // We don't have pre-defined exit positions here, so we use the original player location as an exit point
    if ( !bRelativeExitPos )
    {
        PlayerEnterredRotation = P.Rotation;
        ExitPositions[0] =  P.Location + Vect(0,0,16);
    }

    // Set pawns current controller to control the vehicle pawn instead
    C = P.Controller;
    if ( !bCanCarryFlag && (C.PlayerReplicationInfo.HasFlag != None)  )
        P.DropFlag();

    Driver = P;
    Driver.StartDriving( Self );

    // Disconnect PlayerController from Driver and connect to SVehicle.
    C.bVehicleTransition = true; // to keep Bots from doing Restart()
    C.Unpossess();
    Driver.SetOwner( Self ); // This keeps the driver relevant.
    C.Possess( Self );
    C.bVehicleTransition = false;

    DrivingStatusChanged();

    if ( PlayerController(C) != None )
        VehicleLostTime = 0;

    AttachFlag(PlayerReplicationInfo.HasFlag);

    Level.Game.DriverEnteredVehicle(self, P);
           //  Log("You're using a :");
       //  Log(GunClass);

    if (Weapon != none )
    {
      Log ("Ammo Left over from last time is : "$KFPlayerReplicationInfo(Driver.Controller.PlayerReplicationInfo).MGAmmo);
      Weapon.ConsumeAmmo(0,Weapon.MaxAmmo(0));
      Weapon.AddAmmo(KFPlayerReplicationInfo(Driver.Controller.PlayerReplicationInfo).MGAmmo,0);
     // Log("your ammo is: ");
     // Log(AmmoStored);
    }


}

// Do damage to the Soldier directly, not the weapon.

function TakeDamage( int Damage, Pawn instigatedBy, Vector hitlocation,
                        Vector momentum, class<DamageType> damageType)
{
    local int ActualDamage;
    local Controller Killer;

    // Spawn Protection: Cannot be destroyed by a player until possessed
    if ( bSpawnProtected && instigatedBy != None && instigatedBy != Self )
        return;

    NetUpdateTime = Level.TimeSeconds - 1; // force quick net update

    if (DamageType != None)
    {
        if ((instigatedBy == None || instigatedBy.Controller == None) && DamageType.default.bDelayedDamage && DelayedDamageInstigatorController != None)
            instigatedBy = DelayedDamageInstigatorController.Pawn;

        Damage *= DamageType.default.VehicleDamageScaling;
        momentum *= DamageType.default.VehicleMomentumScaling * MomentumMult;

            if (bShowDamageOverlay && DamageType.default.DamageOverlayMaterial != None && Damage > 0 )
                SetOverlayMaterial( DamageType.default.DamageOverlayMaterial, DamageType.default.DamageOverlayTime, false );
    }

    if (bRemoteControlled && Driver!=None)
    {
        ActualDamage = Damage;
        if (Weapon != None)
            Weapon.AdjustPlayerDamage(ActualDamage, InstigatedBy, HitLocation, Momentum, DamageType );
        if (InstigatedBy != None && InstigatedBy.HasUDamage())
            ActualDamage *= 2;

        ActualDamage = Level.Game.ReduceDamage(ActualDamage, self, instigatedBy, HitLocation, Momentum, DamageType);

        if (Health - ActualDamage <= 0)
            KDriverLeave(false);
    }

    if ( Physics != PHYS_Karma )
    {
         Driver.TakeDamage(Damage,InstigatedBy,HitLocation,Momentum,DamageType);
        return;
    }

    if (Weapon != None)
            Weapon.AdjustPlayerDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType );
    if (InstigatedBy != None && InstigatedBy.HasUDamage())
        Damage *= 2;
    ActualDamage = Level.Game.ReduceDamage(Damage, self, instigatedBy, HitLocation, Momentum, DamageType);
    Driver.Health -= ActualDamage;


    PlayHit(actualDamage, InstigatedBy, hitLocation, damageType, Momentum);
    // The vehicle is dead!
    if ( Health <= 0 )
    {

        if ( Driver!=None && (bEjectDriver || bRemoteControlled) )
        {
            if ( bEjectDriver )
                EjectDriver();
            else
                KDriverLeave( false );
        }

        // pawn died
        if ( instigatedBy != None )
            Killer = instigatedBy.GetKillerController();
        if ( Killer == None && (DamageType != None) && DamageType.Default.bDelayedDamage )
            Killer = DelayedDamageInstigatorController;
        Died(Killer, damageType, HitLocation);
    }
    else if ( Controller != None )
        Controller.NotifyTakeHit(instigatedBy, HitLocation, actualDamage, DamageType, Momentum);

    MakeNoise(1.0);

    if ( !bDeleteMe )
    {
        if ( Location.Z > Level.StallZ )
            Momentum.Z = FMin(Momentum.Z, 0);
        KAddImpulse(Momentum, hitlocation);
    }
}


simulated function PlayFiring(optional float Rate, optional name FiringMode )
{
    if ( FiringMode == '0' )
        PlayAnim('Fire', 0.45);
    else
        PlayAnim('Fire', 0.45);
}

// NO vehicle overlays..

simulated function ActivateOverlay(bool bActive)
{

}


simulated function UpdateRocketAcceleration(float DeltaTime, float YawChange, float PitchChange)
{
    local int       Pitch;
    local rotator   NewRotation;

    if ( PlayerController(Controller) != None && PlayerController(Controller).bFreeCamera )
    {
        PlayerController(Controller).UpdateRotation( DeltaTime, 0);
        return;
    }

    // Make sure Delta is not too big...
    if ( DeltaTime > 0.3 )
        DeltaTime = 0.3;

    YawAccel    = RotationInertia*YawAccel + DeltaTime*RotationSpeed*YawChange;
    PitchAccel  = 0;

    Pitch       = 0;

    // Pitch constraint
    if ( (Pitch > 16384 - RotPitchConstraint.Max) && (Pitch < 49152 + RotPitchConstraint.Min) )
    {
        if ( Pitch > 49152 - RotPitchConstraint.Min )
            PitchAccel = Max(PitchAccel,0);
        else if ( Pitch < 16384 + RotPitchConstraint.Max )
            PitchAccel = Min(PitchAccel,0);
    }

    NewRotation         = Rotation;
    NewRotation.Yaw    += YawAccel;
    NewRotation.Pitch  += PitchAccel;

    SetRotation( NewRotation );

    if ( IsLocallyControlled() )
    {
        if ( TurretBase != None && TurretBase.DrawType == DT_Mesh  )
            TurretBase.UpdateOverlay();

        if ( TurretSwivel != None )
        {
            if ( TurretSwivel.DrawType == DT_Mesh )
                TurretSwivel.UpdateOverlay();
            TurretSwivel.UpdateSwivelRotation( NewRotation );
        }
    }
}

// We Don't want to go to a default Behind view on entering the weapon...

simulated function SpecialCalcBehindView(PlayerController PC, out actor ViewActor, out vector CameraLocation, out rotator CameraRotation )
{

}

defaultproperties
{
<<<<<<< HEAD
	TurretBaseClass=None
	TurretSwivelClass=None
	RotPitchConstraint=(Min=5000.000000,Max=10000.000000)
	RotationSpeed=5.000000
	ZoomSpeed=0.000000
	DefaultWeaponClassName="KFMod.MountedCalWeapon"
	VehicleProjSpawnOffset=(X=50.000000,Z=86.000000)
	CrosshairScale=0.200000
	DrivePos=(X=-55.000000,Y=0.000000,Z=29.000000)
	FPCamPos=(X=-40.000000,Y=0.000000,Z=50.000000)
	MaxViewYaw=1000
	DriverDamageMult=1.000000
	VehiclePositionString="Manning a .50Cal Heavy"
	VehicleNameString=".50Cal Heavy"
	bSimulateGravity=True
	bSpecialHUD=False
	HealthMax=100.000000
	Health=100
	bDynamicLight=True
	Physics=PHYS_Falling
	Mesh=SkeletalMesh'KFVehicleModels.50Cal'
	DrawScale=0.300000
	AmbientGlow=0
	CollisionRadius=40.000000
	CollisionHeight=20.000000
	bCollideWorld=True
	bUseCylinderCollision=True
=======
     TurretBaseClass=None
     TurretSwivelClass=None
     RotPitchConstraint=(Min=5000.000000,Max=10000.000000)
     RotationSpeed=5.000000
     ZoomSpeed=0.000000
     DefaultWeaponClassName="KFMod.MountedCalWeapon"
     VehicleProjSpawnOffset=(X=50.000000,Z=86.000000)
     CrosshairScale=0.200000
     DrivePos=(X=-55.000000,Y=0.000000,Z=29.000000)
     FPCamPos=(X=-40.000000,Y=0.000000,Z=50.000000)
     MaxViewYaw=1000
     DriverDamageMult=1.000000
     VehiclePositionString="Manning a .50Cal Heavy"
     VehicleNameString=".50Cal Heavy"
     bSimulateGravity=True
     bSpecialHUD=False
     HealthMax=100.000000
     Health=100
     bDynamicLight=True
     Physics=PHYS_Falling
     Mesh=SkeletalMesh'KFVehicleModels.50Cal'
     DrawScale=0.300000
     AmbientGlow=0
     CollisionRadius=40.000000
     CollisionHeight=20.000000
     bCollideWorld=True
     bUseCylinderCollision=True
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
