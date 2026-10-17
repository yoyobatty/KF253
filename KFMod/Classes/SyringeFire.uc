class SyringeFire extends SyringeAltFire;

var KFHumanPawn PendingHealTarget;
var() float CashPerHealth;	// a medic's pay for each point of health restored to a team-mate

function DoFireEffect()
{
    PendingHealTarget = GetHealee();
    SetTimer(InjectDelay, False);
}


simulated function Timer()
{
	local KFHumanPawn Healed;
	local int HealSum; // for modifying based on perks

    Healed = PendingHealTarget;
    PendingHealTarget = None;

	if( Healed!=none && Healed.Health>0 && Healed!=Instigator )
	{
		Weapon.ConsumeAmmo(ThisModeNum, AmmoPerFire);
		HealSum = Syringe(Weapon).HealBoostAmount * KFPawn(Instigator).GetVeteran().Static.GetHealPotency();
		PayForHealing(Instigator, Restores(Healed, HealSum));
		Healed.GiveHealth(HealSum, Healed.HealthMax);
		if( KFHumanPawn(Instigator)!=none )
			KFHumanPawn(Instigator).AlphaAmount = 255;
	}
}

// How much of a heal of HealSum Healed really gets: no more than it is missing, a heal still being paid out counted
static function int Restores(Pawn Healed, int HealSum)
{
	local float Missing;

	Missing = Healed.HealthMax - (Healed.Health + KFPawn(Healed).healthToGive);
	return Max(0, Min(HealSum, int(Missing)));
}

// The medic's pay, score and stats for health restored to a team-mate (it was 3 or 4 a needle, whatever it healed, and
// the stats counted the heal before the perk's potency)
static function PayForHealing(Pawn Medic, int Restored)
{
	local KFPlayerReplicationInfo PRI;
	local KFPlayerController PC;
	local int Pay;

	if( Medic==None || Restored<=0 )
		return;
	PC = KFPlayerController(Medic.Controller);
	if( PC!=None && (PC.MyActiveStats!=None || PC.FindStatsObject()) )
		PC.MyActiveStats.ReceiveHealing(Restored);
	PRI = KFPlayerReplicationInfo(Medic.PlayerReplicationInfo);
	if( PRI==None )
		return;
	Pay = Max(1, int(Restored * default.CashPerHealth + 0.5));
	PRI.Score += Pay;
	if( PRI.Team!=None )
		PRI.Team.Score += Pay;
	PRI.ThreeSecondScore += Pay;
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
			// (how close to the aim; not normalised, it took the farthest team-mate anywhere in the front half)
			TempDot = Dir dot Normal(KFHP.Location - Instigator.Location);
			if ( TempDot > 0.7 && TempDot > BestDot )
			{
				BestKFHP = KFHP;
				BestDot = TempDot;
			}
		}
	}
	return BestKFHP;
}

simulated function bool AllowFire()
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
     CashPerHealth=0.600000
     InjectDelay=0.360000
     FireAnim="Fire"
     FireRate=2.800000
     AmmoPerFire=250
}
