//=============================================================================
// Plays one shooter's far sounds for KFFarSound, each once it has travelled the distance, from a spot kept a little
// way off the listener in the shooter's direction. A new shot cuts the last one's echo short, so a burst ends in one
// echo.
//=============================================================================
class KFFarVoice extends Actor;

struct DueSound
{
	var Sound S;
	var float At, Volume, Pitch;
};

var byte Kind;
var vector Source;			// where the shooter was
var array<DueSound> Queue;	// waiting to arrive
var float BusyUntil;		// the last sound played ends then
var float LastVolume, LastAt;

simulated function bool IsBusy()
{
	return Queue.Length>0 || Level.TimeSeconds<BusyUntil;
}

// About how loud it is now: the last sound fades over its length.
simulated function float Loudness()
{
	if( Queue.Length>0 )
		return Queue[Queue.Length-1].Volume;
	if( Level.TimeSeconds>=BusyUntil )
		return 0;
	return LastVolume * (BusyUntil-Level.TimeSeconds) / FMax(BusyUntil-LastAt, 0.01);
}

simulated function Add( Sound S, vector Where, byte NewKind, float NewVolume, float NewPitch, float At )
{
	local int i;
	local KFFarSound F;

	F = KFFarSound(Owner);
	if( NewKind!=Kind || (F!=None && VSize(Where-Source)>F.SameShooterDist) )
		Queue.Length = 0;
	Kind = NewKind;
	Source = Where;
	if( Queue.Length>=8 )
		Queue.Remove(0, 1);
	i = Queue.Length;
	Queue.Length = i+1;
	Queue[i].S = S;
	Queue[i].At = At;
	Queue[i].Volume = NewVolume;
	Queue[i].Pitch = NewPitch;
	Follow();
}

simulated function Tick( float DeltaTime )
{
	while( Queue.Length>0 && Queue[0].At<=Level.TimeSeconds )
	{
		Follow();
		// (PlaySound halves the volume)
		PlaySound(Queue[0].S, SLOT_Misc, 2*Queue[0].Volume, false, 1000, Queue[0].Pitch, true);
		LastVolume = Queue[0].Volume;
		LastAt = Level.TimeSeconds;
		BusyUntil = Level.TimeSeconds + GetSoundDuration(Queue[0].S) / Queue[0].Pitch;
		Queue.Remove(0, 1);
	}
	if( IsBusy() )
		Follow();
}

simulated function Follow()
{
	local KFFarSound F;
	local PlayerController PC;
	local vector Ear;

	F = KFFarSound(Owner);
	if( F==None )
		return;
	PC = PlayerController(F.Owner);
	if( PC==None )
		return;
	Ear = F.EarSpot(PC);
	SetLocation(Ear + Normal(Source-Ear)*F.VoiceDist);
}

defaultproperties
{
	bHidden=True
	DrawType=DT_None
	bCollideActors=False
	bCollideWorld=False
	bBlockActors=False
	RemoteRole=ROLE_None
	SoundOcclusion=OCCLUSION_None
}
