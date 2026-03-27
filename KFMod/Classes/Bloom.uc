//-----------------------------------------------------------
// Bloom Mutator
// Creates Interaction and handles
// rendering of the bloom-texture
//-----------------------------------------------------------
#exec OBJ LOAD FILE=DreamTex.utx
class Bloom extends Mutator;
 
var bool bAffectSpectators; // If this is set to true, an interaction will be created for spectators
var bool bAffectPlayers; // If this is set to true, an interaction will be created for players
var bool bHasInteraction;
var ScriptedTexture st;
var Actor bMesh;
var BloomInteraction BI;
 
function PreBeginPlay()
{
    //Log("ICU Mutator Started"); // Always comment out your logs unless they're errors
}
 
simulated function Tick(float DeltaTime)
{
    local PlayerController PC;
 
 
    // If the player has an interaction already, exit function.
    if (bHasInteraction)
        Return;
    PC = Level.GetLocalPlayerController();
 
    // Run a check to see whether this mutator should create an interaction for the player
    if ( PC != None && ((PC.PlayerReplicationInfo.bIsSpectator && bAffectSpectators) || (bAffectPlayers && !PC.PlayerReplicationInfo.bIsSpectator)) )
    {
        st=ScriptedTexture(Level.ObjectPool.AllocateObject( class'ScriptedTexture' ) );
        st.Client=self;
        //change this for different 'bloom-map' qualities
        st.SetSize(256,256);
 
<<<<<<< HEAD
        PC.Player.InteractionMaster.AddInteraction("Dreamland.BloomInteraction", PC.Player); // Create the interaction
=======
        PC.Player.InteractionMaster.AddInteraction("KFMod.BloomInteraction", PC.Player); // Create the interaction
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
        bHasInteraction = True; // Set the variable so this lot isn't called again
        bMesh=Spawn(class'BloomMesh');
        //A FinalBlend with FB_Brighten
        FinalBlend(bMesh.Skins[0]).Material=st;
 
        BloomInteraction(PC.Player.LocalInteractions[PC.Player.LocalInteractions.Length-1]).St=st;
        BloomInteraction(PC.Player.LocalInteractions[PC.Player.LocalInteractions.Length-1]).BMesh=bMesh;
        BI=BloomInteraction(PC.Player.LocalInteractions[PC.Player.LocalInteractions.Length-1]);
    }
}
 
event RenderTexture(ScriptedTexture Tex)
{
    local PlayerController PC;
    local vector camloc;
    local Rotator camrot;
    local Actor camactor;
    local Color tAlpha;
 
 
 
    talpha.R=238;
    talpha.G=238;
    talpha.B=238;
 
 
    PC = Level.GetLocalPlayerController();
    PC.PlayerCalcView(camactor,camloc,camrot);
    //log("RenderEvent");
 
    Tex.DrawPortal(0,0,Tex.USize,Tex.VSize,camactor,camloc,camrot,PC.DefaultFOV,false);
    //Lightfilter is a FinalBlend with FB_Darken
    //The Light-threshold is controlled via talpha;
    //Colored Bloom should be possible with unequal RGB values (untested)
    Tex.DrawTile(0,0,Tex.USize,Tex.VSize,0,0,16,16,FinalBlend'DreamTex.Lightfilter',talpha);
 
}

defaultproperties
{
<<<<<<< HEAD
	bAffectSpectators=True
	bAffectPlayers=True
	GroupName="KF"
	FriendlyName="Bloom"
	Description="Adds Bloom to the gameplay."
	bAlwaysRelevant=True
	RemoteRole=ROLE_SimulatedProxy
=======
     bAffectSpectators=True
     bAffectPlayers=True
     GroupName="KF-Bloom"
     FriendlyName="Bloom"
     Description="Adds Bloom to the gameplay."
     bAlwaysRelevant=True
     RemoteRole=ROLE_SimulatedProxy
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
