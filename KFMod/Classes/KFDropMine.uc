// A Placeable Mine
// Coded By : Alex

class KFDropMine extends Landmine;

var () int ExplosionDamage;
var () float    DamageRadius;
var () float MomentumFloat;
var Vector HitLocation;
var Actor HurtWall;
var Actor LastTouched;
var UseTrigger OnUseTrigger;
var() class<Projectile> ShrapnelClass;

// Spawn Use Trigger
simulated event PostBeginPlay()
{
	OnUseTrigger = Spawn(class'UseTrigger');
	OnUseTrigger.Event = Tag;
	OnUseTrigger.SetCollisionSize(self.CollisionRadius,self.CollisionHeight);
}


// Detonate the mine if it is caught in the blast radius of another explosive.

function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
 if (damageType == class'DamTypeFrag')
 {
   HitLocation = self.Location;
   HurtRadius ( ExplosionDamage , DamageRadius , DamageType , MomentumFloat, HitLocation);
   Self.Destroy();
 }
}

function PostTouch(Actor Other)
{
    local Pawn P;
    local KFMiniExplosion MineDestructionEffect;

    P = Pawn(Other);
    if (P != None && !P.IsA('KFHumanPawn') && !P.IsA('Vehicle'))
    {
        HitLocation = P.Location;
		SetTimer(1.0, false); // 1 second timer before explosion
        MineDestructionEffect = spawn(class'KFmod.KFMiniExplosion',,,self.Location - self.CollisionHeight * vect(0,0,1));
        PlaySound(BlowupSound,,3.0*TransientSoundVolume);
        Spawn(class'RocketMark',,,self.Location - self.CollisionHeight * vect(0,0,1));

        HurtRadius ( ExplosionDamage , DamageRadius ,class'KFmod.DamTypeFrag', MomentumFloat, HitLocation);
        Self.Destroy();

       // P.AddVelocity(ChuckVelocity);
       // P.TakeDamage(ExplosionDamage,Instigator, P.Location, ChuckVelocity, DamageType);


    }

    if (P.IsA('KFHumanPawn'));
      PlayerController(P.Controller).ClientMessage("Press USE key to pick up.", 'KFCriticalEvent');

}

simulated function HurtRadius( float ExplosionDamage, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
    local actor Victims;
    local float damageScale, dist;
    local vector dir;
    local Projectile p;
    local Rotator AdjustedRotation;

    AdjustedRotation = self.Rotation;

    AdjustedRotation.Pitch += (rand(5000) + 2000);  // Random spray of shrapnel.
    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);
    AdjustedRotation.Pitch =  -AdjustedRotation.Pitch;
    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);
    AdjustedRotation.Yaw += (rand(5000) + 3000);
    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);
    AdjustedRotation.Yaw =  -AdjustedRotation.Yaw;
    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);
    AdjustedRotation.Roll += (rand(5000) + 3000);
    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);
    AdjustedRotation.Roll = -AdjustedRotation.Roll;
    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);

    // Second shrapnel Wave

        AdjustedRotation.Pitch += (rand(5000) + 2000);  // Random spray of shrapnel.
    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);
    AdjustedRotation.Pitch =  -AdjustedRotation.Pitch;
    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);
    AdjustedRotation.Yaw += (rand(5000) + 3000);
    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);
    AdjustedRotation.Yaw =  -AdjustedRotation.Yaw;
    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);
    AdjustedRotation.Roll += (rand(5000) + 3000);
    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);
    AdjustedRotation.Roll = -AdjustedRotation.Roll;
    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);

    if ( bHurtEntry )
        return;

    bHurtEntry = true;
    foreach VisibleCollidingActors( class 'Actor', Victims, DamageRadius, HitLocation )
    {
        // don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
        if( (Hurtwall != Victims) && (Victims.Role == ROLE_Authority) && !Victims.IsA('FluidSurfaceInfo') )
        {
            dir = Victims.Location - HitLocation;
            dist = FMax(1,VSize(dir));
            dir = dir/dist;
            damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);

            if ( Victims == LastTouched )
                LastTouched = None;
            Victims.TakeDamage (damageScale * ExplosionDamage,Instigator,Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir, (damageScale * MomentumFloat * dir + ChuckVelocity),  DamageType );

        }
    }
    if ( (LastTouched != None) && (LastTouched != self) && (LastTouched.Role == ROLE_Authority) && !LastTouched.IsA('FluidSurfaceInfo') )
    {
        Victims = LastTouched;
        LastTouched = None;
        dir = Victims.Location - HitLocation;
        dist = FMax(1,VSize(dir));
        dir = dir/dist;
        damageScale = FMax(Victims.CollisionRadius/(Victims.CollisionRadius + Victims.CollisionHeight),1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius));

        Victims.TakeDamage  ( damageScale * ExplosionDamage, Instigator,  Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir, (damageScale * MomentumFloat * dir + ChuckVelocity), DamageType );

    }

    bHurtEntry = false;
}


event Trigger( Actor Other, Pawn EventInstigator )
{
	local Inventory inv;

	if(UseTrigger(Other) != none && EventInstigator.IsA('KFHumanPawn') )
	{
		PlaySound(sound'WeaponSounds.ArmorHit', SLOT_Pain,2*TransientSoundVolume,,400);
		PlayerController(EventInstigator.Controller).ClientMessage( "You picked up a mine" );
		for(inv = EventInstigator.Inventory;inv != None;inv = inv.Inventory)
		{
			if( inv.IsA('PlaceMineWeapon') )
			{
				if(Weapon(inv).AmmoAmount(0) < Weapon(inv).MaxAmmo(0))
				{
					Weapon(inv).AddAmmo(1, 0) ;
					Destroy();
					Return;
				}
				else
				{
					Destroy();
					Return;
				}
			}
		}
		inv = Spawn(Class'PlaceMineWeapon');
		if( inv!=None )
			inv.GiveTo(EventInstigator);
		Destroy();
	}
}

defaultproperties
{
     ExplosionDamage=600
     DamageRadius=150.000000
     MomentumFloat=200000.000000
     ShrapnelClass=Class'KFMod.KFShrapnel'
     ChuckVelocity=(Z=900.000000)
     BlowupEffect=Class'KFMod.KFNadeExplosion'
     BlowupSound=Sound'ONSVehicleSounds-S.Tank.TankFire01'
     DrawType=DT_StaticMesh
     StaticMesh=StaticMesh'PatchStatics.Mine'
     bHidden=False
     bOrientOnSlope=True
     Physics=PHYS_Falling
     RemoteRole=ROLE_SimulatedProxy
     DrawScale=0.450000
     SurfaceType=EST_Metal
     CollisionRadius=15.000000
     CollisionHeight=3.000000
     bCollideWorld=True
}
