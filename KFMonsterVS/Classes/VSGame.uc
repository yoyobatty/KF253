// Versus, as in Left 4 Dead 2's: two teams of players take a half each as the survivors, through the waves, while the
// other team plays specimens. A specimen player is given a specimen to be, rises as it wherever the survivors cannot see
// it, and after dying rises again as another a few seconds later; from the second wave one of them gets each wave's
// heavy. A team scores in its survivors' half (WavePoints a wave cleared, a share of it for the wave the team fell in,
// and SurvivorPoints for each survivor standing at a wave's end); after the second half the higher score wins. The AI's
// waves come as ever, and bots make up the survivors.
class VSGame extends KFGameType;

var() config float SpecimenSpawnDelay;			// seconds a specimen player waits to rise again after dying

var array< class<KFMonster> > SpecimenClasses;	// what specimen players rise as (each taken by one player at a time, if it can be)
var array< class<KFMonster> > HeavyClasses;
var float HeavyPatience;						// seconds a player's heavy may go without hurting a survivor before the AI takes it
var int HalfTimeLength;							// seconds of the break between the halves
var int WavePoints;
var int SurvivorPoints;							// half for standing at the wave's end, half by health

var VSGRI VGRI;
var byte Half, SurvivorSquad;
var int SurvivorSlots;			// survivors each half fields, players and bots (counted as the first wave begins)
var int WaveTotal, WaveKills;	// the AI specimens of this wave, and how many have been killed
var float HeavyShare;			// the share of the wave killed when the heavy is handed out (0: none this wave)
var bool bHalfTime;
var int HalfTimeLeft;

var localized string HalfTimeText, SecondHalfText, WaveScoreText, FellText, JoinedText;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	GameReplicationInfo.bNoTeamChanges = false;
	VGRI = VSGRI(GameReplicationInfo);
	Half = 1;
}

// ============================================================================
// Teams: each player is on a versus team (VSPRI.VSTeam); the team playing the survivors this half is Teams[0], the other
// Teams[1]. Bots are always survivors.

final function byte RoleTeam( byte S )
{
	if( S==SurvivorSquad )
		return 0;
	return 1;
}
final function int SquadSize( byte S, optional Controller Skip )
{
	local Controller C;
	local int n;

	for( C=Level.ControllerList; C!=None; C=C.NextController )
		if( C!=Skip && PlayerController(C)!=None && VSPRI(C.PlayerReplicationInfo)!=None && !C.PlayerReplicationInfo.bOnlySpectator
		 && VSPRI(C.PlayerReplicationInfo).VSTeam==S )
			n++;
	return n;
}
final function byte PickSquad( Controller Other )
{
	local int A, B;

	A = SquadSize(0,Other);
	B = SquadSize(1,Other);
	if( A<B )
		return 0;
	if( B<A )
		return 1;
	return SurvivorSquad;
}
// Human players on the survivors' side
final function int SurvivorPlayers()
{
	local Controller C;
	local int n;

	for( C=Level.ControllerList; C!=None; C=C.NextController )
		if( PlayerController(C)!=None && C.PlayerReplicationInfo!=None && !C.PlayerReplicationInfo.bOnlySpectator
		 && C.PlayerReplicationInfo.Team==Teams[0] )
			n++;
	return n;
}
final function SetTeam( Controller C, byte T )
{
	if( C.PlayerReplicationInfo.Team==Teams[T] )
		return;
	if( C.PlayerReplicationInfo.Team!=None )
		C.PlayerReplicationInfo.Team.RemoveFromTeam(C);
	Teams[T].AddToTeam(C);
}

function bool ChangeTeam( Controller Other, int N, bool bNewTeam )
{
	local VSPRI P;

	P = VSPRI(Other.PlayerReplicationInfo);
	if( PlayerController(Other)==None || P==None || P.bOnlySpectator )
		return Super.ChangeTeam(Other,N,bNewTeam);
	if( P.VSTeam>1 )
		P.VSTeam = PickSquad(Other);
	SetTeam(Other,RoleTeam(P.VSTeam));
	return true;
}

