class KFAutoGunBase extends ASVehicle_Sentinel_Floor_Base;

auto state Sleeping
{
    simulated event AnimEnd( int Channel )
    {
        if ( KFAutoGun(Owner).bActive )
            GotoState('Opening');
        else
            PlayAnim('IdleClosed', 4, 0.0);
    }

    simulated function BeginState()
    {
        AnimEnd( 0 );
    }
}

defaultproperties
{
}
