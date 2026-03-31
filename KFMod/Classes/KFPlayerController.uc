class KFPlayerController extends xPlayer
	DependsOn(KFPlayerStats);

//const MAX_BUYITEMS=50;
const BUYLIST_CATS=7;
const LIBLIST_CATS=3;

//TODO: Kill these last remenants of the old buy system
var string BuyListHeaders[BUYLIST_CATS];
var string LibraryListHeaders[LIBLIST_CATS];

var bool bChoseStarting, bClassChosen;
var bool IsInLobby;
var int CashThrowAmount; // Amount of cash a player throws per keypress.   Set in the player settings menu

var KFMusicInteraction KFInterAct;
var string DelayedSongToPlay;
var bool bHasDelayedSong,bHasChosenSkill;

var array<Actor> LightSources;

var KFPlayerStats MyActiveStats;

var array<KFPlayerStats.ActStats> ActStats;
var byte ClientStatsState;
var float StatsUdpTimer;
var int CLStats[11];

// Smooth FOV Management
var()   float       TargetFOV;                      // The FOV that the Camera is trying to acheive
var		float		TransitionStartFOV;             // The FOV that was being used at the start of the FOV Transition
var		float		TransitionTimeElapsed;          // How long (in seconds) the camera has been transitioning to TargetFOV
var		float		TransitionTimeTotal;            // How long it should take to transition to the target FOV

//var     config  bool    bUseTrueWideScreenFOV; 

var KFSPNoteMessage ActiveNote;

var Rotator								BehindViewAimRotator;

var() float FlySpeedMulti;
var bool bWantsSprint;

// Fractional Parts of Pitch/Yaw Input
var transient float PitchFraction, YawFraction;

replication
{
	reliable if(REMOTEROLE == ROLE_AUTONOMOUSPROXY)
		NetPlayMusic, NetStopMusic,ClientSwitchToBestMeleeWeapon,ShowLobbyMenu,ClientReceiveStat,StatsFinished,ClientGetStats;

	reliable if( Role < ROLE_Authority )
		KFSwitchToBestWeapon,ServerSetGRIPendingBots,ServerSetTempBotName,GRIKillBotCall,SelectVeterancy,ServerSendStats,UpdateStatsScreen;

	// Functions server can call.
	reliable if( Role==ROLE_Authority )
		KFClientNetWorkMsg;
}

simulated function InitInputSystem()
{
    Super.InitInputSystem();

    InitFOV();
}

// Set up the widescreen FOV values for this player
simulated final function InitFOV()
{
	local float ResX, ResY;
	local float AspectRatio;
	local float OriginalAspectRatio;
	local float NewFOV;

    ResX = float(GUIController(Player.GUIController).ResX);
    ResY = float(GUIController(Player.GUIController).ResY);
    AspectRatio = ResX / ResY;

	if ( AspectRatio >= 1.60 ) //1.6 = 16/10 which is 16:10 ratio and 16:9 comes to 1.77
	{
        OriginalAspectRatio = 4/3;

        NewFOV = (ATan((Tan((90.0*Pi)/360.0)*(AspectRatio/OriginalAspectRatio)),1)*360.0)/Pi;

        default.DefaultFOV = NewFOV;
        DefaultFOV = NewFOV;

        // 16X9
        if( AspectRatio >= 1.70 )
        {
            //log("Detected 16X9: "$(float(GUIController(Player.GUIController).ResX) / GUIController(Player.GUIController).ResY));
        }
        else
        {
            //log("Detected 16X10: "$(float(GUIController(Player.GUIController).ResX) / GUIController(Player.GUIController).ResY));
        }
    }
	else
	{
            //log("Detected 4X3: "$(float(GUIController(Player.GUIController).ResX) / GUIController(Player.GUIController).ResY));
            default.DefaultFOV = 90.0;
            DefaultFOV = 90.0;
	}

	// Set the FOV to the default FOV
	TransitionFOV(DefaultFOV,0.);
}

function AdjustView(float DeltaTime )
{
    local bool bReachedTargetFOV;

	// Updating the FOV
	if( TransitionTimeTotal > 0.0f && FOVAngle != TargetFOV )
	{
		TransitionTimeElapsed += DeltaTime;
		if( TransitionTimeElapsed > TransitionTimeTotal )
		{
			TransitionTimeElapsed = TransitionTimeTotal;
			bReachedTargetFOV = true;
		}

        FOVAngle = Lerp( (TransitionTimeElapsed / TransitionTimeTotal), TransitionStartFOV, TargetFOV );
        DesiredFOV = FOVAngle;

        if( bReachedTargetFOV )
        {
            TransitionTimeTotal = 0;
        }
	}

    super.AdjustView(DeltaTime);
}

function TransitionFOV(float NewFOV, float TransitionTime)
{
	if( TransitionTime > 0.0f )
	{
		TargetFOV = NewFOV;
		TransitionTimeTotal = TransitionTime;
		TransitionStartFOV = FOVAngle;
		TransitionTimeElapsed = 0.0f;
	}
	else
	{
		FOVAngle = NewFOV;
		TargetFOV = NewFOV;
		DesiredFOV = FOVAngle;
		TransitionTimeTotal = 0.0f; // The system won't attempt an FOV transition if TimeTotal is 0.
	}
}

