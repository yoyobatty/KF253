class KFMusicTrigger extends MusicTrigger;

var() string CombatSong;  // To play when the action is hot.
struct SongTypeE
{
	var() string CombatSong,CalmSong;
};
var() array<SongTypeE> WaveBasedSongs;

function PostBeginPlay()
{
	if( KFGameType(Level.Game)!=None )
		KFGameType(Level.Game).MapSongHandler = Self;
}

function Trigger( Actor Other, Pawn EventInstigator );

defaultproperties
{
<<<<<<< HEAD
	FadeInTime=3.000000
	FadeOutTime=3.000000
=======
     FadeInTime=3.000000
     FadeOutTime=3.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
