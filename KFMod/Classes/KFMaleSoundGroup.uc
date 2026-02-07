class KFMaleSoundGroup extends xPawnSoundGroup;

var () Sound BreathingSound;

static function Sound GetNearDeathSound()
{
	return default.BreathingSound;
}

defaultproperties
{
	BreathingSound=Sound'KFPlayerSound.Malebreath'
	Sounds(2)=SoundGroup'PlayerSounds.Final.HitUnderWaterMercMale'
	Sounds(3)=Sound'KFPlayerSound.JumpVoice'
	Sounds(4)=SoundGroup'PlayerSounds.Final.LandGruntMercMale'
	Sounds(5)=SoundGroup'PlayerSounds.Final.GaspMercMale'
	Sounds(6)=SoundGroup'PlayerSounds.Final.DrownMercMale'
	Sounds(7)=SoundGroup'PlayerSounds.Final.BreathAgainMercMale'
	Sounds(8)=Sound'PlayerSounds.JumpSounds.MaleDodge'
	Sounds(9)=Sound'KFPlayerSound.JumpVoice'
	DeathSounds(0)=Sound'NewDeath.MaleMerc.mm_death04'
	DeathSounds(1)=Sound'NewDeath.MaleMerc.mm_death05'
	DeathSounds(2)=Sound'NewDeath.MaleMerc.mm_death09'
	DeathSounds(3)=Sound'NewDeath.MaleMerc.mm_death10'
	DeathSounds(4)=Sound'NewDeath.MaleMerc.mm_death11'
	PainSounds(0)=Sound'KFPlayerSound.hpain3'
	PainSounds(1)=Sound'KFPlayerSound.hpain2'
	PainSounds(2)=Sound'KFPlayerSound.hpain1'
	PainSounds(3)=Sound'KFPlayerSound.hpain3'
	PainSounds(4)=Sound'KFPlayerSound.hpain2'
	PainSounds(5)=Sound'KFPlayerSound.hpain1'
}
