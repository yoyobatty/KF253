Class MonsterFP extends ZombieFleshPound;

var MonsterAIManager Manager;

defaultproperties
{
	MoanVoice=None
	Intelligence=BRAINS_Human
	HearingThreshold=1350.000000
	SightRadius=2200.000000
	PeripheralVision=0.700000
	JumpZ=450.000000
	MenuName="Monster"
	ControllerClass=Class'KFChar.MonsterFPAI'
	bIgnoreEncroachers=True
	bAlwaysRelevant=True
	AmbientSound=None
}