// The escape menu's Switch Team (VSPC.ServerChangeTeam)
function SwitchSquad( VSPC P )
{
	local VSPRI R;
	local byte S;

	R = VSPRI(P.PlayerReplicationInfo);
	if( R==None || R.bOnlySpectator || bGameEnded )
		return;
	if( R.VSTeam>1 )
		S = PickSquad(P);
	else S = 1-R.VSTeam;
	if( Level.NetMode!=NM_Standalone && R.VSTeam<=1 && SquadSize(S)>=SquadSize(R.VSTeam) )
	{
		P.ReceiveLocalizedMessage(class'VSInfoMessage',9);
		return;
	}
	if( P.Pawn!=None )
	{
		if( KFMonster(P.Pawn)!=None )
			ReleaseSpecimen(P);
		else P.Pawn.PlayerChangedTeam();
	}
	R.VSTeam = S;
	SetTeam(P,RoleTeam(S));
	R.bOutOfLives = false;
	R.NumLives = 0;
	Broadcast(Self,R.PlayerName@JoinedText@VGRI.SquadName(S)@"("$VGRI.RoleOf(S)$").");
	if( !GameReplicationInfo.bMatchHasBegun )
		return;
	if( RoleTeam(S)==1 )
	{
		P.NextSpawnTime = Level.TimeSeconds;
		SendToGhost(P);
	}
	else if( !bHalfTime && !bWaveInProgress && !bWaveBossInProgress )
	{
		P.GotoState('PlayerWaiting');
		SyncClientState(P,'PlayerWaiting');
		RestartPlayer(P);
	}
	else
	{
		R.bOutOfLives = true;
		P.GotoState('Spectating');
		SyncClientState(P,'Spectating');
	}
}

final function SyncClientState( PlayerController P, name NewState )
{
	if( P!=None && Viewport(P.Player)==None )
		P.ClientGotoState(NewState,'');
}

// ============================================================================
// Specimen players: a ghost (VSPC state Ghost) until they rise; a specimen of their own (an Awesome class) after

function RestartPlayer( Controller aPlayer )
{
	if( VSPC(aPlayer)!=None && aPlayer.PlayerReplicationInfo.Team==Teams[1] )
	{
		SendToGhost(VSPC(aPlayer));
		return;
	}
	if( bHalfTime )
		return;
	Super.RestartPlayer(aPlayer);
}

final function SendToGhost( VSPC P )
{
	if( P.Pawn!=None || P.PlayerReplicationInfo.bOnlySpectator || bGameEnded )
		return;
	P.PlayerReplicationInfo.bOutOfLives = false;
	P.PlayerReplicationInfo.NumLives = 0;
	if( VSPRI(P.PlayerReplicationInfo).SpawnClass==None )
		GiveSpecimen(P);
	if( !P.IsInState('Ghost') )
	{
		P.GotoState('Ghost');
		SyncClientState(P,'Ghost');
	}
}

// The specimen this player rises as next: one nobody else on the team is or will be, and not the one they just were
final function GiveSpecimen( VSPC P )
{
	local array< class<KFMonster> > Free;
	local int i;

	for( i=0; i<SpecimenClasses.Length; i++ )
		if( SpecimenClasses[i]!=P.LastSpecimen && !SpecimenTaken(SpecimenClasses[i],P) )
			Free[Free.Length] = SpecimenClasses[i];
	if( Free.Length==0 )
		for( i=0; i<SpecimenClasses.Length; i++ )
			if( SpecimenClasses[i]!=P.LastSpecimen )
				Free[Free.Length] = SpecimenClasses[i];
	VSPRI(P.PlayerReplicationInfo).SpawnClass = Free[Rand(Free.Length)];
}
final function bool SpecimenTaken( class<KFMonster> M, Controller Skip )
{
	local Controller C;

	for( C=Level.ControllerList; C!=None; C=C.NextController )
		if( C!=Skip && VSPC(C)!=None && ((C.Pawn!=None && C.Pawn.Class==M) || VSPRI(C.PlayerReplicationInfo).SpawnClass==M) )
			return true;
	return false;
}
final function bool IsHeavy( class<Pawn> M )
{
	local int i;

	for( i=0; i<HeavyClasses.Length; i++ )
		if( M==HeavyClasses[i] )
			return true;
	return false;
}

