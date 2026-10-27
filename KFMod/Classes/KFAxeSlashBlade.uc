//=============================================================================
// KFAxeSlashBlade
// The flying cut's glowing edge (KFAxeSlash): a curved ribbon, white-hot in a crimson halo, flickering; it goes out
// when the cut is spent. Each drawing machine's own.
//=============================================================================
class KFAxeSlashBlade extends Actor;

#exec NEW StaticMesh File="..\KFMod254\KFMod\Models\KFAxeSlashBlade.ase" Name="KFAxeSlashBlade"
#exec TEXTURE IMPORT NAME=KFAxeSlashGlow FILE=..\KFMod254\KFMod\Textures\KFAxeSlashGlow.tga MIPS=ON UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP

var() Texture	GlowTex;			// the picture of its glow
var() float		Bright;				// its glow, over the picture's own
var() float		FadeTime;
var float		Age, FadeAge;
var bool		bFading;
var ConstantColor	Tone;
var Combiner		Lit;
var FinalBlend		Glow;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	Tone = ConstantColor(Level.ObjectPool.AllocateObject(class'ConstantColor'));
	Tone.Color = class'Canvas'.static.MakeColor(255, 255, 255, 255);
	Lit = Combiner(Level.ObjectPool.AllocateObject(class'Combiner'));
	Lit.Material1 = GlowTex;
	Lit.Material2 = Tone;
	Lit.Mask = None;
	Lit.CombineOperation = CO_Multiply;
	Lit.AlphaOperation = AO_Use_Mask;
	Lit.InvertMask = false;
	Lit.Modulate2X = true;
	Lit.Modulate4X = false;
	Glow = FinalBlend(Level.ObjectPool.AllocateObject(class'FinalBlend'));
	Glow.Material = Lit;
	Glow.FrameBufferBlending = FB_Translucent;
	Glow.ZWrite = false;
	Glow.ZTest = true;
	Glow.AlphaTest = false;
	Glow.TwoSided = true;
	Skins[0] = Glow;
}

simulated function Tick( float DT )
{
	local float K;

	Age += DT;
	K = Bright * (0.82 + 0.18 * Sin(Age * 45.0)) * FMin(1.0, Age / 0.05);
	if ( bFading )
	{
		FadeAge += DT;
		K *= FMax(0.0, 1.0 - FadeAge / FadeTime);
		if ( FadeAge >= FadeTime )
		{
			Destroy();
			return;
		}
	}
	SetTone(K);
}

simulated function SetTone( float K )
{
	local byte V;

	V = byte(FClamp(127.0 * K, 0.0, 255.0));
	Tone.Color.R = V;
	Tone.Color.G = V;
	Tone.Color.B = V;
}

simulated function Fade()
{
	if ( bFading )
		return;
	bFading = true;
	SetBase(None);
	LifeSpan = FadeTime + 0.5;
}

simulated function Destroyed()
{
	if ( Glow != None )
	{
		Skins[0] = None;
		Glow.Material = None;
		Lit.Material1 = None;
		Lit.Material2 = None;
		Level.ObjectPool.FreeObject(Glow);
		Level.ObjectPool.FreeObject(Lit);
		Level.ObjectPool.FreeObject(Tone);
		Glow = None;
	}
	Super.Destroyed();
}

defaultproperties
{
     GlowTex=Texture'KFAxeSlashGlow'
     Bright=1.700000
     FadeTime=0.250000
     DrawType=DT_StaticMesh
     StaticMesh=StaticMesh'KFAxeSlashBlade'
     Style=STY_Additive
     bUnlit=True
     bAcceptsProjectors=False
     bShadowCast=False
     bCollideActors=False
     bCollideWorld=False
     bBlockActors=False
     bBlockPlayers=False
     RemoteRole=ROLE_None
     LifeSpan=4.000000
}
