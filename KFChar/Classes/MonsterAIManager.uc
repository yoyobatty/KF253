Class MonsterAIManager extends Mutator
	Placeable;

var MonsterFP ActiveMonster;
var() array<string> TensionSong,TerrorSong,CalmSong;
var() float BrightnessScale,BaseBrightness,CrouchBrightnessScale;
var transient Actor LastLight;
var transient Controller PawnLink;

function PreBeginPlay()
{
	if( Level.Game.BaseMutator==None )
		Level.Game.BaseMutator = Self;
	else Level.Game.BaseMutator.AddMutator(Self);
}

function AddMutator(Mutator M)
{
	if( M!=Self )
		Super.AddMutator(M);
}

function ModifyPlayer(Pawn Other)
{
	local NavigationPoint N;

	Super.ModifyPlayer(Other);
	for ( N=Level.NavigationPointList; N!=None; N=N.NextNavigationPoint )
	{
		if (N.isA('PlayerStart'))
		{			
			ActiveMonster = Spawn(Class'MonsterFP',,,N.Location);
			break;
		}
	}
	ActiveMonster.Manager = Self;
	KFGameType(Level.Game).NumMonsters = 1;
	if( KFPawn(Other)!=None )
		Spawn(Class'FootstepNoiseMaker',Other).Manager = Self;
	if ( NextMutator != None )
		NextMutator.ModifyPlayer(Other);
}

final function SetMonsterRage( bool bEnabled )
{
	if( bEnabled )
	{
		NetUpdateTime = Level.TimeSeconds - 1;
		SetTimer(0,false);
	}
	else SetTimer(10.f,false);
}
function Timer()
{
	NetUpdateTime = Level.TimeSeconds - 1;
}

final function float GetZoneBright( Actor A )
{
	return BaseBrightness+A.Region.Zone.AmbientBrightness;
}
final function byte GetVis()
{
	local float S;
	local KFWeapon W;
	
	W = KFWeapon(PawnLink.Pawn.Weapon);
	if( (W!=None && W.FlashLight!=None && W.FlashLight.bHasLight) || PawnLink.Pawn.AmbientGlow>PawnLink.Pawn.Default.AmbientGlow )
		S+=100;

	if( PawnLink.Pawn.bIsCrouched )
		S *= CrouchBrightnessScale;
	else S *= BrightnessScale;
	return Clamp(S,1,255);
}

function Trigger( Actor Other, Pawn EventInstigator )
{
	ActiveMonster = Spawn(Class'MonsterFP');
	ActiveMonster.Manager = Self;
	KFGameType(Level.Game).NumMonsters = 1;
}

auto state LitPlayers
{
Begin:
	while( true )
	{
		Sleep(0.15f);
		for( PawnLink=Level.ControllerList; PawnLink!=None; PawnLink=PawnLink.nextController )
			if( PawnLink.bIsPlayer && KFPawn(PawnLink.Pawn)!=None && PawnLink.Pawn.Health>0 && !PawnLink.Pawn.bHidden )
			{
				PawnLink.Pawn.Visibility = GetVis();
				Sleep(0.01f);
			}
	}
}

defaultproperties
{
	BrightnessScale=0.650000
	CrouchBrightnessScale=0.450000
	bNoDelete=True
	bAlwaysRelevant=True
	RemoteRole=ROLE_SimulatedProxy
	NetUpdateFrequency=2.000000
	FriendlyName="Add scary Fleshpound"
	GroupName="KF-MonsterAI"
	Description="Spawns a Fleshpound monster that hunts players in the level."
}
