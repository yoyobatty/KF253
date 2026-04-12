class KFAudioSettingsTab extends UT2K4Tab_AudioSettings;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	local int i;
	local bool bIsWin32;

	bIsWin32 = (PlatformIsWindows() && !PlatformIs64Bit());

	Super(Settings_Tabs).InitComponent(MyController, MyOwner);

	if ( bIsWin32 )
	{
		for(i = 0;i < ArrayCount(AudioModes);i++)
			co_Mode.AddItem(AudioModes[i]);
	}
	else co_Mode.AddItem("OpenAL");

	i_BG3.WinWidth=0.475078;
	i_BG3.WinHeight=0.453045;
	i_BG3.WinLeft=0.518712;
	i_BG3.WinTop=0.540831;

	i_BG1.ManageComponent(sl_MusicVol);
	i_BG1.ManageComponent(sl_EffectsVol);
	i_BG1.ManageComponent(co_Mode);
	i_BG1.ManageComponent(ch_LowDetail);
	i_BG1.ManageComponent(ch_Default);
	i_BG1.ManageComponent(ch_reverseStereo);
	i_BG1.ManageComponent(ch_MatureTaunts);
	i_BG1.ManageComponent(ch_AutoTaunt);
	i_BG1.ManageComponent(ch_MessageBeep);

	i_BG3.ManageComponent(ch_TTS);
	i_BG3.ManageComponent(ch_TTSIRC);
	i_BG3.ManageComponent(ch_OnlyTeamTTS);
	i_BG3.ManageComponent(ch_VoiceChat);
	i_BG3.ManageComponent(b_VoiceChat);

	// !!! FIXME: Might use a preinstalled system OpenAL in the future on
	// !!! FIXME:  Mac or Unix, but for now, we don't...  --ryan.
	if ( !PlatformIsWindows() )
		ch_Default.DisableMe();
}

simulated function InternalOnChange(GUIComponent Sender)
{
	local PlayerController PC;
	local float AnnouncerVol;
	local bool bIsWin32;

	bIsWin32 = ( ( PlatformIsWindows() ) && ( !PlatformIs64Bit() ) );

	Super.InternalOnChange(Sender);
	PC = PlayerOwner();

	switch(Sender)
	{
		case sl_VoiceVol:
			iVoice = sl_VoiceVol.GetValue();
			AnnouncerVol = 2.0 * FClamp(0.1 + iVoice*0.225,0.2,1.0);
			PC.PlaySound(Sound'AnnouncerMale2k4.HolyShit_F',SLOT_Talk,AnnouncerVol);
			break;

		case sl_MusicVol:
			fMusic = sl_MusicVol.GetValue();
			PC.ConsoleCommand("set ini:Engine.Engine.AudioDevice MusicVolume"@fMusic);
			PC.ConsoleCommand("SetMusicVolume"@fMusic);
			break;

		case sl_EffectsVol:
			fEffects = sl_EffectsVol.GetValue();
			PC.ConsoleCommand("set ini:Engine.Engine.AudioDevice SoundVolume"@fEffects);
			PC.ConsoleCommand("stopsounds");
			PC.PlaySound(sound'KFWeaponSound.knife_deploy1');
			break;

		case co_Mode:
			if ( !bIsWin32 )  // Simple OpenAL abstraction...  --ryan.
				break;

			iMode = co_Mode.GetIndex();
			if (iMode > 1)
				ShowPerformanceWarning();
			bCompat = iMode < 1;
			b3DSound = iMode > 1;
			bEAX = iMode > 2;
			PC.ConsoleCommand("set ini:Engine.Engine.AudioDevice CompatibilityMode"@bCompat);
			PC.ConsoleCommand("set ini:Engine.Engine.AudioDevice Use3DSound"@b3DSound);
			PC.ConsoleCommand("set ini:Engine.Engine.AudioDevice UseEAX"@bEAX);
			PC.ConsoleCommand("SOUND_REBOOT");
			break;

		case ch_ReverseStereo:
			bRev = ch_ReverseStereo.IsChecked();
			break;

		case ch_MessageBeep:
			bBeep = ch_MessageBeep.IsChecked();
			break;

		case ch_AutoTaunt:
			bAuto = ch_AutoTaunt.IsChecked();
			break;

		case ch_TTS:
			bTTS = ch_TTS.IsChecked();
			break;

		case ch_MatureTaunts:
			bMature = ch_MatureTaunts.IsChecked();
			break;

		case ch_Default:
			bDefault = ch_Default.IsChecked();
			PC.ConsoleCommand("set ini:Engine.Engine.AudioDevice UseDefaultDriver"@bDefault);
			PC.ConsoleCommand("SOUND_REBOOT");
			break;

		case ch_LowDetail:
			bLow = ch_LowDetail.IsChecked();

			PC.Level.bLowSoundDetail = bLow;
			PC.Level.StaticSaveConfig();

			PC.ConsoleCommand("set ini:Engine.Engine.AudioDevice LowQualitySound"@bLow);
			PC.ConsoleCommand("SOUND_REBOOT");

			// Restart music.
			if( PC.Level.Song != "" && PC.Level.Song != "None" )
				PC.ClientSetMusic( PC.Level.Song, MTRAN_Instant );
			else PC.ClientSetMusic( class'UT2K4MainMenu'.default.MenuSong, MTRAN_Instant );
			break;

		case ch_TTSIRC:
			bTTSIRC = ch_TTSIRC.IsChecked();
			break;

		case ch_VoiceChat:
			bVoiceChat = ch_VoiceChat.IsChecked();
			break;

		case ch_OnlyTeamTTS:
			bOnlyTeamTTS = ch_OnlyTeamTTS.IsChecked();
			break;
	}
}

