//=============================================================================
// KFArcFlash
// (Blue Inferno) A charged discharge as each machine sees and hears it (FlameAltFire.ArcFlash): bolts from the nozzle
// to where it struck and on to all it struck round about (KFArcBolt), the blast (KFArcBlast), a scorch, a light that
// floods the room, a crack and a bang; it blinds those who see it and shakes those near. The server sends it once.
//=============================================================================
class KFArcFlash extends Actor;

#exec OBJ LOAD FILE=..\Sounds\WeaponSounds.uax
#exec OBJ LOAD FILE=..\Sounds\ONSBPSounds.uax

var byte	Power;			// the charge, out of 255
var vector	Ends[8];		// those it struck round about, and where the current ran out to over metal
var byte	NumEnds;
var bool	bShown;
var float	Age, LitFor;

var() float	BlindRange, ShakeRange;
var() vector	ShakeRotMag, ShakeRotRate, ShakeOffsetMag, ShakeOffsetRate;
var() float	ShakeTime;

replication
{
	reliable if ( bNetInitial && Role == ROLE_Authority )
		Power, Ends, NumEnds;
}

// The nozzle of P's flamethrower as this machine draws it: the drawn one in its holder's own first-person view, the
// third-person one's tip, or near enough where the eyes are
static function vector NozzleOf( Pawn P )
{
	local vector X, Y, Z;
	local FlameThrower FT;
	local Actor Att;

	if ( P == None )
		return vect(0,0,0);
	FT = FlameThrower(P.Weapon);
	if ( FT != None && P.Level.TimeSeconds - FT.DrawnNozzleTime < 0.1 )
		return FT.DrawnNozzle;
	if ( xPawn(P) != None )
		Att = xPawn(P).WeaponAttachment;
	if ( Att != None && P.Level.TimeSeconds - Att.LastRenderTime < 0.2 )
		return Att.GetBoneCoords('tip').Origin;
	GetAxes(class'KFFlameStream'.static.AimOf(P), X, Y, Z);
	return P.Location + P.EyePosition() + 50 * X + 8 * Y - 14 * Z;
}

simulated function Tick( float DT )
{
	Age += DT;
	if ( Level.NetMode == NM_DedicatedServer )
		return;
	if ( !bShown )
	{
		bShown = true;
		Show();
	}
	if ( LightType != LT_None )
	{
		LightBrightness = default.LightBrightness * FClamp(1.0 - Age / LitFor, 0.0, 1.0);
		if ( Age > LitFor )
			LightType = LT_None;
	}
}

simulated function Show()
{
	local float C;
	local vector Start;
	local int i;
	local KFArcBolt B;
	local KFArcBlast X;

	C = FMax(float(Power) / 255.0, 0.2);
	Start = NozzleOf(Instigator);
	if ( Start != vect(0,0,0) )
		for ( i = 0; i < 3; i++ )
		{
			B = Spawn(class'KFArcBolt',,, Start);
			if ( B != None )
				B.Span(Start, Location + 10 * VRand(), (1.0 - 0.3 * i) * (0.6 + 0.5 * C));
		}
	for ( i = 0; i < NumEnds && i < ArrayCount(Ends); i++ )
	{
		B = Spawn(class'KFArcBolt',,, Location);
		if ( B != None )
			B.Span(Location, Ends[i], 0.35 + 0.25 * C);
	}
	X = Spawn(class'KFArcBlast',,, Location + vector(Rotation) * 12, Rotation);
	if ( X != None )
		X.SetPower(C);
	Spawn(class'KFScorchMark', self,, Location + vector(Rotation) * 4, rotator(-vector(Rotation)));
	if ( C > 0.6 )
		Spawn(class'KFScorchMark', self,, Location + vector(Rotation) * 4 + 30 * VRand(), rotator(-vector(Rotation)));
	class'KFBlast'.static.Ceiling(self, Location + vector(Rotation) * 20, 0.5 + 0.7 * C);
	class'KFGib'.static.Blast(self, Location + vector(Rotation) * 12, 0.4 + 0.8 * C, 0.8);

	PlaySound(Sound'KFMod.Zap.ZapStart', SLOT_None, 2.5,, 2500, 0.65);
	PlaySound(Sound'WeaponSounds.BaseImpactAndExplosions.BExplosion3', SLOT_None, 1.6 + 1.2 * C,, 4500, 0.85 + 0.2 * FRand());
	PlaySound(Sound'ONSBPSounds.ShockTank.ShockBallExplosion', SLOT_None, 1.5 + 1.0 * C,, 3500, 0.9);

	LitFor = 0.2 + 0.25 * C;
	LightRadius = 12 + 14 * C;
	LightType = LT_Steady;
	bDynamicLight = true;

	SeenBy(Level.GetLocalPlayerController(), C);
}

// What the local player gets of it: a white-out if they see it (most when looking at it), and a shake if near
simulated function SeenBy( PlayerController PC, float C )
{
	local vector Eye, Dir;
	local float D, K, Facing;

	if ( PC == None || PC.ViewTarget == None )
		return;
	Eye = PC.ViewTarget.Location;
	if ( Pawn(PC.ViewTarget) != None )
		Eye += Pawn(PC.ViewTarget).EyePosition();
	D = VSize(Location - Eye);
	if ( D < ShakeRange * (0.5 + 0.5 * C) )
		PC.ShakeView(ShakeRotMag * C, ShakeRotRate, ShakeTime, ShakeOffsetMag * C, ShakeOffsetRate, ShakeTime);
	if ( D > BlindRange * (0.4 + 0.6 * C) || !FastTrace(Location + vector(Rotation) * 16, Eye) )
		return;
	Dir = Normal(Location - Eye);
	Facing = FMax(Dir dot vector(PC.GetViewRotation()), 0.0);
	K = C * (1.0 - D / (BlindRange * (0.4 + 0.6 * C))) * (0.3 + 0.7 * Facing);
	if ( K > 0.05 )
		PC.ClientFlash(1.0, vect(900,930,1000) * FMin(K * 0.8, 0.45));
}

defaultproperties
{
     BlindRange=2600.000000
     ShakeRange=1400.000000
     ShakeRotMag=(X=260.000000,Y=260.000000,Z=260.000000)
     ShakeRotRate=(X=12000.000000,Y=12000.000000,Z=12000.000000)
     ShakeOffsetMag=(X=14.000000,Y=14.000000,Z=14.000000)
     ShakeOffsetRate=(X=900.000000,Y=900.000000,Z=900.000000)
     ShakeTime=1.600000
     DrawType=DT_None
     bHidden=True
     LightType=LT_None
     LightHue=165
     LightSaturation=90
     LightBrightness=190.000000
     LightRadius=24.000000
     RemoteRole=ROLE_SimulatedProxy
     bNetTemporary=True
     bReplicateInstigator=True
     NetPriority=3.000000
     LifeSpan=2.000000
     bCollideActors=False
     bBlockActors=False
}
