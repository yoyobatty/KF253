class KFHitEmitter extends Emitter
<<<<<<< HEAD
	abstract
	hidedropdown;
=======
	abstract;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

var() array<Sound> ImpactSounds;

//Particle start velocity is relative to rotation.
simulated function PostBeginPlay()
{
	local vector MinVel, MaxVel;

	Super.PostBeginPlay();
<<<<<<< HEAD

=======
	
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	if(Emitters.Length>0)
	{
		MinVel.X = Emitters[0].StartVelocityRange.X.Min;
		MinVel.Y = Emitters[0].StartVelocityRange.Y.Min;
		MinVel.Z = Emitters[0].StartVelocityRange.Z.Min;

		MaxVel.X = Emitters[0].StartVelocityRange.X.Max;
		MaxVel.Y = Emitters[0].StartVelocityRange.Y.Max;
		MaxVel.Z = Emitters[0].StartVelocityRange.Z.Max;

		MinVel = MinVel >> Rotation;
		MaxVel = MaxVel >> Rotation;

		Emitters[0].StartVelocityRange.X.Min = MinVel.X;
		Emitters[0].StartVelocityRange.Y.Min = MinVel.Y;
		Emitters[0].StartVelocityRange.Z.Min = MinVel.Z;

		Emitters[0].StartVelocityRange.X.Max = MaxVel.X;
		Emitters[0].StartVelocityRange.Y.Max = MaxVel.Y;
		Emitters[0].StartVelocityRange.Z.Max = MaxVel.Z;
	}
	// Ok, now let's do the same for Emitter 1
	if(Emitters.Length>1)
	{
		MinVel.X = Emitters[1].StartVelocityRange.X.Min;
		MinVel.Y = Emitters[1].StartVelocityRange.Y.Min;
		MinVel.Z = Emitters[1].StartVelocityRange.Z.Min;

		MaxVel.X = Emitters[1].StartVelocityRange.X.Max;
		MaxVel.Y = Emitters[1].StartVelocityRange.Y.Max;
		MaxVel.Z = Emitters[1].StartVelocityRange.Z.Max;

		MinVel = MinVel >> Rotation;
		MaxVel = MaxVel >> Rotation;

		Emitters[1].StartVelocityRange.X.Min = MinVel.X;
		Emitters[1].StartVelocityRange.Y.Min = MinVel.Y;
		Emitters[1].StartVelocityRange.Z.Min = MinVel.Z;

		Emitters[1].StartVelocityRange.X.Max = MaxVel.X;
		Emitters[1].StartVelocityRange.Y.Max = MaxVel.Y;
		Emitters[1].StartVelocityRange.Z.Max = MaxVel.Z;
	}
	if( ImpactSounds.Length>0 )
		PlaySound(ImpactSounds[Rand(ImpactSounds.Length)]);
}

defaultproperties
{
<<<<<<< HEAD
	AutoDestroy=True
	bNoDelete=False
	LifeSpan=5.000000
	TransientSoundVolume=150.000000
	TransientSoundRadius=80.000000
=======
     AutoDestroy=True
     bNoDelete=False
     LifeSpan=5.000000
     TransientSoundVolume=150.000000
     TransientSoundRadius=80.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
