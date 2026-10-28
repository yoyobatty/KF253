// The ball KFShieldBubble lays its bent picture on (the stock effects sphere, 32 units across its radius at size 1)
class KFShieldSphere extends Actor;

defaultproperties
{
     DrawType=DT_StaticMesh
     StaticMesh=StaticMesh'XEffects.EffectsSphere144'
     bUnlit=True
     RemoteRole=ROLE_None
     bAcceptsProjectors=False
     bShadowCast=False
     bCollideActors=False
     bCollideWorld=False
     bBlockActors=False
     bBlockPlayers=False
}
