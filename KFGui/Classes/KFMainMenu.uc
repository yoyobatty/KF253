class KFMainMenu extends UT2K4GUIPage;

//var KFDataObject SPAmmo;
var bool bOpenAlready;
var bool bMovingOnTraining, bMovingOnResume, bMovingOnSP;

var automated   GUIImage        KFLogoBit;
var automated  GUILabel KFVersionNum;   // Keep track of updates from now on ! :D




#exec OBJ LOAD FILE=InterfaceContent.utx
#exec OBJ LOAD FIlE=2K4Menus.utx
#exec OBJ LOAD FIlE=2K4MenuSounds.uax

#exec OBJ LOAD FIlE=2K4Menus.utx
#exec OBJ LOAD FIlE=PatchTex.utx
/*
    Variable Name Legend

    l_  GUILabel            lb_ GUIListBox
    i_  GUIImage            li_ GUIList
    b_  GUIButton           tp_ GUITabPanel
    t_  GUITitleBar         sp_ GUISplitter
    c_  GUITabControl
    p_  GUIPanel

    ch_ moCheckBox
    co_ moComboBox
    nu_ moNumericEdit
    ed_ moEditBox
    fl_ moFloatEdit
    sl_ moSlider
*/

var automated   BackgroundImage i_BkChar,
                                i_Background;
var automated   GUIImage        i_UT2Logo,
                                i_PanHuge,
                                i_PanBig,
                                i_PanSmall,
                                i_UT2Shader,
                                i_TV;

var automated   GUIButton   b_SinglePlayer, b_MultiPlayer, b_Host,
                            b_InstantAction, b_ModsAndDemo,  b_Settings, b_Quit,
                            b_SoloPlay;



var bool    bAllowClose;

var array<material> CharShots;

var float CharFade, DesiredCharFade;
var float CharFadeTime;

var GUIButton Selected;
var() bool bNoInitDelay;

var() config string MenuSong;

var bool bNewNews;
var float FadeTime;
var bool  FadeOut;

var localized string NewNewsMsg,FireWallTitle, FireWallMsg;



function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    Super.InitComponent(MyController, MyOwner);

   // Background= Material '2k4Menus.loading.loadingscreen1';
   Background= none;
/*    if (PlayerOwner().Level.IsDemoBuild())
    {
        b_SinglePlayer.DisableMe();
        b_MultiPlayer.SetFocus(none);
    }*/

    i_BkChar.Image = CharShots[rand(CharShots.Length)];
}




function InternalOnOpen()
{
    if (bNoInitDelay)
        Timer();
    else
        SetTimer(4.5,false);

    Controller.PerformRestore();
    /* 
    if( !PlayerOwner().level.game.IsA('cinematicgame'))
    {
        //	PlayerOwner().ConsoleCommand("Disconnect");
        bOpenAlready = True;
        PlayerOwner().ConsoleCommand("OPEN KF-Menu?Game=unrealgame.cinematicgame");
        PlayerOwner().ClientSetInitialMusic(MenuSong,MTRAN_Segue);
    }
    */
    PlayerOwner().ClientSetInitialMusic(MenuSong,MTRAN_Segue);
}

function bool MyOnDraw(Canvas Canvas)
{
    local GUIButton FButton;
    local int i,x2;
    local float XL,YL;
    local float DeltaTime;

    if (bAnimating || !Controller.bCurMenuInitialized )
        return false;

    DeltaTime=Controller.RenderDelta;

    for (i=0;i<Controls.Length;i++)
    {
        if ( (GUIButton(Controls[i])!=None) )
        {

            FButton = GUIButton(Controls[i]);
            if (FButton.Tag>0 && FButton.MenuState!=MSAT_Focused)
            {
                FButton.Tag -= 784*DeltaTime;
                if (FButton.Tag<0)
                    FButton.Tag=0;
            }
            else if (FButton.MenuState==MSAT_Focused)
                FButton.Tag=200;

            if (FButton.Tag>0)
            {
                fButton.Style.TextSize(Canvas,MSAT_Focused, FButton.Caption,XL,YL,FButton.FontScale);
                x2 = FButton.ActualLeft() + XL + 16;
                Canvas.Style=5;
                Canvas.SetDrawColor(150,25,25,FButton.Tag);
                Canvas.SetPos(0,fButton.ActualTop());
                Canvas.DrawTilePartialStretched(material'Highlight',x2,FButton.ActualHeight());
            }
        }
    }

    return false;
}




