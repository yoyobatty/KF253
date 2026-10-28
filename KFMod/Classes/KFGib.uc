// Spawns Trail on PostBeginPlay.

class KFGib extends Gib;

var() xEmitter TrailFlame;

// A giblet off a charred body shows the burnt skin through its own by the share it is charred
var Combiner CharSkin;
var ConstantColor CharMask;
var array<Object> CharMade;				// from the level's pool, given back when it goes
var bool bAsh;							// a lump off a body burnt through (KFMonster.AshCrumble): it does not bleed
var bool bIce;							// a chunk off a frozen specimen (Iced): it shatters
var bool bSmall;						// a bit off a giblet torn apart: torn again, it only bleeds
var bool bBurst;						// (torn apart)
var bool bPulled;						// (caught by a BFG ball's pull)
var float Charred;						// (how far CharTo has charred it)
var float EatAfter;						// (a bit just thrown off is not torn apart again at once)
var bool bFrameLit;						// at rest, lit from the frame round it and not by the engine (TakeFrameLight)
var Material FrameBase;					// ...and the skin it had

// What it does when things go on round it (each machine that draws it has its own giblets)
var() float BlastReach, BurstReach;		// a rocket's blast (Size 1): how far off giblets are thrown, and how close torn apart
var() float BlastThrow;					// ...how fast the nearest are thrown
var() float PullReach, PullEat;			// a BFG ball: how far off it draws giblets in, how close it tears them apart
var() float PullSpeed;					// ...how fast they fly in to it
var() float PullSwirl;					// ...how fast they go round its path
var() float EatRate;					// ...how many a second, of those that have reached it, it tears apart
var() int MaxGibs;						// no new bits are made while this many giblets are about
var() float UnseenLife;					// one at rest that has not been drawn for this long goes, as an unseen corpse does

// (fewer lying about at Normal gore: each lies a shorter while, KFGoreLevel)
simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	LifeSpan *= class'KFGoreLevel'.static.Life();
}

simulated function HitWall( Vector HitNormal, Actor Wall )
{
    local float Speed, MinSpeed;
    local KFBloodStreakDecal Streak;

    Velocity = DampenFactor * ((Velocity dot HitNormal) * HitNormal*(-2.0) + Velocity);
    RandSpin(100000);
    Speed = VSize(Velocity);
    if (  Level.DetailMode == DM_Low )
    {
        MinSpeed = 250;
        LifeSpan = 8.0;
    }
    else
        MinSpeed = 150;

        if( (Level.NetMode != NM_DedicatedServer) && !Level.bDropDetail && !bAsh )
        {
            if ( GibGroupClass.default.BloodGibClass != None )
                Spawn( GibGroupClass.default.BloodGibClass,,, Location, Rotator(-HitNormal) );
            if ( (LifeSpan < 7.3)  && (Level.DetailMode != DM_Low) )
                PlaySound(HitSounds[Rand(2)], SLOT_Misc, class'KFBloodBlast'.static.GoreVol(TransientSoundVolume),, class'KFBloodBlast'.static.GoreRadius(TransientSoundVolume, TransientSoundRadius));

            if ( Speed > 100 )
            {
                Streak = Spawn(class'KFMod.KFBloodStreakDecal',,, Location + 20 * HitNormal, Rotator(HitNormal));
                if ( Streak != None )
                    Streak.SetRotation(Rotator(Velocity));
            }
        }

    if( Speed < 20 ) 
    {
        if(!Level.bDropDetail && (Level.DetailMode != DM_Low) && GibGroupClass.default.BloodHitClass != None && !bAsh )
            Spawn( GibGroupClass.default.BloodHitClass,,, Location, Rotator(-HitNormal) );
        bBounce = False;
        SetPhysics(PHYS_None);
        TakeFrameLight();
        // (at rest: whoever walks through it kicks it along, and out of sight it goes)
        if ( !bBurst )
            SetTimer(0.2 + 0.1 * FRand(), true);
    }
}

// ---- giblets lying about answer what goes on round them

// Thrown: Push is the speed it is given
simulated function Kick( vector Push )
{
	if ( bBurst )
		return;
	if ( Physics != PHYS_Falling )
	{
		SetPhysics(PHYS_Falling);
		bBounce = true;
	}
	Velocity += Push;
	RandSpin(100000);
	LifeSpan = FMax(LifeSpan, 3.0);
	SetTimer(0.0, false);
}

