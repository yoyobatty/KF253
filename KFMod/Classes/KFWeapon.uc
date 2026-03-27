class KFWeapon extends Weapon
	abstract;

var() int ClipCount;
var() float ReloadRate;
var float ReloadTimer;
var int ClipLeft;
var bool bzoomed;
var float ZoomLevel;
var Bool bSpeedMeUp;

var() sound ReloadBeginSound, ReloadSound, ReloadEndSound, ToggleSound;
var() name ReloadAnim;
var() float ReloadAnimRate;
var() bool bHoldToReload;

var name FlashBoneName;
var name WeaponReloadAnim;

var () name ModeSwitchAnim;

var () material HudImage; // What to display on the HUD, when this weapon is selected.

var Name IdleAimAnim;

var bool bSteadyAim;  // If Flicked,  this weapon's accuracy is not affected by Movement.

//var() float HealRate;
//var transient float HealAccum;


// Zoomshit
var transient float LastFOV,ZoomingInTimer;
var bool zoomed;
var Bool bZooming;


var bool bIsReloading, bReloadEffectDone;

var () float Weight; // how much does it weigh

var bool bKFNeverThrow;

var bool bAmmoHUDAsBar;

var bool bUseCombos; // Disable combos for the time being...Too iffy

var bool bNoHit; // Hack for Syringe / Welder. 

var () bool bTorchEnabled; // just a hook for the pawn, and his light.  Dualies and Single have this set to true. the other weapons dont.


var int StoppingPower; // How much each fire of the gun slows you down. Always in negative numbers.
var int UpKick;  // How much upkick each shot has.

var bool bAimingRifle;

var () class<InventoryAttachment> TacShineClass;
var Actor TacShine;

var Effect_TacLightProjector FlashLight;

var float NextAmmoCheckTime,LastAmmoResult;

//var bool bUsingFlashlightAnims;

replication
{
	//TODO - does ClipCount still need sending,
	// and does clipleft simulate sucessfully enough to not need repping?
	reliable if(Role == ROLE_Authority)
		ClipCount,ClipLeft;

	// TODO - which of these ACTUALLY need sending?
	reliable if(Role < ROLE_Authority)
		ReloadMeNow, finishReloading, recalcClipCount,ServerSetAiming, ServerSpawnLight;

	reliable if(Role == ROLE_Authority)
		ClientReload, ClientFinishReloading, ClientReloadEffects,FlashLight;
}

function bool HandlePickupQuery( pickup Item )
{
	if ( Item.InventoryType==Class )
	{
		if( PlayerController(Instigator.Controller)!=none )
			PlayerController(Instigator.Controller).ClientMessage("You already have this weapon.", 'KFCriticalEvent');
		return true;
	}
	return Super.HandlePickupQuery(Item);
}

function LightFire()  //simulated
{
	ServerSpawnLight();
}
/*
simulated function ClientFlashlightAnims()
{
    	// We are using a weapon, and it is a flashlight weapon.


    if (bTorchEnabled)
    {
     // log(KFWeaponAttachment(ThirdPersonActor).WeaponIdleMovementAnim);
     // log(KFWeaponAttachment(ThirdPersonActor).SecondaryFireIdleMovementAnim);

       // It has been activated.
       if( Flashlight != none &&
         Flashlight.bHasLight)
        {
          if (!bUsingFlashlightAnims)
          {
           bUsingFlashlightAnims = true;
           KFPawn(Owner).UpdateClientAnim(KFWeaponAttachment(ThirdPersonActor).default.SecondaryWeaponIdleMovementAnim);
          }
        }
        else
        {          // Otherwise, just make sure its default.
         if (bUsingFlashlightAnims)
         {
           bUsingFlashlightAnims = false;
           KFPawn(Owner).UpdateClientAnim(KFWeaponAttachment(ThirdPersonActor).default.WeaponIdleMovementAnim);
         }
        }

     }

}
 */