event Timer()
{




  if (!bMovingOnTraining && !bMovingOnResume &&!bMovingOnSP)
  {
    bNoInitDelay = true;
    if (!Controller.bQuietMenu)
        PlayerOwner().PlaySound(SlideInSound,SLOT_None);
    i_TV.Animate(-0.000977, 0.332292, 0.35);
    i_UT2Logo.Animate(0.007226,0.016926,0.35);
    i_UT2Shader.Animate(0.249023,0.180988,0.35);
    i_TV.OnEndAnimation = MenuIn_OnArrival;
    i_UT2Logo.OnEndAnimation = MenuIn_OnArrival;
    i_UT2Shader.OnEndAnimation = MenuIn_OnArrival;

  }

  else
  {
    if (bMovingOnResume)
    {
     bMovingOnResume = false;
     Controller.ConsoleCommand("OPEN KFS-RESUMEGAME?Game=KFmod.KFSPGameType");
    }

     if (bMovingOnTraining)
    {
     bMovingOnTraining = false;
     //Controller.ConsoleCommand("OPEN KFS-TRAINING?Game=KFmod.KFSPGameType");
     Controller.ConsoleCommand("OPEN KF-MANOR?Game=KFmod.KFGameType");
    }

     if (bMovingOnSP)
    {
     bMovingOnSP = false;
     //Controller.ConsoleCommand("OPEN KFS-INTRO?Game=KFmod.KFSPGameType");
     Controller.ConsoleCommand("OPEN KF-G-BIOTICSLAB?Game=KFmod.KFGameType");
    }

  }

}

event Opened(GUIComponent Sender)
{
    Super.Opened(Sender);
   // KFLogoBit.Animate(1,0.368813,0);

}


function MoveOn()
{

    switch (Selected)
    {
        case b_SinglePlayer:

             // NO MORE RESUME GAME FOR NOW

             //Profile("SinglePlayer");
             //Controller.ConsoleCommand( "DISCONNECT" );
             //bMovingOnResume = true;
             //SetTimer(0.5,false);
             //Profile("SinglePlayer");

            return;

        case b_MultiPlayer:
            if ( !Controller.AuthroizeFirewall() )
            {
                Controller.OpenMenu("GUI2K4.UT2K4GenericMessageBox",FireWallTitle,FireWallMsg);
                return;
            }
            Profile("ServerBrowser");
            Controller.OpenMenu("KFGUI.KFServerBrowser");
            Profile("ServerBrowser");
            return;
            


        case b_Host:
            if ( !Controller.AuthroizeFirewall() )
            {
                Controller.OpenMenu("GUI2K4.UT2K4GenericMessageBox",FireWallTitle,FireWallMsg);
                return;
            }
            Profile("MPHost");
            Controller.OpenMenu("KFGUI.KFGamePageMP");
            Profile("MPHost");
            return;

        case b_SoloPlay:
            Profile("SoloPlay");
            Controller.OpenMenu("KFGUI.KFGamePageSP");
            Profile("SoloPlay");
            return;

        case b_InstantAction:

             Profile("InstantAction");
             Controller.ConsoleCommand( "DISCONNECT" );
             bMovingOnSP = true;
             SetTimer(0.5,false);
             Profile("InstantAction");

            return;


        case b_ModsAndDemo:
            if ( !Controller.AuthroizeFirewall() )
            {
               Controller.OpenMenu("GUI2K4.UT2K4GenericMessageBox",FireWallTitle,FireWallMsg);
               return;
            }
            

            Profile("ModsandDemos");

            //Controller.ConsoleCommand( "DISCONNECT" );
            //bMovingOnTraining = true;
            
             Controller.ViewportOwner.Console.ConsoleCommand("OPEN KF-Intro?Game=unrealgame.cinematicgame");
             Controller.CloseAll(True);

            SetTimer(0.5,false);
            Profile("ModsandDemos");
            return;

        case b_Settings:
            Profile("Settings");
            Controller.OpenMenu("KFGUI.KFSettingsPage");
            Profile("Settings");
            return;

        case b_Quit:
            Profile("Quit");
            Controller.OpenMenu(Controller.GetQuitPage());
            Profile("Quit");
            return;

        default:
            StopWatch(True);
    }
}




