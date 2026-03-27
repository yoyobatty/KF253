//-----------------------------------------------------------
//
//-----------------------------------------------------------
class KFFPMut extends Mutator;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	if ( KFGameType(Level.Game) != none ) {
		// groups of monsters that will be spawned
		KFGameType(Level.Game).MonsterSquad[0]="2F";
		KFGameType(Level.Game).MonsterSquad[1]="2F";
		KFGameType(Level.Game).MonsterSquad[2]="2F";
		KFGameType(Level.Game).MonsterSquad[3]="2F";
		KFGameType(Level.Game).MonsterSquad[4]="3F";
		KFGameType(Level.Game).MonsterSquad[5]="3F";
		KFGameType(Level.Game).MonsterSquad[6]="3F";
		KFGameType(Level.Game).MonsterSquad[7]="4F";
		KFGameType(Level.Game).MonsterSquad[8]="4F";
		KFGameType(Level.Game).MonsterSquad[9]="4F";
		KFGameType(Level.Game).MonsterSquad[10]="5F";
		KFGameType(Level.Game).MonsterSquad[11]="5F";
		KFGameType(Level.Game).MonsterSquad[12]="5F";
		KFGameType(Level.Game).MonsterSquad[13]="6F";
		KFGameType(Level.Game).MonsterSquad[14]="6F";
		KFGameType(Level.Game).MonsterSquad[15]="6F";
		KFGameType(Level.Game).MonsterSquad[16]="7F";
		KFGameType(Level.Game).MonsterSquad[17]="7F";
		KFGameType(Level.Game).MonsterSquad[18]="7F";
		KFGameType(Level.Game).MonsterSquad[19]="7F";
		// doubling the monster count per wave
		/*
		KFGameType(Level.Game).Waves[0].WaveMaxMonsters *= 2;
		KFGameType(Level.Game).Waves[1].WaveMaxMonsters *= 2;
		KFGameType(Level.Game).Waves[2].WaveMaxMonsters *= 2;
		KFGameType(Level.Game).Waves[3].WaveMaxMonsters *= 2;
		KFGameType(Level.Game).Waves[4].WaveMaxMonsters *= 2;
		KFGameType(Level.Game).Waves[5].WaveMaxMonsters *= 3;
		KFGameType(Level.Game).Waves[6].WaveMaxMonsters *= 3;
		KFGameType(Level.Game).Waves[7].WaveMaxMonsters *= 3;
		KFGameType(Level.Game).Waves[8].WaveMaxMonsters *= 3;
		KFGameType(Level.Game).Waves[9].WaveMaxMonsters *= 3;
		KFGameType(Level.Game).Waves[10].WaveMaxMonsters *= 3;
		KFGameType(Level.Game).Waves[11].WaveMaxMonsters *= 4;
		KFGameType(Level.Game).Waves[12].WaveMaxMonsters *= 4;
		KFGameType(Level.Game).Waves[13].WaveMaxMonsters *= 4;
		KFGameType(Level.Game).Waves[14].WaveMaxMonsters *= 4;
		KFGameType(Level.Game).Waves[15].WaveMaxMonsters *= 4;
		KFGameType(Level.Game).Waves[16].WaveMaxMonsters *= 4;
		KFGameType(Level.Game).Waves[17].WaveMaxMonsters *= 4;
		KFGameType(Level.Game).Waves[18].WaveMaxMonsters *= 4;
		KFGameType(Level.Game).Waves[19].WaveMaxMonsters *= 4;
		*/
// original monster count
/*		KFGameType(Level.Game).MonsterSquad[0]="6A";
		KFGameType(Level.Game).MonsterSquad[1]="6A";
		KFGameType(Level.Game).MonsterSquad[2]="6A";
		KFGameType(Level.Game).MonsterSquad[3]="5A";
		KFGameType(Level.Game).MonsterSquad[4]="5A";
		KFGameType(Level.Game).MonsterSquad[5]="4A";
		KFGameType(Level.Game).MonsterSquad[6]="6A";
		KFGameType(Level.Game).MonsterSquad[7]="5A";
		KFGameType(Level.Game).MonsterSquad[8]="5A";
		KFGameType(Level.Game).MonsterSquad[9]="2A";
		KFGameType(Level.Game).MonsterSquad[10]="4A";
		KFGameType(Level.Game).MonsterSquad[11]="5A";
		KFGameType(Level.Game).MonsterSquad[12]="4A";
		KFGameType(Level.Game).MonsterSquad[13]="3A";
		KFGameType(Level.Game).MonsterSquad[14]="3A";
		KFGameType(Level.Game).MonsterSquad[15]="9A";
		KFGameType(Level.Game).MonsterSquad[16]="12A";
		KFGameType(Level.Game).MonsterSquad[17]="9A";
		KFGameType(Level.Game).MonsterSquad[18]="7A";
		KFGameType(Level.Game).MonsterSquad[19]="6A";
*/
// original waves
/*		KFGameType(Level.Game).MonsterSquad[0]="1A1G2A1G1A";
		KFGameType(Level.Game).MonsterSquad[1]="4A2D";
		KFGameType(Level.Game).MonsterSquad[2]="2D2A2D";
		KFGameType(Level.Game).MonsterSquad[3]="2A1C2D1B";
		KFGameType(Level.Game).MonsterSquad[4]="2A2C1E";
		KFGameType(Level.Game).MonsterSquad[5]="2A2C";
		KFGameType(Level.Game).MonsterSquad[6]="2D1H2A1E";
		KFGameType(Level.Game).MonsterSquad[7]="3B2F";
		KFGameType(Level.Game).MonsterSquad[8]="1H2D1G1C";
		KFGameType(Level.Game).MonsterSquad[9]="2F";
		KFGameType(Level.Game).MonsterSquad[10]="2F2A";
		KFGameType(Level.Game).MonsterSquad[11]="2F2H1E";
		KFGameType(Level.Game).MonsterSquad[12]="2H2D";
		KFGameType(Level.Game).MonsterSquad[13]="1H1C1B";
		KFGameType(Level.Game).MonsterSquad[14]="1H1E1A";
		KFGameType(Level.Game).MonsterSquad[15]="3E2B4A";
		KFGameType(Level.Game).MonsterSquad[16]="2B7F3G";
		KFGameType(Level.Game).MonsterSquad[17]="4A2G3D";
		KFGameType(Level.Game).MonsterSquad[18]="2D2D3H";
		KFGameType(Level.Game).MonsterSquad[19]="2F2G2H";
*/
	}
}

defaultproperties
{
     GroupName="KF"
     FriendlyName="Poundamonium!"
     Description="Only Fleshpounds will appear during the game. Bring a big gun."
}
