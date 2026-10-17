//=============================================================================
// BoomStick Inventory class
// Primary fires one barrel, alt fire both. The switch key reloads the gun
// with the other shell type (buckshot or slugs).
//=============================================================================
class BoomStick extends KFWeaponShotgun;

// Shells
var bool bSlugsLoaded;            // the shells in the gun are slugs
var bool bWantSlugs;              // shell type the next reload puts in
var bool bSwapReload;             // the running reload is changing shell type
var() int SlugsPerFire;           // slugs thrown by one shell

// Reload
var() name ReloadSingleAnim;      // replaces only the fired shell
var() float SingleReloadSpeed;    // the one-shell reload runs this much faster

// Bots
var() float BotBothRange;         // both barrels at an enemy closer than this
var() int BotBothHealth;          // or at one with more health than this
var() float BotSlugRange;         // an empty gun is loaded with slugs for an enemy beyond this
var() float BotSwapRange;         // buckshot is swapped out for slugs for an enemy beyond this

#EXEC OBJ LOAD FILE=KillingFloorHUD.utx

replication
{
	reliable if(Role < ROLE_Authority)
		ServerSwitchShells;

	reliable if (Role == ROLE_Authority)
		bSlugsLoaded, ClientReloadShells;
}

// Two barrels, whatever a perk does to magazines.
simulated function UpdateMagCapacity(PlayerReplicationInfo PRI)
{
	ClipCount = default.ClipCount;
}

// Bots stay on primary fire; BotWantsBoth decides how many barrels it lets off.
function byte BestMode()
{
	return 0;
}

// The reload is short, so an empty gun is no reason for a bot to put it away.
function float GetAIRating()
{
	return AIRating;
}

function float BotEnemyDist()
{
	local Controller C;

	C = Instigator.Controller;
	if ( C == None || C.Enemy == None )
		return -1;
	return VSize(C.Enemy.Location - Instigator.Location);
}

function bool BotWantsBoth()
{
	local float Dist;

	if ( Instigator == None || Instigator.IsHumanControlled() )
		return false;
	Dist = BotEnemyDist();
	if ( Dist < 0 )
		return false;
	return Dist < BotBothRange || Instigator.Controller.Enemy.Health > BotBothHealth;
}

// Switch between buckshot and slugs: the gun is reloaded with the other kind.
simulated function DoToggle ()
{
	local PlayerController Player;

	if( IsFiring() || bIsReloading )
	   return;

	bWantSlugs = !bWantSlugs;
	Player = Level.GetLocalPlayerController();
	if ( Player!=None )
	{
		if ( bWantSlugs )
			Player.ReceiveLocalizedMessage(class'KFmod.BoomStickSwitchMessage',0);
		else
			Player.ReceiveLocalizedMessage(class'KFmod.BoomStickSwitchMessage',1);
	}
	Super.DoToggle();
	ServerSwitchShells(bWantSlugs);
}

// WeaponTick starts the reload as soon as one is allowed
function ServerSwitchShells(bool bSlugs)
{
	bWantSlugs = bSlugs;
}

exec simulated function SwitchModes()
{
	DoToggle();
}

function SetShells(bool bSlugs)
{
	bSlugsLoaded = bSlugs;
	if ( BoomStickFire(FireMode[0]) != None )
		BoomStickFire(FireMode[0]).SetShells(bSlugs, SlugsPerFire);
	if ( BoomStickFire(FireMode[1]) != None )
		BoomStickFire(FireMode[1]).SetShells(bSlugs, SlugsPerFire);
}

function bool AllowReload()
{
	if ( bIsReloading || AmmoAmount(0) < 1 || !WeaponUp() )
		return false;
	// let the last shot's animation finish
	if ( FireMode[0].NextFireTime > Level.TimeSeconds || FireMode[1].NextFireTime > Level.TimeSeconds )
		return false;
	// a trigger pulled this tick fires before any reload starts
	if ( ClipLeft > 0 && ((FireMode[0].bIsFiring && !FireMode[0].bNowWaiting) || (FireMode[1].bIsFiring && !FireMode[1].bNowWaiting)) )
		return false;
	if ( bWantSlugs != bSlugsLoaded )
		return true;
	return ClipLeft < ClipCount && AmmoAmount(0) > ClipLeft;
}

// (a change of shell type is something to load too)
function bool ReloadWanted()
{
	return (bWantSlugs != bSlugsLoaded && AmmoAmount(0) > 0) || Super.ReloadWanted();
}