function MenuIn_OnArrival(GUIComponent Sender, EAnimationType Type)
{
    Sender.OnArrival = none;
    if ( bAnimating )
        return;

    i_UT2Shader.OnDraw = MyOnDraw;
    DesiredCharFade=255;
    CharFadeTime = 0.75;

    if (!Controller.bQuietMenu)
        PlayerOwner().PlaySound(FadeInSound);

   /*
    KFLogoBit.Animate(0.2,0.25,0.25);
    KFLogoBit.OnArrival = PlayPopSound;


   // b_SinglePlayer.Animate(0.315359,0.468813,0.35);    // (0.315359,0.468813,0.35) SP
   // b_SinglePlayer.OnArrival = PlayPopSound;
    b_Multiplayer.Animate(0.0,0.91,0.25);    // (0.363246,0.549282,0.40) MP
    b_Multiplayer.OnArrival = PlayPopSound;
    b_Host.Animate(0.15,0.91,0.35);    // b_Host.Animate(0.395097,0.534027,0.45);
    b_Host.OnArrival = PlayPopSound;
   // b_InstantAction.Animate(0.315359,0.368813,0.35);  // b_InstantAction.Animate(0.315359,0.368813,0.35);
   // b_InstantAction.OnArrival = PlayPopSound;
    b_ModsAndDemo.Animate(0.4,0.91,0.40);  // b_ModsAndDemo.Animate(0.412406,0.710,0.55);
    b_ModsAndDemo.OnArrival = PlayPopSound;
    b_Settings.Animate(0.55,0.91,0.45);    // b_Settings.Animate(0.433406,0.705859,0.55);
    b_Settings.OnArrival = PlayPopSound;
    b_Quit.Animate(0.8,0.91,0.55);      // b_Quit.Animate(0.434477,0.800327,0.6);
    b_Quit.OnArrival = MenuIn_Done;
	bOpenAlready = False;
    */
}

function MainReopened()
{
    if ( !PlayerOwner().Level.IsPendingConnection() )
    {
        i_BkChar.Image = CharShots[rand(CharShots.Length)];
        Opened(none);
        Timer();
    }
}


function OnClose(optional Bool bCancelled)
{
}

function bool MyKeyEvent(out byte Key,out byte State,float delta)
{
    if(Key == 0x1B && state == 1)   // Escape pressed
        bAllowClose = true;

    return false;
}

function bool CanClose(optional bool bCancelled)
{
    if(bAllowClose)
        ButtonClick(b_Quit);

    bAllowClose = False;
    return PlayerOwner().Level.IsPendingConnection();
}

function PlayPopSound(GUIComponent Sender, EAnimationType Type)
{
    if (!Controller.bQuietMenu)
        PlayerOwner().PlaySound(PopInSound);
}

function MenuIn_Done(GUIComponent Sender, EAnimationType Type)
{
    Sender.OnArrival = none;
    PlayPopSound(Sender,Type);
}


function bool ButtonClick(GUIComponent Sender)
{
    if (GUIButton(Sender) != None)
        Selected = GUIButton(Sender);

    if (Selected==None)
        return false;

  /*
    InitAnimOut( i_TV, -0.000977, 1.668619, 0.35);
    InitAnimOut(i_UT2Logo, 0.007226,-0.392579,0.35);
    InitAnimOut(i_UT2Shader,0.249023,-0.105470,0.35);
    InitAnimOut(b_SinglePlayer,1,0.368813,0.35);
    InitAnimOut(b_Multiplayer,1.15,0.449282,0.35);
    InitAnimOut(b_Host,1.3,0.534027,0.35);
    InitAnimOut(b_InstantAction,1.45,0.618619,0.35);
    InitAnimOut(b_ModsAndDemo,1.6,0.705859,0.35);
    InitAnimOut(b_Settings,1.75,0.800327,0.35);
    InitAnimOut(b_Quit,1.9,0.887567,0.35);
    */

    DesiredCharFade=0;
    CharFadeTime = 0.35;
    
    MoveOn();


    return true;
}
/*

function InitAnimOut( GUIComponent C, float X, float Y, float Z )
{
    if ( C == None )
    {
        Warn("UT2K4MainMenu.InitAnimOut called with null component!");
        return;
    }

    C.Animate(X,Y,Z);
    C.OnEndAnimation = MenuOut_Done;
}       
*/

