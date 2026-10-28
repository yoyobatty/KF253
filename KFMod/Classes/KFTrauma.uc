//=============================================================================
// KFTrauma - what the worst kills do to a specimen's body, as Doom does it: a head split down the middle and opened on
// the neck, the top of the skull taken off, a body cut in two across the waist (clean by a blade, torn by a blast), a
// body cleaved in two from the head down.
//
// The parts are the specimen's own mesh, posed as it was. What lies across a cut is made see-through by a mask laid on
// by world position and an alpha test, the meat inside shows on a copy a little smaller than the part, and the cut's
// face lies on the plane (KFCutPiece for a part flying free, KFCutBody for the body left lying). Every machine that
// draws the specimen makes its own; the server only says which (KFMonster.DeathGore, through the HitFX ring).
//=============================================================================
class KFTrauma extends Object
	abstract;

#exec TEXTURE IMPORT NAME=KFCutEdge FILE=..\KFMod254\KFMod\Textures\KFCutEdge.tga MIPS=OFF ALPHA=1 UCLAMPMODE=CLAMP
#exec TEXTURE IMPORT NAME=KFCutRing FILE=..\KFMod254\KFMod\Textures\KFCutRing.tga MIPS=OFF ALPHA=1 UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP
#exec TEXTURE IMPORT NAME=KFCutMeat FILE=..\KFMod254\KFMod\Textures\KFCutMeat.tga
#exec TEXTURE IMPORT NAME=KFCutSkull FILE=..\KFMod254\KFMod\Textures\KFCutSkull.tga ALPHA=1 UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP
#exec TEXTURE IMPORT NAME=KFCutTorso FILE=..\KFMod254\KFMod\Textures\KFCutTorso.tga ALPHA=1 UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP
#exec TEXTURE IMPORT NAME=KFCutSagittal FILE=..\KFMod254\KFMod\Textures\KFCutSagittal.tga ALPHA=1 UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP

var() bool		bTrauma;			// splits, tops and cuts in two at all
var() float		HeadFace;			// the cut face of a head split down the middle, against the head's hit radius
var() float		TopFace;			// ...of the top of a skull taken off across the brow
var() int		HeadTopDamage;		// a round that takes the head off with this much damage or more...
var() float		HeadTopChance;		// ...takes the top of the skull off this often (else the head bursts as before)
var() float		SplitReach;			// an upright cut this near the head's middle, against its hit radius, splits it
var() float		TorsoFace;			// ...of a body across the waist, against its collision radius
var() float		ShellShrink;		// the meat inside a part, against the part
var() float		CleanEdge, TornEdge;	// how wide the cut's mask is in units (its line wanders a tenth of that): a blade, a blast
var() float		HingeOpen;			// degrees each half of a split head opens on the neck
var() float		HingeTime;			// ...seconds before it drops off
var() float		TorsoRing;			// the waist cut reaches this far round the spine, against the collision radius
var() float		CleaveChance;		// how often an axe's killing chop down through the trunk cleaves the body in two
var() bool		bTraumaDebug;
var bool		bDeviceRead, bDeviceCuts;	// (DeviceCuts)

// Wounds (NoteWound, KFWound): the body as fourteen capsules, a clot's, on the bones a wound can ride
var name		WoundBones[14], WoundEnds[14];
var float		WoundRadii[14];
var int			WoundJoints[14];	// the sever slot whose loss takes a wound on that bone
var() bool		bWounds;
var() float		WoundStandOff;		// a wound is cast from this far out of the body
var() int		ExitDamage;			// a single round of this much damage or more tears its way out of the far side
var() float		HoleSize, HeavyHoleSize, ExitSize, CavitySize, GashSize;	// across the projector, in units
var() float		CavityReach;		// a shotgun blast from this near opens a cavity...
var() float		CavityShare;		// ...if the blast so far is this share of the specimen's health
var() int		TunnelDamage;		// a killing round of this much damage or more leaves a hole right through the body
var() float		TunnelPerDamage;	// ...this many units round for each point of damage (TunnelMin to TunnelMax)
var() float		TunnelMin, TunnelMax;

// ---- materials (from the level's pool; given back with KFFXMat.FreeAll)

// The plain picture under a skin, for a cut to be laid over: a texture, a Shader's diffuse, a blend's plain side
static function Texture CutSource( Material M )
{
	local int i;

	for ( i=0; i<6 && M != None; i++ )
	{
		if ( Texture(M) != None )
			return Texture(M);
		if ( Shader(M) != None )
			M = Shader(M).Diffuse;
		else if ( Combiner(M) != None )
		{
			if ( Texture(Combiner(M).Material2) != None )
				M = Combiner(M).Material2;
			else
				M = Combiner(M).Material1;
		}
		else if ( FinalBlend(M) != None )
			M = FinalBlend(M).Material;
		else if ( Modifier(M) != None )
			M = Modifier(M).Material;
		else
			return None;
	}
	return None;
}

