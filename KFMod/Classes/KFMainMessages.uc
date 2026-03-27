class KFMainMessages extends CriticalEventPlus
	abstract;
	
var(Message) localized string ShopBootMsg;

//
// Messages common to GameInfo derivatives.
//
static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1, 
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    switch (Switch)
    {
        case 0:
            return Default.ShopBootMsg;
            break;
    }
    return "";
}

defaultproperties
{
     ShopBootMsg="You can't stay in this shop after closing"
     bIsUnique=False
     DrawColor=(B=10,G=10,R=140)
     StackMode=SM_Down
     PosY=0.800000
     FontSize=2
}