function MenuOut_Done(GUIComponent Sender, EAnimationType Type)
{
    Sender.OnArrival = none;
    if ( bAnimating )
        return;

    MoveOn();
}

event bool NotifyLevelChange()
{
    if ( bDebugging )
        log(Name@"NotifyLevelChange  PendingConnection:"$PlayerOwner().Level.IsPendingConnection());

    return PlayerOwner().Level.IsPendingConnection();
}


function bool CommunityDraw(canvas c)
{
    local float x,y,xl,yl,a;
    if (bNewNews)
    {

        a = 255.0 * (FadeTime/1.0);
        if (FadeOut)
            a = 255 - a;

        FadeTime += Controller.RenderDelta;
        if (FadeTime>=1.0)
        {
            FadeTime = 0;
            FadeOut = !FadeOut;
        }

        a = fclamp(a,1.0,254.0);
        x = b_ModsAndDemo.ActualLeft();
        y = b_Settings.ActualTop();
        C.Font = Controller.GetMenuFont("UT2MenuFont").GetFont(C.ClipX);
        C.Strlen("Qz,q",xl,yl);
        y -= yl - 5;
        C.Style=5;
        C.SetPos(x+1,y+1);
        C.SetDrawColor(0,0,0,A);
        C.DrawText(NewNewsMsg);

        C.SetPos(x,y);
        C.SetDrawColor(207,185,103,A);
        C.DrawText(NewNewsMsg);
    }

    return false;
}