exec function ReloadMeNow()
{
	local float ReloadMulti;
	local bool bSingle;

	if ( !ReloadNowOrLater() )
		return;

	// a bot filling an empty gun picks the shells for the enemy in front of it
	if ( !Instigator.IsHumanControlled() && ClipLeft < 1 )
		bWantSlugs = BotEnemyDist() > BotSlugRange;

	ReloadMulti = 1;
	if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
		ReloadMulti = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetReloadSpeedModifier(self);
	if( KFPawn(Instigator)!=None )
		ReloadMulti *= KFPawn(Instigator).GetReloadSpeedScale();

	// changing shell type empties both barrels; otherwise a live shell stays where it is
	bSwapReload = (bWantSlugs != bSlugsLoaded);
	bSingle = !bSwapReload && Min(ClipCount, AmmoAmount(0)) - ClipLeft == 1;

	bIsReloading = true;
	ReloadTimer = Level.TimeSeconds;
	ReloadRate = Default.ReloadRate/ReloadMulti;
	if ( bSingle )
		ReloadRate /= SingleReloadSpeed;
	PlaySound(ReloadBeginSound, SLOT_Misc, TransientSoundVolume,,TransientSoundRadius,ReloadMulti,false);
	ClientReloadShells(bSingle);
	Instigator.SetAnimAction(WeaponReloadAnim);

	ZoomLevel=0.0;
	if(PlayerController(Instigator.Controller)!=none)
		PlayerController(Instigator.Controller).StopZoom();
}

simulated function ClientReloadShells(bool bSingle)
{
	local float Rate;

	Rate = ReloadAnimRate;
	if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
		Rate *= KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetReloadSpeedModifier(self);
	if( KFPawn(Instigator)!=None )
		Rate *= KFPawn(Instigator).GetReloadSpeedScale();

	bIsReloading = true;
	if ( bSingle )
		PlayAnim(ReloadSingleAnim, Rate*SingleReloadSpeed, 0.05);
	else
		PlayAnim(ReloadAnim, Rate, 0.05);
}

// The gun is open with the shells out, so a reload runs to its end.
simulated function bool InterruptReload()
{
	return false;
}

exec function FinishReloading()
{
}

// A bot does not put the gun away empty; it would meet its next enemy with nothing loaded.
simulated function bool PutDown()
{
	if ( Instigator != None && !Instigator.IsHumanControlled() && ClipLeft < 1 && AmmoAmount(0) > 0 )
		return false;
	return Super.PutDown();
}

simulated function InsertBullet()
{
	if ( bSwapReload )
		SetShells(bWantSlugs);
	bSwapReload = false;
	ClipLeft = Min(ClipCount, AmmoAmount(0));
	ClientForceKFAmmoUpdate(ClipLeft,AmmoAmount(0));
}

// A shot can empty one barrel or both.
simulated function bool ConsumeAmmo( int Mode, float Load, optional bool bAmountNeededIsMax )
{
	if( Super(Weapon).ConsumeAmmo(Mode, Load, bAmountNeededIsMax) )
	{
		ClipLeft = Max(0, ClipLeft - int(Load));
		return true;
	}
	return false;
}

simulated event WeaponTick(float dt)
{
	Super.WeaponTick(dt);

	if ( Role < ROLE_Authority || Instigator == None || bIsReloading )
		return;

	if ( !Instigator.IsHumanControlled() && !bSlugsLoaded && BotEnemyDist() > BotSwapRange )
		bWantSlugs = true;

	if ( bWantSlugs != bSlugsLoaded && AmmoAmount(0) < 1 )
		SetShells(bWantSlugs);     // nothing to load, just keep the choice
	else if ( (ClipLeft < 1 || bWantSlugs != bSlugsLoaded) && Instigator.PendingWeapon == None && AllowReload() )
		ReloadMeNow();             // an empty gun reloads itself, as the old one-piece animation did
}

defaultproperties
{
	SlugsPerFire=1
	ReloadSingleAnim="ReloadSingle"
	SingleReloadSpeed=1.150000
	BotBothRange=400.000000
	BotBothHealth=500
	BotSlugRange=600.000000
	BotSwapRange=1200.000000
	ClipCount=2
	ReloadRate=2.050000
	ReloadAnim="Reload"
	ReloadAnimRate=1.000000
	UpKick=2500
	FireModeClass(0)=Class'KFMod.BoomStickFire'
	FireModeClass(1)=Class'KFMod.BoomStickAltFire'
	PutDownAnim="PutDown"
	SelectSound=Sound'KFPlayerSound.getweaponout'
	AIRating=0.900000
	CurrentRating=0.900000
	bSniping=False
	OldCenteredOffsetY=0.000000
	OldPlayerViewOffset=(X=-8.000000,Y=5.000000,Z=-6.000000)
	OldSmallViewOffset=(X=4.000000,Y=11.000000,Z=-12.000000)
	OldPlayerViewPivot=(Pitch=400)
	OldCenteredRoll=3000
	Description="A double barreled shotgun used by big game hunters. It fires two slugs simultaneously and can bring down even the largest targets, quickly."
	DisplayFOV=70.000000
	Priority=20
	SmallViewOffset=(X=8.000000,Y=18.000000,Z=-4.000000)
	CenteredOffsetY=-5.000000
	CenteredRoll=3000
	CenteredYaw=-1500
	InventoryGroup=4
	GroupOffset=3
	PickupClass=Class'KFMod.BoomStickPickup'
	BobDamping=4.000000
	AttachmentClass=Class'KFMod.BoomStickAttachment'
	ItemName="Hunting Shotgun"
	bUseDynamicLights=True
	Mesh=SkeletalMesh'KFWeaponModels.BoomStick'
	TransientSoundVolume=1.000000
}
