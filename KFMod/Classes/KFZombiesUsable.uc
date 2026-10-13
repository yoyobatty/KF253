class KFZombiesUsable extends UseTrigger
	abstract;

var() float RefireDelay, PromptInterval, LookAtDot;
var() bool bRequireLookAt;

var float LastAttempt;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(PromptInterval, true);
}

function string GetPrompt( Pawn P );

function bool IsValidUser( Pawn P )
{
	Return P!=None && P.Health>0 && KFHumanPawn(P)!=None && !KFHumanPawn(P).bIsDowned;
}

function bool IsLookingAtMe( Pawn P )
{
	if( !bRequireLookAt )
		Return true;
	Return Normal(Location - (P.Location + P.EyePosition())) Dot vector(P.GetViewRotation()) > LookAtDot;
}

function bool CanUseNow( Pawn user )
{
	if( !IsValidUser(user) || (Level.TimeSeconds-LastAttempt)<RefireDelay )
		Return false;
	LastAttempt = Level.TimeSeconds;
	Return true;
}

function Notify( Pawn P, string S )
{
	if( S!="" && P!=None && PlayerController(P.Controller)!=None )
		PlayerController(P.Controller).ClientMessage(S, 'CriticalEvent');
}

function bool Charge( Pawn P, int Amount )
{
	if( P.PlayerReplicationInfo==None || P.PlayerReplicationInfo.Score<Amount )
		Return false;
	P.PlayerReplicationInfo.Score -= Amount;
	Return true;
}

function bool IsSoloGame()
{
	Return KFZombiesGameType(Level.Game)!=None && KFZombiesGameType(Level.Game).IsSoloGame();
}

function ShowPrompt( Pawn P )
{
	local string S;

	if( !IsValidUser(P) || PlayerController(P.Controller)==None || !IsLookingAtMe(P) )
		Return;

	S = GetPrompt(P);
	if( S=="" )
		Return;

	if( KFHumanPawnZombies(P)!=None )
		KFHumanPawnZombies(P).SetUsePrompt(S);
	else
		Notify(P, S);
}

function Timer()
{
	local KFHumanPawnZombies P;

	ForEach TouchingActors(class'KFHumanPawnZombies', P)
		ShowPrompt(P);
}

function Touch( Actor Other )
{
	local Pawn P;

	P = Pawn(Other);
	if( !IsValidUser(P) )
		Return;

	if( AIController(P.Controller)!=None )
		UsedBy(P);
	else
		ShowPrompt(P);
}

defaultproperties
{
	RefireDelay=1.000000
	PromptInterval=0.400000
	LookAtDot=0.700000
	bStatic=False
	bNoDelete=True
	bCollideActors=True
	bBlockActors=False
	bBlockPlayers=False
}
