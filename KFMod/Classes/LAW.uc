class LAW extends KFWeaponShotgun;

// Killing Floor's Light Anti Tank Weapon.
// This is probably about as badass as things get....

simulated event WeaponTick(float dt)
{ 
	if(AmmoAmount(0) == 0)
		Clipleft = 0;
	super.Weapontick(dt);
}

simulated function PlayAnimZoom( bool bZoomNow )
{
	if( bZoomNow )
	{
		IdleAnim = 'AimIdle';
		PlayAnim('Raise');
	}
	else if( IdleAnim!=Default.IdleAnim )
	{
		IdleAnim = Default.IdleAnim;
		TweenAnim(IdleAnim,0.5);
	}
}

simulated function PlayIdle()
{
	if( ClientState==WS_BringUp && Clipleft==0 && AmmoAmount(0)>0 )
	{
		PlayAnim('AimFire');
		FireMode[0].bIsFiring = True;
		FireMode[0].NextFireTime = Level.TimeSeconds+FireMode[0].FireRate;
		ServerSpawnLight();
	}
	else Super.PlayIdle();
}
function ServerSpawnLight()
{
	if( Clipleft==0 && AmmoAmount(0)>0 && !FireMode[0].bIsFiring )
	{
		Clipleft = 1;
		FireMode[0].bIsFiring = True;
		FireMode[0].NextFireTime = Level.TimeSeconds+FireMode[0].FireRate;
	}
}

// Draw the Winchester, but zoom in the FOV so you can see down the barrel, too.
simulated event RenderOverlays(Canvas Canvas)
{
	local PlayerController PC;

	PC = PlayerController(KFPawn(Owner).Controller);

	if(PC == None)
		return;

	LastFOV = PC.DesiredFOV;

	if (!bAimingRifle)
	{
		Super.RenderOverlays(Canvas);
		zoomed=false;
		//bAimingRifle = false;
	}
	else
	{
		//SetZoomBlendColor(Canvas);
		SetLocation( Instigator.Location + Instigator.CalcDrawOffset(self) );
		SetRotation( Instigator.GetViewRotation() );
		Canvas.DrawActor(self, false);
		zoomed = true;
	}
}

function float GetAIRating()
{
    local Bot B;
    local float Result, Dist;
    local vector Dir;
    local Controller C;
    local int AlliesWithLAW;

    B = Bot(Instigator.Controller);
    if ( (B == None) || (B.Enemy == None) )
        return Super.GetAIRating();

    Dir = B.Enemy.Location - Instigator.Location;
    Dist = VSize(Dir);

    Result = Super.GetAIRating();
    
    // don't pick LAW if enemy is too close
    if ( Dist < MinimumFireRange )
    {
        if(Instigator.Health > Instigator.HealthMax * 0.1 && !KFInvasionBot(B).ManyEnemiesAround(4, Instigator.Location))
            Result -= 0.6;
    }
    else if (Dist > 5000)
        Result -= 0.3;
    
    if (AmmoAmount(0) > 0)
        result -= (1.0 / AmmoAmount(0)); // Penalize for low ammo

    if(KFInvasionBot(B) != None && (KFInvasionBot(B).ManyEnemiesAround(4, Instigator.Location) || KFInvasionBot(B).EnemyReallyScary()))
        result += 0.6;

    // Count allies already wielding a LAW and targeting the same enemy or nearby enemies
    for (C = Level.ControllerList; C != None; C = C.nextController)
    {
        if (C != B && C.bIsPlayer && C.Pawn != None && C.Pawn.Health > 0 
            && C.Pawn.Weapon != None && C.Pawn.Weapon.IsA('LAW')
            && C.Enemy != None && VSize(C.Enemy.Location - B.Enemy.Location) < 600.0)
        {
            AlliesWithLAW++;
        }
    }
    // Heavy penalty per ally already using LAW on same target cluster
    // First LAW user gets no penalty, second gets -0.8, third gets -1.6, etc.
    if (AlliesWithLAW > 0)
        Result -= (AlliesWithLAW * 0.8);

    // Reserve LAW for high-value targets: Fleshpounds, Scrakes, and bosses
    if (KFMonster(B.Enemy) != None)
    {
        if (KFMonster(B.Enemy).bBoss)
            Result += 0.3; // Extra incentive for boss
        else
            Result -= 0.4; // Strong penalty for trash mobs 
    }

    return Result;
}

function bool RecommendRangedAttack()
{
	return true;
}

function float SuggestAttackStyle()
{
	return -1.0;
}

function float SuggestDefenseStyle()
{
   return -1.0;
}

defaultproperties
{
	ClipCount=1
	ReloadRate=3.000000
	MinimumFireRange=350.000000
	Weight=13.000000
	UpKick=300
	FireModeClass(0)=Class'KFMod.LAWFire'
	FireModeClass(1)=Class'KFMod.KFZoom'
	PutDownAnim="PutDown"
	SelectSound=Sound'KFPlayerSound.getweaponout'
	SelectForce="SwitchToRocketLauncher"
	AIRating=1.000000
	CurrentRating=1.000000
	bSniping=False
	Description="The Light Anti Tank Weapon is, as its name suggests, a military grade heavy weapons platform designed to disable or outright destroy armored vehicles."
	EffectOffset=(X=50.000000,Y=1.000000,Z=10.000000)
	DisplayFOV=85.000000
	Priority=50
	HudColor=(G=0)
	SmallViewOffset=(X=22.000000,Y=22.500000,Z=-0.560000)
	InventoryGroup=4
	GroupOffset=1
	PickupClass=Class'KFMod.LAWPickup'
	PlayerViewOffset=(X=22.000000,Y=22.500000,Z=-0.560000)
	PlayerViewPivot=(Pitch=-400)
	BobDamping=4.000000
	AttachmentClass=Class'KFMod.LAWAttachment'
	IconCoords=(X1=429,Y1=212,X2=508,Y2=251)
	ItemName="L.A.W"
	Mesh=SkeletalMesh'KFWeaponModels.LAW'
	DrawScale=0.900000
	AmbientGlow=2
	bModeZeroCanDryFire=False
}