defaultproperties
{
     Begin Object Class=GUISectionBackground Name=AudioBK1
         Caption="Sound Effects"
         NumColumns=2
         MaxPerColumn=5
         WinTop=0.017393
         WinLeft=0.004063
         WinWidth=0.987773
         WinHeight=0.502850
         OnPreDraw=AudioBK1.InternalPreDraw
     End Object
     i_BG1=GUISectionBackground'KFGui.KFAudioSettingsTab.AudioBK1'

     i_BG2=None

     Begin Object Class=GUISectionBackground Name=AudioBK3
         Caption="Text To Speech"
         WinTop=0.004372
         WinLeft=0.004063
         WinWidth=0.987773
         WinHeight=0.517498
         OnPreDraw=AudioBK3.InternalPreDraw
     End Object
     i_BG3=GUISectionBackground'KFGui.KFAudioSettingsTab.AudioBK3'

     Begin Object Class=moSlider Name=AudioMusicVolume
         MaxValue=1.000000
         Caption="Music Volume"
         OnCreateComponent=AudioMusicVolume.InternalOnCreateComponent
         IniOption="@Internal"
         IniDefault="0.5"
         Hint="Adjusts the volume of the background music."
         WinTop=0.070522
         WinLeft=0.018164
         WinWidth=0.450000
         TabOrder=0
         OnChange=KFAudioSettingsTab.InternalOnChange
         OnLoadINI=KFAudioSettingsTab.InternalOnLoadINI
     End Object
     sl_MusicVol=moSlider'KFGui.KFAudioSettingsTab.AudioMusicVolume'

     Begin Object Class=moSlider Name=AudioEffectsVolumeSlider
         MaxValue=1.000000
         Caption="Effects Volume"
         OnCreateComponent=AudioEffectsVolumeSlider.InternalOnCreateComponent
         IniOption="@Internal"
         IniDefault="0.9"
         Hint="Adjusts the volume of all in game sound effects."
         WinTop=0.070522
         WinLeft=0.524024
         WinWidth=0.450000
         TabOrder=5
         OnChange=KFAudioSettingsTab.InternalOnChange
         OnLoadINI=KFAudioSettingsTab.InternalOnLoadINI
     End Object
     sl_EffectsVol=moSlider'KFGui.KFAudioSettingsTab.AudioEffectsVolumeSlider'

     sl_VoiceVol=None

     Begin Object Class=moComboBox Name=AudioMode
         bReadOnly=True
         Caption="Audio Mode"
         OnCreateComponent=AudioMode.InternalOnCreateComponent
         IniOption="@Internal"
         IniDefault="Software 3D Audio"
         Hint="Changes the audio system mode."
         WinTop=0.149739
         WinLeft=0.018164
         WinWidth=0.450000
         TabOrder=1
         OnChange=KFAudioSettingsTab.InternalOnChange
         OnLoadINI=KFAudioSettingsTab.InternalOnLoadINI
     End Object
     co_Mode=moComboBox'KFGui.KFAudioSettingsTab.AudioMode'

     co_Voices=None

     co_Announce=None

     co_RewardAnnouncer=None

     co_StatusAnnouncer=None

     Begin Object Class=moCheckBox Name=AudioReverseStereo
         ComponentJustification=TXTA_Left
         CaptionWidth=0.940000
         Caption="Reverse Stereo"
         OnCreateComponent=AudioReverseStereo.InternalOnCreateComponent
         IniOption="@Internal"
         IniDefault="False"
         Hint="Reverses the left and right audio channels."
         WinTop=0.405678
         WinLeft=0.018164
         WinWidth=0.450000
         TabOrder=4
         OnChange=KFAudioSettingsTab.InternalOnChange
         OnLoadINI=KFAudioSettingsTab.InternalOnLoadINI
     End Object
     ch_ReverseStereo=moCheckBox'KFGui.KFAudioSettingsTab.AudioReverseStereo'

     Begin Object Class=moCheckBox Name=AudioMessageBeep
         ComponentJustification=TXTA_Left
         CaptionWidth=0.940000
         Caption="Message Beep"
         OnCreateComponent=AudioMessageBeep.InternalOnCreateComponent
         IniOption="@Internal"
         IniDefault="True"
         Hint="Enables a beep when receiving a text message from other players."
         WinTop=0.405678
         WinLeft=0.524024
         WinWidth=0.450000
         TabOrder=9
         OnChange=KFAudioSettingsTab.InternalOnChange
         OnLoadINI=KFAudioSettingsTab.InternalOnLoadINI
     End Object
     ch_MessageBeep=moCheckBox'KFGui.KFAudioSettingsTab.AudioMessageBeep'

     ch_AutoTaunt=None

     Begin Object Class=moCheckBox Name=IRCTextToSpeech
         ComponentJustification=TXTA_Left
         CaptionWidth=0.940000
         Caption="Enable on IRC"
         OnCreateComponent=IRCTextToSpeech.InternalOnCreateComponent
         IniOption="@Internal"
         Hint="Enables Text-To-Speech processing in the IRC client (only messages from active tab is processed)"
         WinTop=0.755462
         WinLeft=0.527734
         WinWidth=0.461134
         TabOrder=16
         OnChange=KFAudioSettingsTab.InternalOnChange
         OnLoadINI=KFAudioSettingsTab.InternalOnLoadINI
     End Object
     ch_TTSIRC=moCheckBox'KFGui.KFAudioSettingsTab.IRCTextToSpeech'

     Begin Object Class=moCheckBox Name=OnlyTeamTTSCheck
         ComponentJustification=TXTA_Left
         CaptionWidth=0.940000
         Caption="Team Messages Only"
         OnCreateComponent=OnlyTeamTTSCheck.InternalOnCreateComponent
         IniOption="@Internal"
         Hint="If enabled, only team messages will be spoken in team games, unless the match or round is over."
         WinTop=0.755462
         WinLeft=0.527734
         WinWidth=0.461134
         TabOrder=17
         OnChange=KFAudioSettingsTab.InternalOnChange
         OnLoadINI=KFAudioSettingsTab.InternalOnLoadINI
     End Object
     ch_OnlyTeamTTS=moCheckBox'KFGui.KFAudioSettingsTab.OnlyTeamTTSCheck'

     ch_MatureTaunts=None

     Begin Object Class=moCheckBox Name=AudioLowDetail
         ComponentJustification=TXTA_Left
         CaptionWidth=0.940000
         Caption="Low Sound Detail"
         OnCreateComponent=AudioLowDetail.InternalOnCreateComponent
         IniOption="@Internal"
         IniDefault="False"
         Hint="Lowers quality of sound."
         WinTop=0.235052
         WinLeft=0.018164
         WinWidth=0.450000
         TabOrder=2
         OnChange=KFAudioSettingsTab.InternalOnChange
         OnLoadINI=KFAudioSettingsTab.InternalOnLoadINI
     End Object
     ch_LowDetail=moCheckBox'KFGui.KFAudioSettingsTab.AudioLowDetail'

     Begin Object Class=moCheckBox Name=AudioDefaultDriver
         ComponentJustification=TXTA_Left
         CaptionWidth=0.940000
         Caption="System Driver"
         OnCreateComponent=AudioDefaultDriver.InternalOnCreateComponent
         IniOption="@Internal"
         IniDefault="False"
         Hint="Use system installed OpenAL driver"
         WinTop=0.320365
         WinLeft=0.018164
         WinWidth=0.450000
         TabOrder=3
         OnChange=KFAudioSettingsTab.InternalOnChange
         OnLoadINI=KFAudioSettingsTab.InternalOnLoadINI
     End Object
     ch_Default=moCheckBox'KFGui.KFAudioSettingsTab.AudioDefaultDriver'

     Begin Object Class=moCheckBox Name=AudioEnableTTS
         ComponentJustification=TXTA_Left
         CaptionWidth=0.940000
         Caption="Enable In Game"
         OnCreateComponent=AudioEnableTTS.InternalOnCreateComponent
         IniOption="@Internal"
         IniDefault="False"
         Hint="Enables Text-To-Speech message processing"
         WinTop=0.685037
         WinLeft=0.527734
         WinWidth=0.461134
         TabOrder=15
         OnChange=KFAudioSettingsTab.InternalOnChange
         OnLoadINI=KFAudioSettingsTab.InternalOnLoadINI
     End Object
     ch_TTS=moCheckBox'KFGui.KFAudioSettingsTab.AudioEnableTTS'

     Begin Object Class=moCheckBox Name=EnableVoiceChat
         ComponentJustification=TXTA_Left
         CaptionWidth=0.940000
         Caption="Voice Chat"
         OnCreateComponent=EnableVoiceChat.InternalOnCreateComponent
         IniOption="@Internal"
         Hint="Enables the voice chat system during online matches."
         WinTop=0.834777
         WinLeft=0.527734
         WinWidth=0.461134
         TabOrder=18
         OnChange=KFAudioSettingsTab.InternalOnChange
         OnLoadINI=KFAudioSettingsTab.InternalOnLoadINI
     End Object
     ch_VoiceChat=moCheckBox'KFGui.KFAudioSettingsTab.EnableVoiceChat'

     Begin Object Class=moButton Name=VoiceOptions
         ButtonCaption="Configure"
         MenuTitle="Voice Chat Options"
         MenuClass="GUI2K4.VoiceChatConfig"
         CaptionWidth=0.500000
         Caption="Voice Options"
         OnCreateComponent=VoiceOptions.InternalOnCreateComponent
         WinTop=0.909065
         WinLeft=0.527734
         WinWidth=0.461134
         WinHeight=0.050000
         TabOrder=19
     End Object
     b_VoiceChat=moButton'KFGui.KFAudioSettingsTab.VoiceOptions'

}
