class MiscEmmiter extends Emitter;

//Just to spawn nothing....

var class<DamageType> DamageType;
var vector HitLoc;

function PostBeginPlay()
{

}

simulated function Tick(float deltaTime)
{

}

simulated function Destroyed()
{
	if ( xPawn(Owner) != None )
	{
		xPawn(Owner).bFrozenBody = false;
		xPawn(Owner).PlayDyingAnimation(DamageType, HitLoc);
	}
}

defaultproperties
{
<<<<<<< HEAD
	DrawType=DT_Mesh
=======
     DrawType=DT_Mesh
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
