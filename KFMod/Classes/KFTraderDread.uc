//=============================================================================
// Between waves the map is not left quiet: now and then a specimen groans or calls out somewhere far off and out of
// sight, and some seconds before the next wave they stir all round. Made by the HUD for the player at this machine
// only, so each player hears their own; sounds come from the map's path nodes.
//=============================================================================
class KFTraderDread extends Info
	config(User);

#exec OBJ LOAD FILE=KFPlayerSound.uax
#exec OBJ LOAD FILE=KFPlayerSoundOld.uax
#exec OBJ LOAD FILE=KFAmbientSound.uax

var() config bool bDread;
var() config float Volume, StingVolume;	// as PlaySound takes it, at most 1 (a specimen's own moan is 0.3)
var() config float Radius;				// full loudness within this, fading beyond (a specimen's moan: 300)
var() config float GapMin, GapMax;		// seconds between sounds
var() float QuietStart;					// seconds of quiet once the trader opens
var() int StingAt;						// seconds before the wave when the specimens stir
var() int StingVoices;
var() float NearDist, FarDist;			// how far away a sound is placed
var() float CallShare, BedShare;		// the share of sounds that are a call, a bed

var() array<Sound> Groans;		// the usual: specimens groaning somewhere out there
var() array<Sound> Calls;		// now and then: one of the specials
var() array<Sound> Beds;		// seldom: a long low sound
var() array<Sound> StingSounds;

var array<NavigationPoint> Spots;
var array<vector> StingSpots;	// where the stir's voices came from, so that each comes from somewhere else
var float NextSound, TradingSince, NextStingVoice;
var bool bTrading, bStung;
var int StingLeft;

simulated function PostBeginPlay()
{
	local NavigationPoint N;

	for( N=Level.NavigationPointList; N!=None; N=N.NextNavigationPoint )
		Spots[Spots.Length] = N;
	SetTimer(0.25, true);
}

simulated function PlayerController Listener()
{
	if( HUD(Owner)!=None )
		return HUD(Owner).PlayerOwner;
	return None;
}

simulated function Timer()
{
	local PlayerController PC;
	local KFGameReplicationInfo GRI;
	local float R;

	PC = Listener();
	GRI = KFGameReplicationInfo(Level.GRI);
	if( !bDread || PC==None || GRI==None || !GRI.bMatchHasBegun || GRI.bWaveInProgress || GRI.bZombiesMode
		|| KFHumanPawn(PC.Pawn)==None || PC.Pawn.Health<=0 || PC.IsInState('GameEnded') )
	{
		bTrading = false;
		return;
	}
	if( !bTrading )
	{
		bTrading = true;
		bStung = false;
		StingLeft = 0;
		TradingSince = Level.TimeSeconds;
		NextSound = Level.TimeSeconds + QuietStart + FRand() * GapMin;
	}

	// the stir before the wave: voices from all round, a moment apart (not in the first seconds, while the
	// countdown may still hold the last one's figure)
	if( !bStung && GRI.TimeToNextWave>0 && GRI.TimeToNextWave<=StingAt && Level.TimeSeconds-TradingSince>2.0 )
	{
		bStung = true;
		StingLeft = StingVoices;
		StingSpots.Length = 0;
		NextStingVoice = Level.TimeSeconds;
	}
	if( StingLeft>0 )
	{
		if( Level.TimeSeconds>=NextStingVoice )
		{
			PlayFar(StingSounds[Rand(StingSounds.Length)], StingVolume, PC, true);
			StingLeft--;
			NextStingVoice = Level.TimeSeconds + 0.3 + FRand() * 0.6;
		}
		return;
	}
	// (quiet from a little before the stir until the wave)
	if( bStung || (GRI.TimeToNextWave>0 && GRI.TimeToNextWave<=StingAt+4) || Level.TimeSeconds<NextSound )
		return;

	R = FRand();
	if( R<BedShare && Beds.Length>0 )
		PlayFar(Beds[Rand(Beds.Length)], Volume, PC);
	else if( R<BedShare+CallShare && Calls.Length>0 )
		PlayFar(Calls[Rand(Calls.Length)], Volume, PC);
	else if( Groans.Length>0 )
		PlayFar(Groans[Rand(Groans.Length)], Volume, PC);
	NextSound = Level.TimeSeconds + GapMin + FRand() * (GapMax - GapMin);
}