function ServerSpawnLight()
{
     if (!FireMode[0].bIsFiring && !bIsReloading)
      {
        if(FlashLight==None && KFHumanPawn(Owner).TorchBatteryLife >= 1 && pawn(Owner).Health > 0)
        {
              FlashLight=spawn(class'Effect_TacLightProjector',Instigator);
              PlaySound(sound'KFWeaponSound.HuntingCrack',SLOT_Misc,100);
              PlayAnim(ModeSwitchAnim,FireMode[0].FireAnimRate,FireMode[0].TweenTime);
              FlashLight.bHasLight=!FlashLight.bHasLight;
          }else{
              FlashLight.bHasLight=!FlashLight.bHasLight;
              PlayAnim(ModeSwitchAnim,FireMode[0].FireAnimRate,FireMode[0].TweenTime);
              PlaySound(sound'KFWeaponSound.HuntingCrack',SLOT_Misc,100);
          }
      }
}


simulated event RenderOverlays( Canvas Canvas )
{
    local int m;
    local vector NewScale3D;
    local rotator CenteredRotation;

    if (Instigator == None)
        return;

    if ( Instigator.Controller != None )
        Hand = Instigator.Controller.Handedness;

    if ((Hand < -1.0) || (Hand > 1.0))
        return;

    // draw muzzleflashes/smoke for all fire modes so idle state won't
    // cause emitters to just disappear
    for (m = 0; m < NUM_FIRE_MODES; m++)
    {
        if (FireMode[m] != None)
        {
            FireMode[m].DrawMuzzleFlash(Canvas);
        }
    }


    if ( (Hand != RenderedHand) || bInitOldMesh )
    {
        newScale3D = Default.DrawScale3D;
        if ( Hand != 0 )
            newScale3D.Y *= Hand;
        SetDrawScale3D(newScale3D);
        SetDrawScale(Default.DrawScale);
        CenteredRoll = Default.CenteredRoll;
        CenteredYaw = Default.CenteredYaw;
        CenteredOffsetY = Default.CenteredOffsetY;
        PlayerViewPivot = Default.PlayerViewPivot;
        SmallViewOffset = Default.SmallViewOffset;
        if ( SmallViewOffset == vect(0,0,0) )
            SmallViewOffset = Default.PlayerviewOffset;
        bInitOldMesh = false;
        if ( Default.SmallEffectOffset == vect(0,0,0) )
            SmallEffectOffset = EffectOffset + Default.PlayerViewOffset - SmallViewOffset;
        else
            SmallEffectOffset = Default.SmallEffectOffset;
        if ( Mesh == OldMesh )
        {
            SmallEffectOffset = EffectOffset + OldPlayerViewOffset - OldSmallViewOffset;
            PlayerViewPivot = OldPlayerViewPivot;
            SmallViewOffset = OldSmallViewOffset;
            if ( Hand != 0 )
            {
                PlayerViewPivot.Roll *= Hand;
                PlayerViewPivot.Yaw *= Hand;
            }
            CenteredRoll = OldCenteredRoll;
            CenteredYaw = OldCenteredYaw;
            CenteredOffsetY = OldCenteredOffsetY;
            SetDrawScale(OldDrawScale);
        }
        else if ( Hand == 0 )
        {
            PlayerViewPivot.Roll = Default.PlayerViewPivot.Roll;
            PlayerViewPivot.Yaw = Default.PlayerViewPivot.Yaw;
        }
        else
        {
            PlayerViewPivot.Roll = Default.PlayerViewPivot.Roll * Hand;
            PlayerViewPivot.Yaw = Default.PlayerViewPivot.Yaw * Hand;
        }
        RenderedHand = Hand;
    }
    if ( class'PlayerController'.Default.bSmallWeapons )
        PlayerViewOffset = SmallViewOffset;
    else if ( Mesh == OldMesh )
        PlayerViewOffset = OldPlayerViewOffset;
    else
        PlayerViewOffset = Default.PlayerViewOffset;
    if ( Hand == 0 )
        PlayerViewOffset.Y = CenteredOffsetY;
    else
        PlayerViewOffset.Y *= Hand;



    SetLocation( Instigator.Location + Instigator.CalcDrawOffset(self) );
    
    // Line it up as we're drawing it to avoid weirdness, but then let the rotation wander.
    
    if (pawn(Owner).PendingWeapon == self)
     SetRotation( Instigator.GetViewRotation() );


    
    Canvas.DrawActor(self, false, false, DisplayFOV);


    if ( Hand == 0 )
    {
        CenteredRotation = Instigator.GetViewRotation();
        CenteredRotation.Yaw += CenteredYaw;
        CenteredRotation.Roll = CenteredRoll;
        SetRotation(CenteredRotation);
    }
    else
        SetRotation( Instigator.GetViewRotation() );


    PreDrawFPWeapon();  // Laurent -- Hook to override things before render (like rotation if using a staticmesh)

    //bDrawingFirstPerson = true;

    //bDrawingFirstPerson = false;
    if ( Hand == 0 )
        PlayerViewOffset.Y = 0;


}

