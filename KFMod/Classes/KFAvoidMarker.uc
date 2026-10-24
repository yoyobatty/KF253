class KFAvoidMarker extends AvoidMarker;  

//=============================================================================
// KFAvoidMarker, make it so the player fears this no matter what.    
//=============================================================================

function bool RelevantTo(Pawn P)
{
    // Specimens pay a frag no mind unless it says otherwise
    if ( KFMonster(P) != None && (Nade(Owner) == None || !Nade(Owner).bZedsFear) )
        return false;
    // Avoid if AI and either the pawn is the instigator (creator) or on a different team
    return (AIController(P.Controller) != None) && 
           (P == Instigator || 
            P.Controller.PlayerReplicationInfo == None || 
            P.Controller.PlayerReplicationInfo.Team == None || 
            P.Controller.PlayerReplicationInfo.Team.TeamIndex != TeamNum);
}

defaultproperties
{
    TeamNum=0
}