// A path node at a fitting distance, out of sight if one is found (and for the stir, away from where its other voices
// came from); else a point that far off in some direction
simulated function vector FarSpot( vector Ear, bool bApart )
{
	local int i, j;
	local NavigationPoint N;
	local float D;
	local vector Seen, Dir;
	local bool bSeen, bNear;

	for( i=0; i<48 && Spots.Length>0; i++ )
	{
		N = Spots[Rand(Spots.Length)];
		if( N==None )
			continue;
		D = VSize(N.Location - Ear);
		if( D<NearDist || D>FarDist )
			continue;
		bNear = false;
		for( j=0; bApart && j<StingSpots.Length; j++ )
			if( VSize(N.Location - StingSpots[j])<NearDist )
				bNear = true;
		if( bNear )
			continue;
		if( !FastTrace(N.Location, Ear) )
			return N.Location;
		Seen = N.Location;
		bSeen = true;
	}
	if( bSeen )
		return Seen;
	Dir = VRand();
	Dir.Z = 0;
	return Ear + Normal(Dir) * (NearDist + FarDist) * 0.5;
}

// (simulated, so the sound is played here only: a listen server would otherwise send its own to every client)
simulated function PlayFar( Sound S, float Vol, PlayerController PC, optional bool bSting )
{
	local vector Ear, Spot;
	local KFDreadVoice V;

	if( S==None )
		return;
	Ear = PC.Pawn.Location + PC.Pawn.EyePosition();
	Spot = FarSpot(Ear, bSting);
	if( bSting )
		StingSpots[StingSpots.Length] = Spot;
	V = Spawn(class'KFDreadVoice',,, Spot);
	if( V==None )
		return;
	V.LifeSpan = GetSoundDuration(S) + 1.0;
	V.PlaySound(S, SLOT_None, Vol, false, Radius, 0.85 + FRand() * 0.15, true);
}

defaultproperties
{
	bDread=True
	Volume=0.500000
	StingVolume=0.800000
	GapMin=7.000000
	GapMax=16.000000
	QuietStart=6.000000
	StingAt=10
	StingVoices=4
	NearDist=1000.000000
	FarDist=3000.000000
	Radius=400.000000
	CallShare=0.250000
	BedShare=0.060000
	Groans(0)=Sound'KFPlayerSound.Moan1'
	Groans(1)=Sound'KFPlayerSound.Moan2'
	Groans(2)=Sound'KFPlayerSound.Moan3'
	Groans(3)=Sound'KFPlayerSound.Moan4'
	Groans(4)=Sound'KFPlayerSound.ClotVoice1'
	Groans(5)=Sound'KFPlayerSound.ClotVoice2'
	Groans(6)=Sound'KFPlayerSound.ClotVoice5'
	Groans(7)=Sound'KFPlayerSound.BloatVoice1'
	Groans(8)=Sound'KFPlayerSound.BloatVoice3'
	Groans(9)=Sound'KFPlayerSoundOld.zombiegrowl2'
	Groans(10)=Sound'KFPlayerSoundOld.zombiegrowl3'
	Groans(11)=Sound'KFPlayerSoundOld.zombiegrowl4'
	Groans(12)=Sound'KFPlayerSoundOld.Moan1'
	Groans(13)=Sound'KFPlayerSoundOld.Moan2'
	Calls(0)=Sound'KFPlayerSound.ScrakeGiggle'
	Calls(1)=Sound'KFPlayerSound.StalkerVoice1'
	Calls(2)=Sound'KFPlayerSound.StalkerVoice3'
	Calls(3)=Sound'KFPlayerSound.SirenVoice1'
	Calls(4)=Sound'KFPlayerSound.SirenVoice3'
	Calls(5)=Sound'KFPlayerSound.CrawlerShriek4'
	Calls(6)=Sound'KFPlayerSound.GoreFastVoice1'
	Calls(7)=Sound'KFPlayerSound.GoreFastVoice4'
	Calls(8)=Sound'KFPlayerSound.Flesh4'
	Beds(0)=Sound'KFAmbientSound.disturbing'
	Beds(1)=Sound'KFPlayerSoundOld.ZomAmbient'
	StingSounds(0)=Sound'KFPlayerSound.CrawlerShriek1'
	StingSounds(1)=Sound'KFPlayerSound.SirenVoice2'
	StingSounds(2)=Sound'KFPlayerSound.ScrakeVoice4'
	StingSounds(3)=Sound'KFPlayerSound.Flesh3'
	StingSounds(4)=Sound'KFPlayerSound.GoreFastVoice2'
	StingSounds(5)=Sound'KFPlayerSoundOld.zombiegrowl2'
	StingSounds(6)=Sound'KFPlayerSoundOld.zombiegrowl4'
	StingSounds(7)=Sound'KFPlayerSound.StalkerVoice2'
	RemoteRole=ROLE_None
}