exec function ReloadMeNow()
{
	local float ReloadMulti;

	if(!AllowReload())
		return;
	if( KFPawn(Instigator)!=None )
		ReloadMulti = KFPawn(Instigator).GetVeteran().Static.GetReloadSpeedModifier(Self);
	else ReloadMulti = 1;
	bIsReloading = true;
	ReloadTimer = Level.TimeSeconds;
	ReloadRate = Default.ReloadRate/ReloadMulti;
	PlaySound(ReloadBeginSound, SLOT_Misc, TransientSoundVolume,,TransientSoundRadius,ReloadMulti,false);
	ClientReload();
	Instigator.SetAnimAction(WeaponReloadAnim);
}

simulated function ClientReload()
{
	local float ReloadMulti;

	if( KFPawn(Instigator)!=None )
		ReloadMulti = KFPawn(Instigator).GetVeteran().Static.GetReloadSpeedModifier(Self);
	else ReloadMulti = 1;
	bIsReloading = true;
	PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.1);
}

// This function is borked. I think it's calcualting something
// best called numclips, but there is no numclips
// TODO - purge or correct any calls to this function
simulated function recalcClipCount(byte mode)
{
    ClipCount = default.ClipCount ;
    if(ammoAmount(mode) < default.ClipCount)
        clipCount = 1 ;
}

simulated function ClientReloadEffects(){}


exec function FinishReloading()
{
   if(!bIsReloading)
		return;

   if(bHoldToReload)
	   ActuallyFinishReloading();
}

//We shouldn't allow finishreloading to finish reloading unless
//the weapon works like that.
simulated function ActuallyFinishReloading()
{
   PlaySound(ReloadEndSound, SLOT_Misc, TransientSoundVolume,,TransientSoundRadius,, false);
   ClientFinishReloading();
   bIsReloading = false;
   bReloadEffectDone = false;
}

simulated function ClientFinishReloading()
{
	bIsReloading = false;
	PlayIdle();

	if(Instigator.PendingWeapon != none && Instigator.PendingWeapon != self)
		Instigator.Controller.ClientSwitchToBestWeapon();
}

function ServerSetAiming(bool IsAiming)
{
	if( KFHumanPawn(Instigator)!=None )
		KFHumanPawn(Instigator).SetAiming(IsAiming);
	bAimingRifle = IsAiming;
}

function bool AllowReload()
{
        if(KFInvasionBot(Instigator.Controller) != None && !bIsReloading &&
		ClipLeft < ClipCount && AmmoAmount(0) > ClipLeft)
		return true;
	if(FireMode[0].IsFiring() || FireMode[1].IsFiring() ||
		   bIsReloading || ClipLeft >= ClipCount ||
		   ClientState == WS_BringUp ||
		   AmmoAmount(0) <= ClipLeft ||
                   (FireMode[0].NextFireTime - Level.TimeSeconds) > 0.1 )
		return false;
	return true;
}

simulated function PostNetReceive()
{
    //This function changes the weapon in netplay if it has no ammo
    //we WANT to be able to select guns without ammo. Therefore this
    //function has to be overridden do it does.....nothing.

}

function ServerStopFire(byte Mode)
{
  //TODO: This works, but could be better timing wise
  //      Still, at least the DBShottie/XBow don't have wierd
  //      negative clip sizes now

  super.ServerStopFire(Mode);

  if(ClipCount==1)
    ClipLeft=1;

}

