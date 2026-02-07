//=============================================================================
// Stun Nade
//=============================================================================
class StunProj extends Grenade;

var() vector RotMag;            // how far to rot view
var() vector RotRate;           // how fast to rot view
var() float  RotTime;           // how much time to rot the instigator's view
var() vector OffsetMag;         // max view offset vertically
var() vector OffsetRate;        // how fast to offset view vertically
var() float  OffsetTime;        // how much time to offset view

#exec OBJ LOAD FILE=PatchSounds.uax

simulated function Explode(vector HitLocation, vector HitNormal)
{
    local Controller        C;
    local PlayerController  LocalPlayer;

    BlowUp(HitLocation);
    PlaySound(sound'PatchSounds.StunNadeBoomSound',,100.5*TransientSoundVolume);
    if ( EffectIsRelevant(Location,false) )
    {
        Spawn(class'KFmod.KFMiniExplosion',,, HitLocation, rotator(vect(0,0,1)));
        Spawn(ExplosionDecal,self,,HitLocation, rotator(-HitNormal));
    }
    Destroy();
    
        // Shake nearby players screens

     LocalPlayer = Level.GetLocalPlayerController();
    if ( (LocalPlayer != None) && (VSize(Location - LocalPlayer.ViewTarget.Location) < DamageRadius) )       
        LocalPlayer.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);

    for ( C=Level.ControllerList; C!=None; C=C.NextController )
        if ( (PlayerController(C) != None) && (C != LocalPlayer)
            && (VSize(Location - PlayerController(C).ViewTarget.Location) < DamageRadius) )
            C.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);
}

simulated function Destroyed()
{
    if ( Trail == None )
        Trail.mRegen = false; // stop the emitter from regenerating
    Super.Destroyed();
}


simulated function PostBeginPlay()
{
    local PlayerController PC;
    
    Super.PostBeginPlay();

    if ( Level.NetMode != NM_DedicatedServer)
    {
        PC = Level.GetLocalPlayerController();
        if ( (PC.ViewTarget != None) && VSize(PC.ViewTarget.Location - Location) < 5500 )
      }

    if ( Role == ROLE_Authority )
    {
        Velocity = Speed * Vector(Rotation);
        RandSpin(25000);
        bCanHitOwner = false;
        if (Instigator.HeadVolume.bWaterVolume)
        {
            bHitWater = true;
            Velocity = 0.6*Velocity;
        }
    }
}

simulated function ProcessTouch( actor Other, vector HitLocation )
{
   // if ( !Other.bWorldGeometry && (Other != Instigator || bCanHitOwner) )
    //{
      //  Explode(HitLocation, Normal(HitLocation-Other.Location));
   // }
}

<<<<<<< HEAD
defaultproperties
{
	RotMag=(X=100.000000,Y=100.000000,Z=100.000000)
	RotRate=(X=500.000000,Y=500.000000,Z=500.000000)
	RotTime=3.000000
	OffsetMag=(X=40.000000,Y=40.000000,Z=40.000000)
	OffsetRate=(X=500.000000,Y=500.000000,Z=500.000000)
	OffsetTime=3.000000
	DampenFactor=0.250000
	DampenFactorParallel=0.400000
	HitEffectClass=None
	Speed=160.000000
	MaxSpeed=350.000000
	Damage=25.000000
	DamageRadius=350.000000
	MomentumTransfer=25000.000000
	MyDamageType=Class'KFMod.DamTypeStunNade'
	StaticMesh=StaticMesh'PatchStatics.StunProjectile'
	DrawScale=0.400000
	AmbientGlow=0
	bUnlit=False
=======
/* HurtRadius()
 Hurt locally authoritative actors within the radius.
*/
simulated function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
	local actor Victims;
    local KFMonster KFMonst;
	local float damageScale, dist;
	local vector dir;

	if ( bHurtEntry )
		return;

	bHurtEntry = true;

	// It'll be slower, but let's see if this helps the grenades deal damage properly in a radius.
	foreach CollidingActors (class 'Actor', Victims, DamageRadius, HitLocation)
	{
		// don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
		if( (Victims !=None) && (Victims != self) && (Hurtwall != Victims) && (Victims.Role == ROLE_Authority) && !Victims.IsA('FluidSurfaceInfo') && ExtendedZCollision(Victims)==None )
		{
			if( (Instigator==None || Instigator.Health<=0) && KFPawn(Victims)!=None )
				Continue;
            KFMonst = KFMonster(Victims);
            if(KFMonst!=None)
                KFMonst.FlipOver();
			dir = Victims.Location - HitLocation;
			dist = FMax(1,VSize(dir));
			dir = dir/dist;
			damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);
            // Incendiary Effects..
            if ( Instigator == None || Instigator.Controller == None )
				Victims.SetDelayedDamageInstigatorController( InstigatorController );
			Victims.TakeDamage(damageScale * DamageAmount,Instigator,Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,(damageScale * Momentum * dir),DamageType);
			if (Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
				Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, InstigatorController, DamageType, Momentum, HitLocation);                
        }
	}
	bHurtEntry = false;
}

defaultproperties
{
     RotMag=(X=100.000000,Y=100.000000,Z=100.000000)
     RotRate=(X=500.000000,Y=500.000000,Z=500.000000)
     RotTime=3.000000
     OffsetMag=(X=40.000000,Y=40.000000,Z=40.000000)
     OffsetRate=(X=500.000000,Y=500.000000,Z=500.000000)
     OffsetTime=3.000000
     DampenFactor=0.250000
     DampenFactorParallel=0.400000
     HitEffectClass=None
     Speed=160.000000
     MaxSpeed=350.000000
     Damage=25.000000
     DamageRadius=350.000000
     MomentumTransfer=25000.000000
     MyDamageType=Class'KFMod.DamTypeStunNade'
     StaticMesh=StaticMesh'PatchStatics.StunProjectile'
     DrawScale=0.400000
     AmbientGlow=0
     bUnlit=False
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
