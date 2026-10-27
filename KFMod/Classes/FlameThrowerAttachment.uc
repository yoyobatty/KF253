class FlameThrowerAttachment extends KFMeleeAttachment;//KFWeaponAttachment;

var KFFlameStream Stream;	// the stream as this machine shows it, fed by each shot
var KFGasSpray Spray;		// the gas mode's jet (FlameAltFire), likewise
var KFMonster ZapTarget[3];	// (Blue Inferno) where the lightning goes just now, one after another from the nozzle (FlameBurstFire.Zap)
var vector ZapSpot;			// ...or with no one to strike, the metal floor or water it strikes instead (bZapSpot)
var bool bZapSpot;
var byte ArcCharge;			// (Blue Inferno) how far its arc flash is charged just now, out of 255 (FlameAltFire)
var KFArcCharge Charging;	// the charge as this machine shows it

replication
{
	unreliable if ( Role == ROLE_Authority )
		ZapTarget, ZapSpot, bZapSpot, ArcCharge;
}

// (the server)
function ShowCharge( float C )
{
	local byte B;

	B = byte(FClamp(C * 255.0, 0.0, 255.0));
	if ( C > 0 && B == 0 )
		B = 1;
	if ( Abs(int(B) - int(ArcCharge)) >= 8 || (B == 0) != (ArcCharge == 0) )
		ArcCharge = B;
}

// How far charged it is shown: its holder's own machine knows at once, the others go by ArcCharge
simulated function float ChargeShown()
{
	local FlameThrower FT;

	if ( Instigator != None && Instigator.IsLocallyControlled() && Instigator.Weapon != None )
	{
		FT = FlameThrower(Instigator.Weapon);
		if ( FT != None && FlameAltFire(FT.GetFireMode(1)) != None )
			return FlameAltFire(FT.GetFireMode(1)).ChargeFraction();
		return 0;
	}
	return float(ArcCharge) / 255.0;
}

simulated function Tick( float DT )
{
	local float C;

	Super.Tick(DT);
	if ( Level.NetMode == NM_DedicatedServer )
		return;
	C = 0;
	if ( Instigator != None && Instigator.Health > 0 )
		C = ChargeShown();
	if ( C > 0 )
	{
		if ( Charging == None || Charging.bDeleteMe )
		{
			Charging = Spawn(class'KFArcCharge', self);
			if ( Charging != None )
				Charging.Instigator = Instigator;
		}
		if ( Charging != None )
			Charging.SetCharge(C);
	}
	else if ( Charging != None )
	{
		Charging.Fade();
		Charging = None;
	}
}

simulated function Destroyed()
{
	if ( Charging != None )
		Charging.Fade();
	Super.Destroyed();
}

simulated event ThirdPersonEffects()
{
	Super.ThirdPersonEffects();
	if ( Level.NetMode == NM_DedicatedServer || Instigator == None )
		return;
	if ( FlashCount > 0 && FiringMode == 1 && bUpgraded )
	{
		// (the arc flash is KFArcFlash, sent by the server)
		if ( Stream != None && !Stream.bDeleteMe )
			Stream.Release();
	}
	else if ( FlashCount > 0 && FiringMode == 1 && !bUpgraded )
	{
		if ( Spray == None || Spray.bDeleteMe )
			Spray = Spawn(class'KFGasSpray', self);
		if ( Spray != None )
			Spray.Feed();
		if ( Stream != None && !Stream.bDeleteMe )
			Stream.Release();
	}
	else if ( FlashCount > 0 )
	{
		if ( Stream == None || Stream.bDeleteMe )
			Stream = Spawn(class'KFFlameStream', self);
		if ( Stream != None )
		{
			Stream.SetHot(bUpgraded);
			Stream.Feed();
		}
	}
	else if ( Stream != None && !Stream.bDeleteMe )
		Stream.Release();
}

defaultproperties
{
     TPAnims(0)="FlameThrowerFire"
     WeaponIdleMovementAnim="FlamethrowerIdle"
     Mesh=SkeletalMesh'KFWeaponModels.FlameThrower3P'
     DrawScale=0.450000
}
