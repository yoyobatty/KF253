class ZombieVolume extends Volume;

var() float CanRespawnTime; // How long to save CanSpawn values before re-check

var float LastCheckTime;
var bool bSpawnPossible;

function PostBeginPlay()
{
	// assume true until shown otherwise
	bSpawnPossible=true;
	super.PostBeginPlay();
}

// Reduces calls the CPU-heavy SpawnInHere function,
// at the cost of possibly returning occasional inaccurate values
function bool CanSpawnInHere(array< class<Actor> > zombies)
{
	if(LastCheckTime+CanRespawnTime < Level.TimeSeconds )
	{
		bSpawnPossible = SpawnInHere(zombies,0,,,,true);
		LastCheckTime = Level.TimeSeconds;
	}
	return bSpawnPossible;
}

//Experimental volume for spawning squads of zombies.
function bool SpawnInHere(array< class<Actor> > zombies,int index, optional int loc, optional ZombieVolume parent, optional out int finish,optional bool test,optional out int numspawned,optional out int TotalMaxMonsters,optional out int WaveMonsters)
{
	local int counter,nextind,i,dir,loc2;
	local float divisor;
	//local Actor t;
	local ZombieVolume p,s;
	local bool result;
	local vector floorloc;
	local Actor Act;

	//local float NextZombieTime;

	//Assign our parent- things run differently if we're the parent
	if(parent==none)
		p=self;
	else
	{
		//check for touching parent
		p=parent;
	}

	//Make sure we're still within the parent (we fail if we get outside it without
		//spawning everything.)
	//Also make sure we're not colliding with any actors.
	result = true;
	finish=1;

    //TODO: gibber - this looks exessive. Removing on a hunch
    //      that this is the biggest stumbling block
    /*
    foreach TouchingActors(class'Actor',t)
	{
		//Don't quit if we find our parent
		if(p==t)
			finish = 0;

		//Go back and try a new loc if we find anything else
		else if(t.bBlockActors || t.Owner == p)
		{
                        result = false;
			break;

		}
	}

	//Quit if we found anything but the parent
	//or if we didn't find the parent, and the parent ain't us
	if((!result || finish>0) && p != self)
	{
		bSpawnPossible = false;
        LastCheckTime = Level.TimeSeconds;
        //Log ("Found something other than the parent, or didn't find the parent");
	    return false;

    }
    */

	//If we're the parent, we'll use the index we were handed.
	if(p != self)
	   nextind = index + 1;
	else
	   nextind = index;

	//Set result to true, so if we skip placement (due to being finished)
		//we'll come out as a successful completion
	result=true;
	finish=0;

	loc2 = loc+1;

	//We end up finished, quit the loop, or if we should be finished because
		//we're done with the list, quit the loop.
	while(finish==0 && nextind < zombies.length)
	{
		//Spawn the volume for the next zombie in the list to spawn into.
		s = Spawn(class'ZombieVolume',p,,location,rotation);
		//log("spawned new volume!!!");
		//Log("zombie spawn1!");
		//If we can't spawn the volume, or set the size of the volume to that of
		//the zombie in question, then what the hell is going on?
		if(s == None || !s.SetCollisionSize(zombies[nextind].default.collisionradius,zombies[nextind].default.collisionheight))
		{
			result=false;
	        finish=1;
	        Log("Failed to set new Volume size, or spawn volume");
			break;
		}

		//Here's the part where we spiral outward.  THe stuff iwth the divisor
		//is a weird mathematical formula that gives us how many "spaces" in a row
		//as we spiral outward before changing directions.  anyway, this stuff
		//is strange and complicated, so don't touch it unless you consult with
		//me first to make sure you know what you're doing.  -Slinky

		//loc=0 means the center of the parent volume
		if(loc2 > 1)
		{
						//We use the counter to catch up with the
						//exponentially-growing index of loc at direction
						//change.

			i=1;
			divisor=1;
			dir=1;
			for(counter=loc;counter<loc2;counter++)
			{
				while(counter >= i)
				{
					i += i/int(divisor);
					dir = (dir+1)%4;
					divisor += 0.5;
				}

				floorloc = s.location;
				switch(dir)
		        {
					case 0:
				        floorloc.Y -= collisionradius*2;
				        break;
			        case 1:
				        floorloc.X += collisionradius*2;
				        break;
			        case 2:
				        floorloc.Y += collisionradius*2;
				        break;
			        case 3:
				        floorloc.X -= collisionradius*2;
		        }
		        s.SetLocation(floorloc);
		        //log("CHILDvolumeX:  "$floorloc.X@".");
			//log("CHILDvolumeY:  "$floorloc.Y@".");
		    }
		}

		//We've (hopefully) moved the volume into the correct position.
		//Now we run the same code on our new volume to see if it works.
		if(counter==0 && p != self)
			counter = loc+1;
			//Log("zombie spawn2!");
		result = s.SpawnInHere(zombies,nextind,counter,p,finish,test,numspawned,TotalMaxMonsters,WaveMonsters);

		//If the volume doesn't belong there, then we're going to destroy it
		//and try again with a new position.
		if(!result)
			s.Destroy();

		//Increase our position for next iteration.
		loc2++;
	}

	if(result == true && p != self && index < zombies.length && !test)
	{
		if( TotalMaxMonsters>0 )
		{
			Act = Spawn(zombies[index],,,location,rotation);
			if(Act!=None)
			{
				TotalMaxMonsters--;
				WaveMonsters++;
				numspawned++;
			}
		}
	}

	if(s != None)
		s.Destroy();

	finish=1;

	if( !test )
		bSpawnPossible = false; // if sucessful, spawn point is full of zombies. Can't use it for awhile. If not sucessful, can't use. This is always false
	else bSpawnPossible = result;

	LastCheckTime = Level.TimeSeconds;

	return result;
}

