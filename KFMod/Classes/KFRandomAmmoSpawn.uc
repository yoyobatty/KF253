// Spawn Random items / weapons in to keep the envirments searchable and dynamic :)
// Modded from WildcardBase to allow for all pickup classtypes, not just tournament ones.

class KFRandomAmmoSpawn extends KFRandomSpawn;

/*
var() class<KFAmmoPickup> PickupClasses[8];
var() bool bSequential;
var int NumClasses;
var int CurrentClass;

simulated function PostBeginPlay()
{
    local int i;

    if ( Role == ROLE_Authority )
    {
        NumClasses = 0;
        while (NumClasses < ArrayCount(PickupClasses) && PickupClasses[NumClasses] != None)
            NumClasses++;

        if (bSequential)
            CurrentClass = 0;
        else
            CurrentClass = Rand(NumClasses);

        PowerUp = PickupClasses[CurrentClass];
    }
    if ( Level.NetMode != NM_DedicatedServer )
    {
        for ( i=0; i< NumClasses; i++ )
            PickupClasses[i].static.StaticPrecache(Level);
    }
    Super.PostBeginPlay();
    SetLocation(Location + vect(0,0,-1)); // adjust because reduced drawscale
}

function TurnOn()
{

    if (bSequential)
        CurrentClass = (CurrentClass+1)%NumClasses;
    else
        CurrentClass = Rand(NumClasses);

    PowerUp = PickupClasses[CurrentClass];

    if( myPickup != None )
        myPickup = myPickup.Transmogrify(PowerUp);
}

function SpawnPickup()
{
   local Rotator AdjustedRotation;

   AdjustedRotation = self.Rotation;
   AdjustedRotation.Pitch = rand(10000) + 1000;

    if( PowerUp == None )
        return;

    myPickUp = Spawn(PowerUp,,,Location + SpawnHeight * vect(0,0,1), AdjustedRotation);

    if (myPickUp != None)
    {
        myPickUp.PickUpBase = self;
        myPickup.Event = event;
    }

    if (myMarker != None)
    {
        myMarker.markedItem = myPickUp;
        myMarker.ExtraCost = ExtraPathCost;
        if (myPickUp != None)
            myPickup.MyMarker = MyMarker;
    }
    //else log("No marker for "$self);
}
*/

defaultproperties
{
     PickupClasses(0)=Class'KFMod.SingleAmmoPickup'
     PickupClasses(1)=Class'KFMod.ShotgunAmmoPickup'
     PickupClasses(2)=Class'KFMod.BullpupAmmoPickup'
     PickupClasses(3)=Class'KFMod.DeagleAmmoPickup'
     PickupClasses(4)=Class'KFMod.WinchesterAmmoPickup'
     PickupClasses(5)=Class'KFMod.CrossbowAmmoPickup'
     PickupClasses(6)=Class'KFMod.LAWAmmoPickup'
     PickupClasses(7)=Class'KFMod.DBShotgunAmmoPickup'
     PickupClasses(8)=Class'KFMod.FragAmmoPickup'
     PickupClasses(9)=Class'KFMod.FTAmmoPickup'
     PickupClasses(10)=Class'KFMod.CashPickup'
     PickupWeight(0)=3
     PickupWeight(1)=3
     PickupWeight(2)=3
     PickupWeight(3)=3
     PickupWeight(4)=3
     PickupWeight(8)=3
     PickupWeight(9)=3
     Texture=Texture'PatchTex.Common.AmmoSpawnIcon'
}