// A ghost's Fire (VSPC.ServerRise): its specimen rises there, if no survivor can see the spot
function RiseSpecimen( VSPC P )
{
	local VSPRI R;
	local vector Spot;
	local rotator Facing;
	local byte Problem;
	local KFMonster M;
	local int i, OldPlayers;

	R = VSPRI(P.PlayerReplicationInfo);
	if( R==None || P.Pawn!=None || R.SpawnClass==None || R.Team!=Teams[1] || Level.TimeSeconds<P.NextSpawnTime )
		return;
	if( bHalfTime || bGameEnded || (!bWaveInProgress && !bWaveBossInProgress) )
	{
		P.ReceiveLocalizedMessage(class'VSInfoMessage',6);
		return;
	}
	Problem = P.SpawnProblem(R.SpawnClass,Spot);
	if( Problem!=0 )
	{
		P.ReceiveLocalizedMessage(class'VSInfoMessage',Problem);
		return;
	}
	Facing.Yaw = P.Rotation.Yaw;
	// (its health and blows are worked out for the survivors in play, not counting the specimen players)
	OldPlayers = NumPlayers;
	NumPlayers = SurvivorPlayers();
	M = Spawn(R.SpawnClass,,,Spot,Facing);
	NumPlayers = OldPlayers;
	if( M!=None )
		for( i=0; i<ShopList.Length; i++ )
			if( ShopList[i]!=None && ShopList[i].Encompasses(M) )
			{
				if( M.Controller!=None )
					M.Controller.Destroy();
				M.Destroy();
				M = None;
				break;
			}
	if( M==None )
	{
		P.ReceiveLocalizedMessage(class'VSInfoMessage',5);
		return;
	}
	if( M.Controller!=None )
	{
		M.Controller.Pawn = None;
		M.Controller.Destroy();
	}
	P.Possess(M);
	P.ClientSetRotation(Facing);
	P.LastSpecimen = R.SpawnClass;
	R.SpawnClass = None;
	P.bHeavy = IsHeavy(M.Class);
	if( P.bHeavy )
	{
		P.LastHurtTime = Level.TimeSeconds;
		R.Patience = 100;
	}
}

// The AI takes the player's specimen over and the player is a ghost again (Suicide as a specimen, the heavy's patience
// run out, a change of team)
final function ReleaseSpecimen( VSPC P )
{
	local KFMonster M;
	local rotator R;

	M = KFMonster(P.Pawn);
	if( M==None )
		return;
	R.Yaw = M.Rotation.Yaw;
	P.UnPossess();
	P.ClientSetRotation(R);
	P.bHeavy = false;
	P.NextSpawnTime = Level.TimeSeconds + SpecimenSpawnDelay;
	if( M.Health>0 )
	{
		M.Controller = Spawn(M.ControllerClass);
		if( M.Controller!=None )
			M.Controller.Possess(M);
		else M.Suicide();
	}
	SendToGhost(P);
}

// Every second: dead specimen players back to ghosts, the wait before they may rise, the heavy's patience, and the
// player's controller back in its movement state if specimen code sent it to an AI one
final function SpecimenTimer()
{
	local Controller C;
	local VSPC P;
	local VSPRI R;

	for( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		P = VSPC(C);
		if( P==None || P.PlayerReplicationInfo.Team!=Teams[1] || P.PlayerReplicationInfo.bOnlySpectator )
			continue;
		R = VSPRI(P.PlayerReplicationInfo);
		if( P.Pawn==None )
		{
			if( !P.IsInState('Ghost') && Level.TimeSeconds>P.DeathTime+2 )
				SendToGhost(P);
			R.SpawnWait = Max(0,int(P.NextSpawnTime-Level.TimeSeconds+0.99));
		}
		else if( KFMonster(P.Pawn)!=None && P.Pawn.Health>0 )
		{
			if( P.bHeavy )
			{
				R.Patience = Clamp(100*(1.0-(Level.TimeSeconds-P.LastHurtTime)/HeavyPatience),0,100);
				if( R.Patience==0 )
				{
					P.ReceiveLocalizedMessage(class'VSInfoMessage',8);
					ReleaseSpecimen(P);
					continue;
				}
			}
			if( !P.IsInState('PlayerWalking') && !P.IsInState('PlayerSpidering') && !P.IsInState('PlayerSwimming')
			 && !P.IsInState('PlayerClimbing') && !P.IsInState('PlayerFlying') )
				P.GotoState(P.Pawn.LandMovementState);
		}
	}
	GiveHeavy();
}

// From the second wave, once a share of the wave is dead, one specimen player gets the heavy as what they rise as next
// (a ghost first, and whoever has had it least)
final function GiveHeavy()
{
	local Controller C;
	local VSPC P, Best;
	local int Score, BestScore;

	if( HeavyShare<=0 || !bWaveInProgress || WaveTotal<=0 || WaveKills<WaveTotal*HeavyShare )
		return;
	HeavyShare = 0;
	for( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		P = VSPC(C);
		if( P==None || P.PlayerReplicationInfo.Team!=Teams[1] || P.PlayerReplicationInfo.bOnlySpectator )
			continue;
		Score = Rand(10) - P.HeavyCount*100;
		if( P.Pawn==None )
			Score += 1000;
		if( Best==None || Score>BestScore )
		{
			Best = P;
			BestScore = Score;
		}
	}
	if( Best==None )
		return;
	Best.HeavyCount++;
	VSPRI(Best.PlayerReplicationInfo).SpawnClass = HeavyClasses[Rand(HeavyClasses.Length)];
	if( Best.Pawn==None )
		Best.NextSpawnTime = Level.TimeSeconds;
	Best.ReceiveLocalizedMessage(class'VSInfoMessage',7,,,VSPRI(Best.PlayerReplicationInfo).SpawnClass);
}

