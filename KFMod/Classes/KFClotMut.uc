//-----------------------------------------------------------
//
//-----------------------------------------------------------
class KFClotMut extends Mutator;

function PostBeginPlay()
{
	SetTimer(0.1,False);
}
function Timer()
{
	local KFGameType KF;
	local byte i;
	local class<Monster> MC;

	KF = KFGameType(Level.Game);
	MC = Class<Monster>(DynamicLoadObject("KFChar.ZombieClot",Class'Class'));
	if ( KF!=None && MC!=None )
	{
		// groups of monsters that will be spawned
		KF.InitSquads.Length = 1;
		KF.InitSquads[0].MSquad.Length = 8;
		for( i=0; i<8; i++ )
			KF.InitSquads[0].MSquad[i] = MC;
	}
	Destroy();
}

defaultproperties
{
<<<<<<< HEAD
	GroupName="KF-MonsterMut"
	FriendlyName="KF Clot Mutator"
	Description="Only Clots will appear during the game."
=======
     GroupName="KF-MonsterMut"
     FriendlyName="KF Clot Mutator"
     Description="Only Clots will appear during the game."
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