function bool SpawnInHereTest(array< class<Actor> > zombies,int index, optional int loc, optional ZombieVolume parent, optional out int finish,optional bool test,optional out int numspawned,optional out int TotalMaxMonsters,optional out int WaveMonsters,optional ZombieVolume s)
{
	local int counter,nextind,i,dir,loc2;
	local float divisor;
	local Actor t;
	local ZombieVolume p;
	local bool result;
	local vector floorloc;
	local Actor Act;

	//local float NextZombieTime;

	//Assign our parent- things run differently if we're the parent
	if(parent==none)
		p=self;
	else
	{
		//check for touching parent
		p=parent;
	}

	//Make sure we're still within the parent (we fail if we get outside it without
		//spawning everything.)
	//Also make sure we're not colliding with any actors.
	result = true;
	finish=1;
	foreach TouchingActors(class'Actor',t)
	{
		//Don't quit if we find our parent
		if(p==t)
			finish = 0;
		//Go back and try a new loc if we find anything else
		else if(t.bBlockActors || t.Owner == p)
		{
			result = false;
		}
	}

	//Quit if we found anything but the parent
	//or if we didn't find the parent, and the parent ain't us
	if((!result || finish>0) && p != self)
	{
		return false;
	}

	//If we're the parent, we'll use the index we were handed.
	if(p != self)
	   nextind = index + 1;
	else
	   nextind = index;

	//Set result to true, so if we skip placement (due to being finished)
		//we'll come out as a successful completion
	result=true;
	finish=0;

	loc2 = loc+1;

	//We end up finished, quit the loop, or if we should be finished because
		//we're done with the list, quit the loop.
	while(finish==0 && nextind < zombies.length)
	{
		//Spawn the volume for the next zombie in the list to spawn into.
		if (s==None)
			s = Spawn(class'ZombieVolume',p,,location,rotation);

		//If we can't spawn the volume, or set the size of the volume to that of
		//the zombie in question, then what the hell is going on?
		if(s == None || !s.SetCollisionSize(zombies[nextind].default.collisionradius,zombies[nextind].default.collisionheight))
		{
			result=false;
			finish=1;
			break;
		}

		//Here's the part where we spiral outward.  THe stuff iwth the divisor
		//is a weird mathematical formula that gives us how many "spaces" in a row
		//as we spiral outward before changing directions.  anyway, this stuff
		//is strange and complicated, so don't touch it unless you consult with
		//me first to make sure you know what you're doing.  -Slinky

		//loc=0 means the center of the parent volume
		if(loc2 > 1)
		{
						//We use the counter to catch up with the
						//exponentially-growing index of loc at direction
						//change.

			i=1;
			divisor=1;
			dir=1;
			for(counter=loc;counter<loc2;counter++)
			{
				while(counter >= i)
				{
					i += i/int(divisor);
					dir = (dir+1)%4;
					divisor += 0.5;
				}

				floorloc = s.location;
				switch(dir)
		        {
					case 0:
				        floorloc.Y -= collisionradius*2;
				        break;
			        case 1:
				        floorloc.X += collisionradius*2;
				        break;
			        case 2:
				        floorloc.Y += collisionradius*2;
				        break;
			        case 3:
				        floorloc.X -= collisionradius*2;
		        }
		        s.SetLocation(floorloc);
		        //log("CHILDvolumeX:  "$floorloc.X@".");
			//log("CHILDvolumeY:  "$floorloc.Y@".");
		    }
		}

		//We've (hopefully) moved the volume into the correct position.
		//Now we run the same code on our new volume to see if it works.
		if(counter==0 && p != self)
			counter = loc+1;
			//Log("zombie spawn2!");
		result = s.SpawnInHereTest(zombies,nextind,counter,p,finish,test,numspawned,TotalMaxMonsters,WaveMonsters,s);

		//If the volume doesn't belong there, then we're going to destroy it
		//and try again with a new position.
		if(!result)
			s.Destroy();

		//Increase our position for next iteration.
		loc2++;
	}

	if(result == true && p != self && index < zombies.length && !test)
	{
		if( TotalMaxMonsters>0 )
		{
			Act = Spawn(zombies[index],,,location,rotation);
			if(Act!=None)
			{
				TotalMaxMonsters--;
				WaveMonsters++;
				numspawned++;
			}

		}
	}

	if(s != None)
		s.Destroy();

	finish=1;
	return result;
}

defaultproperties
{
	CanRespawnTime=10.000000
	bStatic=False
	bNoDelete=False
}