// What specimen players do to the survivors: their damage, and the heavy's patience
function int ReduceDamage( int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType )
{
	local VSPC P;

	Damage = Super.ReduceDamage(Damage,injured,instigatedBy,HitLocation,Momentum,DamageType);
	if( Damage>0 && instigatedBy!=None && KFMonster(instigatedBy)!=None && KFHumanPawn(injured)!=None && injured.Health>0 )
	{
		P = VSPC(instigatedBy.Controller);
		if( P!=None )
		{
			VSPRI(P.PlayerReplicationInfo).SpecimenDamage += Min(Damage,injured.Health);
			P.LastHurtTime = Level.TimeSeconds;
		}
	}
	return Damage;
}

function Killed( Controller Killer, Controller Killed, Pawn KilledPawn, class<DamageType> DamageType )
{
	local VSPC P;

	P = VSPC(Killed);
	if( P!=None && KFMonster(KilledPawn)==None )
		P = None;
	if( KFMonster(KilledPawn)!=None && KFMonsterController(Killed)!=None && (bWaveInProgress || bWaveBossInProgress) )
		WaveKills++;
	Super.Killed(Killer,Killed,KilledPawn,DamageType);
	if( P!=None )
	{
		// (not one of the wave's: the count of specimens left and the kills stay as they were)
		ZombiesKilled--;
		NumMonsters++;
		KFGameReplicationInfo(GameReplicationInfo).MaxMonsters = TotalMaxMonsters+NumMonsters;
		P.NextSpawnTime = Level.TimeSeconds + SpecimenSpawnDelay;
		P.DeathTime = Level.TimeSeconds;
		P.bHeavy = false;
		// (the dying specimen destroys any controller it still has, which would throw the player out)
		P.PawnDied(KilledPawn);
	}
}

function ScoreKill( Controller Killer, Controller Other )
{
	local PlayerReplicationInfo OtherPRI, KillerPRI;
	local int Cash;

	OtherPRI = Other.PlayerReplicationInfo;
	if( Killer!=None )
		KillerPRI = Killer.PlayerReplicationInfo;

	// a specimen player's specimen: its killer is paid as for the AI's
	if( OtherPRI!=None && OtherPRI.Team==Teams[1] )
	{
		if( GameRulesModifiers!=None )
			GameRulesModifiers.ScoreKill(Killer,Other);
		if( PlayerController(Other)!=None && Killer!=None && Killer!=Other )
		{
			if( KillerPRI!=None )
				PlayerController(Other).ReceiveLocalizedMessage(class'VSKilledMessage',,KillerPRI);
			else if( Killer.Pawn!=None )
				PlayerController(Other).ReceiveLocalizedMessage(class'VSKilledMessage',,,,Killer.Pawn.Class);
		}
		if( KillerPRI!=None && KillerPRI.Team==Teams[0] && LastKilledMonsterClass!=None )
		{
			Cash = KillCash(LastKilledMonsterClass);
			KillerPRI.Kills++;
			KillerPRI.Score += Cash;
			KillerPRI.Team.Score += Cash;
			KillerPRI.NetUpdateTime = Level.TimeSeconds - 1;
			KillerPRI.Team.NetUpdateTime = Level.TimeSeconds - 1;
			if( KFPlayerReplicationInfo(KillerPRI)!=None )
				KFPlayerReplicationInfo(KillerPRI).ThreeSecondScore += Cash;
		}
		return;
	}

	// a survivor killed by a specimen player: the survivor's loss as for any death, the kill to the player
	if( OtherPRI!=None && OtherPRI.Team==Teams[0] && KillerPRI!=None && KillerPRI.Team==Teams[1] )
	{
		if( GameRulesModifiers!=None )
			GameRulesModifiers.ScoreKill(Killer,Other);
		OtherPRI.NumLives++;
		OtherPRI.Score -= (OtherPRI.Score * (GameDifficulty * 0.05));
		OtherPRI.Team.Score -= (OtherPRI.Score * (GameDifficulty * 0.05));
		if( OtherPRI.Score<0 )
			OtherPRI.Score = 0;
		if( OtherPRI.Team.Score<0 )
			OtherPRI.Team.Score = 0;
		OtherPRI.Team.NetUpdateTime = Level.TimeSeconds - 1;
		OtherPRI.bOutOfLives = true;
		if( Killer.Pawn!=None )
			BroadcastLocalizedMessage(class'VSInvasionMessage',1,OtherPRI,KillerPRI,Killer.Pawn.Class);
		else BroadcastLocalizedMessage(class'VSInvasionMessage',1,OtherPRI,KillerPRI);
		KillerPRI.Kills++;
		KillerPRI.NetUpdateTime = Level.TimeSeconds - 1;
		CheckScore(None);
		return;
	}
	Super.ScoreKill(Killer,Other);
}

