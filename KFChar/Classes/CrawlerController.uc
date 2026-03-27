class CrawlerController extends KFMonsterController;

var float LastPounceTime;

function bool IsInPounceDist(actor PTarget)
{
  local vector DistVec;
  local float time;

  local float HeightMoved;
  local float EndHeight;

  //work out time needed to reach target

  DistVec = pawn.location - PTarget.location;
  DistVec.Z=0;

  time = vsize(DistVec)/ZombieCrawler(pawn).PounceSpeed;

  // vertical change in that time

  //assumes downward grav only
  HeightMoved = Pawn.JumpZ*time + 0.5*pawn.PhysicsVolume.Gravity.z*time*time;

  EndHeight = pawn.Location.z +HeightMoved;
  
  //log(Vsize(Pawn.Location - PTarget.Location));


  if((abs(EndHeight - PTarget.Location.Z) < Pawn.CollisionHeight + PTarget.CollisionHeight) &&
  VSize(pawn.Location - PTarget.Location) < KFMonster(pawn).MeleeRange * 5)
    return true;
  else
    return false;
}

function bool FireWeaponAt(Actor A)
{
	local vector aFacing,aToB;
	local float RelativeDir;
	local rotator newrot;

    if ( A == None )
		A = Enemy;
	if ( (A == None) || (Focus != A) )
		return false;

	if(CanAttack(A))
    {
	  Target = A;
	  Monster(Pawn).RangedAttack(Target);
    }
    else
    {
      //TODO - base off land time rather than launch time?
      if(LastPounceTime+1 < Level.TimeSeconds )
      {
        aFacing=Normal(Vector(Pawn.Rotation));
        // Get the vector from A to B
        aToB=A.Location-Pawn.Location;

        RelativeDir = aFacing dot aToB;
        if ( RelativeDir > 0.85 )
		{
          //Facing enemy
          if(IsInPounceDist(A) )
          {
            if(ZombieCrawler(Pawn).DoPounce()==true )
              LastPounceTime = Level.TimeSeconds;
          }
          else
          {
            //TODO: if the DoPounce borks, undo rot change?
            //      or can we guarantee no borkage?
            if(frand() < 0.5 )
              newrot = pawn.Rotation + rot(0, 10920,0);//8190,0);
            else
              newrot = pawn.Rotation + rot(0,54616,0); // 57346,0);
            pawn.SetRotation( newrot );
            if(ZombieCrawler(Pawn).DoPounce()==true )
              LastPounceTime = Level.TimeSeconds;
          }
        }
        /*
        else if(RelativeDir > 0.3)
        {
          // Partly facing enemy
          if(!IsInPounceDist(A) )
          {
            if(ZombieCrawler(Pawn).DoPounce()==true )
              LastPounceTime = Level.TimeSeconds;
          }
        }
        */
      }
    }
    return false;
}

function bool NotifyLanded(vector HitNormal)
{
  if( zombiecrawler(pawn).bPouncing )
  {
     // restart pathfinding from landing location
     GotoState('hunting');
     return false;
  }
  else
    return super.NotifyLanded(HitNormal);
}

defaultproperties
{
}
