class SingleAttachment extends KFWeaponAttachment;

var Actor TacShine;
var  Effects TacShineCorona;

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


// Hopefully this will keep the 1P / 3P beams in sync.

simulated function Tick(float DeltaTime)
{
  local vector StartTrace,EndTrace,X,Y,Z,HitLocation,HitNormal;
  local float BeamLength;
  local vector NewDrawScale;

  if (Owner == none || pawn(Owner).Controller == none)
   return;

   StartTrace = pawn(Owner).Weapon.GetFireStart(X,Y,Z); //LightPawn.Location + LightPawn.EyePosition();
   GetAxes(pawn(Owner).Controller.GetViewRotation(),X,Y,Z);
   
   // not too far out, we don't want a flashlight that can shine across the map
    EndTrace = StartTrace + 1800*vector(pawn(Owner).Controller.GetViewRotation());
    Trace(HitLocation,HitNormal,EndTrace,StartTrace,true,,); //SurfaceMat

    // find out how far the first hit was
    BeamLength = VSize(StartTrace-HitLocation);


  if(KFWeapon(pawn(Owner).Weapon).Flashlight != none)
  {
   if (TacShine == none )
    {
      TacShine = Spawn(KFWeapon(pawn(Owner).Weapon).TacShineClass,Owner,,,);
     if(TacShine != none)
      AttachToBone(TacShine,'FlashBone3P');
    }
    

        if (TacShineCorona == none )
    {
      TacShineCorona = Spawn(class 'KFTacLightCorona',Owner,,,);
     if(TacShineCorona != none)
      AttachToBone(TacShineCorona,'FlashBone3P');
    }




    if (TacShine != none)
     TacShine.bHidden = !KFWeapon(pawn(Owner).Weapon).Flashlight.bHasLight;
    if (TacShineCorona != none)
    {
     TacShineCorona.bHidden = !KFWeapon(pawn(Owner).Weapon).Flashlight.bHasLight;
    // TacShineCorona.bDynamicLight = KFWeapon(pawn(Owner).Weapon).Flashlight.bHasLight;
    }


   // Smush the beam, if we are humping up on a wall.
    if (BeamLength <= 90 && TacShine != none)
    {
        NewDrawScale = TacShine.DrawScale3D;
        NewDrawScale.y =  FMax(0.02,(BeamLength/90))* TacShine.Default.DrawScale;
        TacShine.SetDrawScale3D(NewDrawScale);
    }

  }
}

defaultproperties
{
     mMuzFlashClass=Class'KFMod.KFNormal3PMuzzFlash'
     mTracerClass=Class'KFMod.KFNewTracer'
     mTracerIntervalPrimary=0.110000
     mTracerIntervalSecondary=0.140000
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
}
