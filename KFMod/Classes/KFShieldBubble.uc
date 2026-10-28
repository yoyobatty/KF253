//=============================================================================
// KFShieldBubble - the King Fleshpound's shield (ZombieKingFleshpound.bShielded): a ball of red energy round it, the
// stock shield's swirl drifting over it and added to what is behind. It throbs, and flashes as it is struck. Each
// viewer's own. (No picture of the scene behind it: the air is bent by the weapons alone, the waves being dear.)
//=============================================================================
class KFShieldBubble extends Actor;

var Actor Boss;
var float Radius, Grow, Hit;
var ConstantColor Tint;
var TexPanner Flow;
var Combiner Tinted;
var FinalBlend Glow;

static function KFShieldBubble Make( Actor B, float R )
{
	local KFShieldBubble S;

	if ( B == None || B.Level.NetMode == NM_DedicatedServer )
		return None;
	S = B.Spawn(class'KFShieldBubble',,, B.Location);
	if ( S == None )
		return None;
	S.Boss = B;
	S.Radius = R;
	S.Tick(0.0);
	return S;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	Tint = new(None) class'ConstantColor';
	Tint.Color.R = 90;
	Tint.Color.G = 255;
	Tint.Color.B = 255;
	Tint.Color.A = 255;
	Flow = new(None) class'TexPanner';
	Flow.Material = Texture'XEffectMat.Shield.RedShield';
	Flow.PanDirection = rot(16384,0,0);
	Flow.PanRate = 0.15;
	Tinted = new(None) class'Combiner';
	Tinted.Material1 = Flow;
	Tinted.Material2 = Tint;
	Tinted.CombineOperation = CO_Multiply;
	Tinted.AlphaOperation = AO_Use_Alpha_From_Material1;
	Tinted.Modulate2X = true;
	Glow = new(None) class'FinalBlend';
	Glow.Material = Tinted;
	Glow.FrameBufferBlending = FB_Translucent;
	Glow.ZWrite = false;
	Glow.ZTest = true;
	// (seen from inside it too, and from outside its far side through its near)
	Glow.TwoSided = true;
	Skins[0] = Glow;
}

// Struck: it flashes
simulated function Struck()
{
	Hit = 1.0;
}

simulated function Tick( float DT )
{
	if ( Boss == None || Boss.bDeleteMe )
	{
		Destroy();
		return;
	}
	Grow = FMin(1.0, Grow + DT * 4.0);
	Hit = FMax(0.0, Hit - DT * 4.0);
	SetLocation(Boss.Location);
	// (the stock effects sphere is 32 units across its radius at size 1)
	SetDrawScale(FMax(0.01, Radius * Grow * (1.0 + 0.05 * Sin(Level.TimeSeconds * 6.0) + 0.08 * Hit) / 32.0));
	Tint.Color.R = Clamp(int(90.0 + 165.0 * Hit), 0, 255);
}

simulated function Destroyed()
{
	Skins.Length = 0;
	Super.Destroyed();
}

defaultproperties
{
     DrawType=DT_StaticMesh
     StaticMesh=StaticMesh'XEffects.EffectsSphere144'
     bUnlit=True
     Style=STY_Additive
     RemoteRole=ROLE_None
     bAcceptsProjectors=False
     bShadowCast=False
     bCollideActors=False
     bCollideWorld=False
     bBlockActors=False
     bBlockPlayers=False
}