function bool FindStatsObject()
{
	local string ID;

	if( MyActiveStats!=None )
		Return True; // Error?
	if( Player==None || KFGameType(Level.Game)==None )
		Return False;
	ID = GetPlayerIDHash();
	MyActiveStats = KFGameType(Level.Game).FindStats(ID);
	if( MyActiveStats==None )
		MyActiveStats = KFGameType(Level.Game).GenerateStats(ID);
	MyActiveStats.UserName = PlayerReplicationInfo.PlayerName;
	MyActiveStats.InitFor(Self);
	Return True;
}

event ClientOpenMenu (string Menu, optional bool bDisconnect,optional string Msg1, optional string Msg2)
{
	if(Player == None)
		Return;
	else Super.ClientOpenMenu(Menu,bDisconnect,Msg1,Msg2);
}

// TODO : Why are we not in state PlayerWaiting, where this was cut n' pasted
//        from in the first place?
function ServerReStartPlayer()
{
	if( PlayerReplicationInfo.bOutOfLives )
		Return; // No more main menu bug closing.

	ClientCloseMenu(true, true);

	if ( Level.Game.bWaitingToStartMatch )
		PlayerReplicationInfo.bReadyToPlay = true;
	else Level.Game.RestartPlayer(self);
}

/* 
exec function FreeCamera( bool B )
{
    bFreeCamera = B;
    bBehindView = B;
}
*/
// Toggle the Flashlight on or off via an exec call.
exec function ToggleTorch()
{
	if (pawn.Weapon != none && KFWeapon(pawn.Weapon).bTorchEnabled)
		KFWeapon(pawn.Weapon).LightFire();
}

function int FractionCorrection(float in, out float fraction) {
    local int result;
    local float tmp;

    tmp = in + fraction;
    result = int(tmp);
    fraction = tmp - result;

    return result;
}

function UpdateRotation(float DeltaTime, float maxPitch)
{
    local rotator newRotation, ViewRotation;

    if ( bInterpolating || ((Pawn != None) && Pawn.bInterpolating) )
    {
        ViewShake(deltaTime);
        return;
    }

    // Added FreeCam control for better view control
    if (bFreeCam == True)
    {
        if (bFreeCamZoom == True)
        {
            CameraDeltaRad += FractionCorrection(DeltaTime * 0.25 * aLookUp, PitchFraction);
        }
        else if (bFreeCamSwivel == True)
        {
            CameraSwivel.Yaw += FractionCorrection(16.0 * DeltaTime * aTurn, YawFraction);
            CameraSwivel.Pitch += FractionCorrection(16.0 * DeltaTime * aLookUp, PitchFraction);
        }
        else
        {
            CameraDeltaRotation.Yaw += FractionCorrection(32.0 * DeltaTime * aTurn, YawFraction);
            CameraDeltaRotation.Pitch += FractionCorrection(32.0 * DeltaTime * aLookUp, PitchFraction);
        }
    }
    else
    {
        ViewRotation = Rotation;

        if(Pawn != None && Pawn.Physics != PHYS_Flying) // mmmmm
        {
            // Ensure we are not setting the pawn to a rotation beyond its desired
            if( Pawn.DesiredRotation.Roll < 65535 &&
                (ViewRotation.Roll < Pawn.DesiredRotation.Roll || ViewRotation.Roll > 0))
                ViewRotation.Roll = 0;
            else if( Pawn.DesiredRotation.Roll > 0 &&
                (ViewRotation.Roll > Pawn.DesiredRotation.Roll || ViewRotation.Roll < 65535))
                ViewRotation.Roll = 0;
        }

        DesiredRotation = ViewRotation; //save old rotation

        if ( bTurnToNearest != 0 )
            TurnTowardNearestEnemy();
        else if ( bTurn180 != 0 )
            TurnAround();
        else
        {
            TurnTarget = None;
            bRotateToDesired = false;
            bSetTurnRot = false;
            ViewRotation.Yaw += FractionCorrection(32.0 * DeltaTime * aTurn, YawFraction);
            ViewRotation.Pitch += FractionCorrection(32.0 * DeltaTime * aLookUp, PitchFraction);
        }
        if (Pawn != None)
            ViewRotation.Pitch = Pawn.LimitPitch(ViewRotation.Pitch);

        SetRotation(ViewRotation);

        ViewShake(deltaTime);
        ViewFlash(deltaTime);

        NewRotation = ViewRotation;
        //NewRotation.Roll = Rotation.Roll;

        if ( !bRotateToDesired && (Pawn != None) && (!bFreeCamera || !bBehindView) )
            Pawn.FaceRotation(NewRotation, deltatime);
    }
}

function ViewShake(float DeltaTime)
{
	if(bGodMode || Pawn == None || Pawn.Health <= 0)
		return;
	Super.ViewShake(DeltaTime);
}

function ViewFlash(float DeltaTime)
{
	if(bGodMode || Pawn == None || Pawn.Health <= 0)
		return;
	Super.ViewFlash(DeltaTime);
}

