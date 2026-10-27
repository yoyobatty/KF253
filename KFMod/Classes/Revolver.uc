//=============================================================================
// Revolver
// A six-shot .44 magnum revolver. Its first-person model was made for KFMod254 on the Deagle's arms and skeleton
// (KFAnim\Revolver: build_revolver.py): frame, barrel, walnut grip, a hammer that falls and cocks, a cylinder that
// turns a chamber each shot and swings out to be loaded from a speedloader the left hand brings up. It reloads all
// six at once. Others see its own third-person model in its hand (RevolverAttachment).
//=============================================================================
class Revolver extends Deagle;

#exec OBJ LOAD FILE=KillingFloorWeapons.utx
#exec TEXTURE IMPORT NAME=RevSteel FILE=..\KFMod254\KFMod\Textures\RevSteel.tga MIPS=ON
#exec TEXTURE IMPORT NAME=RevWood FILE=..\KFMod254\KFMod\Textures\RevWood.tga MIPS=ON
#exec TEXTURE IMPORT NAME=RevBrass FILE=..\KFMod254\KFMod\Textures\RevBrass.tga MIPS=ON
#exec MESH MODELIMPORT MESH=RevolverMesh MODELFILE=..\KFMod254\KFMod\Models\Revolver.psk LODSTYLE=10
#exec MESH ORIGIN MESH=RevolverMesh X=0 Y=30 Z=15 YAW=0 PITCH=0 ROLL=0
#exec ANIM IMPORT ANIM=RevolverAnims ANIMFILE=..\KFMod254\KFMod\Models\Revolver.psa COMPRESS=1 MAXKEYS=999999 IMPORTSEQS=1
#exec MESHMAP SCALE MESHMAP=RevolverMesh X=1.0 Y=1.0 Z=1.0
#exec MESH DEFAULTANIM MESH=RevolverMesh ANIM=RevolverAnims
#exec ANIM DIGEST ANIM=RevolverAnims USERAWINFO VERBOSE
#exec MESHMAP SETTEXTURE MESHMAP=RevolverMesh NUM=0 TEXTURE=RevSteel
#exec MESHMAP SETTEXTURE MESHMAP=RevolverMesh NUM=1 TEXTURE=RevWood
#exec MESHMAP SETTEXTURE MESHMAP=RevolverMesh NUM=2 TEXTURE=RevBrass

// The reload's sounds and the six empties thrown out, at their frames of the Reload sequence (30 a second)
struct ReloadCue
{
	var() float		Frame;
	var() Sound		Snd;
	var() float		Volume, Pitch;
	var() bool		bShells;
};
var() array<ReloadCue>	ReloadCues;
var() float				ShellSize;
var float				ReloadStartTime, ReloadPace;
var int					NextCue;
var() bool				bSkinDebug;		// (tests) each part of the model a plain colour by its slot

// Its steel, walnut and brass lit as KF's own guns are (their shaders double the light on them); made on each machine
// that draws it
simulated function PostBeginPlay()
{
	local int i;
	local Shader S;
	local ConstantColor C;

	Super.PostBeginPlay();
	if ( Level.NetMode == NM_DedicatedServer )
		return;
	if ( bSkinDebug )
	{
		for ( i = 0; i < 5; i++ )
		{
			C = new class'ConstantColor';
			C.Color.R = 255 * int(i == 0 || i == 3 || i == 4);
			C.Color.G = 255 * int(i == 1 || i == 3);
			C.Color.B = 255 * int(i == 2 || i == 4);
			C.Color.A = 255;
			Skins[i] = C;
		}
		return;
	}
	for ( i = 0; i < 3; i++ )
	{
		S = new class'Shader';
		S.Diffuse = default.Skins[i];
		S.ModulateStaticLighting2X = true;
		Skins[i] = S;
	}
}

