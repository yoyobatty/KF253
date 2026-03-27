// Our own form of Cinematic Player... yay
class KFCinematicPlayer extends KFSPlayerController;

function PostBeginPlay()
{
 ClientOpenMenu("KFGUI.KFMainMenu",false);
}

defaultproperties
{
}