function GRIKillBotCall(int NumBotsToKill)
{
	if (KFGameType(Level.Game) != none && NumBotsToKill > 0)
		KFGameType(Level.Game).KillBots(NumBotsToKill);
}

function KFClientNetWorkMsg(string ParamA, string ParamB)
{
	ClientOpenMenu("KFGUI.KFNetworkStatusMsg", true, ParamA, ParamB);
}

function BecomeSpectator()
{
	if (Role < ROLE_Authority)
		return;

	if ( !Level.Game.BecomeSpectator(self) )
		return;

	if ( Pawn != None )
		Pawn.Died(self, class'DamageType', Pawn.Location);

	if ( PlayerReplicationInfo.Team != None )
		PlayerReplicationInfo.Team.RemoveFromTeam(self);
	PlayerReplicationInfo.Team = None;
	ServerSpectate();
	BroadcastLocalizedMessage(Level.Game.GameMessageClass, 14, PlayerReplicationInfo);

	ClientBecameSpectator();
}


function ServerSetGRIPendingBots(int NumBotsPending,string BotName)
{
	local int arraydifference;

	//if (KFGameReplicationInfo(GameReplicationInfo).PendingBots  > 0)
	//	arraydifference = 1;
	//else
         arraydifference = 0;

	KFGameReplicationInfo(GameReplicationInfo).PendingBots = NumBotsPending;
	KFGameReplicationInfo(GameReplicationInfo).LastBotName[KFGameReplicationInfo(GameReplicationInfo).PendingBots - arraydifference] = BotName;
}


function ServerSetTempBotName(string KFBotName)
{
	KFGameReplicationInfo(GameReplicationInfo).TempBotName = KFBotName;
}


exec function ThrowGrenade()
{
	KFPawn(Pawn).ThrowGrenade();
	//Level.Game.Broadcast(Pawn, Pawn.GetHumanReadableName()$" bot threw nade via quick throw");
}

exec simulated function StartSprintKF()
{
	bWantsSprint = true;
	if (KFHumanPawn(Pawn) != None)
		KFHumanPawn(Pawn).StartSprintKF();
}

exec simulated function StopSprintKF()
{
	bWantsSprint = false;
	if (KFHumanPawn(Pawn) != None)
		KFHumanPawn(Pawn).StopSprintKF();
}

exec function ShoutSupport()
{
	ServerSpeech('SUPP', 0, "");
}

exec function ShoutFormUp()
{
	ServerSpeech('FORM', 0, "");
}

exec function ShoutTakeThis()
{
	ServerSpeech('TAKE', 0, "");
}

exec function ShoutTrading()
{
	ServerSpeech('TRAD', 0, "");
}

exec function ShoutMedic()
{
	ServerSpeech('MEDIC', 0, "");
}

exec function ShoutWelding()
{
	ServerSpeech('WELD', 0, "");
}

exec function ShoutCovering()
{
	ServerSpeech('COVER', 0, "");
}

simulated event PostNetReceive()
{
	Super.PostNetReceive();

	if ( PlayerReplicationInfo != none) // && bWaitingForPRI )
	{
		//bWaitingForPRI = False;

        //rec = class'xUtil'.static.FindPlayerRecord(PlayerReplicationInfo.CharacterName);
		//if ( rec.Species != None )
		//{
		//	if ( PlayerReplicationInfo.Team == None )
		//		rec.Species.static.LoadResources(rec, Level, PlayerReplicationInfo, 255);
		//	else
		//		rec.Species.static.LoadResources(rec, Level, PlayerReplicationInfo, PlayerReplicationInfo.Team.TeamIndex);

        // HACK !!!
        // TODO: remove hack
		PlayerReplicationInfo.VoiceTypeName = "KFCoreVoice.AussieVoice";
		PlayerReplicationInfo.VoiceType = class<VoicePack>(DynamicLoadObject(PlayerReplicationInfo.VoiceTypeName,class'Class'));
	}
}

function KFSwitchToBestWeapon()
{
	KFClientSwitchToBestWeapon();
}


function KFClientSwitchToBestWeapon()
{
	nextWeapon();
}

function ShowBuyMenu(string wlTag,float maxweight)
{
	StopForceFeedback();  // jdf - no way to pause feedback

	// Open menu
	ClientOpenMenu("KFGUI.GUIBuyMenu",,wlTag,string(maxweight));
}

function ShowLobbyMenu()
{
	StopForceFeedback();  // jdf - no way to pause feedback
	// Open menu
	ClientOpenMenu("KFGUI.LobbyMenu");
}

function ClientRestart(Pawn NewPawn)
{
	//KILL LOBBY
	ClientCloseMenu(true, true);
	super.ClientRestart(NewPawn);
}

