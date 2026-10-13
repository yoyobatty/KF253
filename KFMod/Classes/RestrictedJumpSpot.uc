//=============================================================================
// RestrictedJumpSpot
// A JumpSpot subclass that allows specific Pawn classes to be excluded
// from using it. 
//=============================================================================
class RestrictedJumpSpot extends JumpSpot
    placeable;

// Array of Pawn classes that can't use this JumpSpot
var() array<class<Pawn> > ExcludedPawnClasses;

// If true, exclusion check is exact class match only
var() bool bExactClassMatchOnly;

function bool IsPawnExcluded(Pawn Other)
{
    local int i;

    if ( Other == None )
        return false;

    for ( i = 0; i < ExcludedPawnClasses.Length; i++ )
    {
        if ( ExcludedPawnClasses[i] == None )
            continue;

        if ( bExactClassMatchOnly )
        {
            if ( Other.Class == ExcludedPawnClasses[i] )
                return true;
        }
        else
        {
            if ( Other.IsA(ExcludedPawnClasses[i].Name) )
                return true;
        }
    }

    return false;
}

event int SpecialCost(Pawn Other, ReachSpec Path)
{
    if ( IsPawnExcluded(Other) )
        return 10000000;

    return Super.SpecialCost(Other, Path);
}

event bool SuggestMovePreparation(Pawn Other)
{
    if ( IsPawnExcluded(Other) )
    {
        if ( Bot(Other.Controller) != None )
            Bot(Other.Controller).bPreparingMove = false;

        return false;
    }

    return Super.SuggestMovePreparation(Other);
}

defaultproperties
{
    bExactClassMatchOnly=false
}