class KFNadeHealingExplosion extends Emitter;

var   float				HealTime;		// How long its been burning
var() float				Damage, HealAmount;			// Damage per 0.5 seconds
var() float             HealRadius;
var() class<DamageType>	DamageType;		// Damage type for touching damage

simulated function PostBeginPlay()
{
	Super.Postbeginplay();
    SetCollision(true, false, false);
	SetCollisionSize(HealRadius, HealRadius); 
    if (level.NetMode != NM_Client)
		SetTimer(0.8, true);
}

simulated function Tick(float DT)
{
	super.Tick(DT);
	HealTime-=DT;
	if (HealTime <= 0)
	{
		Kill();
        //log(GetHumanReadableName()$" ran out of healing.");
        return;
	}
}

simulated function Timer()
{
	local int i;

    if ( Role < ROLE_Authority )
        return;

	for (i=0;i<Touching.length;i++)
	{
		if ( Touching[i] != None )
        {
			if(Touching[i].IsA('KFMonster'))
            {
				KFMonster(Touching[i]).TakeDamage(Damage,Instigator,Touching[i].Location,vect(0,0,0),DamageType);
                //log(GetHumanReadableName()$" hurt " $Touching[i].GetHumanReadableName());
            }
            if(Touching[i].IsA('KFHumanPawn'))
            {
			    if(KFHumanPawn(Touching[i]).GiveHealth(HealAmount, KFHumanPawn(Touching[i]).HealthMax))
                    PlayOwnedSound(Sound'KFWeaponSound.SyringeFire',SLOT_Interact,TransientSoundVolume,,TransientSoundRadius,,false);
                //log(GetHumanReadableName()$" Healed " $Touching[i].GetHumanReadableName());
            }
        }
	}
}

defaultproperties
{
    HealTime=7.000000
    Damage=30.000000
    HealAmount=10.000000
    HealRadius=175.000000
    DamageType=Class'KFMod.DamTypeMedicNade'
    Begin Object Class=SpriteEmitter Name=SpriteEmitter0
        UseColorScale=True
        RespawnDeadParticles=False
        SpinParticles=True
        UseSizeScale=True
        UseRegularSizeScale=False
        UniformSize=True
        AutomaticInitialSpawning=False
        BlendBetweenSubdivisions=True
        ColorScale(0)=(Color=(G=255,R=128,A=255))
        ColorScale(1)=(RelativeTime=1.000000,Color=(B=61,G=105,R=61,A=255))
        FadeOutFactor=(W=0.000000,X=0.000000,Y=0.000000,Z=0.000000)
        FadeOutStartTime=5.000000
        SpinsPerSecondRange=(Y=(Min=0.050000,Max=0.100000),Z=(Min=0.050000,Max=0.100000))
        StartSpinRange=(X=(Min=-0.500000,Max=0.500000),Y=(Max=1.000000),Z=(Max=1.000000))
        SizeScale(0)=(RelativeSize=1.000000)
        SizeScale(1)=(RelativeTime=1.000000,RelativeSize=5.000000)
        StartSizeRange=(X=(Min=40.000000,Max=40.000000),Y=(Min=40.000000,Max=40.000000),Z=(Min=40.000000,Max=40.000000))
        InitialParticlesPerSecond=500.000000
        DrawStyle=PTDS_AlphaBlend
        StartLocationShape=PTLS_Sphere
        Texture=Texture'ExplosionTex.Framed.SmokeReOrdered'
        TextureUSubdivisions=4
        TextureVSubdivisions=4
        LifetimeRange=(Min=8.000000,Max=10.000000)
        StartLocationOffset=(Z=5.000000)
        StartVelocityRange=(X=(Min=-750.000000,Max=750.000000),Y=(Min=-750.000000,Max=750.000000))
        VelocityLossRange=(X=(Min=10.000000,Max=10.000000),Y=(Min=10.000000,Max=10.000000),Z=(Min=10.000000,Max=10.000000))
        //VelocityLossRange=(X=(Min=0.5,Max=1.0),Y=(Min=0.5,Max=1.0),Z=(Min=0.5,Max=1.0)) // Much less loss, so particles keep moving outward
        Acceleration=(X=0.0,Y=0.0,Z=20.0) // Gentle upward drift, optional
    End Object
    Emitters(0)=SpriteEmitter'KFMod.KFNadeHealingExplosion.SpriteEmitter0'

    AutoDestroy=True
    bNoDelete=False
    RemoteRole=ROLE_SimulatedProxy
    bNotOnDedServer=False
}