// World position to a mask's coordinates (TCS_WorldCoords; SetPlane, SetRing lay it)
static function TexMatrix CutCoords( out array<Object> Made, LevelInfo L, Material Mask )
{
	local TexMatrix T;

	T = TexMatrix(L.ObjectPool.AllocateObject(class'TexMatrix'));
	T.Material = Mask;
	T.TexCoordSource = TCS_WorldCoords;
	T.TexCoordCount = TCN_2DCoords;
	T.TexCoordProjected = false;
	Made[Made.Length] = T;
	return T;
}

// Two masks, solid where either is
static function Combiner EitherMask( out array<Object> Made, LevelInfo L, Material A, Material B )
{
	local Combiner C;

	C = Combiner(L.ObjectPool.AllocateObject(class'Combiner'));
	C.Material1 = A;
	C.Material2 = B;
	C.Mask = None;
	C.InvertMask = false;
	C.Modulate2X = false;
	C.Modulate4X = false;
	C.CombineOperation = CO_Use_Color_From_Material1;
	C.AlphaOperation = AO_Add;
	Made[Made.Length] = C;
	return C;
}

// Skin drawn only where Mask is solid (an alpha test), solid there; two-sided, so that the inside shows past a cut
static function FinalBlend CutSkin( out array<Object> Made, LevelInfo L, Material Skin, Material Mask )
{
	local Combiner C;
	local FinalBlend F;

	C = Combiner(L.ObjectPool.AllocateObject(class'Combiner'));
	C.Material1 = Skin;
	C.Material2 = Mask;
	C.Mask = None;
	C.InvertMask = false;
	C.Modulate2X = false;
	C.Modulate4X = false;
	C.CombineOperation = CO_Use_Color_From_Material1;
	C.AlphaOperation = AO_Use_Alpha_From_Material2;
	Made[Made.Length] = C;
	F = FinalBlend(L.ObjectPool.AllocateObject(class'FinalBlend'));
	F.Material = C;
	F.FrameBufferBlending = FB_Overwrite;
	F.ZWrite = true;
	F.ZTest = true;
	F.AlphaTest = true;
	F.AlphaRef = 127;
	F.TwoSided = true;
	Made[Made.Length] = F;
	return F;
}

// A cut face's skin: its picture's own outline (alpha tested), both sides
static function FinalBlend FaceSkin( out array<Object> Made, LevelInfo L, Material Pic )
{
	local FinalBlend F;

	F = FinalBlend(L.ObjectPool.AllocateObject(class'FinalBlend'));
	F.Material = Pic;
	F.FrameBufferBlending = FB_Overwrite;
	F.ZWrite = true;
	F.ZTest = true;
	F.AlphaTest = true;
	F.AlphaRef = 127;
	F.TwoSided = true;
	Made[Made.Length] = F;
	return F;
}

// Lays a cut's mask (KFCutEdge) on: solid on the side of the plane through Spot that Normal points away from, clear on
// the side it points to. Along runs along the cut, the way its torn line goes, repeating every Repeat units; Width is
// the units the mask spans across the cut (its line wanders about a tenth of that).
static function SetPlane( TexMatrix T, vector Spot, vector Normal, vector Along, float Width, float Repeat )
{
	local Matrix M;

	M.XPlane.X = Normal.X / Width;
	M.YPlane.X = Normal.Y / Width;
	M.ZPlane.X = Normal.Z / Width;
	M.WPlane.X = 0.5 - (Spot dot Normal) / Width;
	M.XPlane.Y = Along.X / Repeat;
	M.YPlane.Y = Along.Y / Repeat;
	M.ZPlane.Y = Along.Z / Repeat;
	M.WPlane.Y = -(Spot dot Along) / Repeat;
	M.ZPlane.Z = 1.0;
	M.WPlane.W = 1.0;
	T.Matrix = M;
}

