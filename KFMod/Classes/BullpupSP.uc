//Long range Bullpup for use in the Single player mission...
class BullpupSP extends Bullpup;


simulated function WeaponTick(float deltaTime)
{
	super(KFWeapon).WeaponTick(deltaTime);

	if( Level.NetMode==NM_DedicatedServer )
		Return;

	if ( bAimingRifle && Instigator!=None && Instigator.Physics==PHYS_Falling )
	{
		FireMode[1].bIsFiring = False;
		ServerSetAiming(False);
		PlayAnimZoom(False);
	}
	else if( bZooming && ZoomingInTimer<Level.TimeSeconds )
	{
		bZooming = False;
		ZoomLevel = 0.30;
		if( PlayerController(Instigator.Controller)!=None )
			PlayerController(Instigator.Controller).DesiredFOV = FClamp(50.0 - (ZoomLevel * 88.0), 1, 170);
	}
}

// Draw the Winchester, but zoom in the FOV so you can see down the barrel, too.
simulated event RenderOverlays(Canvas Canvas)
{
	local PlayerController PC;

	PC = PlayerController(KFPawn(Owner).Controller);

	if(PC == None)
		return;

	LastFOV = PC.DesiredFOV;

	if (PC.DesiredFOV == PC.DefaultFOV || (Level.bClassicView && PC.DesiredFOV == 90))
	{
		Super.RenderOverlays(Canvas);
		zoomed=false;
		//bAimingRifle = false;
	}
	else
	{
		SetZoomBlendColor(Canvas);
		SetLocation( Instigator.Location + Instigator.CalcDrawOffset(self) );
		SetRotation( Instigator.GetViewRotation() );
		Canvas.DrawActor(self, false);
		zoomed = true;
	}
}

defaultproperties
{
<<<<<<< HEAD
	UpKick=50
	FireModeClass(0)=Class'KFMod.BullpupFireSP'
=======
     UpKick=50
     FireModeClass(0)=Class'KFMod.BullpupFireSP'
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
