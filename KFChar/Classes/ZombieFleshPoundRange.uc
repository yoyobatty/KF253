// Zombie Monster for KF Invasion gametype
class ZombieFleshPoundRange extends ZombieFleshPound;

#exec OBJ LOAD FILE=KFCharacters.utx
#exec OBJ LOAD FILE=KFCharacterModels.ukx
#exec OBJ LOAD FILE=KFWeaponSound.uax
#exec OBJ LOAD FILE=KFPlayerSound.uax
#exec OBJ LOAD FILE=PlayerSounds.uax

var float NextMinigunTime;
var byte MGFireCounter;
var vector TraceHitPos;
var Emitter mTracer;
var bool bHadAdjRot;

replication
{
	reliable if( Role==ROLE_Authority )
		TraceHitPos;
}

function RangedAttack(Actor A)
{
	if ( bShotAnim )
		return;
	else if ( CanAttack(A) )
	{
		bShotAnim = true;
		DoAnimAction('ZombieFireGun');
		Controller.bPreparingMove = true;
		Acceleration = vect(0,0,0);
		Controller.GoToState('WaitForAnim');
		MGFireCounter = Rand(20);
		FireMGShot();
		GoToState('Minigunning');
	}
	else if( VSize(A.Location - Location)<=1200 && NextMinigunTime<Level.TimeSeconds && !bDecapitated )
	{
		if( FRand()<0.25 )
		{
			NextMinigunTime = Level.TimeSeconds+FRand()*10;
			Return;
		}
		NextMinigunTime = Level.TimeSeconds+10+FRand()*60;
		bShotAnim = true;
		DoAnimAction('ZombieFireGun');
		Controller.bPreparingMove = true;
		Acceleration = vect(0,0,0);
		Controller.GoToState('WaitForAnim');
		MGFireCounter = Rand(20);
		FireMGShot();
		GoToState('Minigunning');
	}
}
simulated function AnimEnd( int Channel )
{
	if( Channel==1 && Level.NetMode!=NM_DedicatedServer && bHadAdjRot )
	{
		bHadAdjRot = False;
		SetBoneDirection('Bip01 L Forearm', Rotation,, 0, 0);
	}
	Super.AnimEnd(Channel);
}
State Minigunning
{
Ignores StartCharging;

	function RangedAttack(Actor A)
	{
		Controller.Target = A;
		Controller.Focus = A;
	}
	function EndState()
	{
		TraceHitPos = vect(0,0,0);
	}
	function BeginState()
	{
		Acceleration = vect(0,0,0);
	}
	function AnimEnd( int Channel )
	{
		if( Channel!=1 )
			Return;
		MGFireCounter++;
		if( Controller.Enemy!=None )
		{
			if( Controller.LineOfSightTo(Controller.Enemy) )
			{
				Controller.Focus = Controller.Enemy;
				Controller.FocalPoint = Controller.Enemy.Location;
			}
			else Controller.Focus = None;
			Controller.Target = Controller.Enemy;
		}
		FireMGShot();
		bShotAnim = true;
		Acceleration = vect(0,0,0);
		DoAnimAction('ZombieFireGun');
		bWaitForAnim = true;
		if( MGFireCounter>=70 )
			GoToState('');
	}
Begin:
	While( True )
	{
		Acceleration = vect(0,0,0);
		Sleep(0.15);
	}
}
function FireMGShot()
{
	local vector Start,End,HL,HN,Dir;
	local rotator R;
	local Actor A;

	Start = GetBoneCoords('FireBone').Origin;
	if( Controller.Focus!=None )
		R = rotator(Controller.Focus.Location-Start);
	else R = rotator(Controller.FocalPoint-Start);
	Dir = Normal(vector(R)+VRand()*0.04);
	End = Start+Dir*10000;
	A = Trace(HL,HN,End,Start,True);
	if( A==None )
		Return;
	TraceHitPos = HL;
	if( Level.NetMode!=NM_DedicatedServer )
		AddTraceHitFX(HL);
	if( A!=Level )
		A.TakeDamage(1+Rand(3),Self,HL,Dir*100,Class'DamageType');
}
simulated function AddTraceHitFX( vector HitPos )
{
	local vector Start,SpawnVel,SpawnDir;
	local float hitDist;
	local KFHitEffect H;

	if( Level.NetMode==NM_Client )
		DoAnimAction('ZombieFireGun');
	Start = GetBoneCoords('FireBone').Origin;
	if( mTracer==None )
		mTracer = Spawn(Class'NewTracer',,,Start);
	else mTracer.SetLocation(Start);
	hitDist = VSize(HitPos - Start) - 50.f;
	SetBoneDirection('Bip01 L Forearm', rotator(HitPos-Start),, 1.0, 1);
	bHadAdjRot = True;
	if( hitDist>10 )
	{
		SpawnDir = Normal(HitPos - Start);
		SpawnVel = SpawnDir * 10000.f;
		mTracer.Emitters[0].StartVelocityRange.X.Min = SpawnVel.X;
		mTracer.Emitters[0].StartVelocityRange.X.Max = SpawnVel.X;
		mTracer.Emitters[0].StartVelocityRange.Y.Min = SpawnVel.Y;
		mTracer.Emitters[0].StartVelocityRange.Y.Max = SpawnVel.Y;
		mTracer.Emitters[0].StartVelocityRange.Z.Min = SpawnVel.Z;
		mTracer.Emitters[0].StartVelocityRange.Z.Max = SpawnVel.Z;
		mTracer.Emitters[0].LifetimeRange.Min = hitDist / 10000.f;
		mTracer.Emitters[0].LifetimeRange.Max = mTracer.Emitters[0].LifetimeRange.Min;
		mTracer.SpawnParticle(1);
	}
	Instigator = Self;
	H = Spawn(Class'KFHitEffect',,,HitPos);
	if( H!=None )
		H.RemoteRole = ROLE_None;
}
function SpawnTwoShots();

simulated function PostNetReceive()
{
	if( TraceHitPos!=vect(0,0,0) )
	{
		AddTraceHitFX(TraceHitPos);
		TraceHitPos = vect(0,0,0);
	}
	else Super.PostNetReceive();
}
simulated function Destroyed()
{
	if( mTracer!=None )
		mTracer.Destroy();
	Super.Destroyed();
}
simulated function DeviceGoRed();
simulated function DeviceGoNormal();

defaultproperties
{
	damageRand=8
	damageConst=10
	ScoringValue=12
	HealthMax=1600.000000
	Health=1600
	MenuName="Flesh Pound Chaingunner"
	Mesh=SkeletalMesh'KFCharacterModels.RangedPound'
	Skins(0)=Texture'KFCharacters.GunPoundSkin'
	Skins(2)=Texture'KFCharacters.AutoTurretGunTex1'
}