// TODO: Play spot the difference
// cut n pasted to change putdown behaviours
simulated function Timer()
{
	local int Mode;
	local float OldDownDelay;

	OldDownDelay = DownDelay;
	DownDelay = 0;
	


    if (ClientState == WS_BringUp)
    {
		for( Mode = 0; Mode < NUM_FIRE_MODES; Mode++ )
	       FireMode[Mode].InitEffects();
        PlayIdle();
        ClientState = WS_ReadyToFire;
        

    }
    else if (ClientState == WS_PutDown)
    {
        if ( OldDownDelay > 0 )
        {
            if ( HasAnim(PutDownAnim) )
                PlayAnim(PutDownAnim, PutDownAnimRate, 0.0);
			SetTimer(PutDownTime, false);
			return;
		}
		if ( Instigator.PendingWeapon == None )
		{
			if(KFPawn(Instigator)!=none)
			  KFPawn(Instigator).WeaponDown();
			//TODO - resolve this one
            ClientState = WS_ReadyToFire;
            //ClientState = WS_Hidden;
		}
		else
		{
			ClientState = WS_Hidden;
			Instigator.ChangedWeapon();
			if ( Instigator.Weapon == self )
			{
				PlayIdle();
				ClientState = WS_ReadyToFire;
			}
			else
			{
				for( Mode = 0; Mode < NUM_FIRE_MODES; Mode++ )
					FireMode[Mode].DestroyEffects();
			}
		}
    }
}

// Kludge to prevent destroyed weapons destroying the ammo if other guns
// are still using the same ammo
simulated function Destroyed()
{
	local byte m;
	local Inventory InvIt;
	local byte bSaveAmmo[NUM_FIRE_MODES]; // byte, because bool arrays aren't allowed :(

	AmbientSound = None;

	if(Owner!=none)
	{
		for(InvIt = Owner.Inventory; InvIt!=none; InvIt=InvIt.Inventory)
		{
			if(Weapon(InvIt)!=none && InvIt!=self)
			{
				for(m=0; m < NUM_FIRE_MODES; m++)
				{
					if( Weapon(InvIt).Ammo[m]==Ammo[m] )
						bSaveAmmo[m] = 1;
				}
			}
		}
	}

	for (m = 0; m < NUM_FIRE_MODES; m++)
	{
		if ( FireMode[m] != None )
			FireMode[m].DestroyEffects();
		if( Ammo[m] != none && bSaveAmmo[m]==0 )
		{
			Ammo[m].Destroy();
			Ammo[m] = None;
		}
	}
	if( FlashLight!=None )
		FlashLight.Destroy();
	super(Inventory).Destroyed();
}

// TODO: Was a logged WeaponChange here, that prevented super being called
//       The non-called super may have been deliberate, in which case restore
//       said behavior. If not, kill this comment


simulated function Weapon PrevWeapon(Weapon CurrentChoice, Weapon CurrentWeapon)
{

    //log("PREVWEAPON - "$self$" CurrentChoice-"$CurrentChoice$" CurrentWeapon-"$CurrentWeapon);

    //allow selection of empty guns, so that we can select them
    //in order to chuck them away

    //if ( HasAmmo() )
    //{
        if ( (CurrentChoice == None) )
        {
            if ( CurrentWeapon != self )
                CurrentChoice = self;
        }
        else if ( InventoryGroup == CurrentWeapon.InventoryGroup )
        {
            if ( (GroupOffset < CurrentWeapon.GroupOffset)
                && ((CurrentChoice.InventoryGroup != InventoryGroup) || (GroupOffset > CurrentChoice.GroupOffset)) )
                CurrentChoice = self;
		}
        else if ( InventoryGroup == CurrentChoice.InventoryGroup )
        {
            if ( GroupOffset > CurrentChoice.GroupOffset )
                CurrentChoice = self;
        }
        else if ( InventoryGroup > CurrentChoice.InventoryGroup )
        {
			if ( (InventoryGroup < CurrentWeapon.InventoryGroup)
                || (CurrentChoice.InventoryGroup > CurrentWeapon.InventoryGroup)
                || ( (CurrentChoice.InventoryGroup == CurrentWeapon.InventoryGroup) && (CurrentChoice.GroupOffset>CurrentWeapon.GroupOffset) ) )
                CurrentChoice = self;
        }
        else if ( (CurrentChoice.InventoryGroup > CurrentWeapon.InventoryGroup || ( (CurrentChoice.InventoryGroup == CurrentWeapon.InventoryGroup) && (CurrentChoice.GroupOffset>CurrentWeapon.GroupOffset) ))
                && (InventoryGroup < CurrentWeapon.InventoryGroup) )
            CurrentChoice = self;
    //}

    if ( Inventory == None )
        return CurrentChoice;
    else
        return Inventory.PrevWeapon(CurrentChoice,CurrentWeapon);
}