// Torn apart, thrown along Dir at about Speed: a burst of blood, a stain on the floor and, while Room allows, smaller
// bits that fly off bleeding. A bit torn apart only bleeds; ice shatters, ash crumbles. Returns the bits made.
simulated function int Burst( vector Dir, float Speed, int Room )
{
	local int i, n;
	local KFGib G;
	local KFBloodFX B;
	local Actor A;
	local vector HL, HN;

	if ( bBurst || bDeleteMe )
		return 0;
	bBurst = true;
	if ( VSize(Dir) < 0.1 )
		Dir = vect(0,0,1);
	Dir = Normal(Dir);
	if ( bIce )
		Spawn(class'KFIceHit',,, Location);
	else if ( bAsh )
	{
		if ( !bSmall )
			Spawn(class'KFAshBurst',,, Location);
	}
	else
	{
		// a giblet bursts in blood; a bit off one only spatters
		if ( !bSmall )
			class'KFBloodBlast'.static.Make(self, Location, 0.35, Dir);
		B = Spawn(class'KFBloodFX',,, Location, rotator(Dir));
		if ( B != None )
		{
			B.Dir = Dir;
			B.Size = 1.3;
			if ( bSmall )
				B.Size = 0.6;
			B.bHeavy = !bSmall;
			if ( bSmall )
				B.PlaySound(HitSounds[Rand(2)], SLOT_None, class'KFBloodBlast'.static.GoreVol(1.5),, class'KFBloodBlast'.static.GoreRadius(1.5, 400), 1.0 + 0.3 * FRand());
			else
				B.PlaySound(HitSounds[Rand(2)], SLOT_None, class'KFBloodBlast'.static.GoreVol(2.5),, class'KFBloodBlast'.static.GoreRadius(2.5, 600), 0.85 + 0.3 * FRand());
		}
		if ( !bSmall || FRand() < 0.35 )
		{
			A = Trace(HL, HN, Location - vect(0,0,90), Location + vect(0,0,8), false);
			if ( A != None )
			{
				if ( bSmall )
					Spawn(class'KFBloodSplat',,, HL + 20 * HN, rotator(-HN));
				else
					Spawn(class'KFBloodSmack',,, HL + 20 * HN, rotator(-HN));
			}
		}
		if ( !bSmall && Room > 0 )
		{
			n = 3 + Rand(3);
			if ( KFLimbGib(self) != None )
				n += 2;
			if ( Level.bDropDetail || Level.DetailMode == DM_Low )
				n = (n + 1) / 2;
			n = Min(class'KFGoreLevel'.static.SomeGibs(n), Room);
			for ( i = 0; i < n; i++ )
			{
				if ( (i & 1) == 0 )
					G = Spawn(class'KFGibBrain',,, Location + VRand() * 3, RotRand());
				else
					G = Spawn(class'KFGibBrainb',,, Location + VRand() * 3, RotRand());
				if ( G == None )
					continue;
				G.bSmall = true;
				G.SetDrawScale(G.DrawScale * (0.45 + 0.5 * FRand()));
				G.CharTo(Charred);
				G.LifeSpan = 4.0 + 3.0 * FRand();
				G.EatAfter = Level.TimeSeconds + 0.3;
				G.SpawnTrail();
				G.Velocity = Dir * Speed * (0.35 + 0.65 * FRand()) + VRand() * (120.0 + 0.35 * Speed) + vect(0,0,160);
				G.RandSpin(120000);
			}
		}
	}
	Destroy();
	return n;
}

// At rest: kicked along by whoever walks through it; a heavy specimen treads it to pulp
simulated function Timer()
{
	local Pawn P;
	local vector D;
	local float Speed;

	if ( Physics != PHYS_None || bBurst )
	{
		SetTimer(0.0, false);
		return;
	}
	// (giblets out of sight cost as much as those in it: hundreds lay about after a big fight)
	if ( Level.TimeSeconds - SeenAt() > UnseenLife )
	{
		Destroy();
		return;
	}
	// (the first to come to rest asked for the frame's soft picture, which is made from the next frame on)
	if ( !bFrameLit )
		TakeFrameLight();
	if ( Level.bDropDetail )
		return;
	foreach CollidingActors(class'Pawn', P, 80.0, Location)
	{
		Speed = VSize(P.Velocity);
		if ( P.Health <= 0 || Speed < 60.0 || Vehicle(P) != None )
			continue;
		D = Location - P.Location;
		if ( Abs(D.Z + P.CollisionHeight) > 30.0 )
			continue;
		D.Z = 0;
		if ( VSize(D) > P.CollisionRadius + 8.0 )
			continue;
		if ( !bSmall && KFMonster(P) != None && P.Mass >= 400.0 && FRand() < 0.4 )
		{
			Burst(P.Velocity, 250.0, RoomFor(self));
			return;
		}
		Kick(Normal(Normal(D) + P.Velocity / Speed) * (0.8 * Speed + 60.0) + vect(0,0,1) * (100.0 + 0.25 * Speed));
		PlaySound(HitSounds[Rand(2)], SLOT_None, class'KFBloodBlast'.static.GoreVol(1.2),, class'KFBloodBlast'.static.GoreRadius(1.2, 300));
		return;
	}
}