defaultproperties
{
     Begin Object Class=GUIImage Name=KFMenuLogo
         Image=FinalBlend'KillingFloorHUD.KFLogoFB'
         ImageStyle=ISTY_Scaled
         WinTop=0.250000
         WinLeft=0.200000
         WinWidth=0.620000
         WinHeight=0.300000
         RenderWeight=0.050000
     End Object
     KFLogoBit=GUIImage'KFGui.KFMainMenu.KFMenuLogo'

     Begin Object Class=GUILabel Name=KFVersionNumLabel
         Caption="v2.54"
         TextAlign=TXTA_Right
         TextColor=(B=0)
         WinTop=0.200000
         WinLeft=0.500000
         WinWidth=0.300000
         WinHeight=0.150000
         TabOrder=6
     End Object
     KFVersionNum=GUILabel'KFGui.KFMainMenu.KFVersionNumLabel'

     Begin Object Class=BackgroundImage Name=ImgBkChar
         ImageColor=(A=160)
         ImageRenderStyle=MSTY_Alpha
         X1=0
         Y1=0
         X2=1024
         Y2=768
         RenderWeight=0.040000
         Tag=0
     End Object
     i_bkChar=BackgroundImage'KFGui.KFMainMenu.ImgBkChar'

     Begin Object Class=BackgroundImage Name=PageBackground
         ImageStyle=ISTY_Scaled
         ImageRenderStyle=MSTY_Alpha
         X1=0
         Y1=0
         X2=1024
         Y2=768
     End Object
     i_Background=BackgroundImage'KFGui.KFMainMenu.PageBackground'

     Begin Object Class=GUIImage Name=ImgUT2Logo
     End Object
     i_UT2Logo=GUIImage'KFGui.KFMainMenu.ImgUT2Logo'

     Begin Object Class=GUIImage Name=iPanHuge
     End Object
     i_PanHuge=GUIImage'KFGui.KFMainMenu.iPanHuge'

     Begin Object Class=GUIImage Name=iPanBig
     End Object
     i_PanBig=GUIImage'KFGui.KFMainMenu.iPanBig'

     Begin Object Class=GUIImage Name=iPanSmall
     End Object
     i_PanSmall=GUIImage'KFGui.KFMainMenu.iPanSmall'

     Begin Object Class=GUIImage Name=ImgUT2Shader
     End Object
     i_UT2Shader=GUIImage'KFGui.KFMainMenu.ImgUT2Shader'

     Begin Object Class=GUIImage Name=ImgTV
     End Object
     i_TV=GUIImage'KFGui.KFMainMenu.ImgTV'

     Begin Object Class=GUIButton Name=MultiplayerButton
         CaptionEffectStyleName="TextButtonEffect"
         Caption="Servers"
         bUseCaptionHeight=True
         StyleName="ListSelection"
         Hint="All hell breaks loose..."
         WinTop=0.470000
         WinLeft=0.232000
         WinWidth=0.082000
         WinHeight=0.075000
         TabOrder=1
         bFocusOnWatch=True
         OnClick=KFMainMenu.ButtonClick
         OnKeyEvent=MultiplayerButton.InternalOnKeyEvent
     End Object
     b_MultiPlayer=GUIButton'KFGui.KFMainMenu.MultiplayerButton'

     Begin Object Class=GUIButton Name=HostButton
         CaptionEffectStyleName="TextButtonEffect"
         Caption="Create Game"
         bUseCaptionHeight=True
         StyleName="ListSelection"
         Hint="Start a server and invite others to join your game"
         WinTop=0.470000
         WinLeft=0.314000
         WinWidth=0.110000
         WinHeight=0.075000
         TabOrder=2
         bFocusOnWatch=True
         OnClick=KFMainMenu.ButtonClick
         OnKeyEvent=HostButton.InternalOnKeyEvent
     End Object
     b_Host=GUIButton'KFGui.KFMainMenu.HostButton'

     Begin Object Class=GUIButton Name=SoloPlayButton
         CaptionEffectStyleName="TextButtonEffect"
         Caption="Solo Play"
         bUseCaptionHeight=True
         StyleName="ListSelection"
         Hint="Play solo offline"
         WinTop=0.470000
         WinLeft=0.424000
         WinWidth=0.088000
         WinHeight=0.075000
         TabOrder=3
         bFocusOnWatch=True
         OnClick=KFMainMenu.ButtonClick
         OnKeyEvent=SoloPlayButton.InternalOnKeyEvent
     End Object
     b_SoloPlay=GUIButton'KFGui.KFMainMenu.SoloPlayButton'

     Begin Object Class=GUIButton Name=ModsAndDemosButton
         CaptionEffectStyleName="TextButtonEffect"
         Caption="Credits "
         bUseCaptionHeight=True
         StyleName="ListSelection"
         Hint="The Talent behind KF"
         WinTop=0.470000
         WinLeft=0.512000
         WinWidth=0.082000
         WinHeight=0.075000
         TabOrder=6
         bFocusOnWatch=True
         OnDraw=KFMainMenu.CommunityDraw
         OnClick=KFMainMenu.ButtonClick
         OnKeyEvent=ModsAndDemosButton.InternalOnKeyEvent
     End Object
     b_ModsAndDemo=GUIButton'KFGui.KFMainMenu.ModsAndDemosButton'

     Begin Object Class=GUIButton Name=SettingsButton
         CaptionEffectStyleName="TextButtonEffect"
         Caption="Settings"
         bUseCaptionHeight=True
         StyleName="ListSelection"
         Hint="Change your controls and settings"
         WinTop=0.470000
         WinLeft=0.594000
         WinWidth=0.088000
         WinHeight=0.075000
         TabOrder=4
         bFocusOnWatch=True
         OnClick=KFMainMenu.ButtonClick
         OnKeyEvent=SettingsButton.InternalOnKeyEvent
     End Object
     b_Settings=GUIButton'KFGui.KFMainMenu.SettingsButton'

     Begin Object Class=GUIButton Name=QuitButton
         CaptionEffectStyleName="TextButtonEffect"
         Caption="Exit "
         bUseCaptionHeight=True
         StyleName="ListSelection"
         Hint="Leave the game"
         WinTop=0.470000
         WinLeft=0.682000
         WinWidth=0.097000
         WinHeight=0.075000
         TabOrder=5
         bFocusOnWatch=True
         OnClick=KFMainMenu.ButtonClick
         OnKeyEvent=QuitButton.InternalOnKeyEvent
     End Object
     b_Quit=GUIButton'KFGui.KFMainMenu.QuitButton'

     MenuSong="KFMenu"
     PopInSound=Sound'PatchSounds.slide1-1'
     SlideInSound=Sound'PatchSounds.slide1-1'
     BeepSound=Sound'KFWeaponSound.bullethitmetal3'
     bRenderWorld=True
     bPersistent=True
     OnOpen=KFMainMenu.InternalOnOpen
     OnReOpen=KFMainMenu.MainReopened
     OnCanClose=KFMainMenu.CanClose
     OnKeyEvent=KFMainMenu.MyKeyEvent
}