simulated function Weapon NextWeapon(Weapon CurrentChoice, Weapon CurrentWeapon)
{

    //log("NEXTWEAPON - "$self$" CurrentChoice-"$CurrentChoice$" CurrentWeapon-"$CurrentWeapon);

    //allow selection of empty guns, so that we can select them
    //in order to chuck them away

    //if ( HasAmmo() )
    //{
        if ( (CurrentChoice == None) )
        {
            if ( CurrentWeapon != self )
                CurrentChoice = self;
        }
        else if ( InventoryGroup == CurrentWeapon.InventoryGroup )
        {
            if ( (GroupOffset > CurrentWeapon.GroupOffset)
                && ((CurrentChoice.InventoryGroup != InventoryGroup) || (GroupOffset < CurrentChoice.GroupOffset)) )
                CurrentChoice = self;
        }
        else if ( InventoryGroup == CurrentChoice.InventoryGroup )
        {
			if ( GroupOffset < CurrentChoice.GroupOffset )
                CurrentChoice = self;
        }

        else if ( InventoryGroup < CurrentChoice.InventoryGroup )
        {
            if ( (InventoryGroup > CurrentWeapon.InventoryGroup)
                || (CurrentChoice.InventoryGroup < CurrentWeapon.InventoryGroup)
                || ( (CurrentChoice.InventoryGroup == CurrentWeapon.InventoryGroup) && (CurrentChoice.GroupOffset<CurrentWeapon.GroupOffset) ) )
                CurrentChoice = self;
        }
        else if ( (CurrentChoice.InventoryGroup < CurrentWeapon.InventoryGroup || (CurrentChoice.InventoryGroup == CurrentWeapon.InventoryGroup) && (CurrentChoice.GroupOffset<CurrentWeapon.GroupOffset))
                && (InventoryGroup > CurrentWeapon.InventoryGroup) )
            CurrentChoice = self;
    //}

    if ( Inventory == None )
        return CurrentChoice;
    else
        return Inventory.NextWeapon(CurrentChoice,CurrentWeapon);
}

simulated function bool PutDown()
{
	if(bIsReloading)
		return false;
	return Super.PutDown();
}

simulated function BringUp(optional Weapon PrevWeapon)
{
	if( KFHumanPawn(Instigator)!=None )
		KFHumanPawn(Instigator).SetAiming(False);
	bAimingRifle = False;
	bIsReloading = false;
	IdleAnim = Default.IdleAnim;
	Super.BringUp(PrevWeapon);
}

simulated function bool ConsumeAmmo( int Mode, float Load, optional bool bAmountNeededIsMax )
{
	if( Super.ConsumeAmmo(Mode, Load, bAmountNeededIsMax) )
	{
		if( Load > 0 )
			ClipLeft--;   // ClipLeft --
		return true;
	}
	return false;
}

//TODO - this should, in theory, let us buy/carry more ammo.
//       is this intended, or should this side-effect be squashed?
function ClipUpgrade()
{
 ClipCount += (0.25 * default.ClipCount);
}

