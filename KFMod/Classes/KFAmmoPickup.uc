class KFAmmoPickup extends UTAmmoPickup;

var() Material KFPickupImage;
<<<<<<< HEAD
var Bool ShowPickup ;
=======
var Bool ShowPickup;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
var Controller OtherPlayer;
var() localized string PickupMSG1;
var bool bfound;

<<<<<<< HEAD
function RespawnEffect()
{
// Get rid of the Yellow puff. It's not welcome here.

}

function float BotDesireability( pawn Bot )
{
  local Actor InvIt;
  local KFWeapon Weap;

  // Only make this desirable if bot can use it
  for(InvIt=Bot; InvIt!=none; InvIt=InvIt.Inventory)
  {
    Weap = KFWeapon(InvIt);

    if(Weap!=none && (Weap.AmmoClass[0]==self.class || Weap.AmmoClass[1]==self.class) )
      return super.BotDesireability(Bot);
  }
  return 0;

=======
function RespawnEffect(); // Get rid of the Yellow puff. It's not welcome here.

function bool CheckCanPickup( Pawn Other )
{
    local Actor InvIt;
    local KFWeapon Weap;

    // Can only pickup if we have a weapon that can use this ammo
    for(InvIt=Other; InvIt!=none; InvIt=InvIt.Inventory)
    {
        Weap = KFWeapon(InvIt);
        if(Weap!=none && (Weap.AmmoClass[0]==InventoryType || Weap.AmmoClass[1]==InventoryType) )
            return true;
    }
    return false;
}

// IF he's exceeding his max carry weight.
function Touch( actor Other )
{
    if ( KFHumanPawn(Other)!=none && !CheckCanPickup(KFHumanPawn(Other)) )
        Return;
    Super.Touch(Other);
}

function float BotDesireability(Pawn Bot)
{
	local Inventory inv;
	local Weapon W;
	local float Desire;
	local Ammunition M;
	
	if ( !CheckCanPickup(Bot) )
        return 0;
	for ( Inv=Bot.Inventory; Inv!=None; Inv=Inv.Inventory )
	{
		W = Weapon(Inv);
		if ( W != None )
		{
			Desire = W.DesireAmmo(InventoryType, false);
			if ( Desire != 0 )
				return Desire * MaxDesireability;
		}
	}
	M = Ammunition(Bot.FindInventoryType(InventoryType));
	if ( (M != None) && (M.AmmoAmount >= M.MaxAmmo) )
		return -1;
	return 0.25 * MaxDesireability;
}

auto state pickup
{
	// When touched by an actor.  Let's mod this to account for Weights. (Player can't pickup items)
	// IF he's exceeding his max carry weight.
    
	function Touch( actor Other )
	{
		if ( KFHumanPawn(Other)!=none && !CheckCanPickup(KFHumanPawn(Other)) )
			Return;
		Super.Touch(Other);
	}
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

State Sleeping
{
    ignores Touch;

    function bool ReadyToPickup(float MaxWait)
    {
        return ( bPredictRespawns && (LatentFloat < MaxWait) );
    }

    function StartSleeping() {}

    function BeginState()
    {
        local int i;
	if(bfound)
		destroy();

        NetUpdateTime = Level.TimeSeconds - 1;
        bHidden = true;
        for ( i=0; i<4; i++ )
            TeamOwner[i] = None;
    }

    function EndState()
    {
        NetUpdateTime = Level.TimeSeconds - 1;
        bHidden = false;
    }

DelayedSpawn:
    if ( Level.NetMode == NM_Standalone )
        Sleep(FMin(30, Level.Game.GameDifficulty * 8));
    else
        Sleep(30);
    Goto('Respawn');
Begin:
    Sleep( GetReSpawnTime() - RespawnEffectTime );
Respawn:
   for ( OtherPlayer=Level.ControllerList; OtherPlayer!=None; OtherPlayer=OtherPlayer.NextController)
   {
    if (OtherPlayer.pawn != none)
    {
     if(!FastTrace(self.Location,OtherPlayer.Pawn.Location))
     {
      RespawnEffect();
      Sleep(RespawnEffectTime);
      if (PickUpBase != None)
        PickUpBase.TurnOn();
      GotoState('Pickup');
     }
     else
         Sleep(rand(5) + 5);   // Crafty randomization...you'll never know when the next respawn attempt will be !  (5-10 seconds)
      Goto('Respawn');
    }
   }
}

function inventory SpawnCopy( pawn Other )
{
    local inventory i;
<<<<<<< HEAD
=======

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
    i=super.SpawnCopy(Other);
    ShowPickup = true;
    return i;
}

function PostRender(Canvas C)
{
<<<<<<< HEAD
  if (ShowPickup == true )
  {
    C.SetPos((C.SizeX - C.SizeY) / 2,0);
    C.DrawTile( KFPickupImage , C.SizeY, C.SizeY, 0.0, 0.0, 256, 256);
  }
=======
    if (ShowPickup)
    {
        C.SetPos((C.SizeX - C.SizeY) / 2,0);
        C.DrawTile( KFPickupImage , C.SizeY, C.SizeY, 0.0, 0.0, 256, 256);
    }
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

simulated function PostBeginPlay()
{
<<<<<<< HEAD
 AmmoAmount = (rand(0.5 * default.AmmoAmount) + default.AmmoAmount);
 default.PickupMSG1 = "Found ("$AmmoAmount$") ";
}



=======
    AmmoAmount = (rand(0.5 * default.AmmoAmount) + default.AmmoAmount);
    default.PickupMSG1 = "Found ("$AmmoAmount$") ";
}

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
static function string GetLocalString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2
    )
{
<<<<<<< HEAD
    return default.PickupMSG1$Default.PickupMessage;
=======
    return default.PickupMSG1$default.PickupMessage;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

defaultproperties
{
<<<<<<< HEAD
	bOnlyReplicateHidden=False
	RespawnTime=60.000000
	PickupSound=Sound'WoodBreakFX.GunCockNoise1'
	bDynamicLight=True
	Physics=PHYS_Falling
	AmbientGlow=40
	UV2Texture=FadeColor'PatchTex.Common.PickupOverlay'
	TransientSoundVolume=100.000000
	CollisionRadius=20.000000
	CollisionHeight=10.000000
=======
     bOnlyReplicateHidden=False
     RespawnTime=60.000000
     PickupSound=Sound'WoodBreakFX.GunCockNoise1'
     bDynamicLight=True
     Physics=PHYS_Falling
     AmbientGlow=40
     UV2Texture=FadeColor'PatchTex.Common.PickupOverlay'
     TransientSoundVolume=100.000000
     CollisionRadius=30.000000
     CollisionHeight=10.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
