//=============================================================================
// Far-off gunfire and blasts. The server passes every shot and blast to each player not standing by it (Loud);
// at that player's machine one far enough off gets a far version of itself on top of its own sound: dulled by the
// air and echoing round the map when it is in sight, a low boom through the walls when it is not, arriving late by
// the speed of sound. The waves are made by KFSound\tools\kf_far.py. One per local player, made by
// KFPlayerController.FarNoise.
//=============================================================================
class KFFarSound extends Info
	config(User);

#exec AUDIO IMPORT FILE=..\KFMod254\KFMod\Sounds\FarPistolOpen.wav NAME=FarPistolOpen GROUP=Far
#exec AUDIO IMPORT FILE=..\KFMod254\KFMod\Sounds\FarPistolWalled.wav NAME=FarPistolWalled GROUP=Far
#exec AUDIO IMPORT FILE=..\KFMod254\KFMod\Sounds\FarMagnumOpen.wav NAME=FarMagnumOpen GROUP=Far
#exec AUDIO IMPORT FILE=..\KFMod254\KFMod\Sounds\FarMagnumWalled.wav NAME=FarMagnumWalled GROUP=Far
#exec AUDIO IMPORT FILE=..\KFMod254\KFMod\Sounds\FarRifleOpen.wav NAME=FarRifleOpen GROUP=Far
#exec AUDIO IMPORT FILE=..\KFMod254\KFMod\Sounds\FarRifleWalled.wav NAME=FarRifleWalled GROUP=Far
#exec AUDIO IMPORT FILE=..\KFMod254\KFMod\Sounds\FarAutoOpen.wav NAME=FarAutoOpen GROUP=Far
#exec AUDIO IMPORT FILE=..\KFMod254\KFMod\Sounds\FarAutoWalled.wav NAME=FarAutoWalled GROUP=Far
#exec AUDIO IMPORT FILE=..\KFMod254\KFMod\Sounds\FarShotgunOpen.wav NAME=FarShotgunOpen GROUP=Far
#exec AUDIO IMPORT FILE=..\KFMod254\KFMod\Sounds\FarShotgunWalled.wav NAME=FarShotgunWalled GROUP=Far
#exec AUDIO IMPORT FILE=..\KFMod254\KFMod\Sounds\FarBigShotgunOpen.wav NAME=FarBigShotgunOpen GROUP=Far
#exec AUDIO IMPORT FILE=..\KFMod254\KFMod\Sounds\FarBigShotgunWalled.wav NAME=FarBigShotgunWalled GROUP=Far
#exec AUDIO IMPORT FILE=..\KFMod254\KFMod\Sounds\FarLaunchOpen.wav NAME=FarLaunchOpen GROUP=Far
#exec AUDIO IMPORT FILE=..\KFMod254\KFMod\Sounds\FarLaunchWalled.wav NAME=FarLaunchWalled GROUP=Far
#exec AUDIO IMPORT FILE=..\KFMod254\KFMod\Sounds\FarBlastOpen.wav NAME=FarBlastOpen GROUP=Far
#exec AUDIO IMPORT FILE=..\KFMod254\KFMod\Sounds\FarBlastWalled.wav NAME=FarBlastWalled GROUP=Far
#exec AUDIO IMPORT FILE=..\KFMod254\KFMod\Sounds\FarGrenadeOpen.wav NAME=FarGrenadeOpen GROUP=Far
#exec AUDIO IMPORT FILE=..\KFMod254\KFMod\Sounds\FarGrenadeWalled.wav NAME=FarGrenadeWalled GROUP=Far

enum EFarKind
{
	FAR_None,
	FAR_Pistol,
	FAR_Magnum,
	FAR_Rifle,
	FAR_Auto,
	FAR_Shotgun,
	FAR_BigShotgun,
	FAR_Launch,
	FAR_Blast,
	FAR_Grenade
};

struct FarKindInfo
{
	var Sound Open, Walled;	// heard in sight, through walls
	var float Gain;			// loudness once fully far, at most 1
	var float Reach;		// how far past FullDist it is down to half
};

var() config bool bFarSound;
var() config float Volume;
var() float NearDist, FullDist;	// nothing inside NearDist, fading in to full at FullDist
var() float WalledGain;			// out of sight
var() float MinGain;			// anything quieter is not played
var() float SoundSpeed;			// units a second
var() float MaxDelay;
var() float VoiceDist;			// a far sound plays this far from the listener, in its direction
var() float SameShooterDist;	// a shot this close to a voice's last one is the same shooter's
var() int MaxVoices;
var() bool bFarLog;
var() FarKindInfo Kinds[10];	// by EFarKind

var array<KFFarVoice> Voices;

simulated function PostBeginPlay()
{
	// (written to the user ini, so they can be changed there: a network client may not use set)
	StaticSaveConfig();
}

simulated function Destroyed()
{
	local int i;

	for( i=0; i<Voices.Length; i++ )
		if( Voices[i]!=None )
			Voices[i].Destroy();
	StaticSaveConfig();
	Super.Destroyed();
}

// (server) A shot or blast at Where: passed on to every human player not standing by it.
static function Loud( Actor Maker, vector Where, EFarKind Kind )
{
	local Controller C;
	local KFPlayerController PC;
	local vector Ear;

	if( Kind==FAR_None || Maker==None || Maker.Level.NetMode==NM_Client )
		return;
	for( C=Maker.Level.ControllerList; C!=None; C=C.NextController )
	{
		PC = KFPlayerController(C);
		if( PC==None )
			continue;
		if( PC.ViewTarget!=None )
			Ear = PC.ViewTarget.Location;
		else Ear = PC.Location;
		if( VSize(Ear-Where) < default.NearDist*0.75 )
			continue;
		if( Viewport(PC.Player)!=None )
			PC.FarNoise(Where, Kind);
		else PC.ClientFarNoise(Where, Kind);
	}
}

