class WeaponLocker extends Actor
placeable;

//var Trigger OpenTrigger;
//var UseTrigger OnUseTrigger;
var float TriggerRadius, TriggerHeight;
var bool bActive, bOpen;
var int OpenRefs;

//var() bool bUseDefaultEquipment;    //Draw equipment from the list in KFGametype?
//var() array< string > LockerEquip;   //Usable for map-set equipment and also for
									//holding the shit from KFGameType otherwise.

//var array< class<GUIBuyable> > LockerClasses;    //Stuff the designers don't see
											//what slinky DOESN'T WANT YOU TO KNOW!!!

simulated event PostBeginPlay()
{

	local Trigger OpenTrigger;
    local UseTrigger OnUseTrigger;

    OpenTrigger = Spawn(class'Trigger');
	OpenTrigger.Event = Tag;
	OpenTrigger.TriggerType = TT_LivePlayerProximity;
	OpenTrigger.SetCollisionSize(TriggerRadius,TriggerHeight);

	OnUseTrigger = Spawn(class'UseTrigger');
	OnUseTrigger.Event = Tag;
	OnUseTrigger.SetCollisionSize(TriggerRadius,TriggerHeight);

	LoopAnim('Idle');

}

/*
function InitItems()
{

    local int i,a,counter;
	//local class<GUIBuyable> newitem;

	//log("Init items.",'KFMessage');

	//If we want to use the defaultequipment
	// TODO: Is this still needed now that equipment is specified in the gametype?
	if(bUseDefaultEquipment)
	{
	    LockerEquip.Remove(0,LockerEquip.Length);  //Just in case some retard mapper doesn't know what he's doing
	    for(i=0;i<KFGameType(Level.Game).MAX_BUYITEMS;i++)
	    {
	        LockerEquip.Insert(0,1);
	        LockerEquip[0] = KFGameType(Level.Game).BuylistItemNames[i];
	    }
	}

	for(a=0;a<LockerEquip.Length;a++)
	{
	    newitem = class<GUIBuyable>(DynamicLoadObject(LockerEquip[a],class'Class'));
	    if(newitem == None)
	        continue;
		LockerClasses[counter] = newitem;
		counter++;
	}

}
*/
event Trigger( Actor Other, Pawn EventInstigator )
{
   //if(EventInstigator == None)
	   //log("EVENTINSTIGATOR IS NONE");
   if(KFHumanPawn(EventInstigator) == None)
   {
	   //log("TRIGGER:  NOT HUMAN PAWN"@EventInstigator.Class);
	   return;
   }
   if(UseTrigger(Other) != None && EventInstigator.Controller.IsA('KFPlayerController') && bOpen)
   {
       KFPlayerController(EventInstigator.Controller).ShowBuyMenu(string(Tag),KFHumanPawn(EventInstigator).MaxCarryWeight);
	   return;
   } else if(bActive)
   {
	  // log("OPENING");
	   SetOpen(true);
	    //if ( KFHumanPawn(Other) != none && bOpen == true)
	    //TODO: Find safe way to get this onto client screen
	    if(PlayerController(EventInstigator.Controller)!=none)
           PlayerController(EventInstigator.Controller).ClientMessage("Press 'USE' key to TRADE", 'KFCriticalEvent');

   }
   // TODO: is there a time when they shouldn't be allowed to shop?
   //if(KFInvasionBot(EventInstigator.Controller)!=none)
   //{
   //  KFInvasionBot(EventInstigator.Controller).DoTrading();
   //}
}

event UnTrigger(Actor Other,Pawn EventInstigator)
{
   if(KFHumanPawn(EventInstigator) == None || !bActive)
	   return;
   //log("CLOSING");
   SetOpen(false);
}

function SetOpen(bool bToOpen)
{
	switch(bToOpen)
	{
		case false:
			 OpenRefs--;
			 //log("Closing. OpenRefs"@OpenRefs,'KFMessage');
			 if(bOpen && OpenRefs == 0)
			 {
				 LoopAnim('Idle');
				 //FreezeAnimAt(0.65);
				 bOpen=false;
			 }
			 break;
		case true:
			 OpenRefs++;
			 //log("Opening.  OpenRefs"@OpenRefs,'KFMessage');
			if(!bOpen)
			 {
				 PlayAnim('Gesture');
				  //FreezeAnimAt(0.65);
				 bOpen=true;
			 }
			 break;
	}
}

defaultproperties
{
     TriggerRadius=150.000000
     TriggerHeight=100.000000
     bActive=True
     DrawType=DT_Mesh
     bReplicateAnimations=True
     Mesh=SkeletalMesh'KFMapObjects.Trader'
     DrawScale=0.500000
     CollisionRadius=15.000000
     CollisionHeight=50.000000
     bCollideActors=True
     bCollideWorld=True
     bBlockActors=True
     bBlockKarma=True
}
