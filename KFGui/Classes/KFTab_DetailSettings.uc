class KFTab_DetailSettings extends UT2K4Tab_DetailSettings;

var automated moCheckBox   ch_Bloom, ch_HitBlur, ch_Vivid, ch_AO, ch_Torch;
var() bool bBloom, bHitBlur, bVivid, bAO, bTorch;
var bool bScreenFXChanged, bTorchChanged;

function SetupPositions()
{
    local int i;

    Super.SetupPositions();
    if (sb_Section2.FindComponentIndex(ch_Bloom) >= 0)
        return;
    // (the mod's own at the head of the section's checkboxes, before the engine's and the fog slider)
    i = sb_Section2.FindComponentIndex(ch_Decals);
    if (i < 0)
        i = sb_Section2.AlignStack.Length;
    sb_Section2.AlignStack.Insert(i, 5);
    sb_Section2.AlignStack[i] = ch_Bloom;
    sb_Section2.AlignStack[i + 1] = ch_HitBlur;
    sb_Section2.AlignStack[i + 2] = ch_Vivid;
    sb_Section2.AlignStack[i + 3] = ch_AO;
    sb_Section2.AlignStack[i + 4] = ch_Torch;
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

        case ch_Vivid:
            bVivid = class'KFMod.KFScreenFX'.default.bVivid;
            ch_Vivid.SetComponentValue(bVivid,true);
            break;

        case ch_AO:
            bAO = class'KFMod.KFScreenFX'.default.bAO;
            ch_AO.SetComponentValue(bAO,true);
            break;

        case ch_Torch:
            bTorch = class'KFMod.KFScreenFX'.default.bTorch;
            ch_Torch.SetComponentValue(bTorch,true);
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

       case ch_Vivid:
            bVivid = ch_Vivid.IsChecked();
            bScreenFXChanged = true;
            break;

       case ch_AO:
            bAO = ch_AO.IsChecked();
            bScreenFXChanged = true;
            break;

       case ch_Torch:
            bTorch = ch_Torch.IsChecked();
            bTorchChanged = true;
            break;
    }
    Super.InternalOnChange(Sender);
}

function ResetClicked()
{
    class'KFMod.KFScreenFX'.static.ResetConfig("bBloom");
    class'KFMod.KFScreenFX'.static.ResetConfig("bHitBlur");
    class'KFMod.KFScreenFX'.static.ResetConfig("bVivid");
    class'KFMod.KFScreenFX'.static.ResetConfig("bAO");
    class'KFMod.KFScreenFX'.static.ResetConfig("bTorch");
    class'KFMod.KFScreenFX'.static.Configure(PlayerOwner(), class'KFMod.KFScreenFX'.default.bBloom, class'KFMod.KFScreenFX'.default.bHitBlur,
        class'KFMod.KFScreenFX'.default.bVivid, class'KFMod.KFScreenFX'.default.bAO);
    bScreenFXChanged = false;
    bTorchChanged = false;
    Super.ResetClicked();
}

function SaveSettings()
{
    Super.SaveSettings();
    // (only what was changed here: a page that was never shown has nothing to say)
    if ( bScreenFXChanged )
    {
        class'KFMod.KFScreenFX'.static.Configure(PlayerOwner(), bBloom, bHitBlur, bVivid, bAO);
        bScreenFXChanged = false;
    }
    if ( bTorchChanged )
    {
        class'KFMod.KFScreenFX'.default.bTorch = bTorch;
        class'KFMod.KFScreenFX'.static.StaticSaveConfig();
        bTorchChanged = false;
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
        Hint="Bright lights, fire and muzzle flashes glow past their edges. Direct3D only."
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
        Hint="Your view goes out of focus for a moment when you are hurt. Direct3D only."
        WinTop=0.479308
        WinLeft=0.600000
        WinWidth=0.300000
        WinHeight=0.040000
        TabOrder=24
        OnChange=KFTab_DetailSettings.InternalOnChange
        OnLoadINI=KFTab_DetailSettings.InternalOnLoadINI
    End Object
    ch_HitBlur=HitBlurDetail

    Begin Object Class=moCheckBox Name=VividDetail
        ComponentJustification=TXTA_Left
        CaptionWidth=0.940000
        Caption="Vivid Colours"
        OnCreateComponent=VividDetail.InternalOnCreateComponent
        IniOption="@Internal"
        IniDefault="True"
        Hint="Strong colours stand out more: fire, blood and lights are richer against the dark. Direct3D only."
        WinTop=0.479308
        WinLeft=0.600000
        WinWidth=0.300000
        WinHeight=0.040000
        TabOrder=25
        OnChange=KFTab_DetailSettings.InternalOnChange
        OnLoadINI=KFTab_DetailSettings.InternalOnLoadINI
    End Object
    ch_Vivid=VividDetail

    Begin Object Class=moCheckBox Name=AODetail
        ComponentJustification=TXTA_Left
        CaptionWidth=0.940000
        Caption="Ambient Occlusion"
        OnCreateComponent=AODetail.InternalOnCreateComponent
        IniOption="@Internal"
        IniDefault="True"
        Hint="Corners, creases and the ground round things are shaded a little darker. Costs some frame rate. Direct3D only."
        WinTop=0.479308
        WinLeft=0.600000
        WinWidth=0.300000
        WinHeight=0.040000
        TabOrder=26
        OnChange=KFTab_DetailSettings.InternalOnChange
        OnLoadINI=KFTab_DetailSettings.InternalOnLoadINI
    End Object
    ch_AO=AODetail

    Begin Object Class=moCheckBox Name=TorchDetail
        ComponentJustification=TXTA_Left
        CaptionWidth=0.940000
        Caption="Shadowed Flashlight"
        OnCreateComponent=TorchDetail.InternalOnCreateComponent
        IniOption="@Internal"
        IniDefault="True"
        Hint="Your own flashlight lights everything it reaches, with shadows behind whatever stands in the beam. Direct3D 9 and 8 only. Costs some frame rate while it is on."
        WinTop=0.479308
        WinLeft=0.600000
        WinWidth=0.300000
        WinHeight=0.040000
        TabOrder=27
        OnChange=KFTab_DetailSettings.InternalOnChange
        OnLoadINI=KFTab_DetailSettings.InternalOnLoadINI
    End Object
    ch_Torch=TorchDetail
}