// Lays the round mask (KFCutRing) on: clear within the oval round Spot whose half widths are RA along A and RB along B
// (A and B square to each other), all the way along the line through it square to both; solid outside
static function SetRing( TexMatrix T, vector Spot, vector A, vector B, float RA, float RB )
{
	local Matrix M;

	M.XPlane.X = 0.25 * A.X / RA;
	M.YPlane.X = 0.25 * A.Y / RA;
	M.ZPlane.X = 0.25 * A.Z / RA;
	M.WPlane.X = 0.5 - 0.25 * (Spot dot A) / RA;
	M.XPlane.Y = 0.25 * B.X / RB;
	M.YPlane.Y = 0.25 * B.Y / RB;
	M.ZPlane.Y = 0.25 * B.Z / RB;
	M.WPlane.Y = 0.5 - 0.25 * (Spot dot B) / RB;
	M.ZPlane.Z = 1.0;
	M.WPlane.W = 1.0;
	T.Matrix = M;
}

// ---- wounds

// (where the hit is dealt: server, or a machine hitting its own body) The wound a hit at HitLocation along Ray leaves:
// where the line first meets the body's capsules; a heavy round's way out of the far side too; told to every machine
// that draws the body (KFMonster.PostWound)
static function NoteWound( KFMonster M, vector HitLocation, vector Ray, int Damage, class<DamageType> DamageType, Pawn InstigatedBy )
{
	local vector Start, In, Out, Up, Edge;
	local float T, TOut, Best, BestOut, R;
	local int i, BestBone;
	local byte Kind;
	local float Size;
	local bool bPower;

	if ( !default.bWounds || M == None || Ray == vect(0,0,0) || M.bFrozen || M.bGibbed || M.bCutBody || M.Mesh == None )
	{
		if ( default.bTraumaDebug )
			log("NOTEWOUND skipped" @ M @ "ray" @ Ray @ "gibbed" @ M.bGibbed @ "cut" @ M.bCutBody);
		return;
	}
	Ray = Normal(Ray);
	Start = HitLocation - Ray * 70.0;
	Best = 100000.0;
	BestBone = -1;
	for ( i=0; i<ArrayCount(default.WoundBones); i++ )
	{
		if ( default.WoundJoints[i] >= 0 && M.Severed[default.WoundJoints[i]] != 0 )
			continue;
		if ( i == 5 && M.Severed[4] != 0 )
			continue;
		if ( CapsuleHit(M, i, Start, Ray, T, TOut, R) && T < Best )
		{
			Best = T;
			BestOut = TOut;
			BestBone = i;
		}
	}
	if ( BestBone < 0 )
	{
		if ( default.bTraumaDebug )
			log("NOTEWOUND no capsule" @ M @ "from" @ HitLocation @ "ray" @ Ray @ "body" @ M.Location @ "phys" @ M.Physics);
		return;
	}
	In = Start + Ray * Best;
	Up = vect(0,0,1);
	bPower = M.IsPowerHit(DamageType);
	if ( class<DamTypeMelee>(DamageType) != None )
	{
		Kind = 3;
		Size = default.GashSize;
		Edge = M.BladeEdge;
		if ( M.BladeTime != M.Level.TimeSeconds || VSize(Edge) < 0.1 )
			Edge = Normal(Ray cross vect(0,0,1));
		Up = Normal(Edge cross Ray);
	}
	else if ( bPower && InstigatedBy != None && VSize(InstigatedBy.Location - M.Location) < default.CavityReach
		&& M.BlastDamage >= default.CavityShare * M.default.Health && M.Level.TimeSeconds - M.LastCavityTime > 0.4 )
	{
		Kind = 2;
		Size = default.CavitySize;
		M.LastCavityTime = M.Level.TimeSeconds;
	}
	else
	{
		// a blast's pellets leave a few holes, not one for each
		if ( bPower && M.Level.TimeSeconds - M.LastPelletWound < 0.04 )
			return;
		if ( bPower )
			M.LastPelletWound = M.Level.TimeSeconds;
		Kind = 0;
		if ( Damage >= default.ExitDamage )
			Size = default.HeavyHoleSize;
		else
			Size = default.HoleSize;
	}
	Size *= M.GibScale;
	// a killing round big enough, or a close blast, blows a hole right through: the scene shows through the body
	// (KFHoleBody; its size goes as tenths of a unit), its torn lip a ring round each end (a wound's dark middle would
	// cover the hole: projectors take no notice of the cut)
	if ( M.Health <= 0 && (Kind == 2 || (Kind == 0 && !bPower && Damage >= default.TunnelDamage)) )
	{
		if ( Kind == 2 )
			R = default.TunnelMax * 0.9;
		else
			R = FClamp(float(Damage) * default.TunnelPerDamage, default.TunnelMin, default.TunnelMax);
		R *= M.GibScale;
		M.PostWound(BestBone, 4, Start + Ray * (0.5 * (Best + BestOut)), Ray, Up, 10.0 * R);
		M.PostWound(BestBone, 5, In - Ray * default.WoundStandOff, Ray, Up, 4.2 * R);
		M.PostWound(BestBone, 5, Start + Ray * BestOut + Ray * default.WoundStandOff, -Ray, Up, 4.6 * R);
		if ( default.bTraumaDebug )
			log("TUNNEL ray" @ Ray @ "bone" @ default.WoundBones[BestBone] @ "R" @ R);
		return;
	}
	M.PostWound(BestBone, Kind, In - Ray * default.WoundStandOff, Ray, Up, Size);
	// a heavy round out of the far side, torn wide
	if ( Kind == 0 && !bPower && Damage >= default.ExitDamage && DamageType.default.bLocationalHit )
	{
		Out = Start + Ray * BestOut;
		M.PostWound(BestBone, 1, Out + Ray * default.WoundStandOff, -Ray, Up, default.ExitSize * M.GibScale);
	}
}