// At rest it takes its light from the frame round it, not from the engine, whose gathering of the lights for each of
// hundreds of giblets every frame was most of what they cost (KFScreenFX.GibSkin). A charred, frozen or ashen one, or
// one whose skin is cut out or seen through, is lit as it was.
simulated function TakeFrameLight()
{
	local Texture T;
	local Material M;

	if ( bFrameLit || bUnlit || bAsh || bIce || CharSkin != None || DrawType != DT_StaticMesh || Skins.Length == 0 )
		return;
	T = Texture(Skins[0]);
	if ( T == None || T.bMasked || T.bAlphaTexture )
		return;
	M = class'KFScreenFX'.static.GibSkin(self, T);
	if ( M == None )
		return;
	FrameBase = T;
	Skins[0] = M;
	bUnlit = true;
	bFrameLit = true;
}

// Lit by the engine again, in its own skin
simulated function DropFrameLight()
{
	if ( !bFrameLit )
		return;
	bFrameLit = false;
	bUnlit = false;
	Skins[0] = FrameBase;
}

// When it was last drawn
simulated function float SeenAt()
{
	return LastRenderTime;
}

// How many bits may still be made
static function int RoomFor( Actor A )
{
	local KFGib G;
	local int n;

	foreach A.DynamicActors(class'KFGib', G)
		n++;
	return Max(MaxNow() - n, 0);
}

// How many giblets there may be about before no new bits are made (fewer at Normal gore, KFGoreLevel)
static function int MaxNow()
{
	return int(default.MaxGibs * class'KFGoreLevel'.static.Gibs());
}

// A blast of Size (a rocket's 1) at Spot: the giblets close by are torn apart, those further off thrown away from it.
// Char: it burns as well (an arc flash, a fireball): what it throws is charred up to that much. bNoBurst: it only throws.
static function Blast( Actor Maker, vector Spot, float Size, optional float Char, optional bool bNoBurst )
{
	local KFGib G;
	local array<KFGib> Near;
	local int i, Room;
	local float Reach, D, K;
	local vector V;

	if ( Maker == None || Maker.Level.NetMode == NM_DedicatedServer || Size <= 0.0 )
		return;
	Reach = default.BlastReach * Size;
	foreach Maker.DynamicActors(class'KFGib', G)
	{
		Room++;
		if ( !G.bBurst && VSize(G.Location - Spot) < Reach )
			Near[Near.Length] = G;
	}
	Room = Max(MaxNow() - Room, 0);
	for ( i = 0; i < Near.Length; i++ )
	{
		G = Near[i];
		if ( G == None || G.bDeleteMe || G.bBurst )
			continue;
		V = G.Location - Spot;
		D = VSize(V);
		K = 1.0 - D / Reach;
		if ( Char > 0.0 )
			G.CharTo(Char * K);
		if ( !bNoBurst && D < default.BurstReach * Size )
			Room -= G.Burst(V + vect(0,0,40), default.BlastThrow * Size * (0.5 + 0.5 * K), Room);
		else
			G.Kick(Normal(V + vect(0,0,60)) * default.BlastThrow * Size * (0.25 + 0.75 * K) + vect(0,0,1) * (120.0 + 260.0 * K) * Size);
	}
}

