class SyringeFire extends SyringeAltFire;

var KFHumanPawn PendingHealTarget;

function DoFireEffect()
{
    PendingHealTarget = GetHealee();
    SetTimer(InjectDelay, False);
}


Function Timer()
{
	local PlayerReplicationInfo OtherPRI;
	local int MedicReward;
	local KFHumanPawn Healed;
	local KFPlayerController PC;
	local int HealSum; // for modifying based on perks

    Healed = PendingHealTarget;
    PendingHealTarget = None;

	if( Healed!=none && Healed.Health>0 && Healed!=Instigator )
	{
		Weapon.ConsumeAmmo(ThisModeNum, AmmoPerFire);
		MedicReward = Syringe(Weapon).HealBoostAmount;
		if( (Healed.Health+MedicReward)>Healed.HealthMax )
		{
			MedicReward = Healed.HealthMax-Healed.Health;
			if( MedicReward<0 )
				MedicReward = 0;
		}
		
		HealSum = Syringe(Weapon).HealBoostAmount * KFPawn(Instigator).GetVeteran().Static.GetHealPotency();
		Healed.GiveHealth(HealSum, Healed.HealthMax);

		// reward medics.
		PC = KFPlayerController(Instigator.Controller);
		if( MedicReward>0 && PC!=None && (PC.MyActiveStats!=None || PC.FindStatsObject()) )
			PC.MyActiveStats.ReceiveHealing(MedicReward);

		OtherPRI = Instigator.PlayerReplicationInfo;
		if ( KFPlayerReplicationInfo(OtherPRI)!=None )
		{
			MedicReward = rand(2)+3;
			OtherPRI.Score += MedicReward;
			OtherPRI.Team.Score += MedicReward;
			KFPlayerReplicationInfo(OtherPRI).ThreeSecondScore += MedicReward;
			if( KFHumanPawn(Instigator)!=none )
				KFHumanPawn(Instigator).AlphaAmount = 255;
		}
		
	}
}
function KFHumanPawn GetHealee()
{
	local KFHumanPawn KFHP, BestKFHP;
	local vector Dir;
	local float TempDot, BestDot;

	Dir = vector(Instigator.GetViewRotation());

	foreach Instigator.VisibleCollidingActors(class'KFHumanPawn', KFHP, 80.0)
	{
		if ( KFHP.Health < KFHP.HealthMax && KFHP.Health > 0 )
		{
			TempDot = Dir dot (KFHP.Location - Instigator.Location);
			if ( TempDot > 0.7 && TempDot > BestDot )
			{
				BestKFHP = KFHP;
				BestDot = TempDot;
			}
		}
	}
	return BestKFHP;
}

function bool AllowFire()
{
   	local KFHumanPawn Healtarget;

	Healtarget = GetHealee();
    // Can't use syringe if we can't find a target
	if(Healtarget == none)
        return false;
    // Can't use syringe if our target is already being healed.
    if(Healtarget.Health == Healtarget.Healthmax || Healtarget.healthToGive > 0 )
        return false;

    return Weapon.AmmoAmount(ThisModeNum) >= AmmoPerFire;
}

defaultproperties
{
     InjectDelay=0.360000
     FireAnim="Fire"
     FireRate=2.800000
     AmmoPerFire=250
}
