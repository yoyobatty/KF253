class CashPickup extends Pickup;

var () int CashAmount;
var bool bDroppedCash;  // if true, its been dropped. dont randomize the amount
var float TossTimer;

//=============================================================================
// Pickup state: this inventory item is sitting on the ground.
auto state Pickup
{
	function bool ReadyToPickup(float MaxWait)
	{
		return true;
	}

	/* ValidTouch()
	 Validate touch (if valid return true to let other pick me up and trigger event).
	*/
	function bool ValidTouch( actor Other )
	{
		// make sure its a live player
		if ( (Pawn(Other) == None) || !Pawn(Other).bCanPickupInventory || (Pawn(Other).DrivenVehicle == None && Pawn(Other).Controller == None)  )
			return false;

		// Disallow instant pick up.
		if( Instigator==Other && TossTimer>Level.TimeSeconds )
			Return False;

		// make sure not touching through wall
		if ( !FastTrace(Other.Location, Location) )
			return false;

		// make sure game will let player pick me up
		if(Level.Game != none && Level.Game.PickupQuery(Pawn(Other), self) )
		{
			TriggerEvent(Event, self, Pawn(Other));
			return true;
		}
		return false;
	}

	// When touched by an actor.
	function Touch( actor Other )
	{
		// If touched by a player pawn, let him pick this up.
		if( ValidTouch(Other) )
		{
			if (KFHumanPawn(Other) != none)
			{
				// You all love the mental-mad typecasting XD

				if (!bDroppedCash)
					CashAmount = (rand(0.5 * default.CashAmount) + default.CashAmount) * (KFGameReplicationInfo(Level.GRI).GameDiff  * 0.5) ;

				if (KFHumanPawn(Other).Controller.PlayerReplicationInfo != none)
				{
					KFHumanPawn(Other).Controller.PlayerReplicationInfo.Score += CashAmount;
					KFHumanPawn(Other).Controller.PlayerReplicationInfo.Team.Score += CashAmount;
				}
			}
			AnnouncePickup(Pawn(Other));
			SetRespawn();
		}
	}

	// Make sure no pawn already touching (while touch was disabled in sleep).
	function CheckTouching()
	{
		local Pawn P;

		ForEach TouchingActors(class'Pawn', P)
			Touch(P);
	}

	function Timer()
	{
		if ( bDropped )
			GotoState('FadeOut');
	}

	function BeginState()
	{
		TossTimer = Level.TimeSeconds+1;
		UntriggerEvent(Event, self, None);
		if ( bDropped )
		{
			AddToNavigation();
			SetTimer(8, false);
		}
	}

	function EndState()
	{
		if ( bDropped )
			RemoveFromNavigation();
	}

Begin:
	CheckTouching();
}

function AnnouncePickup( Pawn Receiver )
{
	Receiver.MakeNoise(0.2);
	if( Receiver.Controller!=None )
	{
		if( PlayerController(Receiver.Controller)!=None )
			PlayerController(Receiver.Controller).ReceiveLocalizedMessage(MessageClass,CashAmount,,,Class);
		else if ( Receiver.Controller.MoveTarget==Self )
		{
			if ( MyMarker!=None )
			{
				Receiver.Controller.MoveTarget = MyMarker;
				Receiver.Anchor = MyMarker;
				Receiver.Controller.MoveTimer = 0.5;
			}
			else Receiver.Controller.MoveTimer = -1.0;
		}
	}
	PlaySound( PickupSound,SLOT_Interact );
}
static function string GetLocalString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2
	)
{
	return "Found ("$Switch$") Pounds.";
}

defaultproperties
{
     CashAmount=25
     RespawnTime=60.000000
     PickupMessage="You found a wad of cash"
     PickupSound=Sound'PatchSounds.SellItem'
     DrawType=DT_StaticMesh
     StaticMesh=StaticMesh'22Patch.BankNote'
     Physics=PHYS_Falling
     DrawScale=0.400000
     AmbientGlow=40
     UV2Texture=FadeColor'PatchTex.Common.PickupOverlay'
     TransientSoundVolume=150.000000
     CollisionRadius=20.000000
     CollisionHeight=5.000000
     MessageClass=Class'UnrealGame.PickupMessagePlus'
}
