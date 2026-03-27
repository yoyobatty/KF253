//=============================================================================
// ZombieVolume - Volume used for spawning squads of zombies in a spiral pattern.
// Each volume acts as a probe to validate placement before spawning actors.
//=============================================================================
class ZombieVolume extends Volume;

var() float CanRespawnTime; // Seconds to cache CanSpawnInHere results

var float LastCheckTime;
var bool bSpawnPossible;

function PostBeginPlay()
{
    bSpawnPossible = true;
    super.PostBeginPlay();
}

// Cached wrapper around SpawnInHere (test mode) to avoid expensive checks every tick.
function bool CanSpawnInHere(array< class<Actor> > zombies)
{
    if (LastCheckTime + CanRespawnTime < Level.TimeSeconds)
    {
        bSpawnPossible = SpawnInHere(zombies, 0, , , , true);
        LastCheckTime = Level.TimeSeconds;
    }
    return bSpawnPossible;
}

// Spawns (or test-fits) a squad of zombies using an outward spiral placement.
// When test=true, no actors are spawned - only validates whether placement is possible.
// Returns true if all zombies in the squad were placed successfully.
function bool SpawnInHere(array< class<Actor> > zombies, int index, optional int loc, optional ZombieVolume parent, optional out int finish, optional bool test, optional out int numspawned, optional out int TotalMaxMonsters, optional out int WaveMonsters)
{
    local int counter, nextind, i, dir, loc2;
    local float divisor;
    local ZombieVolume p, s;
    local bool result;
    local vector floorloc;
    local Actor Act;

    // Determine parent volume - the top-level caller is its own parent
    if (parent == None)
        p = self;
    else
        p = parent;

    // Parent starts at the given index; children advance to the next zombie
    if (p != self)
        nextind = index + 1;
    else
        nextind = index;

    result = true;
    finish = 0;
    loc2 = loc + 1;

    // Spiral outward, placing one probe volume per remaining zombie in the squad
    while (finish == 0 && nextind < zombies.Length)
    {
        // Spawn a fresh probe volume owned by the parent
        s = Spawn(class'ZombieVolume', p, , Location, Rotation);

        // Size the probe to match the next zombie's collision cylinder
        if (s == None || !s.SetCollisionSize(zombies[nextind].default.CollisionRadius, zombies[nextind].default.CollisionHeight))
        {
            result = false;
            finish = 1;
            Log("ZombieVolume: Failed to create or resize probe volume");
            break;
        }

        // Spiral placement: advance the probe to grid position loc2.
        // The direction changes follow a pattern producing a square spiral
        // outward from the center.
        if (loc2 > 1)
        {
            i = 1;
            divisor = 1;
            dir = 1;

            for (counter = loc; counter < loc2; counter++)
            {
                while (counter >= i)
                {
                    i += i / int(divisor);
                    dir = (dir + 1) % 4;
                    divisor += 0.5;
                }

                floorloc = s.Location;
                switch (dir)
                {
                    case 0:
                        floorloc.Y -= s.CollisionRadius * 2;
                        break;
                    case 1:
                        floorloc.X += s.CollisionRadius * 2;
                        break;
                    case 2:
                        floorloc.Y += s.CollisionRadius * 2;
                        break;
                    case 3:
                        floorloc.X -= s.CollisionRadius * 2;
                        break;
                }
                s.SetLocation(floorloc);
            }
        }

        // Ensure counter has a valid starting value for child recursion
        if (counter == 0 && p != self)
        {
            counter = loc + 1;
        }

        // Recurse: validate (and potentially spawn) the next zombie at this position
        result = s.SpawnInHere(zombies, nextind, counter, p, finish, test, numspawned, TotalMaxMonsters, WaveMonsters);

        // If placement failed here, destroy the probe and try the next spiral position
        if (!result)
        {
            s.Destroy();
            s = None;
        }

        loc2++;
    }

    // On successful placement, spawn the actual zombie at this child's position
    if (result && p != self && index < zombies.Length && !test)
    {
        if (TotalMaxMonsters > 0)
        {
            Act = Spawn(zombies[index],,, Location, Rotation);
            if (Act != None)
            {
                TotalMaxMonsters--;
                WaveMonsters++;
                numspawned++;
            }
        }
    }

    // Clean up probe volume
    if (s != None)
    {
        s.Destroy();
        s = None;
    }

    finish = 1;

    // Update spawn availability cache (parent volume only)
    if (p == self)
    {
        if (test)
        {
            bSpawnPossible = result;
            LastCheckTime = Level.TimeSeconds;
        }
        else if (result)
        {
            // Successful real spawn: volume is occupied, lock it out
            bSpawnPossible = false;
            LastCheckTime = Level.TimeSeconds;
        }
        // Failed real spawn: don't update LastCheckTime so CanSpawnInHere
        // will re-evaluate on the next query instead of staying locked out
    }

    return result;
}

defaultproperties
{
    CanRespawnTime=5.000000
    bStatic=False
    bNoDelete=False
}