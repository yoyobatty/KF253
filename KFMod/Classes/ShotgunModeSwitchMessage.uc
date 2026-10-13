class ShotgunModeSwitchMessage extends CriticalEventPlus;

var() localized string SwitchMessage[10];

static function string GetString(optional int Switch, optional PlayerReplicationInfo PRI1, optional PlayerReplicationInfo PRI2, optional Object OptObj)
{
    if (Switch >= 0 && Switch <= 9)
        return Default.SwitchMessage[Switch];
}

defaultproperties
{
    SwitchMessage(0)="Switched to explosive shells."
    SwitchMessage(1)="Switched to regular shells."
    SwitchMessage(2)="No explosive shells loaded."
    DrawColor=(B=0,G=0,R=220)
    FontSize=-2
}
