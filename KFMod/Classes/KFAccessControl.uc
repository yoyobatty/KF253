class KFAccessControl extends AccessControl;

<<<<<<< HEAD

=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
function bool IsLateJoiner(PlayerController C)
{

    if( C!= none && C.Player !=none && (Level.NetMode != NM_Standalone)&&
     !C.PlayerReplicationInfo.bAdmin &&
     KFGameType(Level.Game).bNoLateJoiners &&
     Level.Game.GameReplicationInfo.bMatchHasBegun )
    {
        // TODO implement a way for admins to specify the reason
        C.ClientNetworkMessage("FC_NoLateJoiners",DefaultKickReason);
        if (C.Pawn != None)
            C.Pawn.Destroy();
        if (C != None)
            C.Destroy();
        return true;
    }
    return false;
}

defaultproperties
{
<<<<<<< HEAD
=======
    AdminClass=class'KFMod.KFAdmin'
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