simulated function vector EarSpot( PlayerController PC )
{
	local vector V;

	if( PC.ViewTarget==None )
		return PC.Location;
	V = PC.ViewTarget.Location;
	if( Pawn(PC.ViewTarget)!=None )
		V.Z += Pawn(PC.ViewTarget).EyeHeight;
	return V;
}

simulated function Hear( vector Where, byte Kind )
{
	local PlayerController PC;
	local vector Ear;
	local float Dist, Blend, Gain, Delay;
	local bool bSeen;
	local KFFarVoice V;

	PC = PlayerController(Owner);
	if( !bFarSound || Volume<=0 || PC==None || Kind==0 || Kind>=ArrayCount(Kinds) || Kinds[Kind].Open==None )
		return;
	Ear = EarSpot(PC);
	Dist = VSize(Where-Ear);
	if( Dist<=NearDist )
		return;
	Blend = FMin((Dist-NearDist)/(FullDist-NearDist), 1.0);
	Gain = Volume * Kinds[Kind].Gain * Blend*Blend*(3-2*Blend);
	if( Dist>FullDist )
		Gain *= Kinds[Kind].Reach / (Kinds[Kind].Reach + Dist - FullDist);
	bSeen = FastTrace(Where, Ear);
	if( !bSeen )
		Gain *= WalledGain;
	Gain = FMin(Gain, 1.0);
	if( Gain<MinGain )
		return;
	Delay = FMin(Dist/SoundSpeed, MaxDelay);
	V = VoiceFor(Where, Kind, Gain);
	if( bFarLog )
		log("FAR"@GetEnum(enum'EFarKind', Kind)@"dist"@int(Dist)@"seen"@bSeen@"gain"@Gain@"delay"@Delay@"voice"@V);
	if( V==None )
		return;
	if( bSeen )
		V.Add(Kinds[Kind].Open, Where, Kind, Gain, 0.94 + 0.1*FRand(), Level.TimeSeconds + Delay);
	else V.Add(Kinds[Kind].Walled, Where, Kind, Gain, 0.94 + 0.1*FRand(), Level.TimeSeconds + Delay);
}

// The same shooter keeps its voice (so a burst ends in one echo), else a free one, else the quietest if this is louder.
simulated function KFFarVoice VoiceFor( vector Where, byte Kind, float Gain )
{
	local int i, Quiet;
	local KFFarVoice V;

	for( i=Voices.Length-1; i>=0; i-- )
		if( Voices[i]==None )
			Voices.Remove(i, 1);
	for( i=0; i<Voices.Length; i++ )
		if( Voices[i].Kind==Kind && Voices[i].IsBusy() && VSize(Voices[i].Source-Where)<SameShooterDist )
			return Voices[i];
	for( i=0; i<Voices.Length; i++ )
		if( !Voices[i].IsBusy() )
			return Voices[i];
	if( Voices.Length<MaxVoices )
	{
		V = Spawn(class'KFFarVoice', self);
		if( V!=None )
			Voices[Voices.Length] = V;
		return V;
	}
	if( Voices.Length==0 )
		return None;
	Quiet = 0;
	for( i=1; i<Voices.Length; i++ )
		if( Voices[i].Loudness()<Voices[Quiet].Loudness() )
			Quiet = i;
	if( Voices[Quiet].Loudness()<Gain )
		return Voices[Quiet];
	return None;
}

defaultproperties
{
	bFarSound=True
	Volume=1.000000
	NearDist=900.000000
	FullDist=2400.000000
	WalledGain=0.800000
	MinGain=0.020000
	SoundSpeed=18000.000000
	MaxDelay=0.500000
	VoiceDist=200.000000
	SameShooterDist=300.000000
	MaxVoices=6
	Kinds(1)=(Open=Sound'KFMod.Far.FarPistolOpen',Walled=Sound'KFMod.Far.FarPistolWalled',Gain=0.450000,Reach=3000.000000)
	Kinds(2)=(Open=Sound'KFMod.Far.FarMagnumOpen',Walled=Sound'KFMod.Far.FarMagnumWalled',Gain=0.550000,Reach=5000.000000)
	Kinds(3)=(Open=Sound'KFMod.Far.FarRifleOpen',Walled=Sound'KFMod.Far.FarRifleWalled',Gain=0.550000,Reach=5000.000000)
	Kinds(4)=(Open=Sound'KFMod.Far.FarAutoOpen',Walled=Sound'KFMod.Far.FarAutoWalled',Gain=0.500000,Reach=4000.000000)
	Kinds(5)=(Open=Sound'KFMod.Far.FarShotgunOpen',Walled=Sound'KFMod.Far.FarShotgunWalled',Gain=0.550000,Reach=4500.000000)
	Kinds(6)=(Open=Sound'KFMod.Far.FarBigShotgunOpen',Walled=Sound'KFMod.Far.FarBigShotgunWalled',Gain=0.600000,Reach=5500.000000)
	Kinds(7)=(Open=Sound'KFMod.Far.FarLaunchOpen',Walled=Sound'KFMod.Far.FarLaunchWalled',Gain=0.500000,Reach=3500.000000)
	Kinds(8)=(Open=Sound'KFMod.Far.FarBlastOpen',Walled=Sound'KFMod.Far.FarBlastWalled',Gain=0.750000,Reach=10000.000000)
	Kinds(9)=(Open=Sound'KFMod.Far.FarGrenadeOpen',Walled=Sound'KFMod.Far.FarGrenadeWalled',Gain=0.700000,Reach=9000.000000)
	RemoteRole=ROLE_None
}