simulated function ClientReload()
{
	local float Rate;

	Super.ClientReload();
	Rate = ReloadAnimRate;
	if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != None && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != None )
		Rate *= KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetReloadSpeedModifier(self);
	if ( KFPawn(Instigator) != None )
		Rate *= KFPawn(Instigator).GetReloadSpeedScale();
	ReloadStartTime = Level.TimeSeconds;
	ReloadPace = 30.0 * FMax(Rate, 0.1);
	NextCue = 0;
}

simulated function WeaponTick( float DT )
{
	local float Frame;

	Super.WeaponTick(DT);
	if ( !bIsReloading || NextCue >= ReloadCues.Length || Level.NetMode == NM_DedicatedServer || Instigator == None )
		return;
	Frame = (Level.TimeSeconds - ReloadStartTime) * ReloadPace;
	while ( NextCue < ReloadCues.Length && Frame >= ReloadCues[NextCue].Frame )
	{
		if ( ReloadCues[NextCue].Snd != None )
			PlaySound(ReloadCues[NextCue].Snd, SLOT_None, ReloadCues[NextCue].Volume,, 300, ReloadCues[NextCue].Pitch);
		if ( ReloadCues[NextCue].bShells )
			ThrowShells();
		NextCue++;
	}
}

// The six empties out of the open cylinder (drawn with the gun, as KFWeapon's brass is)
simulated function ThrowShells()
{
	local int i;

	if ( !Instigator.IsFirstPerson() )
		return;
	if ( BrassFX == None || BrassFX.bDeleteMe )
	{
		BrassFX = Spawn(class'KFBrass', self);
		if ( BrassFX == None )
			return;
		BrassFX.SetSize(ShellSize);
	}
	for ( i = 0; i < 6; i++ )
		BrassFX.Eject(GetBoneCoords('CasingBone').Origin + 2.0 * VRand(), Rotation);
	BrassLandAt = Level.TimeSeconds + 0.55;
}

// (straight into the idle: the cylinder ends its turn a chamber on, which looks the same; a blend back would turn it
// back half a chamber)
simulated function PlayIdle()
{
	if ( !bAimingRifle )
		LoopAnim(IdleAnim, IdleAnimRate, 0.0);
	else
		Super.PlayIdle();
}

defaultproperties
{
     ReloadCues(0)=(Frame=5.000000,Snd=Sound'KFWeaponSound.DeagleClipout',Volume=1.000000,Pitch=0.800000)
     ReloadCues(1)=(Frame=14.000000,Snd=Sound'KFWeaponSound.DeagleClipout',Volume=0.700000,Pitch=1.300000,bShells=True)
     ReloadCues(2)=(Frame=50.000000,Snd=Sound'KFWeaponSound.DeagleClipin',Volume=1.000000,Pitch=0.900000)
     ReloadCues(3)=(Frame=57.000000,Snd=Sound'KFWeaponSound.DeagleCock',Volume=1.000000,Pitch=0.700000)
     ShellSize=1.300000
     BrassClass=None
     Element=5
     ClipCount=6
     ReloadRate=2.600000
     ReloadAnimRate=0.870000
     UpKick=2100
     FireModeClass(0)=Class'KFMod.RevolverFire'
     Description="A six-shot .44 magnum revolver with a six-inch barrel. Slow to load and hard to hold down, it hits like a train and keeps going."
     PickupClass=Class'KFMod.RevolverPickup'
     AttachmentClass=Class'KFMod.RevolverAttachment'
     ItemName="Magnum Revolver"
     Mesh=SkeletalMesh'KFMod.RevolverMesh'
     Skins(0)=Texture'KFMod.RevSteel'
     Skins(1)=Texture'KFMod.RevWood'
     Skins(2)=Texture'KFMod.RevBrass'
     Skins(3)=Texture'KillingFloorWeapons.Deagle.HandSkinNew'
     Skins(4)=Texture'KillingFloorWeapons.Deagle.ArmSkinNew'
     UpgradeName="Golden Gun"
     SheenSlots(0)=0
     SheenMats(0)=Texture'KFMod.RevSteel'
     SheenSlots(1)=0
     SheenMats(1)=Texture'KFMod.RevSteel'
     Priority=6
}
