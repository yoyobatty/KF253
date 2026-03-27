class CrossbowAttachment extends KFMeleeAttachment;


// All this to kill one accessed none :(
// TODO: That said, there looks to be a lot of baggage to lose here
//       if there's time to investigate later.
//       I suspect using xWeaponAttachment in place of MinigunAttachment
//       will go far.

/*
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
					Spawn(class'HitEffect'.static.GetHitEffect(mHitActor, mHitLocation, mHitNormal),,, mHitLocation, Rotator(mHitNormal));
				else
					Spawn(class'XEffects.ExploWallHit',,, mHitLocation, Rotator(mHitNormal));
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

    super(xWeaponAttachment).ThirdPersonEffects();
}
*/

defaultproperties
{
     TPAnims(0)="CrossbowFire"
     WeaponIdleMovementAnim="CrossbowIdle"
     Mesh=SkeletalMesh'KFWeaponModels.Xbow3P'
}
