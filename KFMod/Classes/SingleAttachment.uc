class SingleAttachment extends KFWeaponAttachment;

var Actor TacShine;
var  Effects TacShineCorona;
var bool bBeamEnabled;

// Prevents tracers from spawning if player is using the flashlight function of the 9mm
simulated event ThirdPersonEffects()
{
	if( FiringMode==1 )
		return;
	Super.ThirdPersonEffects();
}

simulated function Destroyed()
{
	if ( TacShineCorona != None )
		TacShineCorona.Destroy();
	if ( TacShine != None )
		TacShine.Destroy();
	Super.Destroyed();
}

simulated function UpdateTacBeam( float Dist )
{
	local vector Sc;

	if( !bBeamEnabled )
	{
		ChangeIdleToSecondary();
		if (TacShine == none )
		{
			TacShine = Spawn(Class'Single'.Default.TacShineClass,Owner,,,);
			AttachToBone(TacShine,'FlashBone3P');
			TacShine.RemoteRole = ROLE_None;
		}
		else TacShine.bHidden = False;
		if (TacShineCorona == none )
		{
			TacShineCorona = Spawn(class 'KFTacLightCorona',Owner,,,);
			AttachToBone(TacShineCorona,'FlashBone3P');
			TacShineCorona.RemoteRole = ROLE_None;
		}
		TacShineCorona.bHidden = False;
		bBeamEnabled = True;
	}
	Sc = TacShine.DrawScale3D;
	Sc.Y = FClamp(Dist/90.f,0.02,1.f);
	if( TacShine.DrawScale3D!=Sc )
		TacShine.SetDrawScale3D(Sc);
}

simulated function TacBeamGone()
{
	if( bBeamEnabled )
	{
		ChangeIdleToPrimary();
		if (TacShine!=none )
			TacShine.bHidden = True;
		if (TacShineCorona!=none )
			TacShineCorona.bHidden = True;
		bBeamEnabled = False;
	}
}

defaultproperties
{
<<<<<<< HEAD
	mMuzFlashClass=Class'KFMod.KFNormal3PMuzzFlash'
	mTracerClass=Class'KFMod.KFNewTracer'
	mShellCaseEmitterClass=Class'KFMod.KFShellSpewer'
	TPAnims(0)="DeagleBlast"
	WeaponIdleMovementAnim="DeagleHold"
	SecondaryWeaponIdleMovementAnim="SingleTacLightHold"
	bHeavy=True
	SplashEffect=Class'XGame.BulletSplash'
	LightType=LT_Pulse
	LightRadius=0.000000
	CullDistance=5000.000000
	Mesh=SkeletalMesh'KFWeaponModels.Single3P'
=======
     mMuzFlashClass=Class'KFMod.KFNormal3PMuzzFlash'
     mTracerClass=Class'KFMod.KFNewTracer'
     mShellCaseEmitterClass=Class'KFMod.KFShellSpewer'
     TPAnims(0)="DeagleBlast"
     WeaponIdleMovementAnim="DeagleHold"
     SecondaryWeaponIdleMovementAnim="SingleTacLightHold"
     //bHeavy=True
     SplashEffect=Class'XGame.BulletSplash'
     LightType=LT_Pulse
     LightRadius=0.000000
     CullDistance=5000.000000
     Mesh=SkeletalMesh'KFWeaponModels.Single3P'
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
