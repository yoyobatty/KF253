// Spawns Trail on PostBeginPlay.

class KFGib extends Gib;

var() xEmitter TrailFlame;

// A giblet off a charred body shows the burnt skin through its own by the share it is charred
var Combiner CharSkin;
var ConstantColor CharMask;
var array<Object> CharMade;				// from the level's pool, given back when it goes

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

        if( (Level.NetMode != NM_DedicatedServer) && !Level.bDropDetail )
        {
            if ( GibGroupClass.default.BloodGibClass != None )
                Spawn( GibGroupClass.default.BloodGibClass,,, Location, Rotator(-HitNormal) );
            if ( (LifeSpan < 7.3)  && (Level.DetailMode != DM_Low) )
                PlaySound(HitSounds[Rand(2)]);

            if ( Speed > 100 )
            {
                Streak = Spawn(class'KFMod.KFBloodStreakDecal',,, Location + 20 * HitNormal, Rotator(HitNormal));
                if ( Streak != None )
                    Streak.SetRotation(Rotator(Velocity));
            }
        }

    if( Speed < 20 ) 
    {
        if(!Level.bDropDetail && (Level.DetailMode != DM_Low) && GibGroupClass.default.BloodHitClass != None )
            Spawn( GibGroupClass.default.BloodHitClass,,, Location, Rotator(-HitNormal) );
        bBounce = False;
        SetPhysics(PHYS_None);
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

// Charred by Amount, 0 to 1; called again as its body chars further
simulated function CharTo( float Amount )
{
	local Texture T;

	if ( Amount <= 0.0 || Level.NetMode == NM_DedicatedServer )
		return;
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
}
