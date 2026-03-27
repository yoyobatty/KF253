Class PatrolingPoint extends PathNode;

var() edfindable PatrolingPoint nextPatrolPoint;
var() float PatrolPauseTime;
var() name PatrolWaitForEvent;
var() bool bRunToThisPoint;
var vector LookDirection;

function PostBeginPlay()
{
	LookDirection = vector(Rotation)*2000+Location;
	Super.PostBeginPlay();
}

defaultproperties
{
<<<<<<< HEAD
	Texture=Texture'Engine.S_NavP'
=======
     Texture=Texture'Engine.S_NavP'
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