// The survivors are out when none of them has a life left (specimen players always have)
function bool CheckMaxLives( PlayerReplicationInfo Scorer )
{
	local Controller C;
	local PlayerController Living;
	local int AliveCount;

	if( MaxLives<=0 || bHalfTime )
		return false;
	for( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		if( C.PlayerReplicationInfo!=None && C.bIsPlayer && !C.PlayerReplicationInfo.bOutOfLives
		 && !C.PlayerReplicationInfo.bOnlySpectator && C.PlayerReplicationInfo.Team==Teams[0] )
		{
			AliveCount++;
			if( Living==None )
				Living = PlayerController(C);
		}
	}
	if( AliveCount==0 )
	{
		EndGame(Scorer,"LastMan");
		return true;
	}
	if( AliveCount==1 && Living!=None )
		Living.ReceiveLocalizedMessage(Class'KFLastManStandingMsg');
	return false;
}

// ============================================================================
// Scoring and the halves

final function AddScore( int Points )
{
	VGRI.SquadScore[SurvivorSquad] += Points;
	VGRI.NetUpdateTime = Level.TimeSeconds - 1;
}

// A wave cleared: its points, and the bonus for the survivors standing
final function ScoreWave()
{
	local Controller C;
	local float Bonus;

	for( C=Level.ControllerList; C!=None; C=C.NextController )
		if( C.PlayerReplicationInfo!=None && C.PlayerReplicationInfo.Team==Teams[0] && KFHumanPawn(C.Pawn)!=None && C.Pawn.Health>0 )
			Bonus += SurvivorPoints*0.5 + SurvivorPoints*0.5*FMin(float(C.Pawn.Health)/C.Pawn.HealthMax,1.0);
	AddScore(WavePoints + int(Bonus));
	VGRI.SquadWaves[SurvivorSquad]++;
	Announce(VGRI.SquadName(SurvivorSquad)@WaveScoreText@WavePoints@"+"@int(Bonus)$".");
}

// The survivors fell during a wave: the share of it they killed (of the boss's health, on the boss's wave)
final function ScoreFall()
{
	local Controller C;
	local float Share;

	if( bWaveBossInProgress )
	{
		for( C=Level.ControllerList; C!=None; C=C.NextController )
			if( KFMonsterController(C)!=None && C.Pawn!=None && Monster(C.Pawn).bBoss )
				Share = FMax(Share,1.0-float(C.Pawn.Health)/C.Pawn.HealthMax);
	}
	else if( bWaveInProgress && WaveTotal>0 )
		Share = FMin(float(WaveKills)/WaveTotal,1.0);
	AddScore(int(WavePoints*Share));
	Announce(VGRI.SquadName(SurvivorSquad)@FellText@int(WavePoints*Share)$".");
}

final function Announce( string S )
{
	local Controller C;

	for( C=Level.ControllerList; C!=None; C=C.NextController )
		if( PlayerController(C)!=None )
			PlayerController(C).ClientMessage(S,'CriticalEvent');
}

// The end of the first half starts the break; the end of the second ends the match
function EndGame( PlayerReplicationInfo Winner, string Reason )
{
	if( bHalfTime || bGameEnded )
		return;
	if( Reason~="LastMan" || Reason~="TimeLimit" || Reason~="NULL" )
	{
		if( bWaveInProgress || bWaveBossInProgress )
			ScoreFall();
		if( Half==1 )
		{
			StartHalfTime();
			return;
		}
	}
	if( VGRI.SquadScore[0]>VGRI.SquadScore[1] )
		VGRI.WinnerSquad = 0;
	else if( VGRI.SquadScore[1]>VGRI.SquadScore[0] )
		VGRI.WinnerSquad = 1;
	else VGRI.WinnerSquad = 2;
	Super.EndGame(Winner,Reason);
}

function bool CheckEndGame( PlayerReplicationInfo Winner, string Reason )
{
	local Controller P;

	EndTime = Level.TimeSeconds + EndTimeDelay;
	if( VGRI.WinnerSquad<2 )
		GameReplicationInfo.Winner = Teams[RoleTeam(VGRI.WinnerSquad)];
	else GameReplicationInfo.Winner = None;
	KFGameReplicationInfo(GameReplicationInfo).EndGameType = 2;
	for( P=Level.ControllerList; P!=None; P=P.NextController )
	{
		if( PlayerController(P)!=None )
		{
			PlayerController(P).ClientSetBehindView(true);
			PlayerController(P).ClientGameEnded();
		}
		P.GameHasEnded();
	}
	if( CurrentGameProfile!=None )
		CurrentGameProfile.bWonMatch = false;
	return true;
}