// Where the line Start along Dir goes into capsule i of M (T) and out of it (TOut); R its radius
static function bool CapsuleHit( KFMonster M, int i, vector Start, vector Dir, out float T, out float TOut, out float R )
{
	local coords C;
	local vector A, B, Axis, W, Cr;
	local float Len, S, Along, D, Sin, Half;

	C = M.GetBoneCoords(default.WoundBones[i]);
	A = C.Origin;
	if ( default.WoundEnds[i] == 'None' )
		B = A + Normal(C.XAxis) * (2.0 * M.HeadHeight * M.HeadScale);
	else
		B = M.GetBoneCoords(default.WoundEnds[i]).Origin;
	if ( i == 5 )
		R = 0.72 * M.HeadRadius * M.HeadScale;
	else
		R = default.WoundRadii[i] * M.GibScale * M.DrawScale / 1.1;
	Axis = B - A;
	Len = VSize(Axis);
	if ( Len < 0.5 )
		return false;
	Axis = Axis / Len;
	// the line's nearest pass to the bone's axis
	Cr = Dir cross Axis;
	Sin = VSize(Cr);
	W = Start - A;
	if ( Sin < 0.05 )
		return false;
	D = Abs(W dot (Cr / Sin));
	if ( D >= R )
		return false;
	// along the line to that nearest pass
	S = ((A - Start) cross Axis) dot (Cr / (Sin * Sin));
	Half = Sqrt(R * R - D * D) / Sin;
	T = S - Half;
	TOut = S + Half;
	// and it must pass the bone within its length (a little beyond the joints)
	Along = (Start + Dir * S - A) dot Axis;
	if ( Along < -0.4 * R || Along > Len + 0.4 * R )
		return false;
	return T > 0.0;
}

// ---- what a body can come to

// Blood pumping out of a fresh cut, riding Bone of M and spurting along the bone's own way (or against it)
static function CutJet( KFMonster M, name Bone, optional bool bBack )
{
	local KFCutJet J;

	if ( M == None || M.Level.NetMode == NM_DedicatedServer || class'GameInfo'.static.UseLowGore() )
		return;
	J = M.Spawn(class'KFCutJet', M,, M.GetBoneCoords(Bone).Origin);
	if ( J == None )
		return;
	M.AttachToBone(J, Bone);
	if ( bBack )
		J.SetRelativeRotation(rot(32768,0,0));
	else
		J.SetRelativeRotation(rot(0,0,0));
}

static function bool Allowed( KFMonster M )
{
	return default.bTrauma && M != None && M.Mesh != None && M.bOwnLimbs && M.Level.NetMode != NM_DedicatedServer
		&& !class'GameInfo'.static.UseLowGore() && !M.Level.bDropDetail && M.Level.DetailMode != DM_Low && DeviceCuts(M);
}

// Whether this machine draws with a renderer whose alpha test the cuts work with: Direct3D 8 and 9. (Direct3D 11 draws
// the cut parts whole, two heads where the halves of one should be; OpenGL is not tried.) Read once a game run.
static function bool DeviceCuts( Actor A )
{
	local PlayerController PC;
	local string Dev;

	if ( !default.bDeviceRead )
	{
		PC = A.Level.GetLocalPlayerController();
		if ( PC == None )
			return false;
		Dev = Caps(PC.ConsoleCommand("get ini:Engine.Engine.RenderDevice Class"));
		default.bDeviceCuts = InStr(Dev, "D3D9DRV") >= 0 || InStr(Dev, "D3DDRV.") >= 0;
		default.bDeviceRead = true;
	}
	return default.bDeviceCuts;
}

