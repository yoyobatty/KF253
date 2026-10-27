//=============================================================================
// CryoBolt
// The cryo cannon's bolt: a white-blue spark trailing frost, that bursts where it strikes into a freezing cloud
// (Burst): every specimen within FreezeRadius is frozen solid for up to FreezeTime (less to the edge, half as long
// for the big ones) and chilled for ChillDamage; frost on the floor and walls (KFCryoBurst, KFFrostMark).
//=============================================================================
class CryoBolt extends Projectile;

#exec OBJ LOAD FILE=..\Sounds\IndoorAmbience.uax

var() float	FreezeRadius, FreezeTime;
var() int	ChillDamage;
var KFCryoBoltFX	FX;
var bool	bBurst;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	Velocity = vector(Rotation) * Speed;
	if ( Level.NetMode != NM_DedicatedServer )
	{
		FX = Spawn(class'KFCryoBoltFX', self,, Location, Rotation);
		if ( FX != None )
			FX.SetBase(self);
	}
}

simulated function ProcessTouch( Actor Other, vector HitLocation )
{
	if ( Other == None || Other == Instigator || Other == Owner || Other.bDeleteMe || bBurst )
		return;
	if ( KFHumanPawn(Other) != None || Projectile(Other) != None || (Other.Base != None && KFHumanPawn(Other.Base) != None) )
		return;
	Explode(HitLocation, Normal(HitLocation - Other.Location));
}

simulated function HitWall( vector HitNormal, Actor Wall )
{
	Explode(Location + HitNormal * 4, HitNormal);
}

simulated function Explode( vector HitLocation, vector HitNormal )
{
	if ( bBurst )
		return;
	bBurst = true;
	if ( Role == ROLE_Authority )
		Burst(HitLocation);
	if ( Level.NetMode != NM_DedicatedServer )
		Show(HitLocation, HitNormal);
	if ( FX != None )
		FX.Kill();
	Destroy();
}

// (the server) Everything in the cloud frozen and chilled
function Burst( vector C )
{
	local KFMonster M;
	local float D, K;

	foreach VisibleCollidingActors(class'KFMonster', M, FreezeRadius, C)
	{
		if ( M.Health <= 0 )
			continue;
		D = FMax(VSize(M.Location - C) - M.CollisionRadius, 0.0);
		K = 1.0 - 0.5 * FMin(D / FreezeRadius, 1.0);
		M.Freeze(Instigator, FreezeTime * K);
		if ( M != None && !M.bDeleteMe && M.Health > 0 )
			M.TakeDamage(ChillDamage, Instigator, M.Location, vect(0,0,0), class'DamTypeCryo');
	}
}

simulated function Show( vector C, vector N )
{
	Spawn(class'KFCryoBurst',,, C + N * 8, rotator(N));
	Spawn(class'KFFrostMark', self,, C + N * 4, rotator(-N));
	if ( N.Z < 0.7 )
		Spawn(class'KFFrostMark', self,, C - vect(0,0,4), rot(-16384,0,0));
}

simulated function Destroyed()
{
	if ( FX != None )
		FX.Kill();
	Super.Destroyed();
}

defaultproperties
{
     FreezeRadius=260.000000
     FreezeTime=7.000000
     ChillDamage=20
     Speed=3200.000000
     MaxSpeed=3200.000000
     Damage=0.000000
     MyDamageType=Class'KFMod.DamTypeCryo'
     DrawType=DT_None
     AmbientSound=Sound'IndoorAmbience.hiss1'
     SoundRadius=300.000000
     SoundVolume=160
     SoundPitch=90
     LightType=LT_Steady
     LightHue=150
     LightSaturation=120
     LightBrightness=150.000000
     LightRadius=6.000000
     bDynamicLight=True
     CollisionRadius=6.000000
     CollisionHeight=6.000000
     LifeSpan=4.000000
     NetPriority=2.500000
     RemoteRole=ROLE_SimulatedProxy
}
