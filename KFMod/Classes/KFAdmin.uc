class KFAdmin extends Admin;

exec function Summon( string ClassName )
{
	local class<actor> NewClass;
	local vector SpawnLoc;

    NewClass = class<actor>( DynamicLoadObject( ClassName, class'Class' ) );
    if( NewClass!=None )
    {
        if ( Pawn != None )
            SpawnLoc = Pawn.Location;
        else
            SpawnLoc = Location;
        Spawn( NewClass,,,SpawnLoc + 72 * Vector(Rotation) + vect(0,0,1) * 15 );
    }   	
}

//================================================
//Put Target In God Mode
exec function GodOn(string target){
    local Controller C;
    local int namematch;
      	
    if (target == "all") {
        for( C = Level.ControllerList; C != None; C = C.nextController ) {
            if( C.IsA('PlayerController') || C.IsA('xBot')) {
                C.bGodMode = true;
                PlayerController(C).ClientMessage("You are in god mode");
                C.Pawn.PlayTeleportEffect(true, true);
            }
        }
        ServerSay("Everyone is in God mode");
        return;
    } else if (target == ""){
        target = PlayerReplicationInfo.PlayerName;
        log(target);
        for( C = Level.ControllerList; C != None; C = C.nextController ) {
            namematch = InStr( Caps(C.PlayerReplicationInfo.PlayerName), Caps(target)); 
            if (namematch >=0) {
                C.bGodMode = true;
                PlayerController(C).ClientMessage("You are in god mode");
                C.Pawn.PlayTeleportEffect(true, true);
                return;
            }
        }
        ServerSay(target$ " is in God mode");
        return;
    } else {
        for( C = Level.ControllerList; C != None; C = C.nextController ) {
            if( C.IsA('PlayerController') || C.IsA('xBot')) {
                namematch = InStr( Caps(C.PlayerReplicationInfo.PlayerName), Caps(target)); 
                if (namematch >=0) { 
                    C.bGodMode = true;
                    PlayerController(C).ClientMessage("You are in god mode");
                    C.Pawn.PlayTeleportEffect(true, true);
                    ServerSay(C.PlayerReplicationInfo.PlayerName$ " is in God mode");
                }
            }
        }
    }
}

//Take Target Out Of God Mode
exec function GodOff(string target){
    local Controller C;
    local int namematch;
    
    if (target == "all") {
        for( C = Level.ControllerList; C != None; C = C.nextController ) {
            if( C.IsA('PlayerController') || C.IsA('xBot')) {
                C.bGodMode = false;
                PlayerController(C).ClientMessage("You are no longer in god mode");
                C.Pawn.PlayTeleportEffect(true, true);
            }
        }
        ServerSay("All Players are out of God Mode");
        return;
    } else if (target == ""){
        target = PlayerReplicationInfo.PlayerName;
        for( C = Level.ControllerList; C != None; C = C.nextController ) {
            namematch = InStr( Caps(C.PlayerReplicationInfo.PlayerName), Caps(target)); 
            if (namematch >=0) {
                C.bGodMode = false;
                PlayerController(C).ClientMessage("You are no longer in god mode");
                C.Pawn.PlayTeleportEffect(true, true);
            }
        }
        ServerSay(target$ " is out of God mode");
        return;
    } else {          
        for( C = Level.ControllerList; C != None; C = C.nextController ) {
            if( C.IsA('PlayerController') || C.IsA('xBot')) {
                namematch = InStr( Caps(C.PlayerReplicationInfo.PlayerName), Caps(target)); 
                if (namematch >=0) { 
                    if ( C.bGodMode == false){
                        return;
                    }
                    C.bGodMode = false;
                    PlayerController(C).ClientMessage("You are no longer in god mode");
                    ServerSay(C.PlayerReplicationInfo.PlayerName$ " is out of God Mode");
                    C.Pawn.PlayTeleportEffect(true, true);
                }
            }
        }
    }
}



defaultproperties
{
}