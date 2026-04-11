class KFWeaponShotgun extends KFWeapon
    abstract;

exec function ReloadMeNow()
{
    if(!AllowReload())
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
// AI should avoid reloading if they have no ammo left or have recently been seen by an enemy
function bool DiscourageReload()
{
	local float   ReloadMulti;
	if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
		ReloadMulti = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetReloadSpeedModifier(self);
	return ReloadMulti <= 1.0 && ClipLeft < 1 && AIController(Instigator.Controller).Enemy != None && (Level.TimeSeconds - AIController(Instigator.Controller).LastSeenTime < 0.5 || AmmoAmount(0) < 1);
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