simulated function bool FindInterAction()
{
	local int i;

	if( Player.InteractionMaster==None )
		Return False;
	For( i=0; i<Player.InteractionMaster.GlobalInteractions.Length; i++ ) // First search if one remains from last map.
	{
		if( KFMusicInteraction(Player.InteractionMaster.GlobalInteractions[i])!=None )
		{
			KFInterAct = KFMusicInteraction(Player.InteractionMaster.GlobalInteractions[i]);
			Return True;
		}
	}
	// Else create one.
	KFInterAct = New(None)Class'KFMusicInteraction';
	KFInterAct.ViewportOwner = Player;
	KFInterAct.Master = Player.InteractionMaster;
	i = Player.InteractionMaster.GlobalInteractions.Length;
	Player.InteractionMaster.GlobalInteractions.Length = i+1;
	Player.InteractionMaster.GlobalInteractions[i] = KFInterAct;
	KFInterAct.Initialize();
	Return True;
}

function ClientSetMusic( string NewSong, EMusicTransition NewTransition )
{
	local float FadeIn, FadeOut;

	switch (NewTransition)
	{
		case MTRAN_Segue:
			FadeIn = 7.0;
			FadeOut = 3.0;
			break;
		case MTRAN_Fade:
			FadeIn = 3.0;
			FadeOut = 3.0;
			break;
		case MTRAN_FastFade:
			FadeIn = 1.0;
			FadeOut = 1.0;
			break;
		case MTRAN_SlowFade:
			FadeIn = 5.0;
			FadeOut = 5.0;
			break;
	}
	if( NewSong=="" )
		NetStopMusic(FadeOut);
	else NetPlayMusic(NewSong,FadeIn,FadeOut);
}
function NetPlayMusic( string Song, float FadeInTime, float FadeOutTime )
{
	if( Player==None )
	{
		if( Song=="" )
			Return;
		DelayedSongToPlay = Song;
		bHasDelayedSong = True;
		Return;
	}
	else if( NetConnection(Player)!=None )
		Return;
	if( KFInterAct==None && !FindInterAction() )
		Return;
	bHasDelayedSong = False;
	KFInterAct.SetSong(Song,FadeInTime,FadeOutTime);
}
function NetStopMusic(float FadeOutTime)
{
	bHasDelayedSong = False;
	if( Player==None || NetConnection(Player)!=None )
		Return;
	if( KFInterAct==None && !FindInterAction() )
		Return;
	KFInterAct.StopSong(FadeOutTime);
}

event PlayerTick( float DeltaTime )
{
	if( bHasDelayedSong && Player!=None )
		NetPlayMusic(DelayedSongToPlay,0.5,0);
    Super.PlayerTick(DeltaTime);
}

//===========================================================================
// Behind View support
// Credit: Ballistic Weapons, implemented by YoYoBatty
// Over the shoulder
//===========================================================================
function CalcBehindView(out vector CameraLocation, out rotator CameraRotation, float Dist)
{
    local vector View,HitLocation,HitNormal;
    local float ViewDist,RealDist;
    local vector globalX,globalY,globalZ;
    local vector localX,localY,localZ;

	if (ViewTarget != Pawn || !Pawn.bProjTarget)
	{
		Super.CalcBehindView(CameraLocation, CameraRotation, Dist);
		return;
	}

    CameraRotation = Rotation;
    CameraRotation.Roll = 0;
	
	GetAxes(CameraRotation, localX, localY, localZ);
	
	CameraLocation.Z += 22;
	CameraLocation += localY * 1.8 * CameraDist;
	CameraLocation += localZ * 3.4 * CameraDist;

    // add view rotation offset to cameraview (amb)
    CameraRotation += CameraDeltaRotation;

    View = vect(1,0,0) >> CameraRotation;

    // add view radius offset to camera location and move viewpoint up from origin (amb)
    RealDist = Dist;
    Dist += CameraDeltaRad;

    if( Trace( HitLocation, HitNormal, CameraLocation - Dist * vector(CameraRotation), CameraLocation,false,vect(12,12,12) ) != None )
        ViewDist = FMin( (CameraLocation - HitLocation) Dot View, Dist );
    else
        ViewDist = Dist;

    if ( !bBlockCloseCamera || !bValidBehindCamera || (ViewDist > 10 + FMax(ViewTarget.CollisionRadius, ViewTarget.CollisionHeight)) )
	{
		bValidBehindCamera = true;
		OldCameraLoc = CameraLocation - ViewDist * View;
		OldCameraRot = CameraRotation;
	}
	else
		SetRotation(OldCameraRot);

    CameraLocation = OldCameraLoc;
    CameraRotation = OldCameraRot;

    // add view swivel rotation to cameraview (amb)
    GetAxes(CameraSwivel,globalX,globalY,globalZ);
    localX = globalX >> CameraRotation;
    localY = globalY >> CameraRotation;
    localZ = globalZ >> CameraRotation;
    CameraRotation = OrthoRotation(localX,localY,localZ);
}

//Free aim in behind view.
simulated function rotator GetViewRotation()
{
	if (Pawn != None)
	{	
		if ( bBehindView )
		{
			return TraceView();
			//return Rotation;	
		}
	}
    return Rotation;
}

