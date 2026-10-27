//=============================================================================
// KFAmmoModFX
// What everyone sees and hears of a special ammo going off (KFAmmoMod): sent once from the server, made on each
// machine. Kind 1 lightning from point to point; 2 bursts of flame at each point; 3 a wall of force out of Points[0]
// along Points[1], kicking up dust under those it throws (Points[2] on); 4 the turned specimen (Target) glows green.
//=============================================================================
class KFAmmoModFX extends Actor;

#exec OBJ LOAD FILE=..\Sounds\WeaponSounds.uax
#exec OBJ LOAD FILE=..\Sounds\PickupSounds.uax

var byte	Kind, Count;
var vector	Points[6];
var Actor	Target;
var float	TurnTime;
var bool	bBegun;
var() Sound	Sounds[5];
var Material	TurnedLook;		// (made once on each machine)

replication
{
	reliable if ( bNetInitial && Role == ROLE_Authority )
		Kind, Count, Points, Target, TurnTime;
}

simulated function PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
	if ( Role < ROLE_Authority )
		Begin();
}

simulated function Begin()
{
	local int i;
	local xEmitter Bolt;
	local Actor A;
	local KFBlastEmitter E;

	if ( bBegun )
		return;
	bBegun = true;
	if ( Kind < ArrayCount(Sounds) && Sounds[Kind] != None )
		PlaySound(Sounds[Kind], SLOT_None, 2.0,, 900.0);
	if ( Level.NetMode == NM_DedicatedServer )
		return;
	if ( Kind == 1 )
	{
		for ( i = 0; i < Count - 1 && i < ArrayCount(Points) - 1; i++ )
		{
			// (two bolts on each jump, for a thicker, livelier arc)
			Bolt = Spawn(class'XEffects.ChildLightningBolt',,, Points[i], rotator(Points[i + 1] - Points[i]));
			if ( Bolt != None )
			{
				Bolt.RemoteRole = ROLE_None;
				Bolt.mSpawnVecA = Points[i + 1];
			}
			Bolt = Spawn(class'XEffects.ChildLightningBolt',,, Points[i] + VRand() * 6.0, rotator(Points[i + 1] - Points[i]));
			if ( Bolt != None )
			{
				Bolt.RemoteRole = ROLE_None;
				Bolt.mSpawnVecA = Points[i + 1] + VRand() * 6.0;
			}
		}
		for ( i = 0; i < Count && i < ArrayCount(Points); i++ )
			Spark(Points[i], class'KFAmmoMod'.static.ColourOf(1));
	}
	else if ( Kind == 2 )
	{
		for ( i = 0; i < Count && i < ArrayCount(Points); i++ )
		{
			A = Spawn(class'KFIncendiaryExplosion',,, Points[i], rot(16384,0,0));
			if ( A != None )
				A.RemoteRole = ROLE_None;
		}
	}
	else if ( Kind == 3 )
	{
		// (the wave out in front, and the dust under those it throws, not in the face of the one who fired)
		class'KFScreenFX'.static.Wave(Level, Points[0], 0.9);
		for ( i = 2; i < Count && i < ArrayCount(Points); i++ )
		{
			E = Spawn(class'KFBlastDust',,, Points[i], rotator(Points[1] + vect(0,0,0.6)));
			if ( E != None )
				E.Size = 0.35;
			Spark(Points[i] + vect(0,0,40), class'KFAmmoMod'.static.ColourOf(3));
		}
	}
	else if ( Kind == 4 )
	{
		Spark(Points[0], class'KFAmmoMod'.static.ColourOf(4));
		if ( Target != None && TurnTime > 0.0 )
			Target.SetOverlayMaterial(Turned(), TurnTime, true);
	}
}

simulated function Spark( vector Spot, color C )
{
	local KFElementHit H;

	H = Spawn(class'KFElementHit',,, Spot, rot(16384,0,0));
	if ( H != None )
	{
		H.Tint = C;
		H.bTint = true;
		H.Size = 1.6;
	}
}

// A turned specimen's look: a slow green shimmer over its skin
static function Material Turned()
{
	local ConstantColor CC;
	local Combiner CB;
	local Shader SH;

	if ( default.TurnedLook != None )
		return default.TurnedLook;
	CC = new class'ConstantColor';
	CC.Color = class'Canvas'.static.MakeColor(70, 170, 60, 255);
	CB = new class'Combiner';
	CB.CombineOperation = CO_Multiply;
	CB.Material1 = class'KFElement'.static.Panner(6);
	CB.Material2 = CC;
	SH = new class'Shader';
	SH.Specular = CB;
	default.TurnedLook = SH;
	return SH;
}

defaultproperties
{
	Sounds(1)=Sound'WeaponSounds.BaseFiringSounds.BLightningGunFire'
	Sounds(2)=Sound'KFWeaponSound.FlameThrowerFire'
	Sounds(3)=Sound'WeaponSounds.BaseFiringSounds.BShockRifleAltFire'
	Sounds(4)=Sound'PickupSounds.AdrenelinPickup'
	DrawType=DT_None
	bHidden=True
	RemoteRole=ROLE_SimulatedProxy
	bNetTemporary=True
	bAlwaysRelevant=True
	bReplicateMovement=False
	LifeSpan=2.000000
	NetPriority=3.000000
	TransientSoundVolume=2.000000
	TransientSoundRadius=900.000000
}
