// In case you want to put a basic mesh in the world which spawns Squirrelzero's lightsourced Shadows...

class RealTimeShadowMeshActor extends pawn;

var Effect_ShadowController RealtimeShadow;
var () bool bRealtimeShadows; // Advanced Shadows care of Squirrelzero's code.


simulated function PostBeginPlay()
{

  if (bActorShadows &&(Level.NetMode != NM_DedicatedServer))
	{
		// decide which type of shadow to spawn
		if (bRealtimeShadows)
		{
			RealtimeShadow = Spawn(class'Effect_ShadowController',self,'',Location);
			RealtimeShadow.Instigator = self;
			RealtimeShadow.Initialize();
		}
	}
	
}

function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType){}

defaultproperties
{
<<<<<<< HEAD
	bRealtimeShadows=True
	bJumpCapable=False
	bCanJump=False
	bCanWalk=False
	bInvulnerableBody=True
	ControllerClass=None
	DrawType=DT_StaticMesh
	StaticMesh=StaticMesh'GKStaticMeshes.basicShapes.BasicCube'
	bStasis=False
	bStaticLighting=True
	bMovable=False
	bCanBeDamaged=False
	CollisionRadius=20.000000
	CollisionHeight=40.000000
=======
     bRealtimeShadows=True
     bJumpCapable=False
     bCanJump=False
     bCanWalk=False
     bInvulnerableBody=True
     ControllerClass=None
     DrawType=DT_StaticMesh
     StaticMesh=StaticMesh'GKStaticMeshes.basicShapes.BasicCube'
     bStasis=False
     bStaticLighting=True
     bMovable=False
     bActorShadows=True
     bCanBeDamaged=False
     CollisionRadius=20.000000
     CollisionHeight=40.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