final function StartHalfTime()
{
	local Controller C;
	local KFMonster M;
	local Projectile Proj;
	local Pickup Item;

	bHalfTime = true;
	HalfTimeLeft = HalfTimeLength;
	VGRI.HalfTimeLeft = HalfTimeLeft;
	bWaveInProgress = false;
	bWaveBossInProgress = false;
	KFGameReplicationInfo(GameReplicationInfo).bWaveInProgress = false;

	foreach DynamicActors(class'KFMonster',M)
	{
		if( PlayerController(M.Controller)!=None )
			M.Controller.UnPossess();
		else if( M.Controller!=None )
			M.Controller.Destroy();
		M.Destroy();
	}
	for( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		if( C.Pawn!=None )
			C.Pawn.Destroy();
		if( PlayerController(C)!=None && !C.PlayerReplicationInfo.bOnlySpectator )
		{
			C.GotoState('Spectating');
			SyncClientState(PlayerController(C),'Spectating');
		}
	}
	foreach DynamicActors(class'Projectile',Proj)
		Proj.Destroy();
	foreach DynamicActors(class'Pickup',Item)
		if( Item.bDropped )
			Item.Destroy();
	StartGameMusic(False);
	Announce(HalfTimeText@VGRI.SquadName(SurvivorSquad)@VGRI.SquadScore[SurvivorSquad]$".");
}

// The second half: the teams change sides and the waves start over
final function StartSecondHalf()
{
	local Controller C, NextC;
	local VSPRI R;
	local KFDoorMover Door;
	local KFTraderDoor TDoor;
	local int Bots;

	Half = 2;
	VGRI.Half = 2;
	SurvivorSquad = 1-SurvivorSquad;
	VGRI.SurvivorSquad = SurvivorSquad;

	WaveNum = Max(0,InitialWave-1);
	InvasionGameReplicationInfo(GameReplicationInfo).WaveNumber = WaveNum;
	WaveCountDown = Max(InitialCountDownValue,1);
	KFGameReplicationInfo(GameReplicationInfo).TimeToNextWave = WaveCountDown;
	KFGameReplicationInfo(GameReplicationInfo).MaxMonstersOn = false;
	TotalMaxMonsters = 0;
	NumMonsters = 0;
	NextSpawnSquad.Length = 0;
	WaveTimeElapsed = 0;
	WaveTotal = 0;
	WaveKills = 0;
	HeavyShare = 0;
	bHasSetViewYet = false;
	ViewingBoss = None;
	MusicPlaying = false;
	CalmMusicPlaying = false;
	Teams[0].Score = 0;
	Teams[1].Score = 0;

	// (the trader's doors stand open before the first wave, as when the map began)
	if( !bTradingDoorsOpen )
	{
		foreach DynamicActors(class'KFTraderDoor',TDoor)
			TDoor.TriggerEvent(TDoor.Tag,TDoor,None);
		bTradingDoorsOpen = true;
	}
	foreach DynamicActors(class'KFDoorMover',Door)
		Door.RespawnDoor();

	for( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		R = VSPRI(C.PlayerReplicationInfo);
		if( C.PlayerReplicationInfo==None || C.PlayerReplicationInfo.bOnlySpectator )
			continue;
		C.PlayerReplicationInfo.Score = StartingCash;
		C.PlayerReplicationInfo.bOutOfLives = false;
		C.PlayerReplicationInfo.NumLives = 0;
		C.PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;
		if( VSPC(C)!=None && R!=None && R.VSTeam<=1 )
		{
			SetTeam(C,RoleTeam(R.VSTeam));
			R.SpawnClass = None;
			VSPC(C).NextSpawnTime = 0;
			VSPC(C).HeavyCount = 0;
		}
		else if( Bot(C)!=None )
			Bots++;
	}

	// (the bots make up the survivors to the first half's number)
	for( C=Level.ControllerList; C!=None; C=NextC )
	{
		NextC = C.NextController;
		if( Bot(C)!=None && Bots>Max(0,SurvivorSlots-SurvivorPlayers()) )
		{
			C.Destroy();
			Bots--;
		}
	}
	while( Bots<SurvivorSlots-SurvivorPlayers() && AddBot() )
		Bots++;

	bHalfTime = false;
	VGRI.HalfTimeLeft = 0;
	for( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		if( C.PlayerReplicationInfo==None || C.PlayerReplicationInfo.bOnlySpectator || C.Pawn!=None )
			continue;
		if( PlayerController(C)!=None && C.PlayerReplicationInfo.Team==Teams[0] )
		{
			C.GotoState('PlayerWaiting');
			SyncClientState(PlayerController(C),'PlayerWaiting');
		}
		RestartPlayer(C);
	}
	Announce(SecondHalfText@VGRI.SquadName(SurvivorSquad)@VGRI.RoleOf(SurvivorSquad)$".");
}

