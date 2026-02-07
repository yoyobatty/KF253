// Spawns Trail on PostBeginPlay.

class KFGib extends Gib;

var() xEmitter TrailFlame;

simulated function HitWall( Vector HitNormal, Actor Wall )
{
    local float Speed, MinSpeed;

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
        }

    if( Speed < 20 ) 
    {
        if(!Level.bDropDetail && (Level.DetailMode != DM_Low) && GibGroupClass.default.BloodHitClass != None )
            Spawn( GibGroupClass.default.BloodHitClass,,, Location, Rotator(-HitNormal) );
        bBounce = False;
        SetPhysics(PHYS_None);
    }
}

simulated function SpawnTrail()
{
    if ( Level.NetMode != NM_DedicatedServer )
    {
		if ( bFlaming && FRand() < 0.7) //Spawn both!
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
}
