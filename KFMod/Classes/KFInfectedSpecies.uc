class KFInfectedSpecies extends SpeciesType
    abstract;
    
static function string GetRagSkelName(String MeshName)
{
    return "Infected";
}

defaultproperties
{
	MaleVoice="KFmod.KFMaleZombieSounds"
	FemaleVoice="KFmod.KFMaleZombieSounds"
	GibGroup="KFMod.KFGibGroup"
	FemaleSkeleton="KFCharacterModels.InfectedWhiteMale1"
	MaleSkeleton="KFCharacterModels.InfectedWhiteMale1"
	MaleSoundGroup="KFmod.KFMaleZombieSounds"
	FemaleSoundGroup="KFmod.KFMaleZombieSounds"
	SpeciesName="Infected"
	AirControl=1.200000
	GroundSpeed=1.400000
	ReceivedDamageScaling=1.300000
	AccelRate=1.100000
}