// A BFG ball going by: the giblets near it are drawn up off the floor and in to it, and torn apart when they reach it
static function Pull( Actor Ball, float DT )
{
	local KFGib G;
	local array<KFGib> Near;
	local int i, Room;
	local float D, K;
	local vector V, Want, Axis;

	if ( Ball == None || Ball.Level.NetMode == NM_DedicatedServer )
		return;
	Axis = Normal(Ball.Velocity);
	foreach Ball.DynamicActors(class'KFGib', G)
	{
		Room++;
		if ( !G.bBurst && VSize(G.Location - Ball.Location) < default.PullReach )
			Near[Near.Length] = G;
	}
	Room = Max(MaxNow() - Room, 0);
	for ( i = 0; i < Near.Length; i++ )
	{
		G = Near[i];
		if ( G == None || G.bDeleteMe || G.bBurst )
			continue;
		V = Ball.Location - G.Location;
		D = FMax(VSize(V), 1.0);
		if ( D < default.PullEat && Ball.Level.TimeSeconds >= G.EatAfter && FRand() < DT * default.EatRate )
		{
			Room -= G.Burst(Ball.Velocity, 500.0, Room);
			continue;
		}
		K = 1.0 - D / default.PullReach;
		if ( G.Physics != PHYS_Falling )
		{
			G.SetPhysics(PHYS_Falling);
			G.bBounce = true;
			G.Velocity.Z += 150.0;
			G.SetTimer(0.0, false);
		}
		if ( !G.bPulled )
		{
			G.bPulled = true;
			G.RandSpin(150000);
		}
		// (in to it, round its path, and along with it the nearer they are)
		Want = V / D * default.PullSpeed * (0.25 + 0.75 * K) + (Axis cross (V / D)) * default.PullSwirl * K + Ball.Velocity * (0.7 * K);
		G.Velocity += (Want - G.Velocity) * FMin(DT * (0.8 + 4.0 * K), 1.0);
		G.Velocity.Z += 700.0 * K * DT;
		G.LifeSpan = FMax(G.LifeSpan, 2.0);
	}
}

// A line from A to B (a rail slug, a BFG tracer): the giblets it goes through are torn apart
static function Line( Actor Maker, vector A, vector B, float Width )
{
	local KFGib G;
	local array<KFGib> Near;
	local int i, Room;
	local vector Dir;
	local float L, T;

	if ( Maker == None || Maker.Level.NetMode == NM_DedicatedServer )
		return;
	Dir = B - A;
	L = VSize(Dir);
	if ( L < 1.0 )
		return;
	Dir = Dir / L;
	foreach Maker.DynamicActors(class'KFGib', G)
	{
		Room++;
		if ( G.bBurst )
			continue;
		T = FClamp((G.Location - A) dot Dir, 0.0, L);
		if ( VSize(G.Location - (A + Dir * T)) < Width + G.CollisionRadius )
			Near[Near.Length] = G;
	}
	Room = Max(MaxNow() - Room, 0);
	for ( i = 0; i < Near.Length; i++ )
		if ( Near[i] != None && !Near[i].bBurst )
			Room -= Near[i].Burst(Dir + vect(0,0,0.3), 700.0, Room);
}

// A melee swing crossing the view from Eye along Aim, reaching Range: the giblets lying where it goes are chopped apart
// (a blunt weapon, Kind 2, knocks some about instead)
static function Chop( Actor Maker, vector Eye, vector Aim, float Range, byte Kind )
{
	local KFGib G;
	local array<KFGib> Near;
	local int i, Room;
	local vector V;
	local float T;

	if ( Maker == None || Maker.Level.NetMode == NM_DedicatedServer )
		return;
	foreach Maker.DynamicActors(class'KFGib', G)
	{
		Room++;
		if ( G.bBurst )
			continue;
		V = G.Location - Eye;
		T = V dot Aim;
		if ( T > 0.0 && T < Range && VSize(V - Aim * T) < 18.0 + 0.35 * T )
			Near[Near.Length] = G;
	}
	Room = Max(MaxNow() - Room, 0);
	for ( i = 0; i < Near.Length; i++ )
	{
		G = Near[i];
		if ( G == None || G.bBurst )
			continue;
		if ( Kind != 2 || FRand() < 0.6 )
			Room -= G.Burst(Aim + vect(0,0,0.5), 350.0, Room);
		else
			G.Kick(Normal(Aim + vect(0,0,0.6)) * 380.0);
	}
}

// A shot or a blow that struck the world at Spot with an impact of Power (a rifle round's 1, a pellet's 0.45, an axe's
// 1.9): a giblet it went into is torn apart, mostly; those beside it jump
static function Struck( Actor Maker, vector Spot, float Power )
{
	local KFGib G;
	local array<KFGib> Near;
	local int i, Room;
	local float Reach, D;
	local vector V;

	if ( Maker == None || Maker.Level.NetMode == NM_DedicatedServer || Power <= 0.0 )
		return;
	Reach = 16.0 + 16.0 * Power;
	foreach Maker.DynamicActors(class'KFGib', G)
	{
		Room++;
		if ( !G.bBurst && VSize(G.Location - Spot) < Reach + G.CollisionRadius )
			Near[Near.Length] = G;
	}
	if ( Near.Length == 0 )
		return;
	Room = Max(MaxNow() - Room, 0);
	for ( i = 0; i < Near.Length; i++ )
	{
		G = Near[i];
		if ( G == None || G.bDeleteMe || G.bBurst )
			continue;
		V = G.Location - Spot;
		D = VSize(V);
		if ( D < (Reach + G.CollisionRadius) * 0.5 && FRand() < 0.35 + 0.5 * Power )
			Room -= G.Burst(V + vect(0,0,24), 250.0 + 150.0 * Power, Room);
		else
			G.Kick(Normal(V + vect(0,0,20)) * (140.0 + 160.0 * Power) + vect(0,0,1) * (120.0 + 100.0 * Power));
	}
}