function SetupWave()
{
	local int OldPlayers;

	OldPlayers = NumPlayers;
	NumPlayers = SurvivorPlayers();
	Super.SetupWave();
	NumPlayers = OldPlayers;
	WaveTotal = TotalMaxMonsters;
	WaveKills = 0;
	if( SurvivorSlots==0 )
		SurvivorSlots = Max(Teams[0].Size,MinPlayers);
	if( WaveNum>=1 && HeavyClasses.Length>0 )
		HeavyShare = 0.3 + 0.4*FRand();
	else HeavyShare = 0;
}
function bool AddSquad()
{
	local int OldPlayers;
	local bool bRes;

	OldPlayers = NumPlayers;
	NumPlayers = SurvivorPlayers();
	bRes = Super.AddSquad();
	NumPlayers = OldPlayers;
	return bRes;
}
function bool AddBoss()
{
	local int OldPlayers;
	local bool bRes;

	OldPlayers = NumPlayers;
	NumPlayers = SurvivorPlayers();
	bRes = Super.AddBoss();
	NumPlayers = OldPlayers;
	return bRes;
}

State MatchInProgress
{
	// (specimens are the AI's alone; living survivors keep the match going)
	function bool UpdateMonsterCount()
	{
		local Controller C;
		local int i, j;

		for( C=Level.ControllerList; C!=None; C=C.NextController )
		{
			if( C.Pawn!=None && C.Pawn.Health>0 )
			{
				if( KFMonsterController(C)!=None )
					i++;
				else if( KFMonster(C.Pawn)==None )
					j++;
			}
		}
		NumMonsters = i;
		return (j>0);
	}

	function Timer()
	{
		if( bHalfTime )
		{
			Global.Timer();
			ElapsedTime++;
			GameReplicationInfo.ElapsedTime = ElapsedTime;
			HalfTimeLeft--;
			VGRI.HalfTimeLeft = Max(HalfTimeLeft,0);
			if( HalfTimeLeft<=0 )
				StartSecondHalf();
			return;
		}
		Super.Timer();
		if( !bHalfTime && !bGameEnded )
			SpecimenTimer();
	}

	function StartWaveBoss()
	{
		Super.StartWaveBoss();
		WaveTotal = 0;
		WaveKills = 0;
		HeavyShare = 0;
	}

	function float CalcNextSquadSpawnTime()
	{
		local float Res;
		local int OldPlayers;

		OldPlayers = NumPlayers;
		NumPlayers = SurvivorPlayers();
		Res = Super.CalcNextSquadSpawnTime();
		NumPlayers = OldPlayers;
		return Res;
	}

	// (the wave's points first, while the dead are still dead; then the player specimens go and the ghosts wait)
	function DoWaveEnd()
	{
		local Controller C;

		if( !bHalfTime && !bGameEnded )
			ScoreWave();
		for( C=Level.ControllerList; C!=None; C=C.NextController )
			if( VSPC(C)!=None && KFMonster(C.Pawn)!=None && C.Pawn.Health>0 )
				C.Pawn.KilledBy(C.Pawn);
		Super.DoWaveEnd();
	}
}

state MatchOver
{
	function BeginState()
	{
		Super.BeginState();
	}
}

// Only the survivors share the cash left over at a wave's end
function bool RewardSurvivingPlayers()
{
	local Controller C;
	local int MoneyPerPlayer, Div;
	local TeamInfo T;

	T = Teams[0];
	if( T==None || T.Score<=0 )
		return false;
	for( C=Level.ControllerList; C!=None; C=C.NextController )
		if( C.Pawn!=None && C.PlayerReplicationInfo!=None && C.PlayerReplicationInfo.Team==T )
			Div++;
	if( Div==0 )
		return false;
	MoneyPerPlayer = int(T.Score / float(Div));
	for( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		if( C.Pawn!=None && C.PlayerReplicationInfo!=None && C.PlayerReplicationInfo.Team==T )
		{
			if( Div==1 )
			{
				C.PlayerReplicationInfo.Score += T.Score;
				T.Score = 0;
			}
			else
			{
				C.PlayerReplicationInfo.Score += MoneyPerPlayer;
				T.Score -= MoneyPerPlayer;
				Div--;
			}
			C.PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;
			if( T.Score<=0 )
			{
				T.Score = 0;
				break;
			}
		}
	}
	T.NetUpdateTime = Level.TimeSeconds - 1;
	return true;
}