simulated function rotator TraceView()
{
	local Vector HitLocation, HitNormal;
	
	if ( LastPlayerCalcView == Level.TimeSeconds && CalcViewActor != None && CalcViewActor.Location == CalcViewActorLocation )
		return BehindViewAimRotator;
	if (Trace( HitLocation, HitNormal, 15000 * vector(OldCameraRot) + OldCameraLoc, OldCameraLoc,false) != None)
		BehindViewAimRotator = Rotator(HitLocation - (Pawn.Location + Pawn.EyePosition()));
	else BehindViewAimRotator = Rotator(15000 * vector(OldCameraRot) + OldCameraLoc - (Pawn.Location + Pawn.EyePosition()));
	return BehindViewAimRotator;
}

function rotator AdjustAim(FireProperties FiredAmmunition, vector projStart, int aimerror)
{
    local vector FireDir, AimSpot, HitNormal, HitLocation, OldAim, AimOffset;
    local actor BestTarget;
    local float bestAim, bestDist, projspeed;
    local actor HitActor;
    local bool bNoZAdjust, bLeading;
    local rotator AimRot;

    FireDir = vector(GetViewRotation());
    if ( FiredAmmunition.bInstantHit )
        HitActor = Trace(HitLocation, HitNormal, projStart + 10000 * FireDir, projStart, true);
    else
        HitActor = Trace(HitLocation, HitNormal, projStart + 4000 * FireDir, projStart, true);
    if ( (HitActor != None) && HitActor.bProjTarget )
    {
        BestTarget = HitActor;
        bNoZAdjust = true;
        OldAim = HitLocation;
        BestDist = VSize(BestTarget.Location - Pawn.Location);
    }
    else
    {
        // adjust aim based on FOV
        bestAim = 0.90;
        if ( (Level.NetMode == NM_Standalone) && bAimingHelp )
        {
            bestAim = 0.93;
            if ( FiredAmmunition.bInstantHit )
                bestAim = 0.97;
            if ( FOVAngle < DefaultFOV - 8 )
                bestAim = 0.99;
        }
        else if ( FiredAmmunition.bInstantHit )
                bestAim = 1.0;
        BestTarget = PickTarget(bestAim, bestDist, FireDir, projStart, FiredAmmunition.MaxRange);
        if ( BestTarget == None )
        {
            return GetViewRotation();
        }
        OldAim = projStart + FireDir * bestDist;
    }
	InstantWarnTarget(BestTarget,FiredAmmunition,FireDir);
	ShotTarget = Pawn(BestTarget);
    if ( !bAimingHelp || (Level.NetMode != NM_Standalone) )
    {
        return GetViewRotation();
    }

    // aim at target - help with leading also
    if ( !FiredAmmunition.bInstantHit )
    {
        projspeed = FiredAmmunition.ProjectileClass.default.speed;
        BestDist = vsize(BestTarget.Location + BestTarget.Velocity * FMin(1, 0.02 + BestDist/projSpeed) - projStart);
        bLeading = true;
        FireDir = BestTarget.Location + BestTarget.Velocity * FMin(1, 0.02 + BestDist/projSpeed) - projStart;
        AimSpot = projStart + bestDist * Normal(FireDir);
        // if splash damage weapon, try aiming at feet - trace down to find floor
        if ( FiredAmmunition.bTrySplash
            && ((BestTarget.Velocity != vect(0,0,0)) || (BestDist > 1500)) )
        {
            HitActor = Trace(HitLocation, HitNormal, AimSpot - BestTarget.CollisionHeight * vect(0,0,2), AimSpot, false);
            if ( (HitActor != None)
                && FastTrace(HitLocation + vect(0,0,4),projstart) )
                return rotator(HitLocation + vect(0,0,6) - projStart);
        }
    }
    else
    {
        FireDir = BestTarget.Location - projStart;
        AimSpot = projStart + bestDist * Normal(FireDir);
    }
    AimOffset = AimSpot - OldAim;

    // adjust Z of shooter if necessary
    if ( bNoZAdjust || (bLeading && (Abs(AimOffset.Z) < BestTarget.CollisionHeight)) )
        AimSpot.Z = OldAim.Z;
    else if ( AimOffset.Z < 0 )
        AimSpot.Z = BestTarget.Location.Z + 0.4 * BestTarget.CollisionHeight;
    else
        AimSpot.Z = BestTarget.Location.Z - 0.7 * BestTarget.CollisionHeight;

    if ( !bLeading )
    {
        // if not leading, add slight random error ( significant at long distances )
        if ( !bNoZAdjust )
        {
            AimRot = rotator(AimSpot - projStart);
            if ( FOVAngle < DefaultFOV - 8 )
                AimRot.Yaw = AimRot.Yaw + 200 - Rand(400);
            else
                AimRot.Yaw = AimRot.Yaw + 375 - Rand(750);
            return AimRot;
        }
    }
    else if ( !FastTrace(projStart + 0.9 * bestDist * Normal(FireDir), projStart) )
    {
        FireDir = BestTarget.Location - projStart;
        AimSpot = projStart + bestDist * Normal(FireDir);
    }

    return rotator(AimSpot - projStart);
}


//  enforce Lobby menu appearance here - there were all sorts of conditions attached,
//  but none of them should occur in KF. This simplifies matters ;)
simulated function ShowLoginMenu()
{
	if( (Pawn != none && Pawn.Health > 0) || (Pawn.PlayerReplicationInfo != none && Pawn.PlayerReplicationInfo.bReadyToPlay) )
		return;
	ClientReplaceMenu("KFGUI.LobbyMenu");
}


