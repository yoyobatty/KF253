class KFMeleeAttachment extends XWeaponAttachment;

var() array<name> TPAnims,TPAnimsB; // Custom third person animations.
var() name WeaponIdleMovementAnim; // Custom holding weapon animation.
var Pawn LastInstig;

// The swing a swept melee fire mode chose (KFMeleeFire.Swing.BodyAnim) and the speed it plays at, so every machine
// shows the swing that is struck; without one a third-person animation is picked at random
var name SwingAnim;
var float SwingRate;

// The blade, as points of this model (its own axes, after DrawScale): a swing in behind view is struck along it
var() vector BladeBase, BladeTip;
var() float BladeExtend;	// reach added beyond the tip, along the blade

replication
{
	reliable if ( bNetDirty && !bNetOwner && Role == ROLE_Authority )
		SwingAnim, SwingRate;
}

simulated event ThirdPersonEffects()
{
	if ( (Level.NetMode == NM_DedicatedServer) || (Instigator == None) )
		return;

	if ( FlashCount>0 )
	{
		if( KFPawn(Instigator)!=None )
		{
			if ( SwingAnim != '' )
				KFPawn(Instigator).StartFiringX(bHeavy,false,SwingAnim,SwingRate);
			else if (FiringMode == 0)
				KFPawn(Instigator).StartFiringX(bHeavy,bRapidFire,GetThirdPersonAnim());
			else KFPawn(Instigator).StartFiringX(bHeavy,bAltRapidFire,GetThirdPersonAnim());
		}
	}
	else
	{
		GotoState('');
		if( KFPawn(Instigator)!=None )
			KFPawn(Instigator).StopFiring();
	}
}
simulated function name GetThirdPersonAnim()
{
	if( FiringMode==1 && TPAnimsB.Length>0 )
		Return TPAnimsB[Rand(TPAnimsB.Length)];
	if( TPAnims.Length==0 )
		Return '';
	else if( TPAnims.Length==1 )
		Return TPAnims[0];
	Return TPAnims[Rand(TPAnims.Length)];
}

// Where the blade is in the world. The bones place this model every tick only while its holder has bForceSkelUpdate
// (KFMeleeFire sets it for the swing); otherwise only when it is drawn, so never on a dedicated server.
simulated function BladeEnds( out vector Base, out vector Tip )
{
	local vector X, Y, Z, T;

	GetAxes(Rotation, X, Y, Z);
	T = BladeTip + Normal(BladeTip - BladeBase) * BladeExtend;
	Base = Location + BladeBase.X * X + BladeBase.Y * Y + BladeBase.Z * Z;
	Tip = Location + T.X * X + T.Y * Y + T.Z * Z;
}

simulated function PostNetReceive()
{
	if( Instigator!=LastInstig )
	{
		LastInstig = Instigator;
		if( KFPawn(Instigator)!=None )
			KFPawn(Instigator).UpdateClientAnim(WeaponIdleMovementAnim);
	}
}
simulated function PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
	LastInstig = Instigator;
	if( KFPawn(Instigator)!=None )
		KFPawn(Instigator).UpdateClientAnim(WeaponIdleMovementAnim);
	bNetNotify = True;
}

defaultproperties
{
     WeaponIdleMovementAnim="Idle_Rifle"
     bHeavy=True
}