simulated event TakeDamage(int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType)
{
    if ( DamageType != class'DamTypeLAW' && DamageType != class'DamTypeFrag' )
        return;

    if ( Physics == PHYS_None )
    {
        SetPhysics(PHYS_Falling);
        bBounce = True;
    }
    Velocity += Momentum / Mass;
    Velocity.Z += 200 + FRand() * 300;
    RandSpin(100000);
}

// Called when the giblet is made, and again once its specimen has said whether it was burning,
// so each part is only made the first time.
simulated function SpawnTrail()
{
    if ( Level.NetMode != NM_DedicatedServer )
    {
		if ( bFlaming && TrailFlame == None && FRand() < 0.65) //Spawn both!
		{
			TrailFlame = Spawn(class'KFHitFlame', self,,Location,Rotation);
            TrailFlame.SetPhysics( PHYS_Trailer );
			TrailFlame.LifeSpan = 4 + 2*FRand();
			LifeSpan = TrailFlame.LifeSpan + 4.0;
			TrailFlame.SetTimer(LifeSpan - 3.0,false);
		}
		if ( Trail == None && TrailClass != None )
		{
			Trail = Spawn(TrailClass, self,, Location, Rotation);
			Trail.LifeSpan = 1.8;
			Trail.SetPhysics( PHYS_Trailer );
			RandSpin( 64000 );
		}
	}
}

// A lump of a body burnt through: no blood trails behind it or splashes where it lands
simulated function Ashen()
{
	bAsh = true;
	if ( Trail != None )
	{
		Trail.Destroy();
		Trail = None;
	}
}

// A chunk of a specimen frozen solid: ice blue, and it does not bleed
simulated function Iced()
{
	local Combiner C;
	local ConstantColor CC;

	Ashen();
	bIce = true;
	if ( Skins.Length == 0 || Level.NetMode == NM_DedicatedServer )
		return;
	CC = new class'ConstantColor';
	CC.Color.R = 150;
	CC.Color.G = 200;
	CC.Color.B = 255;
	CC.Color.A = 255;
	C = new class'Combiner';
	C.CombineOperation = CO_Multiply;
	C.Material1 = Skins[0];
	C.Material2 = CC;
	Skins[0] = C;
}

// Charred by Amount, 0 to 1; called again as its body chars further
simulated function CharTo( float Amount )
{
	local Texture T;

	if ( Amount <= Charred || Level.NetMode == NM_DedicatedServer )
		return;
	Charred = Amount;
	DropFrameLight();
	if ( CharSkin == None )
	{
		if ( Skins.Length == 0 )
			return;
		T = Texture(Skins[0]);
		if ( T == None || T.bMasked || T.bAlphaTexture )
			return;
		CharMask = class'KFFXMat'.static.Tone(CharMade, Level, 255, 255);
		CharSkin = class'KFFXMat'.static.Fade(CharMade, Level, Texture'PatchTex.Common.ZedBurnSkin', T, CharMask);
		Skins[0] = CharSkin;
	}
	CharMask.Color.A = Clamp(int(255.0 * (1.0 - Amount)), 0, 255);
}

simulated function Destroyed()
{
	if ( CharMade.Length > 0 )
		class'KFFXMat'.static.FreeAll(CharMade, Level);
	Super.Destroyed();
}

defaultproperties
{
    DampenFactor=0.400000
    LifeSpan=12.000000
    Mass=280.000000
    DrawScale=1.100000
    GibGroupClass=Class'KFMod.KFGibGroup'
    bUseDynamicLights=True
    BlastReach=420.000000
    BurstReach=150.000000
    BlastThrow=950.000000
    PullReach=450.000000
    PullEat=80.000000
    PullSpeed=800.000000
    PullSwirl=350.000000
    EatRate=8.000000
    MaxGibs=160
    UnseenLife=3.000000
}
