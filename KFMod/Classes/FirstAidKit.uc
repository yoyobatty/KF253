//====================================================================
//  First Aid Kit//
//====================================================================

class FirstAidKit extends MiniHealthPack;

var() localized string  Message;

static function string GetLocalString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2
    )
{
    return Default.PickupMessage;
}

function RespawnEffect()
{
// Get rid of the Yellow puff. It's not welcome here.
}

event float BotDesireability(Pawn Bot)
{
    if (Bot.Health >= Bot.HealthMax)
        return 0;
    return Super.BotDesireability(Bot);
}

auto state Pickup
{
    function Touch( actor Other )
    {
        local Pawn P;
        local PlayerController PC;

        P = Pawn(Other);
        if(P!=none)
        {
            PC = PlayerController(P.Controller);
            if ( ValidTouch(Other) && (P.Health < P.HealthMax) && KFHumanPawn(P).HealthToGive == 0 )
            {
                // Make sure he's wounded, and not already being affected by a kit.
                if ( P.GiveHealth(HealingAmount, GetHealMax(P)) || (bSuperHeal && !Level.Game.bTeamGame) )
                {
                    AnnouncePickup(P);
                    SetRespawn();
                }
            }
            else
            {
                if (P.Health >= P.HealthMax && PC!=none)
                    PC.ClientMessage("You are already at full health.", 'CriticalEvent');
            }
        }
    }
}


function AnnouncePickup( Pawn Receiver )
{
    Receiver.HandlePickup(self);
    PlaySound( PickupSound,SLOT_Interact,2*100,,100 );
}

defaultproperties
{
     HealingAmount=50
     bSuperHeal=False
     bOnlyReplicateHidden=False
     RespawnTime=60.000000
     PickupMessage="You used a First Aid Kit"
     PickupSound=Sound'KFPlayerSound.MedkitUse'
     StaticMesh=StaticMesh'KillingFloorStatics.FirstAidKit'
     Physics=PHYS_Falling
     DrawScale=1.000000
     AmbientGlow=40
     UV2Texture=FadeColor'PatchTex.Common.PickupOverlay'
     ScaleGlow=0.000000
     CollisionRadius=28.000000
     CollisionHeight=20.000000
     RotationRate=(Yaw=0)
}
