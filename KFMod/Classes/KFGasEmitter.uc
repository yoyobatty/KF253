class KFGasEmitter extends Emitter;

var int NumGroundFires;
var float GasAge;

event Tick(float DeltaTime)
{
    super.Tick(DeltaTime);
    GasAge += DeltaTime;
  
}

function TakeDamage(int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType)
{
    if(DamageType == class'Burned' || DamageType == class'KFMod.DamTypeFlamethrower')
    {
        Ignite(EventInstigator);
    }
}

simulated function Ignite(Pawn EventInstigator)
{
	if(Role != ROLE_Authority)
		return;

    SpawnIncendiaryGroundFires(Location);

	Destroy();
}

function SpawnIncendiaryGroundFires(vector BlastLoc)
{
    local int i;
    local float Angle, StepAngle, Dist;
    local vector Dir, TestLoc, TraceStart, TraceEnd, HitLoc, HitNorm;
    local Actor A;

    if ( Role != ROLE_Authority )         
        return;

    NumGroundFires = int(GasAge + 1);

    StepAngle = 2 * Pi / NumGroundFires;

    for ( i = 0; i < NumGroundFires; i++ )
    {
        Angle = (StepAngle * i) + (FRand() - 0.5) * (StepAngle * 0.4);
		Dist = RandRange(50.0, 150.0);

        Dir   = vect(1,0,0) * Cos(Angle) + vect(0,1,0) * Sin(Angle);
        TestLoc = BlastLoc + Dir * Dist;

        TraceStart = TestLoc + vect(0,0,128);
        TraceEnd   = TestLoc - vect(0,0,256);
        HitLoc = TestLoc;
        HitNorm = vect(0,0,1);

        if ( Trace(HitLoc, HitNorm, TraceEnd, TraceStart, true) == None )
        {
            HitLoc = TestLoc;
            HitNorm = vect(0,0,1);
        }

        HitLoc.Z += 5.0;

        A = Spawn(class'FuelFlameHurting',,, HitLoc,
                  rotator( HitNorm));
    }
}


defaultproperties
{
     Begin Object Class=SpriteEmitter Name=SpriteEmitter0
         UseColorScale=True
         RespawnDeadParticles=False
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         AutomaticInitialSpawning=False
         BlendBetweenSubdivisions=True
         Opacity=0.350000
         MaxParticles=10
         ColorScale(0)=(Color=(R=255,G=255,B=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(R=227,G=255,B=7,A=255))
         FadeIn=True
         FadeInEndTime=0.500000
         FadeOutFactor=(W=0.000000,X=0.000000,Y=0.000000,Z=0.000000)
         FadeOutStartTime=6.000000
         FadeOut=True
         SpinsPerSecondRange=(Y=(Min=0.050000,Max=0.100000),Z=(Min=0.050000,Max=0.100000))
         StartSpinRange=(X=(Min=-0.500000,Max=0.500000),Y=(Max=1.000000),Z=(Max=1.000000))
         SizeScale(0)=(RelativeSize=0.800000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=7.000000)
         StartSizeRange=(X=(Min=30.000000,Max=30.000000),Y=(Min=30.000000,Max=30.000000),Z=(Min=30.000000,Max=30.000000))
         InitialParticlesPerSecond=500.000000
         DrawStyle=PTDS_AlphaBlend
         StartLocationShape=PTLS_Sphere
         StartLocationOffset=(Z=10.000000)
         SphereRadiusRange=(Min=10.000000,Max=20.000000)
         Texture=Texture'ExplosionTex.Framed.SmokeReOrdered'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         LifetimeRange=(Min=30.000000,Max=30.000000)
         StartVelocityRange=(X=(Min=-20.000000,Max=20.000000),Y=(Min=-20.000000,Max=20.000000))
         VelocityLossRange=(X=(Min=1.000000,Max=2.000000),Y=(Min=1.000000,Max=2.000000),Z=(Min=0.100000,Max=0.500000))
         Acceleration=(X=0.0,Y=0.0,Z=0.5)
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFGasEmitter.SpriteEmitter0'

     AutoDestroy=True
     LifeSpan=20.000000
     bNoDelete=False
     RemoteRole=ROLE_SimulatedProxy
     bNotOnDedServer=False
     bCanBeDamaged=True
     CollisionRadius=72.000000
     CollisionHeight=72.000000
     bCollideActors=True
     bUseCylinderCollision=True
}
