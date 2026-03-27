Class KFPlayerStats extends Object
	Config(KFStats)
	PerObjectConfig;

var() config string UserName,CurrentVeterancy;
var() config int	TotalMeleeDamage,
			TotalKills,
			TotalHealed,
			TotalWelded,
			DecaptedKills,
			MeleeKills,
			PowerWpnKills,
			BullpupDamage,
			StalkerKills,
			TotalPlaytime,
			GamesWon,
			GamesLost;
var KFPlayerController CurrentOwner;
struct ActStats
{
	var bool bNotified;
	var Class<KFVeterancyTypes> VetCl;
};
var array<ActStats> ActiveStats;
var float LastCheckTime;
var bool bHasBeenInit;

function InitFor( KFPlayerController Other )
{
	local KFGameType KF;
	local int i,j;

	CurrentOwner = Other;
	if( CurrentVeterancy!="" )
	{
		KFPlayerReplicationInfo(Other.PlayerReplicationInfo).ClientVeteranSkill = Class<KFVeterancyTypes>(DynamicLoadObject(CurrentVeterancy,Class'Class',True));
		if( KFHumanPawn(Other.Pawn)!=None )
			KFHumanPawn(Other.Pawn).CheckCarryWeight();
	}
	if( bHasBeenInit )
		Return;
	bHasBeenInit = True;
	KF = KFGameType(Other.Level.Game);
	if( KF==None )
		Return;
	j = KF.LoadedSkills.Length;
	ActiveStats.Length = j;
	For( i=0; i<j; i++ )
	{
		ActiveStats[i].VetCl = KF.LoadedSkills[i];
		ActiveStats[i].bNotified = False;
	}
	CheckStatsAvailable(False);
}
function ReceiveKill( bool bWasMelee, bool bWasRanged, bool bWasPower, bool bStalker )
{
	TotalKills++;
	if( bWasMelee )
		MeleeKills++;
	if( bWasRanged )
		DecaptedKills++;
	if( bWasPower )
		PowerWpnKills++;
	if( bStalker )
		StalkerKills++;
	CheckStatsAvailable(True);
}
function ReceiveDamage( int Dmg, bool bWasBullpup )
{
	if( bWasBullpup )
		BullpupDamage+=Dmg;
	else TotalMeleeDamage+=Dmg;
	CheckStatsAvailable(True);
}
function ReceiveHealing( int Healed )
{
	TotalHealed+=Healed;
	CheckStatsAvailable(True);
}
function ReceiveWelded( int WldAmt )
{
	TotalWelded+=WldAmt;
	CheckStatsAvailable(True);
}
function CheckStatsAvailable( bool bMessageOwner )
{
	local int i,j;

	if( LastCheckTime>CurrentOwner.Level.TimeSeconds )
		Return;
	LastCheckTime = CurrentOwner.Level.TimeSeconds+1;
	j = ActiveStats.Length;
	for( i=0; i<j; i++ )
	{
		if( ActiveStats[i].bNotified )
			continue;
		else if( ActiveStats[i].VetCl.Static.QualityFor(Self) )
		{
			ActiveStats[i].bNotified = True;
			if( bMessageOwner )
			{
				CurrentOwner.ReceiveLocalizedMessage(Class'KFVetEarnedMessage',,,,ActiveStats[i].VetCl);
				CurrentOwner.ClientReceiveStat(ActiveStats[i].VetCl,True);
			}
		}
	}
}
function ApplyVeterancy( Class<KFVeterancyTypes> VType )
{
	if( VType==None )
		CurrentVeterancy = "";
	else CurrentVeterancy = string(VType);
	KFPlayerReplicationInfo(CurrentOwner.PlayerReplicationInfo).ClientVeteranSkill = VType;
	if( KFHumanPawn(CurrentOwner.Pawn)!=None )
		KFHumanPawn(CurrentOwner.Pawn).CheckCarryWeight();
}

defaultproperties
{
}
