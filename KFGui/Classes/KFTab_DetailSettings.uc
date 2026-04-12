class KFTab_DetailSettings extends UT2K4Tab_DetailSettings;

var automated moCheckBox   ch_HitBlur;
var() bool bHitBlur;

function SetupPositions()
{
    Super.SetupPositions();
    sb_Section2.ManageComponent(ch_HitBlur);
}

function InternalOnLoadINI(GUIComponent Sender, string s)
{
    local PlayerController PC;

    PC = PlayerOwner();
    switch (Sender)
    {
        case ch_HitBlur:
            ch_HitBlur.SetComponentValue(bHitBlur,true);
            break;

        default:
            Super.InternalOnLoadINI(Sender, s);
    }
}

function InternalOnChange(GUIComponent Sender)
{
    if ( bIgnoreChange )
        return;

    switch (Sender)
    {
       // Hit Blur
       case ch_HitBlur:
            bHitBlur = ch_HitBlur.IsChecked();
            break;
    }
    Super.InternalOnChange(Sender);
}

function SaveSettings()
{
    local KFHumanPawn KP;

    Super.SaveSettings();
    KP = KFHumanPawn(PlayerOwner().Pawn);
    if(KP != None)
    {
        KP.bHitBlurEnabled = bHitBlur;
        KP.SaveConfig();
    }
    else 
    {
        class'KFMod.KFHumanPawn'.default.bHitBlurEnabled = bHitBlur;
        class'KFMod.KFHumanPawn'.static.StaticSaveConfig();
    }  
}

defaultproperties
{
    Begin Object Class=moCheckBox Name=HitBlurDetail
        ComponentJustification=TXTA_Left
        CaptionWidth=0.940000
        Caption="Hit Blur"
        OnCreateComponent=HitBlurDetail.InternalOnCreateComponent
        IniOption="@Internal"
        IniDefault="false"
        Hint="Enables/Disables motion blur effects"
        WinTop=0.479308
        WinLeft=0.600000
        WinWidth=0.300000
        WinHeight=0.040000
        TabOrder=13
        OnChange=KFTab_DetailSettings.InternalOnChange
        OnLoadINI=KFTab_DetailSettings.InternalOnLoadINI
    End Object
    ch_HitBlur=HitBlurDetail
}
