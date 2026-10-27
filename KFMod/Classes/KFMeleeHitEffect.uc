//=============================================================================
// KFMeleeHitEffect
// A melee blow on the world, made as the bullet impacts are (KFImpact*) and bigger: a blade throws sparks off metal
// and stone along its swing and leaves a gash (a bright gouge on metal), a blunt weapon a crushed spot. Which way the
// blade went and what kind of weapon it was (SwingDir, Kind) are set on the class default just before the spawn
// (KFMeleeFire.NoteWorldHit): its effects are made while it is being spawned, before anything could be set on it.
//=============================================================================
class KFMeleeHitEffect extends KFHitEffect;

var vector	SwingDir;
var byte	Kind;					// 0 a blade, 1 a heavy blade (axe, chainsaw), 2 a blunt weapon (bat)
var() float	KindScale[3];			// its impact's size for each kind
var() class<Projector>	BladeMarks[11], BluntMarks[11];
var() float	MarkScale[3];

simulated function SpawnEffects()
{
	local ESurfaceTypes ST;
	local vector HitNormal, X, Y, Z;
	local class<Projector> MarkClass;
	local Projector Mark;

	SwingDir = class'KFMeleeHitEffect'.default.SwingDir;
	Kind = class'KFMeleeHitEffect'.default.Kind;
	class'KFMeleeHitEffect'.default.SwingDir = vect(0,0,0);
	class'KFMeleeHitEffect'.default.Kind = 0;
	if ( Kind > 2 )
		Kind = 0;
	ImpactScale = KindScale[Kind];

	ST = FindSurface(HitNormal);
	if ( HitEffects[ST].HitEffect != None )
		Spawn(HitEffects[ST].HitEffect, self,, Location, rotator(HitNormal));

	if ( Kind == 2 )
		MarkClass = BluntMarks[ST];
	else
		MarkClass = BladeMarks[ST];
	if ( MarkClass == None || KActor(Owner) != None )
		return;
	// laid along the swing: the mark's length (its texture's U) follows the blade across the surface
	X = -HitNormal;
	Y = SwingDir - (SwingDir dot X) * X;
	if ( VSize(Y) < 0.1 )
		Y = vect(0,0,1) - X.Z * X;
	if ( VSize(Y) < 0.1 )
		Y = vect(1,0,0) - X.X * X;
	Y = Normal(Y);
	Z = X cross Y;
	Mark = Spawn(MarkClass, self,, Location, OrthoRotation(X, Y, Z));
	if ( Mark != None && MarkScale[Kind] != 1.0 )
	{
		Mark.DetachProjector();
		Mark.SetDrawScale(Mark.DrawScale * MarkScale[Kind]);
		Mark.AttachProjector();
	}
}

// Sparks struck off along the swing: Count of emitter Index's (Blunt of them for a blunt weapon), thrown along the
// surface the way the blade was going and a little out of it. E faces out of the surface (KFImpactEmitter).
static function Scrape( Emitter E, int Index, int Count, int Blunt )
{
	local KFMeleeHitEffect H;
	local vector L;
	local float G;

	H = KFMeleeHitEffect(E.Owner);
	if ( H == None || Index < 0 || Index >= E.Emitters.Length || E.Emitters[Index] == None )
		return;
	if ( H.Kind == 2 )
		Count = Blunt;
	if ( Count <= 0 )
		return;
	G = Sqrt(H.ImpactScale);
	L = H.SwingDir << E.Rotation;
	L.X = 0;
	if ( VSize(L) < 0.1 )
		L = VRand() * vect(0,1,1);
	L = Normal(L) * 700 * G;
	E.Emitters[Index].StartVelocityRange.X.Min = 40;
	E.Emitters[Index].StartVelocityRange.X.Max = 280 * G;
	E.Emitters[Index].StartVelocityRange.Y.Min = L.Y - 320;
	E.Emitters[Index].StartVelocityRange.Y.Max = L.Y + 320;
	E.Emitters[Index].StartVelocityRange.Z.Min = L.Z - 320;
	E.Emitters[Index].StartVelocityRange.Z.Max = L.Z + 320;
	E.Emitters[Index].SpawnParticle(int(float(Count) * G));
}

defaultproperties
{
	HitEffects(0)=(HitEffect=class'KFMeleeImpactStone')
	HitEffects(1)=(HitEffect=class'KFMeleeImpactStone')
	HitEffects(2)=(HitEffect=class'KFMeleeImpactDirt')
	HitEffects(3)=(HitEffect=class'KFMeleeImpactMetal')
	HitEffects(4)=(HitEffect=class'KFMeleeImpactWood')
	HitEffects(5)=(HitEffect=class'KFMeleeImpactDirt')
	HitEffects(6)=(HitEffect=class'FleshHitEmitter')
	HitEffects(7)=(HitEffect=class'KFImpactSnow')
	HitEffects(8)=(HitEffect=class'KFImpactSnow')
	HitEffects(9)=(HitEffect=class'WaterHitEmitter')
	HitEffects(10)=(HitDecal=class'GlassBulletDecal',HitEffect=class'GlassHitEmitter')
	BladeMarks(0)=class'KFMeleeGashMark'
	BladeMarks(1)=class'KFMeleeGashMark'
	BladeMarks(3)=class'KFMeleeScratchMark'
	BladeMarks(4)=class'KFMeleeGashMark'
	BladeMarks(10)=class'GlassBulletDecal'
	BluntMarks(0)=class'KFMeleeDentMark'
	BluntMarks(1)=class'KFMeleeDentMark'
	BluntMarks(3)=class'KFMeleeDentMark'
	BluntMarks(4)=class'KFMeleeDentMark'
	BluntMarks(10)=class'GlassBulletDecal'
	KindScale(0)=1.400000
	KindScale(1)=1.900000
	KindScale(2)=1.700000
	MarkScale(0)=1.000000
	MarkScale(1)=1.350000
	MarkScale(2)=1.200000
}