// The head split down the middle by a blow along Dir's plane (Dir points across the cut), each half opening out on the
// neck and dropping off a moment later
static function bool SplitHead( KFMonster M, rotator Dir, class<DamageType> DamageType )
{
	local coords H;
	local vector Up, Mid, N, Hinge;
	local KFCutPiece A, B;
	local float R;

	if ( !Allowed(M) || M.Severed[4] != 0 )
		return false;
	H = M.GetBoneCoords(M.HeadBone);
	Up = Normal(H.XAxis);
	R = M.HeadRadius * M.HeadScale;
	Mid = H.Origin + Up * (M.HeadHeight * M.HeadScale);
	N = vector(Dir);
	N = N - Up * (N dot Up);
	if ( VSize(N) < 0.2 )
		N = Normal(H.ZAxis);
	N = Normal(N);
	Hinge = Normal(N cross Up);

	A = M.Spawn(class'KFCutPiece',,, Mid, M.Rotation);
	B = M.Spawn(class'KFCutPiece',,, Mid, M.Rotation);
	if ( A == None || B == None || !A.TakeLimb(M, M.HeadBone, 'None', 'None', M.StumpSize[4] * M.GibScale * M.DrawScale)
		|| !B.TakeLimb(M, M.HeadBone, 'None', 'None', M.StumpSize[4] * M.GibScale * M.DrawScale) )
	{
		if ( A != None )
			A.Destroy();
		if ( B != None )
			B.Destroy();
		return false;
	}
	A.Cut(Mid, N, Hinge, default.CleanEdge, Texture'KFCutSkull', R * default.HeadFace, R * default.HeadFace, Up);
	B.Cut(Mid, -N, Hinge, default.CleanEdge, Texture'KFCutSkull', R * default.HeadFace, R * default.HeadFace, Up);
	A.HingeOn(M, 'Bip01 Neck', H.Origin, Hinge, default.HingeOpen, default.HingeTime);
	B.HingeOn(M, 'Bip01 Neck', H.Origin, -Hinge, default.HingeOpen, default.HingeTime + 0.15);

	// the body: no head, the neck capped; blood up out of the neck between the halves
	M.Severed[4] = 1;
	M.HideBone(M.HeadBone);
	M.AddStump(4, M.HeadBone);
	CutJet(M, 'Bip01 Neck');
	class'KFBloodBlast'.static.Make(M, Mid, 0.22 * M.BloodBlastSize(), Up * 0.6);
	M.SpawnGiblet(class'KFMod.KFGibBrain', Mid, rotator(Up), 0.25);
	M.SpawnGiblet(class'KFMod.KFGibBrainb', Mid, rotator(Up), 0.25);
	M.PlaySound(sound'PlayerSounds.NewGibs.NewGib2', SLOT_Misc, class'KFBloodBlast'.static.GoreVol(255),, class'KFBloodBlast'.static.GoreRadius(255, M.TransientSoundRadius));
	if ( default.bTraumaDebug )
		log("TRAUMA split head" @ M @ "N" @ N @ "Up" @ Up);
	return true;
}

// The top of the skull taken off by a round going in at Dir: it flies on, turning over, and what is left on the neck
// shows the brain
static function bool TopHead( KFMonster M, rotator Dir, class<DamageType> DamageType )
{
	local coords H;
	local vector Up, Mid, Spot, Fly, Along;
	local KFCutPiece Top, Low;
	local float R;

	if ( !Allowed(M) || M.Severed[4] != 0 )
		return false;
	H = M.GetBoneCoords(M.HeadBone);
	Up = Normal(H.XAxis);
	R = M.HeadRadius * M.HeadScale;
	Mid = H.Origin + Up * (M.HeadHeight * M.HeadScale);
	// across the brow, a little above the head's middle
	Spot = Mid + Up * (0.25 * R);
	Along = Normal(H.YAxis);

	Top = M.Spawn(class'KFCutPiece',,, Mid, M.Rotation);
	Low = M.Spawn(class'KFCutPiece',,, Mid, M.Rotation);
	if ( Top == None || Low == None || !Top.TakeLimb(M, M.HeadBone, 'None', 'None', 0.0)
		|| !Low.TakeLimb(M, M.HeadBone, 'None', 'None', M.StumpSize[4] * M.GibScale * M.DrawScale) )
	{
		if ( Top != None )
			Top.Destroy();
		if ( Low != None )
			Low.Destroy();
		return false;
	}
	// the top keeps what is above the cut, the rest what is below
	Top.Cut(Spot, -Up, Along, default.TornEdge, Texture'KFCutSkull', R * default.TopFace, R * default.TopFace, Along);
	Low.Cut(Spot, Up, Along, default.TornEdge, Texture'KFCutSkull', R * default.TopFace, R * default.TopFace, Along);
	Low.HingeOn(M, 'Bip01 Neck', H.Origin, Along, 0.0, 30.0);
	Fly = vector(Dir);
	Fly = Normal(Normal(Fly) + Up * 0.8);
	Top.SetPhysics(PHYS_Falling);
	Top.Velocity = M.Velocity + Fly * (380.0 + 160.0 * FRand());
	Top.RandSpin(150000);

	M.Severed[4] = 1;
	M.HideBone(M.HeadBone);
	M.AddStump(4, M.HeadBone);
	CutJet(M, 'Bip01 Neck');
	class'KFBloodBlast'.static.Make(M, Spot, 0.25 * M.BloodBlastSize(), Fly * 0.6);
	M.SpawnGiblet(class'KFMod.KFGibBrain', Spot, rotator(Fly), 0.2);
	M.SpawnGiblet(class'KFMod.KFGibBrainb', Spot, rotator(Fly), 0.2);
	M.SpawnGiblet(class'KFMod.KFGibBrain', Spot, rotator(Fly), 0.3);
	M.PlaySound(sound'PlayerSounds.NewGibs.NewGib2', SLOT_Misc, class'KFBloodBlast'.static.GoreVol(255),, class'KFBloodBlast'.static.GoreRadius(255, M.TransientSoundRadius));
	if ( default.bTraumaDebug )
		log("TRAUMA top of head" @ M);
	return true;
}