event WeaponTick(float dt)
{
	local float LastSeenSeconds,ReloadMulti;

     if ( (Level.NetMode == NM_Client) || Instigator == None || Instigator.PlayerReplicationInfo == None)
        return;

	// Turn it off on death  / battery expenditure
	if (FlashLight != none)
	{
		// Keep the 1Pweapon client beam up to date.
		AdjustLightGraphic();
   
   if (FlashLight.bHasLight)
   {
    if (Instigator.Health <= 0 ||
        KFHumanPawn(Instigator).TorchBatteryLife <= 0 ||
        Instigator.PendingWeapon != none )
        {
          //Log("Killing Light...you're out of batteries, or switched / dropped weapons");
          KFHumanPawn(Instigator).bTorchOn = false;
          ServerSpawnLight();
        }
    }
  }


   //   SetLocation( Instigator.Location + Instigator.CalcDrawOffset(self) +  SmallViewOffset);
  //    SetRotation( Instigator.GetViewRotation() );


	if(!bIsReloading)
	{

		if(!Instigator.IsHumanControlled())
		{
			LastSeenSeconds = Level.TimeSeconds - Instigator.Controller.LastSeenTime;
			if(ClipLeft == 0 || ((LastSeenSeconds >= 5 || LastSeenSeconds > ClipLeft) && ClipLeft < ClipCount))
				ReloadMeNow();
		}
	}
	else
	{

		if((Level.TimeSeconds - ReloadTimer) >= ReloadRate)
		{
			if(AmmoAmount(0) <= ClipCount && !bHoldToReload)
			{
				ClipLeft = AmmoAmount(0);
				ActuallyFinishReloading();
			}
			else
			{
				if( KFPawn(Instigator)!=None )
					ReloadMulti = KFPawn(Instigator).GetVeteran().Static.GetReloadSpeedModifier(Self);
				else ReloadMulti = 1;
				PlaySound(ReloadSound, SLOT_Misc, TransientSoundVolume,,TransientSoundRadius,ReloadMulti,false);

				InsertBullet();

				if(ClipLeft < ClipCount && ClipLeft < AmmoAmount(0) && bHoldToReload)
					ReloadTimer = Level.TimeSeconds;
				if(ClipLeft >= ClipCount || ClipLeft >= AmmoAmount(0) || !bHoldToReload)
					ActuallyFinishReloading();
				else if( Level.NetMode!=NM_Client )
					Instigator.SetAnimAction(WeaponReloadAnim);
			}
		}
		else if(bIsReloading && !bReloadEffectDone && Level.TimeSeconds - ReloadTimer >= ReloadRate / 2)
		{
			bReloadEffectDone = true;
			ClientReloadEffects();
		}
	}
}

function InsertBullet()
{
	if(ammoAmount(0) >= clipCount)
            ClipLeft = ClipCount;
        else
            clipLeft = ammoAmount(0) ;
}

simulated function DoToggle ()
{
	PlaySound(ToggleSound, SLOT_Misc, TransientSoundVolume,,TransientSoundRadius,, false);
}

// TODO - Decode the purpose of this mangled mess
simulated function float ChargeBar()
{
	Return 0;
}

function byte BestMode()
{
	return 0;
}

