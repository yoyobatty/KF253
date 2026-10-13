class KFTab_DetailSettings extends UT2K4Tab_DetailSettings;

var automated moCheckBox   ch_Bloom, ch_HitBlur;
var() bool bBloom, bHitBlur;
var bool bScreenFXChanged;

function SetupPositions()
{
    Super.SetupPositions();
    sb_Section2.ManageComponent(ch_Bloom);
    sb_Section2.ManageComponent(ch_HitBlur);
}

function InternalOnLoadINI(GUIComponent Sender, string s)
{
    switch (Sender)
    {
        case ch_Bloom:
            bBloom = class'KFMod.KFScreenFX'.default.bBloom;
            ch_Bloom.SetComponentValue(bBloom,true);
            break;

        case ch_HitBlur:
            bHitBlur = class'KFMod.KFScreenFX'.default.bHitBlur;
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
       case ch_Bloom:
            bBloom = ch_Bloom.IsChecked();
            bScreenFXChanged = true;
            break;

       // Hit Blur
       case ch_HitBlur:
            bHitBlur = ch_HitBlur.IsChecked();
            bScreenFXChanged = true;
            break;
    }
    Super.InternalOnChange(Sender);
}

function ResetClicked()
{
    class'KFMod.KFScreenFX'.static.ResetConfig("bBloom");
    class'KFMod.KFScreenFX'.static.ResetConfig("bHitBlur");
    class'KFMod.KFScreenFX'.static.Configure(PlayerOwner(), class'KFMod.KFScreenFX'.default.bBloom, class'KFMod.KFScreenFX'.default.bHitBlur);
    bScreenFXChanged = false;
    Super.ResetClicked();
}

function SaveSettings()
{
    Super.SaveSettings();
    // (only what was changed here: a page that was never shown has nothing to say)
    if ( bScreenFXChanged )
    {
        class'KFMod.KFScreenFX'.static.Configure(PlayerOwner(), bBloom, bHitBlur);
        bScreenFXChanged = false;
    }
}

defaultproperties
{
    Begin Object Class=moCheckBox Name=BloomDetail
        ComponentJustification=TXTA_Left
        CaptionWidth=0.940000
        Caption="Bloom"
        OnCreateComponent=BloomDetail.InternalOnCreateComponent
        IniOption="@Internal"
        IniDefault="True"
        Hint="Bright lights, fire and muzzle flashes glow past their edges."
        WinTop=0.479308
        WinLeft=0.600000
        WinWidth=0.300000
        WinHeight=0.040000
        TabOrder=23
        OnChange=KFTab_DetailSettings.InternalOnChange
        OnLoadINI=KFTab_DetailSettings.InternalOnLoadINI
    End Object
    ch_Bloom=BloomDetail

    Begin Object Class=moCheckBox Name=HitBlurDetail
        ComponentJustification=TXTA_Left
        CaptionWidth=0.940000
        Caption="Hit Blur"
        OnCreateComponent=HitBlurDetail.InternalOnCreateComponent
        IniOption="@Internal"
        IniDefault="True"
        Hint="Your view goes out of focus for a moment when you are hurt."
        WinTop=0.479308
        WinLeft=0.600000
        WinWidth=0.300000
        WinHeight=0.040000
        TabOrder=24
        OnChange=KFTab_DetailSettings.InternalOnChange
        OnLoadINI=KFTab_DetailSettings.InternalOnLoadINI
    End Object
    ch_HitBlur=HitBlurDetail
}