// Cleaved in two from the head down along the plane square to Dir: each half the body's own, raw meat along the cut,
// falling away to its own side. The body itself goes.
static function bool Cleave( KFMonster M, rotator Dir, class<DamageType> DamageType )
{
	local vector Up, Mid, N, Fwd, Trunk, Head;
	local coords H;
	local KFCutPiece A, B;
	local float Tall, Deep, R;
	local int i;

	if ( !Allowed(M) || M.bFrozen || M.bGibbed || M.bCutBody || M.Severed[5] != 0 )
		return false;
	Up = Normal(M.GetBoneCoords('Bip01 Neck').Origin - M.GetBoneCoords('Bip01 Pelvis').Origin);
	Mid = M.GetBoneCoords('Bip01 Spine1').Origin;
	N = vector(Dir);
	N = N - Up * (N dot Up);
	if ( VSize(N) < 0.2 )
		N = M.GetBoneCoords('Bip01 R Thigh').Origin - M.GetBoneCoords('Bip01 L Thigh').Origin;
	N = Normal(N);
	Fwd = Normal(N cross Up);

	A = M.Spawn(class'KFCutPiece',,, Mid, M.Rotation);
	B = M.Spawn(class'KFCutPiece',,, Mid, M.Rotation);
	if ( A == None || B == None || !A.TakeUpper(M, 'Bip01 Spine1', true) || !B.TakeUpper(M, 'Bip01 Spine1', true) )
	{
		if ( A != None )
			A.Destroy();
		if ( B != None )
			B.Destroy();
		return false;
	}
	// the trunk's face from the hips to the neck, the head's on the head
	Trunk = 0.5 * (M.GetBoneCoords('Bip01 Neck').Origin + M.GetBoneCoords('Bip01 Pelvis').Origin);
	Tall = 0.58 * VSize(M.GetBoneCoords('Bip01 Neck').Origin - M.GetBoneCoords('Bip01 Pelvis').Origin);
	Deep = 0.40 * M.CollisionRadius;
	H = M.GetBoneCoords(M.HeadBone);
	Head = H.Origin + Normal(H.XAxis) * (M.HeadHeight * M.HeadScale);
	R = M.HeadRadius * M.HeadScale * default.HeadFace;
	A.Cut(Mid, N, Up, default.CleanEdge, Texture'KFCutSagittal', Deep, Tall, Up);
	B.Cut(Mid, -N, Up, default.CleanEdge, Texture'KFCutSagittal', Deep, Tall, Up);
	// (moved, an attached actor leaves its base: put back on it)
	if ( A.Face != None )
	{
		A.Face.SetLocation(A.Face.Location + (Trunk - Mid) - N * ((Trunk - Mid) dot N));
		A.Face.SetBase(A);
	}
	if ( B.Face != None )
	{
		B.Face.SetLocation(B.Face.Location + (Trunk - Mid) - N * ((Trunk - Mid) dot N));
		B.Face.SetBase(B);
	}
	if ( M.Severed[4] == 0 )
	{
		A.Face2 = A.MakeFace(Texture'KFCutSkull', R, R, Up, Head);
		B.Face2 = B.MakeFace(Texture'KFCutSkull', R, R, Up, Head);
	}
	// falling away from the cut, each to its own side
	A.SetPhysics(PHYS_Falling);
	B.SetPhysics(PHYS_Falling);
	A.Velocity = 0.5 * M.Velocity - N * (50.0 + 30.0 * FRand()) + Up * 30.0;
	B.Velocity = 0.5 * M.Velocity + N * (50.0 + 30.0 * FRand()) + Up * 30.0;
	A.RandSpin(12000);
	B.RandSpin(12000);

	class'KFBloodBlast'.static.Make(M, Mid, 0.8 * M.BloodBlastSize(), Up * 0.4);
	for ( i=0; i<3 + Rand(3); i++ )
		M.SpawnGiblet(class'KFMod.KFGibBrainb', Mid, rotator(Normal(VRand() + Fwd * 0.5)), 0.6);
	M.SpawnGiblet(class'KFMod.KFGibBrain', M.GetBoneCoords(M.HeadBone).Origin, rotator(Up), 0.3);
	M.PlaySound(sound'PlayerSounds.NewGibs.NewGib4', SLOT_Misc, class'KFBloodBlast'.static.GoreVol(255),, class'KFBloodBlast'.static.GoreRadius(255, M.TransientSoundRadius));
	M.bGibbed = true;
	for ( i=0; i<ArrayCount(M.Stumps); i++ )
		M.DropStump(i);
	if ( M.NeckJet != None )
		M.NeckJet.Destroy();
	M.RemoveGibbedBody();
	if ( default.bTraumaDebug )
		log("TRAUMA cleave" @ M @ "N" @ N);
	return true;
}