auto state PlayerWaiting
{
	exec function Fire(optional float F)
	{
		LoadPlayers();
	}

	function bool CanRestartPlayer()
	{
		if(Level.Game.GameReplicationInfo.bMatchHasBegun)
			return False;
		return ((bReadyToStart || (DeathMatch(Level.Game) != None && DeathMatch(Level.Game).bForceRespawn)) && Super.CanRestartPlayer());
	}
}


// unpossessed a pawn (because pawn was killed)
function PawnDied(Pawn P)
{
	local int i;

	for (i = 0; i < CameraEffects.Length; i++)
	{
      	RemoveCameraEffect(CameraEffects[i]);
	}
	Super.PawnDied(P);
}
 
function ZoneInfo GetCurrentZone()
{
  return Region.Zone;
}

simulated function PlayBeepSound()
{
    if ( ViewTarget != None )
        ViewTarget.PlaySound(sound'KFWeaponSound.bullethitflesh2', SLOT_None,,,,,false);
}
function ShowMidGameMenu(bool bPause)
{
	// Pause if not already
	if( Level.Pauser==None && Level.NetMode==NM_StandAlone )
		SetPause(true);

	if ( Level.NetMode != NM_DedicatedServer )
		StopForceFeedback();  // jdf - no way to pause feedback

	// Open menu
	if (bDemoOwner)
		ClientopenMenu(DemoMenuClass);

	else if ( LoginMenuClass != "" )
		ClientOpenMenu(LoginMenuClass);

	else ClientOpenMenu(MidGameMenuClass);
}

// Fast Melee Switch Code.
// server calls this to force client to switch
function ClientSwitchToBestMeleeWeapon()
{
	SwitchToBestMeleeWeapon();
}

// Same as SwitchToBestWeapon, but we're only dealing in Melee arms now.
exec function SwitchToBestMeleeWeapon()
{
	local inventory inv;

	if ( Pawn == None || KFMeleeGun(Pawn.Inventory) == None )
		return;

	if ( (Pawn.PendingWeapon == None)  )
	{
		for(inv = pawn.Inventory; inv!=None; inv=inv.Inventory)
      	{
			if(inv.IsA('Knife'))
			{
				Pawn.PendingWeapon = Knife(inv);
				Break;
			}
		}
		if ( Pawn.PendingWeapon == Pawn.Weapon )
			Pawn.PendingWeapon = None;
		if ( Pawn.PendingWeapon == None )
			return;
	}
	StopFiring();

	if ( Pawn.Weapon == None )
		Pawn.ChangedWeapon();
	else if ( Pawn.Weapon != Pawn.PendingWeapon )
		Pawn.Weapon.PutDown();
}
function SelectVeterancy( Class<KFVeterancyTypes> VetSkill )
{
	local int i,j;
	//local Inventory Inv;

	if( VetSkill==None || MyActiveStats==None )
		Return;
	if( bHasChosenSkill )
	{
		ClientMessage("You can't change veterancy twice on the same map.");
		Return;
	}
	if( VetSkill==KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill )
	{
		ClientMessage("You are already a '"$VetSkill.Default.VeterancyName$"'");
		Return;
	}
	/* 
	for(inv=Pawn.Inventory; inv!=None; inv=inv.Inventory)
	{
		if(KFWeapon(inv)!=None)
			KFWeapon(inv).ChangedPerk(VetSkill.Default.VeterancyName);
	}
	*/
	j = MyActiveStats.ActiveStats.Length;
	for( i=0; i<j; i++ )
	{
		if( MyActiveStats.ActiveStats[i].VetCl==VetSkill )
		{
			if( !MyActiveStats.ActiveStats[i].bNotified )
				Return; // Can't get that, dude.
			MyActiveStats.ApplyVeterancy(VetSkill);
			ClientMessage("You have chosen to be a '"$VetSkill.Default.VeterancyName$"'");
			//bHasChosenSkill = True;
			Return;
		}
	}
}

exec function OpenVeterancyMenu() 
{ 
	if( Viewport(Player)==None || PlayerReplicationInfo==None || PlayerReplicationInfo.bOnlySpectator || KFGameReplicationInfo(Level.GRI)==None
	 || !KFGameReplicationInfo(Level.GRI).bPerksEnabled )
		Return;
	Super.ClientOpenMenu("KFGUI.GUIVeterancyBinder", false);
}

simulated function RequestForClasses()
{
	if( ClientStatsState==0 )
	{
		ClientStatsState = 1;
		ServerSendStats();
	}
}
function ServerSendStats()
{
	local int i;

	if( MyActiveStats==None || !FindStatsObject() || KFGameReplicationInfo(Level.GRI)==None || !KFGameReplicationInfo(Level.GRI).bPerksEnabled )
	{
		StatsFinished();
		Return;
	}
	For( i=0; i<MyActiveStats.ActiveStats.Length; i++ )
		ClientReceiveStat(MyActiveStats.ActiveStats[i].VetCl,MyActiveStats.ActiveStats[i].bNotified);
	StatsFinished();
}


