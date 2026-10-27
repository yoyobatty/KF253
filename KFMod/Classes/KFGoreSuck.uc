//=============================================================================
// KFGoreSuck
// The Gore Cannon's vacuum on the bodies and giblets of one machine (each keeps its own): those in the cone in front of
// the barrel's mouth (or close all round it) are woken and dragged in, and swallowed when they reach it, with a wet
// spray and a slurp.
//=============================================================================
class KFGoreSuck extends Object;

#exec OBJ LOAD FILE=PlayerSounds.uax

const BodyPull = 320000.0;		// Karma's push a second on a body at the mouth
const BodyLift = 90000.0;
const GibSpeed = 1100.0;		// how fast a giblet flies in

// What it swallows is added to Bodies (each body's class) and Gibs
static function Suck( Actor Here, vector Mouth, vector Dir, float DT, float Reach, float ConeCos, float NearAll,
	out array< class<KFMonster> > Bodies, out int Gibs )
{
	local KFMonster M;
	local KFGib G;
	local array<KFMonster> Ms;
	local array<KFGib> Gs;
	local vector C, V, Push, Want;
	local float D, K;
	local int i;

	if ( Here == None || Here.Level.NetMode == NM_DedicatedServer )
		return;
	foreach Here.DynamicActors(class'KFMonster', M)
		if ( M.Health <= 0 && !M.bGibbed && !M.bDeleteMe && M.Physics == PHYS_KarmaRagdoll && VSize(M.Location - Mouth) < Reach + 100 )
			Ms[Ms.Length] = M;
	foreach Here.DynamicActors(class'KFGib', G)
		if ( !G.bBurst && !G.bDeleteMe && VSize(G.Location - Mouth) < Reach )
			Gs[Gs.Length] = G;

	for ( i = 0; i < Ms.Length; i++ )
	{
		M = Ms[i];
		C = M.GetBoneCoords('Bip01 Spine2').Origin;
		V = Mouth - C;
		D = FMax(VSize(V), 1.0);
		if ( D > Reach || (D > NearAll && (-V / D) dot Dir < ConeCos) )
			continue;
		if ( D < 70.0 + 0.5 * M.CollisionRadius )
		{
			Bodies[Bodies.Length] = M.Class;
			Swallow(Here, Mouth, Dir, 1.0);
			M.bGibbed = true;
			M.RemoveGibbedBody();
			continue;
		}
		K = 1.0 - D / Reach;
		M.WakeBody();
		Push = (V / D * BodyPull * (0.35 + 0.65 * K) + vect(0,0,1) * BodyLift * K) * DT * 0.5;
		M.KAddImpulse(Push, M.GetBoneCoords('Bip01 Pelvis').Origin, 'Bip01 Pelvis');
		M.KAddImpulse(Push, M.GetBoneCoords('Bip01 Neck').Origin, 'Bip01 Neck');
	}

	for ( i = 0; i < Gs.Length; i++ )
	{
		G = Gs[i];
		if ( G == None || G.bDeleteMe || G.bBurst )
			continue;
		V = Mouth - G.Location;
		D = FMax(VSize(V), 1.0);
		if ( D > NearAll && (-V / D) dot Dir < ConeCos )
			continue;
		if ( D < 45.0 )
		{
			if ( KFLimbGib(G) != None )
				Gibs += 2;
			else if ( !G.bSmall )
				Gibs += 1;
			Swallow(Here, Mouth, Dir, 0.4);
			G.Destroy();
			continue;
		}
		K = 1.0 - D / Reach;
		if ( G.Physics != PHYS_Falling )
		{
			G.SetPhysics(PHYS_Falling);
			G.bBounce = true;
			G.SetTimer(0.0, false);
			G.RandSpin(150000);
		}
		Want = V / D * GibSpeed * (0.35 + 0.65 * K);
		G.Velocity += (Want - G.Velocity) * FMin(DT * (2.0 + 6.0 * K), 1.0);
		G.Velocity.Z += 500.0 * K * DT;
		G.LifeSpan = FMax(G.LifeSpan, 2.0);
	}
}

// A wet spray back out of the mouth, and a slurp
static function Swallow( Actor Here, vector Mouth, vector Dir, float Size )
{
	local KFBloodFX B;

	B = Here.Spawn(class'KFBloodFX',,, Mouth, rotator(Dir));
	if ( B != None )
	{
		B.Dir = Dir;
		B.Size = 0.5 * Size;
		B.bNoMist = true;
	}
	Here.PlaySound(Sound'PlayerSounds.NewGibs.NewGib2', SLOT_None, class'KFBloodBlast'.static.GoreVol(1.0 + Size),, class'KFBloodBlast'.static.GoreRadius(1.0 + Size, 600), 1.4 - 0.3 * Size);
}
