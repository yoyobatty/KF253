class LAW extends KFWeaponShotgun;

// Killing Floor's Light Anti Tank Weapon.
// This is probably about as badass as things get....

function float GetAIRating()
{
    local Bot B;
    local float Result, Dist;
    local vector Dir;
    local Controller C;
    local int AlliesWithLAW;
    local bool bBig;

    B = Bot(Instigator.Controller);
    if ( (B == None) || (B.Enemy == None) )
        return Super.GetAIRating();
    // (KFInvasionBot.bRocketBig) a Fleshpound or Scrake: what the rockets are kept for, the last one too, and one each
    // from several of us (one rocket does not kill him)
    bBig = KFInvasionBot(B) != None && KFInvasionBot(B).bRocketBig && KFInvasionBot(B).IsBigSpecimen(B.Enemy);

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
    
    if (AmmoAmount(0) > 0 && !bBig)
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
    if (AlliesWithLAW > 0 && !bBig)
        Result -= (AlliesWithLAW * 0.8);

    // Reserve LAW for high-value targets: Fleshpounds, Scrakes, and bosses
    if (KFMonster(B.Enemy) != None)
    {
        if (KFMonster(B.Enemy).bBoss || bBig)
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

// (not back up to the shoulder until the next rocket is in)
simulated function bool CanZoomNow()
{
	return Super.CanZoomNow() && Level.TimeSeconds >= FireMode[0].NextFireTime;
}

defaultproperties
{
	MeshMats(0)=Texture'KillingFloorWeapons.Deagle.HandSkinNew'
	MeshMats(1)=Texture'KillingFloorWeapons.Deagle.ArmSkinNew'
	MeshMats(2)=Texture'KillingFloorWeapons.Deagle.HandSkinNew'
	MeshMats(3)=Texture'KillingFloorWeapons.Deagle.ArmSkinNew'
	MeshMats(5)=Shader'KillingFloorWeapons.LAW.LAWScope'
     Element=1
	FarKind(0)=FAR_Launch
	ClipCount=1
	ReloadRate=3.000000
	bLoadsWithFire=True
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
	AimInTime=1.000000
	AimOutTime=0.500000
	AimViewOffset=(X=22.000000,Y=22.310000,Z=-0.636000)
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
     UpgradeName="Hellfire"
     SheenSlots(0)=4
     SheenMats(0)=Shader'KillingFloorWeapons.LAW.LawShineShader'
     SheenSlots(1)=6
     SheenMats(1)=Texture'KillingFloorWeapons.LAW.RocketSkin'
}