// In two across the waist: the top half (trunk, arms and head, what is left of them) its own whole self, thrown along
// Dir's up axis (a part's flight, as for a giblet), cut clean by a blade and torn by anything else; the legs and hips
// left lying as the body, cut the same; raw faces on both, guts and blood
static function bool CutWaist( KFMonster M, rotator Dir, class<DamageType> DamageType )
{
	local coords S1;
	local vector Up, Spot, Side, Front, X, Y, Z;
	local KFCutPiece Top;
	local KFCutBody Low;
	local float RA, RB, W;
	local bool bBlade;
	local int i;

	if ( !Allowed(M) || M.Severed[5] != 0 || M.bFrozen || M.bGibbed || M.bCutBody )
		return false;
	S1 = M.GetBoneCoords('Bip01 Spine1');
	Up = Normal(M.GetBoneCoords('Bip01 Neck').Origin - M.GetBoneCoords('Bip01 Pelvis').Origin);
	Spot = S1.Origin;
	Side = M.GetBoneCoords('Bip01 R Thigh').Origin - M.GetBoneCoords('Bip01 L Thigh').Origin;
	Side = Side - Up * (Side dot Up);
	if ( VSize(Side) < 0.1 )
		Side = Normal(S1.YAxis);
	Side = Normal(Side);
	Front = Normal(Side cross Up);
	RA = M.CollisionRadius * 0.62 * default.TorsoRing;
	RB = M.CollisionRadius * 0.48 * default.TorsoRing;
	bBlade = class<DamTypeMelee>(DamageType) != None || class<DamTypeAxeSlash>(DamageType) != None;
	if ( bBlade )
		W = default.CleanEdge;
	else
		W = default.TornEdge;

	Top = M.Spawn(class'KFCutPiece',,, Spot, M.Rotation);
	if ( Top == None )
		return false;
	if ( !Top.TakeUpper(M, 'Bip01 Spine2') )
	{
		Top.Destroy();
		return false;
	}
	Top.Cut(Spot, -Up, Side, W, Texture'KFCutTorso', RA * default.TorsoFace / default.TorsoRing, RB * default.TorsoFace / default.TorsoRing, Front);
	Top.Ring(Spot, Side, Front, RA, RB);
	Top.SetCollisionSize(10.0, 7.0);
	GetAxes(Dir, X, Y, Z);
	Top.SetPhysics(PHYS_Falling);
	if ( bBlade )
	{
		Top.Velocity = M.Velocity + Z * (160.0 + 80.0 * FRand()) + Up * 60.0;
		Top.RandSpin(25000);
	}
	else
	{
		Top.Velocity = M.Velocity + Z * (320.0 + 160.0 * FRand()) + Up * 120.0;
		Top.RandSpin(70000);
	}

	Low = M.Spawn(class'KFCutBody', M,, Spot);
	if ( Low != None )
		Low.Take(M, 'Bip01 Spine', Spot, Up, Side, Side, Front, RA, RB, W, Texture'KFCutTorso', RA * default.TorsoFace / default.TorsoRing, RB * default.TorsoFace / default.TorsoRing, Front);
	// all above the cut goes with the top half
	M.SetBoneScale(10, 0.0, 'Bip01 Neck');
	M.Severed[5] = 1;
	M.Severed[2] = 1;
	M.Severed[3] = 1;
	M.Severed[4] = 1;
	M.Severed[8] = 1;
	M.Severed[9] = 1;
	M.DropStump(2);
	M.DropStump(3);
	M.DropStump(4);
	M.DropStump(8);
	M.DropStump(9);
	if ( M.NeckJet != None )
		M.NeckJet.Destroy();
	CutJet(M, 'Bip01 Spine1');
	// guts out of both halves
	for ( i=0; i<3 + Rand(3); i++ )
		M.SpawnGiblet(class'KFMod.KFGibBrainb', Spot, rotator(Normal(VRand() + Up * 0.3)), 0.6);
	if ( default.bTraumaDebug )
		log("TRAUMA waist" @ M @ "Up" @ Up @ "Side" @ Side @ "blade" @ bBlade);
	return true;
}

