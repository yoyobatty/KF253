//=============================================================================
// KFBlast
// What a blast does to the world round it, on each machine that sees it, beside its own fireball and smoke: the
// ground it went off on answers (dust off stone, earth off the ground, sparks off metal), the room lights up and dies
// away, smoke climbs and embers drift out of it, and the air bends round it as the wave goes out (KFScreenFX.Wave).
// Too far off for all that, it is still seen: a flash and a glow (Far).
//=============================================================================
class KFBlast extends Actor
	abstract;

// A blast of Size (a rocket's is 1) at Spot, off the surface facing Normal; bNoWave for one that is not a weapon's (the
// air bends round the weapons' blasts alone: a wave is dear, a picture of the scene each)
static function Go( Actor Maker, vector Spot, vector Normal, float Size, optional bool bNoWave )
{
	local vector HitLoc, HitNorm, Down;
	local Material Mat;
	local Actor A;
	local class<KFBlastEmitter> GroundFX;
	local KFBlastEmitter E;
	local KFBlastLight Light;
	local ESurfaceTypes ST;

	if ( Maker == None || Maker.Level.NetMode == NM_DedicatedServer )
		return;
	class'KFGib'.static.Blast(Maker, Spot + Normal * 8, Size);
	// the ground: what it struck, else what lies under it close by
	if ( Normal == vect(0,0,0) )
		Normal = vect(0,0,1);
	A = Maker.Trace(HitLoc, HitNorm, Spot - Normal * 40, Spot + Normal * 16, false,, Mat);
	if ( A == None )
	{
		Down = Spot - vect(0,0,1) * 120 * Size;
		A = Maker.Trace(HitLoc, HitNorm, Down, Spot, false,, Mat);
	}
	if ( A != None )
	{
		ST = EST_Default;
		if ( !A.IsA('LevelInfo') && A.SurfaceType != EST_Default )
			ST = A.SurfaceType;
		else if ( Mat != None )
			ST = ESurfaceTypes(Mat.SurfaceType);
		GroundFX = class'KFBlastDust';
		if ( ST == EST_Metal )
			GroundFX = class'KFBlastSparks';
		else if ( ST == EST_Dirt || ST == EST_Plant || ST == EST_Snow || ST == EST_Ice || TerrainInfo(A) != None )
			GroundFX = class'KFBlastDirt';
		E = Maker.Spawn(GroundFX,,, HitLoc + HitNorm * 6, rotator(HitNorm));
		if ( E != None )
			E.Size = Size;
	}
	E = Maker.Spawn(class'KFBlastSmoke',,, Spot + Normal * 10);
	if ( E != None )
		E.Size = Size;
	Light = Maker.Spawn(class'KFBlastLight',,, Spot + Normal * 40);
	if ( Light != None )
		Light.Size = Size;
	if ( !bNoWave )
		class'KFScreenFX'.static.Wave(Maker.Level, Spot + Normal * 20, Size);
	Ceiling(Maker, Spot + Normal * 20, Size);
}

// The ceiling over a blast and round it shaken: dust sifts down and grit falls (KFBlastCeiling)
static function Ceiling( Actor Maker, vector From, float Size )
{
	local int i;
	local vector Start, HL, HN;
	local KFBlastEmitter E;

	if ( Maker == None || Maker.Level.NetMode == NM_DedicatedServer )
		return;
	for ( i = 0; i < 3; i++ )
	{
		Start = From;
		if ( i > 0 )
		{
			Start.X += (FRand() - 0.5) * 520 * Size;
			Start.Y += (FRand() - 0.5) * 520 * Size;
			if ( !Maker.FastTrace(Start, From) )
				continue;
		}
		if ( Maker.Trace(HL, HN, Start + vect(0,0,1) * 560 * Size, Start, false) == None || HN.Z > -0.7 )
			continue;
		E = Maker.Spawn(class'KFBlastCeiling',,, HL - vect(0,0,6), rot(0,0,0));
		if ( E == None )
			continue;
		E.Size = Size;
		if ( i > 0 )
			E.Size = 0.6 * Size;
	}
}

// A blast too far off for its own effects: seen if the viewer has it in sight
static function Far( Actor Maker, vector Spot, float Size )
{
	local PlayerController PC;
	local vector Eye;
	local KFBlastEmitter E;

	if ( Maker == None || Maker.Level.NetMode == NM_DedicatedServer )
		return;
	PC = Maker.Level.GetLocalPlayerController();
	if ( PC == None || PC.ViewTarget == None )
		return;
	Eye = PC.ViewTarget.Location;
	if ( Pawn(PC.ViewTarget) != None )
		Eye.Z += Pawn(PC.ViewTarget).EyeHeight;
	if ( VSize(Spot - Eye) > 20000 || !Maker.FastTrace(Spot + vect(0,0,24), Eye) )
		return;
	E = Maker.Spawn(class'KFFarFlash',,, Spot + vect(0,0,24));
	if ( E != None )
		E.Size = Size;
}
