class WeaponLocker extends Actor
	placeable;

//var() float TriggerRadius, TriggerHeight;
var bool bActive, bOpen;
var int OpenRefs;
var ShopVolume Shop;
var ShadowProjector PlayerShadow;
var float NextLightUpdateTime; // throttle scripted updates

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	if( Level.NetMode!=NM_DedicatedServer )
		LoopAnim('Idle',,,0);

	foreach VisibleCollidingActors(class'ShopVolume', Shop, 1000)
	{
		Shop.MyTrader = self;
	}

	if (bActorShadows &&(Level.NetMode != NM_DedicatedServer))
	{
		PlayerShadow = Spawn(class'ShadowProjectorMid',Self,'',Location);
		PlayerShadow.ShadowActor = self;
		PlayerShadow.LightDirection = GetNearbyLightDirection();
		PlayerShadow.LightDistance = VSize(Location - (Location - PlayerShadow.LightDirection * 500));
		PlayerShadow.MaxTraceDistance = 500;
		PlayerShadow.InitShadow();
		PlayerShadow.bShadowActive = true;
	}
}

function Vector GetNearbyLightDirection()
{
	local Light NearbyLight;
	local vector LightDir;
	local float ClosestDist, Dist;

	ClosestDist = 500.f;
	foreach RadiusActors(class'Light', NearbyLight, 500.f)
	{
		if(!FastTrace(Location, NearbyLight.Location))
			continue;
		Dist = VSize(NearbyLight.Location - Location);
		if (Dist < ClosestDist)
		{
			ClosestDist = Dist;
			LightDir = Normal(NearbyLight.Location - Location);
		}
	}
	if(LightDir.Z < 0.3)
		LightDir.Z = 0.3;
	if (ClosestDist < 500.f)
		return LightDir;
	else
		return Normal(vect(1,1,3));
}

function SetOpen(bool bToOpen)
{
	switch(bToOpen)
	{
	case false:
		OpenRefs--;
		if(bOpen && OpenRefs == 0)
		{
			if( Level.NetMode!=NM_DedicatedServer )
				LoopAnim('Idle',,,0);
			bOpen=false;
		}
		break;
	case true:
		OpenRefs++;
		if(!bOpen)
		{
			NetUpdateTime = Level.TimeSeconds - 1;
			bClientTrigger = !bClientTrigger;
			if( Level.NetMode!=NM_DedicatedServer )
				ClientTrigger();
			bOpen=true;
		}
		break;
	}
}

simulated function AnimEnd( int Channel )
{
	if( Level.NetMode!=NM_DedicatedServer )
		LoopAnim('Idle',,,0);
}
simulated event ClientTrigger()
{
	PlayAnim('Gesture',,,1);
}

defaultproperties
{
	//TriggerRadius=150.000000
	//TriggerHeight=100.000000
	bActive=True
	DrawType=DT_Mesh
	bAlwaysRelevant=True
	bNetInitialRotation=True
	RemoteRole=ROLE_SimulatedProxy
	NetUpdateFrequency=0.200000
	Mesh=SkeletalMesh'KFMapObjects.Trader'
	DrawScale=0.500000
	CollisionRadius=15.000000
	CollisionHeight=50.000000
	bCollideActors=True
	bCollideWorld=True
	bBlockActors=True
	bBlockKarma=True
	bActorShadows=True
}