// The survivors' team size: bots make up the survivors to this many
function bool NeedPlayers()
{
	if( SurvivorSlots==0 )
		return Super.NeedPlayers();
	return (Teams[0].Size<SurvivorSlots);
}
function bool TooManyBots( Controller botToRemove )
{
	if( SurvivorSlots==0 )
		return Super.TooManyBots(botToRemove);
	return (Teams[0].Size>SurvivorSlots);
}

function NotifySpree( Controller Other, int num )
{
	if( Other.PlayerReplicationInfo!=None && Other.PlayerReplicationInfo.Team==Teams[1] )
		Super.NotifySpree(Other,num);
}
function EndSpree( Controller Killer, Controller Other )
{
	if( Other.PlayerReplicationInfo!=None && Other.PlayerReplicationInfo.Team==Teams[1] )
		Super.EndSpree(Killer,Other);
}

function BroadcastDeathMessage( Controller Killer, Controller Other, class<DamageType> damageType )
{
	local PlayerReplicationInfo K, V;
	local class<Monster> M;
	local Controller C;

	if( Other==None || Other.PlayerReplicationInfo==None )
		return;
	if( Killer!=None && Killer!=Other )
	{
		K = Killer.PlayerReplicationInfo;
		if( Killer.Pawn!=None )
			M = class<Monster>(Killer.Pawn.Class);
	}
	V = Other.PlayerReplicationInfo;
	for( C=Level.ControllerList; C!=None; C=C.NextController )
		if( C.bIsPlayer && VSPC(C)!=None )
			VSPC(C).ClientDeathMessage(V,damageType,K,M);
}

// Stub
static function Texture GetRandomTeamSymbol( int base )
{
	return Texture'Engine.DefaultTexture';
}

static function FillPlayInfo( PlayInfo PlayInfo )
{
	Super.FillPlayInfo(PlayInfo);
	PlayInfo.AddSetting(default.ServerGroup,"SpecimenSpawnDelay","Specimen rise delay",0,1,"Text","6;0.0:60.0");
}
static event string GetDescriptionText( string PropName )
{
	switch( PropName )
	{
		case "MinPlayers":			return "How many survivors each half fields: bots make up any not taken by players.";
		case "SpecimenSpawnDelay":	return "Seconds a specimen player waits to rise again after dying.";
	}
	return Super.GetDescriptionText(PropName);
}

defaultproperties
{
     SpecimenSpawnDelay=8.000000
     SpecimenClasses(0)=Class'KFMonsterVS.AwesomeClot'
     SpecimenClasses(1)=Class'KFMonsterVS.AwesomeCrawler'
     SpecimenClasses(2)=Class'KFMonsterVS.AwesomeStalker'
     SpecimenClasses(3)=Class'KFMonsterVS.AwesomeGoreFast'
     SpecimenClasses(4)=Class'KFMonsterVS.AwesomeBloat'
     SpecimenClasses(5)=Class'KFMonsterVS.AwesomeSiren'
     SpecimenClasses(6)=Class'KFMonsterVS.AwesomeShade'
     SpecimenClasses(7)=Class'KFMonsterVS.AwesomeWretch'
     HeavyClasses(0)=Class'KFMonsterVS.AwesomeFleshPound'
     HeavyClasses(1)=Class'KFMonsterVS.AwesomeScrake'
     HeavyPatience=20.000000
     HalfTimeLength=12
     WavePoints=100
     SurvivorPoints=50
     HalfTimeText="Half time."
     SecondHalfText="Second half: now playing the survivors,"
     WaveScoreText="clear the wave:"
     FellText="fall. Points for the wave's kills:"
     JoinedText="joined"
     bNoBots=False
     bFirstBlood=True
     LoginMenuClass="KFMonsterVS.VSLoginMenu"
     HUDType="KFMonsterVS.VSHUD"
     ScoreBoardType="KFMonsterVS.VSTeamScoreBoard"
     MutatorClass="KFMonsterVS.VSBaseMut"
     PlayerControllerClass=Class'KFMonsterVS.VSPC'
     PlayerControllerClassName="KFMonsterVS.VSPC"
     GameReplicationInfoClass=Class'KFMonsterVS.VSGRI'
     GameName="Team VS KF"
     Description="Versus: two teams of players take turns. One plays the survivors through the waves while the other rises as specimens to stop them, then they change sides. The team that scores more as survivors wins."
}
