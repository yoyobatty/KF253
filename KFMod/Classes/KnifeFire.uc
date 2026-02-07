// Knife Fire //

class KnifeFire extends KFMeleeFire;

var() array<name> FireAnims;
var name LastFireAnim;


function PlayFiring()
{
     Super.PlayFiring();
}

simulated event ModeDoFire()
{
     local int AnimToPlay;

     if(FireAnims.length > 0)
     {

         AnimToPlay = rand(FireAnims.length);

          LastFireAnim = FireAnim;
          FireAnim = FireAnims[AnimToPlay];
     
          damageConst = default.damageConst;
          DamagedelayMin = default.DamagedelayMin;

           //  3  and 2 should never play consecutively. it looks screwey.
            //  3 should never repeat directly after itself. buffer with 1

          if(LastFireAnim == FireAnims[1] && FireAnim == FireAnims[2] ||
           LastFireAnim == FireAnims[2] && FireAnim == FireAnims[1] ||
            LastFireAnim == FireAnims[2] && FireAnim == FireAnims[2])
            FireAnim = FireAnims[0];

           if(FireAnim == FireAnims[2])
            {
              damageConst *= 1.5;
              DamagedelayMin = 0.25;
            }
            
     }

  Super(KFMeleeFire).ModeDoFire();

}

defaultproperties
{
     WeaponRange=65.000000
     FireAnims(0)="Fire"
     FireAnims(1)="Fire2"
     FireAnims(2)="fire3"
     damageConst=25
     maxAdditionalDamage=10
     DamagedelayMin=0.100000
     DamagedelayMax=0.300000
     hitDamageClass=Class'KFMod.DamTypeKnife'
     WideDamageMinHitAngle=0.750000
     UpSwingRot=(Pitch=20,Yaw=10)
     UpSwingTime=0.200000
     DownSwingRot=(Pitch=-30,Yaw=-20)
     DownSwingTime=0.100000
     FireRate=0.600000
     BotRefireRate=0.900000
}
