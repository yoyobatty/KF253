//=============================================================================
// The wall round a lockdown (KFLockdown), Doom style: a ring of red energy rising off the floor, streaming upward, and
// embers rising along it. It grows up out of the floor when the lockdown starts and sinks away when it is cleared. Each
// machine draws its own; it holds no one (KFLockdown does).
//=============================================================================
class KFLockdownWall extends Actor;

#exec NEW StaticMesh File="..\KFMod254\KFMod\Models\KFLockdownWall.ase" Name="KFLockdownWallMesh"
#exec TEXTURE IMPORT NAME=KFLockdownWallTex FILE=..\KFMod254\KFMod\Textures\KFLockdownWall.tga VCLAMPMODE=CLAMP

var() float Height;
var float Radius, Grow;
var bool bSinking;
var TexPanner Flow;
var FinalBlend Glow;
var Emitter Embers;

simulated function Setup( float R )
{
	local vector S;

	Radius = R;
	Flow = new(None) class'TexPanner';
	Flow.Material = Texture'KFLockdownWallTex';
	Flow.PanDirection = rot(16384,0,0);
	Flow.PanRate = 0.35;
	Glow = new(None) class'FinalBlend';
	Glow.Material = Flow;
	Glow.FrameBufferBlending = FB_Translucent;
	Glow.ZWrite = false;
	Glow.ZTest = true;
	Glow.TwoSided = true;
	Skins[0] = Glow;
	S.X = Radius / 100.0;
	S.Y = Radius / 100.0;
	S.Z = 0.01;
	SetDrawScale3D(S);
	Embers = Spawn(class'KFLockdownEmbers',,, Location);
	if ( Embers != None )
	{
		Embers.Emitters[0].StartLocationPolarRange.Z.Min = Radius;
		Embers.Emitters[0].StartLocationPolarRange.Z.Max = Radius;
	}
}

simulated function Tick( float DeltaTime )
{
	local vector S;

	if ( bSinking )
		Grow = FMax(0.0, Grow - DeltaTime * 1.4);
	else
		Grow = FMin(1.0, Grow + DeltaTime * 1.6);
	S.X = Radius / 100.0;
	S.Y = Radius / 100.0;
	S.Z = FMax(0.01, Height * Grow * (1.0 + 0.04 * Sin(Level.TimeSeconds * 9.0)) / 100.0);
	SetDrawScale3D(S);
	if ( bSinking && Grow <= 0.0 )
		Destroy();
}

simulated function Sink()
{
	bSinking = true;
	if ( Embers != None )
	{
		Embers.Kill();
		Embers = None;
	}
}

simulated function Destroyed()
{
	if ( Embers != None )
		Embers.Destroy();
	Skins.Length = 0;
	Super.Destroyed();
}

defaultproperties
{
     Height=230.000000
     DrawType=DT_StaticMesh
     StaticMesh=StaticMesh'KFLockdownWallMesh'
     bUnlit=True
     Style=STY_Additive
     RemoteRole=ROLE_None
     bAcceptsProjectors=False
     bShadowCast=False
     bCollideActors=False
     bCollideWorld=False
     bBlockActors=False
     bBlockPlayers=False
     bAlwaysRelevant=True
     LightType=LT_None
}
