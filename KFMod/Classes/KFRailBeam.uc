//=============================================================================
// KFRailBeam
// The railgun's line as each machine sees it (RailgunFire): a white-hot core and a blue glow along it, a spiral of
// rings round it that drift apart and fade as Quake's do, a flash and sparks where a wall stopped it, and a mark there.
// The server sends it once.
//=============================================================================
class KFRailBeam extends Actor;

var vector	EndPoint;
var bool	bWall;
var bool	bShown;

replication
{
	reliable if ( bNetInitial && Role == ROLE_Authority )
		EndPoint, bWall;
}

// Where the line starts as this machine draws it: off the muzzle of the gun in its holder's own first-person view,
// else off the third-person gun, else in front of the eyes
simulated function vector Muzzle()
{
	local vector X, Y, Z, Eye;
	local Actor Att;

	if ( Instigator == None )
		return Location;
	GetAxes(Instigator.GetViewRotation(), X, Y, Z);
	Eye = Instigator.Location + Instigator.EyePosition();
	if ( Instigator.IsLocallyControlled() && Instigator.IsFirstPerson() )
		return Eye + 42 * X + 9 * Y - 9 * Z;
	if ( xPawn(Instigator) != None )
		Att = xPawn(Instigator).WeaponAttachment;
	if ( Att != None && Level.TimeSeconds - Att.LastRenderTime < 0.2 )
		return Att.Location + 40 * vector(Att.Rotation);
	return Eye + 40 * X;
}

simulated function Tick( float DT )
{
	local vector Start;
	local KFRailSpiral S;
	local Emitter E;

	if ( bShown || Level.NetMode == NM_DedicatedServer )
		return;
	bShown = true;
	Start = Muzzle();
	S = Spawn(class'KFRailSpiral',,, Start);
	if ( S != None )
		S.Lay(Start, EndPoint);
	class'KFGib'.static.Line(self, Start, EndPoint, 18.0);
	if ( bWall )
	{
		E = Spawn(class'KFRailImpact',,, EndPoint, rotator(Start - EndPoint));
		Spawn(class'KFRailMark', self,, EndPoint + Normal(Start - EndPoint) * 4, rotator(EndPoint - Start));
		PlaySound(Sound'WeaponSounds.BaseImpactAndExplosions.BLightningGunImpact', SLOT_None, 1.5,, 1200);
	}
}

defaultproperties
{
     DrawType=DT_None
     bHidden=True
     RemoteRole=ROLE_SimulatedProxy
     bNetTemporary=True
     bReplicateInstigator=True
     NetPriority=3.000000
     LifeSpan=1.000000
     bCollideActors=False
     bBlockActors=False
}
