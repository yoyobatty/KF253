class KFWeaponShotgun extends KFWeapon
    abstract;

<<<<<<< HEAD


=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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
<<<<<<< HEAD
    ++ClipLeft;
}

//I'll just copy and paste the damn things if you want them
//so badly.
// AI Interface
function float GetAIRating()
{
	local Bot B;
	local float EnemyDist;
	local vector EnemyDir;

	B = Bot(Instigator.Controller);
	if ( B == None )
		return AIRating;

	if ( (B.Target != None) && (Pawn(B.Target) == None) && (VSize(B.Target.Location - Instigator.Location) < 1250) )
		return 0.9;

	if ( B.Enemy == None )
	{
		if ( (B.Target != None) && VSize(B.Target.Location - B.Pawn.Location) > 3500 )
			return 0.2;
		return AIRating;
	}

	EnemyDir = B.Enemy.Location - Instigator.Location;
	EnemyDist = VSize(EnemyDir);
	if ( EnemyDist > 750 )
	{
		if ( EnemyDist > 2000 )
		{
			if ( EnemyDist > 3500 )
				return 0.2;
			return (AIRating - 0.3);
		}
		if ( EnemyDir.Z < -0.5 * EnemyDist )
			return (AIRating - 0.3);
	}
	else if ( (B.Enemy.Weapon != None) && B.Enemy.Weapon.bMeleeWeapon )
		return (AIRating + 0.35);
	else if ( EnemyDist < 400 )
		return (AIRating + 0.2);
	return FMax(AIRating + 0.2 - (EnemyDist - 400) * 0.0008, 0.2);
=======
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
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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
<<<<<<< HEAD
	bHoldToReload=True
=======
    bHoldToReload=True
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