defaultproperties
{
     bTrauma=True
     HeadFace=0.780000
     TopFace=0.480000
     HeadTopDamage=90
     HeadTopChance=0.550000
     SplitReach=0.700000
     TorsoFace=0.540000
     ShellShrink=0.965000
     CleanEdge=6.000000
     TornEdge=40.000000
     HingeOpen=38.000000
     HingeTime=1.300000
     TorsoRing=1.150000
     CleaveChance=0.650000
     WoundBones(0)="Bip01 Pelvis"
     WoundBones(1)="Bip01 Spine"
     WoundBones(2)="Bip01 Spine1"
     WoundBones(3)="Bip01 Spine2"
     WoundBones(4)="Bip01 Neck"
     WoundBones(5)="Bip01 Head"
     WoundBones(6)="Bip01 L UpperArm"
     WoundBones(7)="Bip01 L Forearm"
     WoundBones(8)="Bip01 R UpperArm"
     WoundBones(9)="Bip01 R Forearm"
     WoundBones(10)="Bip01 L Thigh"
     WoundBones(11)="Bip01 L Calf"
     WoundBones(12)="Bip01 R Thigh"
     WoundBones(13)="Bip01 R Calf"
     WoundEnds(0)="Bip01 Spine"
     WoundEnds(1)="Bip01 Spine1"
     WoundEnds(2)="Bip01 Spine2"
     WoundEnds(3)="Bip01 Neck"
     WoundEnds(4)="Bip01 Head"
     WoundEnds(5)="None"
     WoundEnds(6)="Bip01 L Forearm"
     WoundEnds(7)="Bip01 L Hand"
     WoundEnds(8)="Bip01 R Forearm"
     WoundEnds(9)="Bip01 R Hand"
     WoundEnds(10)="Bip01 L Calf"
     WoundEnds(11)="Bip01 L Foot"
     WoundEnds(12)="Bip01 R Calf"
     WoundEnds(13)="Bip01 R Foot"
     WoundRadii(0)=9.000000
     WoundRadii(1)=9.000000
     WoundRadii(2)=9.500000
     WoundRadii(3)=10.000000
     WoundRadii(4)=4.500000
     WoundRadii(5)=6.000000
     WoundRadii(6)=3.400000
     WoundRadii(7)=2.800000
     WoundRadii(8)=3.400000
     WoundRadii(9)=2.800000
     WoundRadii(10)=4.600000
     WoundRadii(11)=3.600000
     WoundRadii(12)=4.600000
     WoundRadii(13)=3.600000
     WoundJoints(0)=-1
     WoundJoints(1)=-1
     WoundJoints(2)=5
     WoundJoints(3)=5
     WoundJoints(4)=5
     WoundJoints(5)=4
     WoundJoints(6)=8
     WoundJoints(7)=3
     WoundJoints(8)=9
     WoundJoints(9)=2
     WoundJoints(10)=0
     WoundJoints(11)=6
     WoundJoints(12)=1
     WoundJoints(13)=7
     bWounds=True
     WoundStandOff=6.000000
     ExitDamage=55
     HoleSize=17.000000
     HeavyHoleSize=23.000000
     ExitSize=30.000000
     CavitySize=50.000000
     GashSize=26.000000
     CavityReach=320.000000
     CavityShare=0.450000
     TunnelDamage=150
     TunnelPerDamage=0.018000
     TunnelMin=3.200000
     TunnelMax=7.000000
}
