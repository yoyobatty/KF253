class DualiesAttachment extends KFWeaponAttachment;

var bool bIsOffHand,bMyFlashTurn;
var bool bBeamEnabled;
var DualiesAttachment brother;
var () Mesh BrotherMesh;

var Actor TacShine;

var  Effects TacShineCorona;
//var () class<actor> TacShineCoronaClass;    

simulated function name GetThirdPersonAnim()
{
	if( bMyFlashTurn )
		Return TPAnims[0];
	else Return TPAnims[1];
}

simulated function DoFlashEmitter()
{
	if(bIsOffHand)
		return;
	if(bMyFlashTurn)
		ActuallyFlash();
	else if(brother != None)
		brother.ActuallyFlash();
	bMyFlashTurn = !bMyFlashTurn;
}

simulated function ActuallyFlash()
{
    Super.DoFlashEmitter();
}

simulated function Destroyed()
{
	if ( TacShineCorona != None )
		TacShineCorona.Destroy();
	if ( TacShine != None )
		TacShine.Destroy();
	Super.Destroyed();
}

// Prevents tracers from spawning if player is using the flashlight function of the 9mm
simulated event ThirdPersonEffects()
{
	if( FiringMode==1 )
		return;
	Super.ThirdPersonEffects();
}

simulated function vector GetTracerStart()
{
    local Pawn p;

    p = Pawn(Owner);

    if ( (p != None) && p.IsFirstPerson() && p.Weapon != None )
    {
        return p.Weapon.GetEffectStart();
    }

    // 3rd person
    if ( mMuzFlash3rd != None && bMyFlashTurn)
        return mMuzFlash3rd.Location;
    else
	if ( brother != none && brother.mMuzFlash3rd != None && !bMyFlashTurn)
		return  brother.mMuzFlash3rd.Location;
	//   return Location;
}

simulated function UpdateTacBeam( float Dist )
{
	local vector Sc;
	local DualiesAttachment DA;

	if( Mesh==BrotherMesh )
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
		if( brother==None )
		{
			ForEach DynamicActors(Class'DualiesAttachment',DA)
			{
				if( DA!=Self && DA.Instigator==Instigator && DA.Mesh!=BrotherMesh )
				{
					brother = DA;
					Break;
				}
			}
		}
		if( brother!=None )
			brother.UpdateTacBeam(Dist);
		Return;
	}
	if( !bBeamEnabled )
	{
		ChangeIdleToSecondary();
		if (TacShine == none )
		{
			TacShine = Spawn(Class'Dualies'.Default.TacShineClass,Owner,,,);
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
	local DualiesAttachment DA;

	if( Mesh==BrotherMesh )
	{
		if( brother==None )
		{
			ForEach DynamicActors(Class'DualiesAttachment',DA)
			{
				if( DA!=Self && DA.Instigator==Instigator && DA.Mesh!=BrotherMesh )
				{
					brother = DA;
					Break;
				}
			}
		}
		if( brother!=None )
			brother.TacBeamGone();
		Return;
	}
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
     bMyFlashTurn=True
     BrotherMesh=SkeletalMesh'KFWeaponModels.9mm3P'
     mMuzFlashClass=Class'KFMod.KFNormal3PMuzzFlash'
     mTracerClass=Class'KFMod.KFNewTracer'
     mShellCaseEmitterClass=Class'KFMod.KFShellSpewer'
     TPAnims(0)="DualiesAttackRight"
     TPAnims(1)="DualiesAttackLeft"
     WeaponIdleMovementAnim="IdleDualies"
     SecondaryWeaponIdleMovementAnim="DoubleTacLightHold"
     Mesh=SkeletalMesh'KFWeaponModels.Single3P'
}