simulated function ClientReceiveStat( Class<KFVeterancyTypes> StatClass, bool bEnabled )
{
	local int i;

	for( i=0; i<ActStats.Length; i++ )
	{
		if( ActStats[i].VetCl==StatClass )
		{
			ActStats[i].bNotified = bEnabled;
			Return;
		}
	}
	i = ActStats.Length;
	ActStats.Length = i+1;
	ActStats[i].VetCl = StatClass;
	ActStats[i].bNotified = bEnabled;
}
simulated function StatsFinished()
{
	ClientStatsState = 2;
}

// Stats...
function UpdateStatsScreen()
{
	if( StatsUdpTimer>Level.TimeSeconds )
		Return;
	StatsUdpTimer = Level.TimeSeconds+10;
	if( MyActiveStats==None || !FindStatsObject() )
		Return;
	ClientGetStats(MyActiveStats.TotalKills,MyActiveStats.TotalMeleeDamage,MyActiveStats.DecaptedKills,MyActiveStats.PowerWpnKills
	 ,MyActiveStats.TotalHealed,MyActiveStats.TotalWelded,MyActiveStats.StalkerKills,MyActiveStats.BullpupDamage,MyActiveStats.TotalPlaytime
	 ,MyActiveStats.GamesWon,MyActiveStats.GamesLost);
}

simulated function ClientGetStats( int TK, int TMK, int TDK, int TPK, int THL, int TWL, int TSLK, int TBDM, int TPLT, int GW, int GL )
{
	CLStats[0] = TK;
	CLStats[1] = TMK;
	CLStats[2] = TDK;
	CLStats[3] = TPK;
	CLStats[4] = THL;
	CLStats[5] = TWL;
	CLStats[6] = TSLK;
	CLStats[7] = TBDM;
	CLStats[8] = TPLT;
	CLStats[9] = GW;
	CLStats[10] = GL;
}

function Destroyed()
{
	if( MyActiveStats!=None && MyActiveStats.CurrentOwner==Self )
		MyActiveStats.CurrentOwner = None;
	MyActiveStats = None;
	Super.Destroyed();
}

function SetPawnClass(string inClass, string inCharacter)
{
	PawnClass = Class'KFHumanPawn';
	inCharacter = Class'KFGameType'.Static.GetValidCharacter(inCharacter);
	PawnSetupRecord = class'xUtil'.static.FindPlayerRecord(inCharacter);
	PlayerReplicationInfo.SetCharacterName(inCharacter);
}

exec function RMode2( byte MD )
{
	RendMap = MD;
}

state Dead
{
	event PlayerCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation )
	{
		if( Level.NetMode==NM_DedicatedServer )
		{
			Global.PlayerCalcView(ViewActor,CameraLocation,CameraRotation);
			Return;
		}
		if ( LastPlayerCalcView == Level.TimeSeconds && CalcViewActor != None && CalcViewActor.Location == CalcViewActorLocation )
		{
			ViewActor	= CalcViewActor;
			CameraLocation	= CalcViewLocation;
			CameraRotation	= CalcViewRotation;
			return;
		}
		if( Pawn(ViewTarget)!=None && Pawn(ViewTarget).bSpecialCalcView )
		{
			// try the 'special' calcview. This may return false if its not applicable, and we do the usual.
			if ( Pawn(ViewTarget).SpecialCalcView(ViewActor, CameraLocation, CameraRotation) )
			{
				CacheCalcView(ViewActor,CameraLocation,CameraRotation);
				return;
			}
		}
		Global.PlayerCalcView(ViewActor,CameraLocation,CameraRotation);
	}
	function BeginState()
	{
		Super.BeginState();
		if( HudKillingFloor(myHUD)!=None )
		{
			HudKillingFloor(myHUD).bDisplayDeathScreen = True;
			HudKillingFloor(myHUD).GoalTarget = ViewTarget;
		}
	}
}

simulated function DisplayDebug(Canvas Canvas, out float YL, out float YPos)
{
	Super.DisplayDebug(Canvas, YL, YPos);

	if( Pawn != None )
	{
		Canvas.SetDrawColor(255, 255, 255);
		Canvas.DrawText("Rotation:"@Rotation@"Pawn Rotation:"@Pawn.Rotation@"Smooth View Yaw:"@Pawn.SmoothViewYaw@"Aim rotator:"@BehindViewAimRotator);
		YPos += YL;
		Canvas.SetPos(4, YPos);
	}
}

