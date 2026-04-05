// Spawns Trail on PostBeginPlay.

class KFGib extends Gib;

var() xEmitter TrailFlame;

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

simulated function SpawnTrail()
{
    if ( Level.NetMode != NM_DedicatedServer )
    {
		if ( bFlaming && FRand() < 0.65) //Spawn both!
		{
			TrailFlame = Spawn(class'KFHitFlame', self,,Location,Rotation);
            TrailFlame.SetPhysics( PHYS_Trailer );
			TrailFlame.LifeSpan = 4 + 2*FRand();
			LifeSpan = TrailFlame.LifeSpan + 4.0;
			TrailFlame.SetTimer(LifeSpan - 3.0,false);
		}
        Trail = Spawn(TrailClass, self,, Location, Rotation);
        Trail.LifeSpan = 1.8;
		Trail.SetPhysics( PHYS_Trailer );
		RandSpin( 64000 );
	}
}

defaultproperties
{
    DampenFactor=0.400000
    LifeSpan=12.000000
    Mass=280.000000
    DrawScale=1.100000
    bCollideActors=True
    bProjTarget=True
    CollisionRadius=5.000000
    CollisionHeight=5.000000
    GibGroupClass=Class'KFMod.KFGibGroup'
}