// complete cut n' paste job needed, so that it can be modified
// to stop this function giving ammo to empty guns that have been
// thrown out
function GiveAmmo(int m, WeaponPickup WP, bool bJustSpawned)
{
    local bool bJustSpawnedAmmo;
    local int addAmount, InitialAmount;

    if ( FireMode[m] != None && FireMode[m].AmmoClass != None )
    {
        Ammo[m] = Ammunition(Instigator.FindInventoryType(FireMode[m].AmmoClass));
		bJustSpawnedAmmo = false;

		if ( bNoAmmoInstances )
		{
            if ( (FireMode[m].AmmoClass == None) || ((m != 0) && (FireMode[m].AmmoClass == FireMode[0].AmmoClass)) )
				return;

			InitialAmount = FireMode[m].AmmoClass.Default.InitialAmount;

            // HERE IS THE IMPORTANT CHANGE
            //if ( (WP != None) && ((WP.AmmoAmount[0] > 0) || (WP.AmmoAmount[1] > 0))  )
			if(WP!=none && WP.bThrown==true)
            {
                InitialAmount = WP.AmmoAmount[m];
                if(KFWeaponPickup(WP)!=none)
                  ClipLeft = KFWeaponPickup(WP).ClipLeft;
			}
			else
			{
			  // Other change - if not thrown, give the gun a full clip
			  ClipLeft = ClipCount;

			}

			if ( Ammo[m] != None )
			{
				addamount = InitialAmount + Ammo[m].AmmoAmount;
				Ammo[m].Destroy();

			}
			else
				addAmount = InitialAmount;

			AddAmmo(addAmount,m);
		}
		else
		{
			if ( (Ammo[m] == None) && (FireMode[m].AmmoClass != None) )
			{
				Ammo[m] = Spawn(FireMode[m].AmmoClass, Instigator);
				Instigator.AddInventory(Ammo[m]);
				bJustSpawnedAmmo = true;
			}
			else if ( (m == 0) || (FireMode[m].AmmoClass != FireMode[0].AmmoClass) )
				bJustSpawnedAmmo = ( bJustSpawned || ((WP != None) && !WP.bWeaponStay) );

            // and here is the modification for instanced ammo actors
			//if ( (WP != None) && ((WP.AmmoAmount[0] > 0) || (WP.AmmoAmount[1] > 0))  )

            if(WP!=none && WP.bThrown==true)
            {
				addAmount = WP.AmmoAmount[m];
                if(KFWeaponPickup(WP)!=none)
                  ClipLeft = KFWeaponPickup(WP).ClipLeft;
            }
			else if ( bJustSpawnedAmmo )
			{
				addAmount = Ammo[m].InitialAmount;
				//new KF bit here to
				ClipLeft = ClipCount;
			}

			Ammo[m].AddAmmo(addAmount);
			Ammo[m].GotoState('');
		}
    }
}

//this is a terribly ugly hack allowing us to silently add weapons
//in the case of buy menu consumables

//This does NOT work online and has been replaced.

function SilentGiveTo(Pawn Other, optional Pickup Pickup)
{
	local int m;
	local weapon w;
	local bool bJustSpawned;

	Instigator = Other;
	W = Weapon(Instigator.FindInventoryType(class));
	if ( W == None || W.Class != Class ) // added class check because somebody made FindInventoryType() return subclasses for some reason
	{
		bJustSpawned = true;
		Super.GiveTo(Other);
		W = self;
	}
	for (m = 0; m < NUM_FIRE_MODES; m++)
	{
		if ( FireMode[m] != None )
		{
			FireMode[m].Instigator = Instigator;
			W.GiveAmmo(m,WeaponPickup(Pickup),bJustSpawned);
		}
	}


	if ( !bJustSpawned )
	{
		for (m = 0; m < NUM_FIRE_MODES; m++)
			Ammo[m] = None;
		Destroy();
	}
}

// Modded to allow for throwing even when out of ammo.  (also added : You cannot throw while reloading)
simulated function bool CanThrow()
{
    local int Mode;

    if(bKFNeverThrow)
      return false;

    for (Mode = 0; Mode < NUM_FIRE_MODES; Mode++)
    {
        if ( FireMode[Mode].bFireOnRelease && FireMode[Mode].bIsFiring )
            return false;
        if ( FireMode[Mode].NextFireTime > Level.TimeSeconds)
            return false;
    }
    return (bCanThrow && !bIsReloading && (ClientState == WS_ReadyToFire || (Level.NetMode == NM_DedicatedServer) || (Level.NetMode == NM_ListenServer)));
}

function DropFrom(vector StartLocation)
{
    local int m;
    local Pickup Pickup;

    if (!bCanThrow)
        return;

    ClientWeaponThrown();

    for (m = 0; m < NUM_FIRE_MODES; m++)
    {
        if (FireMode[m].bIsFiring)
            StopFire(m);
    }

    if ( Instigator != None )
    {
        DetachFromPawn(Instigator);
    }

    Pickup = Spawn(PickupClass,,, StartLocation);
    if ( Pickup != None )
    {
        Pickup.InitDroppedPickupFor(self);
        Pickup.Velocity = Velocity;
        if (Instigator.Health > 0)
            WeaponPickup(Pickup).bThrown = true;
    }

    Destroy();
}


// Only fill to initial the FIRST time we come across this weapon.

