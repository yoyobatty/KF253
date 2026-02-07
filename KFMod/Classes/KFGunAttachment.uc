class KFGunAttachment extends MinigunAttachment;


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

        DoFlashEmitter();

        if ( (mShellCaseEmitter == None) && (Level.DetailMode != DM_Low) && !Level.bDropDetail )
        {
            mShellCaseEmitter = Spawn(mShellCaseEmitterClass);
            if ( mShellCaseEmitter != None )
                AttachToBone(mShellCaseEmitter, 'shell');
        }
        if (mShellCaseEmitter != None)
            mShellCaseEmitter.mStartParticles++;
    }
    else
    {
        GotoState('');
    }

    Super(xWeaponAttachment).ThirdPersonEffects();
}

simulated function DoFlashEmitter()
{
    if (mMuzFlash3rd == None)
    {
        mMuzFlash3rd = Spawn(mMuzFlashClass);
        AttachToBone(mMuzFlash3rd, 'tip');
    }
    if(mMuzFlash3rd != None)
        mMuzFlash3rd.SpawnParticle(1);
}

defaultproperties
{
}
