class KFMeleeProxy extends Actor
	placeable;

var float ProxySize;
Var Vector RangeVec;
var() class<damageType> MyDamageType;
var() int mydamage;
var vector HitLocationP;
var()  Pawn MyPawn;
Var KFMeleeGun	MyWeapon;
Var Actor AlreadyHit[6];
var Float ViewVec;
var vector TempVec;
var() float n,maxtime;
var() vector ImpactShakeRotMag;           // how far to rot view
var() vector ImpactShakeRotRate;          // how fast to rot view
var() float  ImpactShakeRotTime;          // how much time to rot the instigator's view
var() vector ImpactShakeOffsetMag;        // max view offset vertically
var() vector ImpactShakeOffsetRate;       // how fast to offset view vertically
var() float  ImpactShakeOffsetTime;       // how much time to offset view

simulated function postbeginplay()
{
	setrelativeRotation(MyPawn.GetViewRotation());
	TempVec = vect( 1 , 0 , 0) * ViewVec;
	setDrawScale(ProxySize);
	SetTimer(0.01,True);
}

Simulated Function Timer()
{
	Tempvec.z -= 10;
	Tempvec.x -= 3;
	n+= 0.05;
	setrelativeRotation(MyPawn.GetViewRotation());
	setrelativelocation(TempVec);

	if(n >= maxtime)
	{
		//log("Away I go and hopefully I'm the server");
		SetBase(None);
		destroy();
	}
}

Simulated Event Touch(Actor other)
{
	local vector dir;
	local vector AdjustedMomentum;
	local PlayerController P;
	local int i;
	
	 // make sure not touching through wall

if(Other==None ||
 Other == MyPawn ||
 !Other.IsA('Pawn') ||
 !FastTrace(Other.Location, Location) )
            	return;


			for(i = 0; i < 6; i++)
				if(AlreadyHit[i]==Other)
					return;


if( (other != self) && (other.Role == ROLE_Authority) && (!other.IsA('FluidSurfaceInfo')) && (other != MyPawn))
		{
			dir = other.Location;
			/*dist = FMax(1,VSize(dir));
			dir = dir/dist;*/

			dir.Z -= 50;

			AdjustedMomentum = Vector(MyPawn.GetViewRotation());
			//AdjustedMomentum.Z += 25;

			if(Other.IsA('KFMonster') && KFMonster(Other).Health > 0)
			{
				KFMonster(other).bRanged=True;
				other.TakeDamage
				(
					mydamage,
					MyPawn,
					HitLocationP,
					Vector(MyPawn.GetViewRotation()) * 50000,
					MyDamageType
				);
              	 	  	  Spawn(class'KFMeleeHitEffect',,,HitLocationP, rotator(other.Location - (MyPawn.Location + MyPawn.EyePosition())));
            	  		   MyWeapon.playServerSound();

			}

                        // Better stun balance.
                        // The specimens health %age is compared to the damage output of the melee weapon in relative terms
                        // weapons like the axe , due to their consistently high damage output, have a greater chance of staggering
                        // foes, no matter their health state. The bat / knife may only cause stuns to a wounded specimen.
                        // Some foes cannot be stunned at all, for balance purposes.  At current :  Fleshpound / Scrake
                        // : Alex

			if(Other.IsA('KFMonster')  &&
                         KFMonster(Other).Health > 0 &&
                        !KFMonster(Other).bMeleeStunImmune &&
                        ((mydamage + rand(mydamage * 0.15)) / 200) > KFMonster(Other).Health / KFMonster(Other).HealthMax )
			{
			      KFmonster(other).SetAnimAction(KFmonster(other).HitAnims[Rand(3)]);
  			      KFmonster(other).bSTUNNED = true;
 			      KFmonster(other).SetTimer(1.0,false);
			}

        	        if((KActor(Other) != none))
      		          {
              	 	  //   HitLocation.Z -= 30;
				other.TakeDamage
				(
					mydamage,
					MyPawn,
					HitLocationP,
					Vector(MyPawn.GetViewRotation()) * 50000,
					MyDamageType
				);
              	 	  	  Spawn(class'KFMeleeHitEffect',,,HitLocationP, rotator(other.Location - (MyPawn.Location + MyPawn.EyePosition())));
               		 }

      	  	        if((KFGlassMover(Other) != none))
       		         {
     		                //log("MeleeProxy Found a bit of glass");
                                   //HitLocation +=  vect(0,0,15);
				other.TakeDamage
				(
					mydamage,
					MyPawn,
					HitLocationP,
					Vector(MyPawn.GetViewRotation()) * 50000,
					MyDamageType
				);
              	 	  	  Spawn(class'KFMeleeHitEffect',,,HitLocationP, rotator(other.Location - (MyPawn.Location + MyPawn.EyePosition())));
    		            }

       		         if((Other.bWorldGeometry))
      		          {
     		             // HitLocation +=  vect(0,0,25);
             	 	  	  Spawn(class'KFMeleeHitEffect',,,HitLocationP, rotator(other.Location - (MyPawn.Location + MyPawn.EyePosition())));

       		         }
	
 			   P = PlayerController(MyPawn.Controller);
  			  if (P != None )
   			     P.WeaponShakeView(ImpactShakeRotMag, ImpactShakeRotRate, ImpactShakeRotTime, ImpactShakeOffsetMag, ImpactShakeOffsetRate, ImpactShakeOffsetTime);


			for(i = 0; i < 6; i++)
				if(AlreadyHit[i]==None)
					{
					AlreadyHit[i] = Other;
					return;
					}

			AlreadyHit[1] = Other;
		}
	//If(Other.IsA('Pawn') && Pawn(Other)!=Owner)
	//	Other.TakeDamage(MyDamage,Instigator,location,location,MyDamageType);
}

defaultproperties
{
<<<<<<< HEAD
	MyDamageType=Class'KFMod.DamTypeAxe'
	ImpactShakeRotMag=(X=50.000000,Y=50.000000,Z=50.000000)
	ImpactShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
	ImpactShakeRotTime=2.000000
	ImpactShakeOffsetMag=(X=10.000000,Y=10.000000,Z=10.000000)
	ImpactShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
	ImpactShakeOffsetTime=2.000000
	DrawType=DT_StaticMesh
	StaticMesh=StaticMesh'Editor.TexPropSphere'
	bHidden=True
	bAlwaysRelevant=True
	DrawScale=0.200000
	DrawScale3D=(Y=0.500000)
	CollisionRadius=0.000000
	CollisionHeight=0.000000
	bCollideActors=True
	bCollideWorld=True
=======
     MyDamageType=Class'KFMod.DamTypeAxe'
     ImpactShakeRotMag=(X=50.000000,Y=50.000000,Z=50.000000)
     ImpactShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
     ImpactShakeRotTime=2.000000
     ImpactShakeOffsetMag=(X=10.000000,Y=10.000000,Z=10.000000)
     ImpactShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
     ImpactShakeOffsetTime=2.000000
     DrawType=DT_StaticMesh
     StaticMesh=StaticMesh'Editor.TexPropSphere'
     bHidden=True
     bAlwaysRelevant=True
     DrawScale=0.200000
     DrawScale3D=(Y=0.500000)
     CollisionRadius=0.000000
     CollisionHeight=0.000000
     bCollideActors=True
     bCollideWorld=True
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
