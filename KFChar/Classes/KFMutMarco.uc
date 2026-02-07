//-----------------------------------------------------------
// Written by .:..:
//-----------------------------------------------------------
class KFMutMarco extends Mutator;

var int LastSetWave;

function PostBeginPlay()
{
	SetTimer(0.1,False);
}
function Timer()
{
	local KFGameType KF;
	local int i,j;

	KF = KFGameType(Level.Game);
	if ( KF!=None )
	{
		for( i=0; i<KF.InitSquads.Length; i++ )
		{
			for( j=0; j<KF.InitSquads[i].MSquad.Length; j++ )
				KF.InitSquads[i].MSquad[j] = GetReplaceClass(KF.InitSquads[i].MSquad[j]);
		}
		KF.FallbackMonster = GetReplaceClass(KF.FallbackMonster);
		KF.EndGameBossClass = string(Class'ZombieBossMix');
	}
	Destroy();
}

function Class<Monster> GetReplaceClass( Class<Monster> MC )
{
	switch( MC )
	{
	case Class'ZombieClot':
		return Class'ZombieClotMix';
	case Class'ZombieBloat':
		return Class'ZombieBloatMix';
	case Class'ZombieCrawler':
		return Class'ZombieCrawlerMix';
	case Class'ZombieStalker':
		return Class'ZombieStalkerMix';
	case Class'ZombieSiren':
		return Class'ZombieSirenMix';
	case Class'ZombieScrake':
		return Class'ZombieScrakeMix';
	case Class'ZombieFleshPound':
		return Class'ZombieFleshPoundMix';
	case Class'ZombieGorefast':
		return Class'ZombieGorefastMix';
	case Class'ZombieBoss':
		return Class'ZombieBossMix';
	default:
		return MC;
	}
}

defaultproperties
{
<<<<<<< HEAD
	GroupName="KF-MonsterMut"
	FriendlyName="Marco Mode!"
	Description="omgwtflolol"
=======
     GroupName="KF-MonsterMut"
     FriendlyName="Marco Mode!"
     Description="omgwtflolol"
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
