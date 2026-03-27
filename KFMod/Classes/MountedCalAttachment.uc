class MountedCalAttachment extends MinigunAttachment;


simulated event ThirdPersonEffects()
{
    local PlayerController PC;
    
    if ( (Level.NetMode == NM_DedicatedServer) || (Instigator == None) )
        return; 

    if ( FlashCount > 0 )
    {
        PC = Level.GetLocalPlayerController();
        if ( OldSpawnHitCount != SpawnHitCount )
        {
            OldSpawnHitCount = SpawnHitCount;
            GetHitInfo();
            PC = Level.GetLocalPlayerController();
            if ( (Instigator.Controller == PC) || (VSize(PC.ViewTarget.Location - mHitLocation) < 2000) )
            {
                if ( FiringMode == 0 )
                    Spawn(class'KFHitEffect',,, mHitLocation, rotator(mHitLocation - (Instigator.Location + Instigator.EyePosition())));
                else
                    Spawn(class'KFHitEffect',,, mHitLocation, rotator(mHitLocation - (Instigator.Location + Instigator.EyePosition())));
                CheckForSplash();
            }
        }
        if ( (Level.TimeSeconds - LastRenderTime > 0.2) && (Instigator.Controller != PC) )
            return;

        WeaponLight();

        if (FiringMode == 0)
        {
            mTracerInterval = mTracerIntervalPrimary;
            mRollInc = 65536.f*3.f;
        }
        else
        {
            mTracerInterval = mTracerIntervalSecondary;
            mRollInc = 65536.f;
        } 

        if ( Level.bDropDetail || Level.DetailMode == DM_Low )
            mTracerInterval *= 2.0;

        UpdateRollTime(true);
        
        UpdateTracer();

        if (mMuzFlash3rd == None)
        {
            mMuzFlash3rd = Spawn(mMuzFlashClass);
            AttachToBone(mMuzFlash3rd, 'tip');
        }
        if (mMuzFlash3rd != None)
        {
            mMuzFlash3rd.SpawnParticle(1);
        }

        if ( (mShellCaseEmitter == None) && (Level.DetailMode != DM_Low) && !Level.bDropDetail )
        {
            mShellCaseEmitter = Spawn(mShellCaseEmitterClass);
            if ( mShellCaseEmitter != None )
              //  AttachToBone(mShellCaseEmitter, 'shell');
        }
       // if (mShellCaseEmitter != None)
         //   mShellCaseEmitter.mStartParticles++;
    }
    else
    {
        GotoState('');
    }

    Super.ThirdPersonEffects();
}

defaultproperties
{
<<<<<<< HEAD
	mShellEmitterOffset=(X=28.000000,Y=-20.000000,Z=92.000000)
	LightBrightness=0.000000
	LightRadius=0.000000
	bDynamicLight=True
	Mesh=SkeletalMesh'KFVehicleModels.50CalFrame'
=======
     mShellEmitterOffset=(X=28.000000,Y=-20.000000,Z=92.000000)
     LightBrightness=0.000000
     LightRadius=0.000000
     bDynamicLight=True
     Mesh=SkeletalMesh'KFVehicleModels.50CalFrame'
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