simulated function FillToInitialAmmo()
{
    if ( bNoAmmoInstances )
    {
        if ( AmmoClass[0] != None )
            AmmoCharge[0] = Max(AmmoCharge[0], AmmoClass[0].Default.InitialAmount);
        if ( (AmmoClass[1] != None) && (AmmoClass[0] != AmmoClass[1]) )
            AmmoCharge[1] = Max(AmmoCharge[1], AmmoClass[1].Default.InitialAmount);
        return;
    }

    if ( Ammo[0] != None )
        Ammo[0].AmmoAmount = Max(Ammo[0].AmmoAmount,Ammo[0].InitialAmount);
    if ( Ammo[1] != None )
        Ammo[1].AmmoAmount = Max(Ammo[1].AmmoAmount,Ammo[1].InitialAmount);//InitialAmount
}





// Change the Accuracy based on player movement
simulated function AccuracyUpdate(float Velocity)
{
 if (Owner != none)
 {
   if (KFFire(FireMode[0])!= none)
    KFFire(FireMode[0]).AccuracyUpdate(Velocity);
   else
   if  (KFShotgunFire(FireMode[0]) !=none)
    KFShotgunFire(FireMode[0]).AccuracyUpdate(Velocity);
 }
}


function AdjustLightGraphic()
{
  if (TacShine == none)
  {
     TacShine = Spawn(TacShineClass,,,,);
     AttachToBone(TacShine,'LightBone');
  }

  if (KFHumanPawn(Owner) != none && FlashLight != none)
     Tacshine.bHidden = !FlashLight.bHasLight;
     //Tacshine.bHidden = !KFHumanPawn(Owner).bTorchOn;

}

simulated function PlayAnimZoom( bool bZoomNow ); // Called from KFZoom whenever start or end the zooming.
simulated function bool CanZoomNow()
{
	Return !FireMode[0].bIsFiring;
}

simulated function float GetAmmoMulti()
{
	if( NextAmmoCheckTime>Level.TimeSeconds )
		Return LastAmmoResult;
	NextAmmoCheckTime = Level.TimeSeconds+1;
	if( FireMode[0]!=None && FireMode[0].AmmoClass!=None && KFPawn(Instigator)!=None )
		LastAmmoResult = KFPawn(Instigator).GetVeteran().Static.AddExtraAmmoFor(FireMode[0].AmmoClass);
	else LastAmmoResult = 1;
	Return LastAmmoResult;
}
simulated function int MaxAmmo(int mode)
{
	if ( AmmoClass[mode] != None )
		return AmmoClass[mode].Default.MaxAmmo*GetAmmoMulti();
	return 0;
}
simulated function bool AmmoMaxed(int mode)
{
	if ( AmmoClass[mode] == None )
		return false;

	if ( bNoAmmoInstances )
	{
		if ( AmmoClass[0] == AmmoClass[mode] )
			mode = 0;
		return AmmoCharge[mode] >= MaxAmmo(mode);
	}
	if ( Ammo[mode] == None )
		return false;
	return (Ammo[mode].AmmoAmount >= MaxAmmo(mode));
}
simulated function float AmmoStatus(optional int Mode) // returns float value for ammo amount
{
	if ( bNoAmmoInstances )
	{
		if ( AmmoClass[Mode] == None )
			return 0;
		if ( AmmoClass[0] == AmmoClass[mode] )
			mode = 0;

		return float(AmmoCharge[Mode])/float(MaxAmmo(Mode));
	}
	if (Ammo[Mode] == None)
		return 0.0;
	else return float(Ammo[Mode].AmmoAmount) / float(Ammo[Mode].MaxAmmo)*GetAmmoMulti();
}

defaultproperties
{
     FlashBoneName="tip"
     WeaponReloadAnim="Reload1"
     ModeSwitchAnim="'"
     bReloadEffectDone=True
     Weight=10.000000
     StoppingPower=-1000
     UpKick=500
     TacShineClass=Class'KFMod.TacLightShineAttachment'
     bNoAmmoInstances=False
     Description="This is a very generic weapon."
     LightType=LT_Steady
     LightEffect=LE_NonIncidence
     LightHue=30
     LightSaturation=150
     LightBrightness=255.000000
     LightRadius=10.000000
     LightPeriod=3
     AmbientGlow=0
     TransientSoundVolume=100.000000
}
