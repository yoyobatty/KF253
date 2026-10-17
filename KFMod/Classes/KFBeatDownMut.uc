class KFBeatDownMut extends Mutator;

function bool CheckReplacement( Actor Other, out byte bSuperRelevant )
 {
  local KFRandomItemSpawn S;
  local int i;

  // Only pansies need ammunition.
  if ( Other.IsA('KFRandomAmmoSpawn') )
   return false;

  // Melee in this spawner's own list, which it then keeps (bForceDefault off).
  // Writing the class defaults instead carried the melee list over to every later map.
  S = KFRandomItemSpawn(Other);
  if ( S != None )
  {
   for ( i=0; i<ArrayCount(S.PickupClasses); i++ )
   {
    S.PickupClasses[i] = S.default.PickupClasses[i];
    S.PickupWeight[i] = S.default.PickupWeight[i];
   }
   S.PickupClasses[0] = class'KFMod.BatPickup';
   S.PickupClasses[1] = class'KFMod.AxePickup';
   S.PickupClasses[2] = class'KFMod.BatPickup';
   S.PickupClasses[3] = class'KFMod.BatPickup';
   S.PickupClasses[4] = class'KFMod.AxePickup';
   S.PickupClasses[5] = class'KFMod.BatPickup';
   S.PickupClasses[6] = class'KFMod.AxePickup';
   S.PickupClasses[7] = class'KFMod.BatPickup';
   S.bForceDefault = false;
  }

  return true; // false here would delete the spawner
 }

defaultproperties
{
     FriendlyName="BeatDown"
     Description="Melee Weapons only. For ye hard'uns."
}
