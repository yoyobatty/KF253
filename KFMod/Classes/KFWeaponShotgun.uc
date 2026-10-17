class KFWeaponShotgun extends KFWeapon
    abstract;

exec function ReloadMeNow()
{
    if(!ReloadNowOrLater())
        return;

    Super.ReloadMeNow();
    ZoomLevel=0.0;
    if(PlayerController(Instigator.Controller)!=none)
      PlayerController(Instigator.Controller).StopZoom();
}

simulated function InsertBullet()
{
	if(AmmoAmount(0) > 0)
    	++ClipLeft;
    if( !bHoldToReload )
    {
        ClientForceKFAmmoUpdate(ClipLeft,AmmoAmount(0));
    }
}

function float GetAIRating()
{
	if (DiscourageReload()) //Swap to better if we can't reload fast
		return AIRating * 0.5;
	return AIRating;
}
// AI should avoid reloading if they have no ammo left or have recently been seen by an enemy, and carry another
// loaded gun to use instead (with none, loading shells beats drawing a blade, and a gun put away empty never reloads)
function bool DiscourageReload()
{
	local float   ReloadMulti;
	if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
		ReloadMulti = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetReloadSpeedModifier(self);
	return ReloadMulti <= 1.0 && ClipLeft < 1 && AIController(Instigator.Controller) != None && AIController(Instigator.Controller).Enemy != None
		&& (Level.TimeSeconds - AIController(Instigator.Controller).LastSeenTime < 0.5 || AmmoAmount(0) < 1) && OtherGunLoaded();
}

// Another gun carried with a round in it (not a blade, tool, grenade or rocket).
function bool OtherGunLoaded()
{
	local Inventory Inv;
	local KFWeapon W;

	for ( Inv=Instigator.Inventory; Inv!=None; Inv=Inv.Inventory )
	{
		W = KFWeapon(Inv);
		if ( W != None && W != self && !W.bMeleeWeapon && Frag(W) == None && LAW(W) == None && W.ClipLeft > 0 && W.HasAmmo() )
			return true;
	}
	return false;
}

function float SuggestAttackStyle()
{
	if ( (AIController(Instigator.Controller) != None)
		&& (AIController(Instigator.Controller).Skill < 3) )
		return 0.4;
    return 0.8;
}

defaultproperties
{
    bHoldToReload=True
    SideKick=400
}
