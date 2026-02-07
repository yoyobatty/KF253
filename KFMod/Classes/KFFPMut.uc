//-----------------------------------------------------------
//
//-----------------------------------------------------------
class KFFPMut extends Mutator;

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
	MC = Class<Monster>(DynamicLoadObject("KFChar.ZombieFleshPound",Class'Class'));
	if ( KF!=None && MC!=None )
	{
		// groups of monsters that will be spawned
		KF.InitSquads.Length = 1;
		KF.InitSquads[0].MSquad.Length = 12;
		for( i=0; i<12; i++ )
			KF.InitSquads[0].MSquad[i] = MC;
	}
	Destroy();
}

defaultproperties
{
<<<<<<< HEAD
	GroupName="KF-MonsterMut"
	FriendlyName="Poundamonium!"
	Description="Only Fleshpounds will appear during the game. Bring a big gun."
=======
     GroupName="KF-MonsterMut"
     FriendlyName="Poundamonium!"
     Description="Only Fleshpounds will appear during the game. Bring a big gun."
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