//Ignoring ServerSpectate in movement state code
state PlayerWalking
{
	ignores SeePlayer, HearNoise, Bump, ServerSpectate;
	function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
    {
        local vector OldAccel;
        local bool OldCrouch;
		
		if ( Pawn == None )
			return;
		if ( (DoubleClickMove == DCLICK_Active) && (Pawn.Physics == PHYS_Falling) )
			DoubleClickDir = DCLICK_Active;
		else if ( (DoubleClickMove != DCLICK_None) && (DoubleClickMove < DCLICK_Active) )
		{
			if ( UnrealPawn(Pawn).Dodge(DoubleClickMove) )
				DoubleClickDir = DCLICK_Active;
		}
        OldAccel = Pawn.Acceleration;
        if ( Pawn.Acceleration != NewAccel )
			Pawn.Acceleration = NewAccel;
		if ( bDoubleJump && (bUpdating || Pawn.CanDoubleJump()) )
			Pawn.DoDoubleJump(bUpdating);
        else if ( bPressedJump )
			Pawn.DoJump(bUpdating);

		if (!bBehindView)
			Pawn.SetViewPitch(Rotation.Pitch);
		else
			Pawn.SetViewPitch(BehindViewAimRotator.Pitch);

        if ( Pawn.Physics != PHYS_Falling )
        {
            OldCrouch = Pawn.bWantsToCrouch;
            if (bDuck == 0)
                Pawn.ShouldCrouch(false);
            else if ( Pawn.bCanCrouch )
                Pawn.ShouldCrouch(true);
        }
    }
}

state PlayerFlying
{
ignores SeePlayer, HearNoise, Bump, ServerSpectate;

	//copied from PlayerSwimming, updated
    function PlayerMove(float DeltaTime)
    {
        local vector X,Y,Z, NewAccel;

        GetAxes(Rotation, X, Y, Z);

        NewAccel = aForward*X + aStrafe*Y + aUp*vect(0,0,1);
		
        if ( VSize(NewAccel) < 1.0 )
            NewAccel = vect(0,0,0); 
		if ( bCheatFlying && (Pawn.Acceleration == vect(0,0,0)) )
            Pawn.Velocity = vect(0,0,0);
        if (bWantsSprint)
            Pawn.AirSpeed = Pawn.default.AirSpeed * FlySpeedMulti;
		else Pawn.AirSpeed = Pawn.default.AirSpeed;
		Pawn.AccelRate = 4096.0;

        // Update rotation.
        UpdateRotation(DeltaTime, 2);

        if ( Role < ROLE_Authority ) // then save this move and replicate it
            ReplicateMove(DeltaTime, NewAccel, DCLICK_None, rot(0,0,0));
        else
            ProcessMove(DeltaTime, NewAccel, DCLICK_None, rot(0,0,0));
    }
}

state Spectating
{
	ignores SwitchWeapon, RestartLevel, ClientRestart, Suicide,
	ThrowWeapon, NotifyPhysicsVolumeChange, NotifyHeadVolumeChange;

	function bool IsSpectating()
	{
		return true;
	}

    function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
    {
        Acceleration = NewAccel;
        MoveSmooth(SpectateSpeed * Normal(Acceleration) * DeltaTime);
    }

    function PlayerMove(float DeltaTime)
    {
        local vector X,Y,Z, NewAccel;

		if ( (Pawn(ViewTarget) != None) && (Level.NetMode == NM_Client) )
		{
			if ( Pawn(ViewTarget).bSimulateGravity )
				TargetViewRotation.Roll = 0;
			BlendedTargetViewRotation.Pitch = BlendRot(DeltaTime, BlendedTargetViewRotation.Pitch, TargetViewRotation.Pitch & 65535);
			BlendedTargetViewRotation.Yaw = BlendRot(DeltaTime, BlendedTargetViewRotation.Yaw, TargetViewRotation.Yaw & 65535);
			BlendedTargetViewRotation.Roll = BlendRot(DeltaTime, BlendedTargetViewRotation.Roll, TargetViewRotation.Roll & 65535);
		}
        GetAxes(Rotation,X,Y,Z);

        NewAccel = aForward*X + aStrafe*Y + aUp*vect(0,0,1);
		
        if ( VSize(NewAccel) < 1.0 )
            NewAccel = vect(0,0,0); 
		if (bWantsSprint)
			SpectateSpeed = default.SpectateSpeed * FlySpeedMulti;
		else
			SpectateSpeed = default.SpectateSpeed;

        UpdateRotation(DeltaTime, 1);

        if ( Role < ROLE_Authority ) // then save this move and replicate it
            ReplicateMove(DeltaTime, NewAccel, DCLICK_None, rot(0,0,0));
        else
            ProcessMove(DeltaTime, NewAccel, DCLICK_None, rot(0,0,0));
    }
}

defaultproperties
{
	BuyListHeaders(0)="My Inventory"
	BuyListHeaders(1)="Melee"
	BuyListHeaders(2)="Power"
	BuyListHeaders(3)="Speed"
	BuyListHeaders(4)="Range"
	BuyListHeaders(5)="Ammo"
	BuyListHeaders(6)="Equipment"
	LibraryListHeaders(0)="BackStory"
	LibraryListHeaders(1)="Equipment"
	LibraryListHeaders(2)="Enemies"
	//bUseTrueWideScreenFOV=True
	//bBehindView=True
	CheatClass=Class'KFMod.KFCheatManager'
	TeamBeaconTexture=Texture'ONSInterface-TX.HealthBar'
	MidGameMenuClass="KFGUI.KFInvasionLoginMenu"
	PlayerReplicationInfoClass=Class'KFMod.KFPlayerReplicationInfo'
	FlySpeedMulti=2.500000
}
