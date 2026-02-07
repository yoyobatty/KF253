class KFShadeMut extends Mutator;


function PostBeginPlay()
{
	SetTimer(0.1,False);
}
function Timer()
{
	local KFGameType KF;
	local byte i;
	local class<KFMonster> MC;

	KF = KFGameType(Level.Game);
	MC = Class<KFMonster>(DynamicLoadObject("KFChar.ZombieShade",Class'Class'));
	if ( KF!=None && MC!=None )
	{
		// groups of monsters that will be spawned
		KF.NextSpawnSquad.Length = 1;
		KF.NextSpawnSquad.Length = 12;
		for( i=0; i<12; i++ )
			KF.NextSpawnSquad[0] = MC;
	}
	Destroy();
}

defaultproperties
{
     bAddToServerPackages=True
     GroupName="KF"
     FriendlyName="Bloody Araneae"
     Description="Only shades will appear during the game, watch your step. Made by YoYoBatty"
     bAlwaysRelevant=True
     RemoteRole=ROLE_SimulatedProxy
}
