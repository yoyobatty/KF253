class CrossbowArrowExplosive extends CrossbowArrow;

var() float DelayExplode;
var() float DamageExplode;
var() float DamageRadiusExplode;
var   class<DamageType>	   MyDamageTypeExplode;

// camera shakes //
var() vector ShakeRotMag;           // how far to rot view
var() vector ShakeRotRate;          // how fast to rot view
var() float  ShakeRotTime;          // how much time to rot the instigator's view
var() vector ShakeOffsetMag;        // max view offset vertically
var() vector ShakeOffsetRate;       // how fast to offset view vertically
var() float  ShakeOffsetTime;       // how much time to offset view

var() vector RotMag;            // how far to rot view
var() vector RotRate;           // how fast to rot view
var() float  RotTime;           // how much time to rot the instigator's view
var() vector OffsetMag;         // max view offset vertically
var() vector OffsetRate;        // how fast to offset view vertically
var() float  OffsetTime;        // how much time to offset view

 simulated function Explode(vector HitLocation, vector HitNormal)
{
    local Controller C;
    local PlayerController PC;
    local PlayerController  LocalPlayer;


    PlaySound(sound'KFWeaponSound.Bang1',,100.5*TransientSoundVolume);
    if ( EffectIsRelevant(Location,false) )
    {
        Spawn(class'KFMiniExplosion',,,HitLocation + HitNormal*20,rotator(HitNormal)+rot(-16384,0,0));
        PC = Level.GetLocalPlayerController();
        if ( (PC.ViewTarget != None) && VSize(PC.ViewTarget.Location - Location) < 5000 )
            Spawn(class'ExplosionCrap',,, HitLocation + HitNormal*20, rotator(HitNormal));
//		if ( (ExplosionDecal != None) && (Level.NetMode != NM_DedicatedServer) )
//			Spawn(ExplosionDecal,self,,Location, rotator(-HitNormal));
    }

    BlowUp(HitLocation);
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

simulated function BlowUp(vector HitLocation)
{
	HurtRadius(DamageExplode,DamageRadiusExplode, MyDamageTypeExplode, MomentumTransfer*5, HitLocation );
	if ( Role == ROLE_Authority )
		MakeNoise(1.0);
}

simulated function Timer()
{
    Explode(Location, vect(0,0,1));
}

simulated function HitWall( vector HitNormal, actor Wall )
{
	speed = VSize(Velocity);
      
	if ( Role==ROLE_Authority && Wall!=none )
	{
		if ( !Wall.bStatic && !Wall.bWorldGeometry )
		{
			if ( Instigator == None || Instigator.Controller == None )
				Wall.SetDelayedDamageInstigatorController(InstigatorController);
			Wall.TakeDamage( Damage, instigator, Location, MomentumTransfer * Normal(Velocity), MyDamageType);
			HurtWall = Wall;
		}
		MakeNoise(1.0);
	}
	PlaySound(Arrow_hitwall[Rand(3)],,2.5*TransientSoundVolume);
	Spawn(class'KFHitEffect');
	if( Instigator!=None && Level.NetMode!=NM_Client )
		MakeNoise(0.3);
	Stick(Wall, Location+HitNormal);
}

simulated function Stick(actor HitActor, vector HitLocation)
{
	SetTimer(DelayExplode,false);
	Super.Stick(HitActor, HitLocation);
}

simulated function ProcessTouch (Actor Other, vector HitLocation)
{
	local vector X;

	if ( Other!=none && Other!=Instigator && Other.Base!=Instigator ) // dont want to hit ourself (nor we want to hit same target twice) :)
	{
		X = Normal(Velocity);

		if( Physics==PHYS_Projectile && Pawn(Other)!=None && Vehicle(Other)==None )
		{
			Other.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * X, MyDamageType);
		}
		else if( ExtendedZCollision(Other)!=None && Pawn(Other.Owner)!=None )
		{
			Return;
		}
		Stick(Other,HitLocation);
		if( Level.NetMode!=NM_Client )
		{
			PlayhitNoise(Pawn(Other)!=none && Pawn(Other).ShieldStrength>0);
			Other.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * X, MyDamageType);
		}
	}
}

defaultproperties
{
	DelayExplode=2.000000
    HeadShotDamageMult=1.000000
    Speed=10000.000000
    MaxSpeed=10000.000000
	Damage=50.000000
  	MomentumTransfer=15000.000000
	DamageExplode=400
	DamageRadiusExplode=150
    MyDamageTypeExplode=Class'KFMod.DamTypeFrag'
}
