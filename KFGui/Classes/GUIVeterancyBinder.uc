class GUIVeterancyBinder extends  UT2K4GUIPage;

var Automated GUIImage MyHeader;

var Automated array<GUIVeterancyButton> bSkills;
var array< Class<KFVeterancyTypes> > SkillsCl;
var Class<KFVeterancyTypes> ChosenClass;

var bool bIgnoreEsc,bPerButtonSizes,bHasAddedPerks,bAsked,bTaken;
var float PulseTime;			// how long since a perk was picked: its frame beats, waiting for the click that takes it
var color MineFrame,PickFrame;	// the frames round the perk held and the perk picked
var array<string> SkillText;	// what each perk gives, or what it takes and how far along that is
var float PanelX,PanelY;		// where the panel that says so is drawn: beside the tiles
var Font PanelFont,PanelHeadFont;	// its lettering: the old tooltip's Neuzeit, picked for the screen's height
var float PanelFontFor;
var int NeuzeitSizes[10];		// the sizes of Neuzeit there are, biggest first
var float TextShare;			// the lettering is no taller than this share of the screen
var color HeadColor,BodyColor,RuleColor;
var byte UnderAlpha;			// how dark the backing under the framed box is

function AddSkill( Class<KFVeterancyTypes> VCl, bool bEnabled, optional string Progress )
{
	local int i;
	local string S;

	i = bSkills.Length;
	bSkills.Length = i+1;
	SkillsCl.Length = i+1;
	SkillsCl[i] = VCl;
	bSkills[i] = New Class'GUIVeterancyButton';
	bSkills[i].Caption = VCl.Default.VeterancyName;
	//bSkills[i].StyleName = VCL.Default.VetButtonStyle;
	bSkills[i].PerksIcon = VCL.Default.OnHUDIcon;
	bSkills[i].OnClick = InternalOnClick;
	bSkills[i].TabOrder = (i+1);
	bSkills[i].WinTop = MyHeader.WinTop+0.2+i*0.1;
	bSkills[i].WinLeft = 0.05;
	bSkills[i].WinWidth = 1.0;//MyHeader.WinWidth-0.1;
	bSkills[i].WinHeight = 3.5;
	if( bEnabled )
		S = VCl.Default.VeterancyDescription;
	else
	{
		S = VCl.Default.VeterancyRequirement;
		if( Progress!="" )
			S = S$"||SO FAR:||"$Progress;
	}
	// (said in the panel beside the tiles, not in a tooltip: it is there without waiting over a tile)
	SkillText[i] = S;
	bSkills[i].Hint = "";
	bSkills[i].OnDblClick = InternalOnDblClick;
	AppendComponent(bSkills[i],False);
	if( !bEnabled )
		bSkills[i].MakeMeUnavailable();
}
function bool InternalOnPreDraw(Canvas Canvas)
{
	local int i,Y,XLeft;
	local float MYL,SX,SY;
	local KFPlayerController PC;
	local bool bStillInit;

	if( !bHasAddedPerks )
	{
		PC = KFPlayerController(PlayerOwner());
		if( !bAsked )
		{
			// (asked for anew each time the screen opens: how far along each perk is has moved on)
			bAsked = True;
			PC.RefreshClasses();
		}
		else if( PC.ClientStatsState==2 )
		{
			for( i=0; i<PC.ActStats.Length; i++ )
			{
				if( i<PC.ActProgress.Length )
					AddSkill(PC.ActStats[i].VetCl,PC.ActStats[i].bNotified,PC.ActProgress[i]);
				else AddSkill(PC.ActStats[i].VetCl,PC.ActStats[i].bNotified);
			}
			bHasAddedPerks = True;
			bStillInit = True;
		}
	}
	// They stopped growing at 140 by 120 pixels: on a bigger screen they keep the share of its height a 4:3 screen gave them.
	SX = FMax(FClamp(Canvas.ClipX/10,20,140),Canvas.ClipY/7.5);
	SY = FMax(FClamp(Canvas.ClipX/13,15,120),Canvas.ClipY/9.75);

	// Positional Values for the Background
	MyHeader.WinLeft = 0;
	MyHeader.WinTop = 0;
	MyHeader.WinHeight = Canvas.ClipY;
	MyHeader.WinWidth = Canvas.ClipX;

	// Starting Y position
	Y = Canvas.ClipY / 30.0;   // +-24
	MYL = Canvas.ClipY/5.f*4.f;
	XLeft = Canvas.ClipX / 60;
	for (i = 0; i < Components.Length; i++)
	{
		if (GUIButton(Components[i]) != None )
		{
			Components[i].WinTop = Y;
			Components[i].WinLeft = XLeft;
			Components[i].WinWidth = SX;
			Components[i].WinHeight = SY;
			Y+=SY;
			if( Y>MYL )
			{
				Y = Canvas.ClipY / 30.0;
				XLeft+=SX;
			}
		}
	}
	PanelX = XLeft+SX+Canvas.ClipX/60.0;
	PanelY = Canvas.ClipY/30.0;
	return false;
}
// A double click on a perk that can be had takes it and closes the screen
function bool InternalOnDblClick(GUIComponent Sender)
{
	local int i;
	if( GUIVeterancyButton(Sender)==None || GUIVeterancyButton(Sender).bNoSelectMe )
		return false;
	for( i=0; i<bSkills.Length; i++ )
	{
		if( bSkills[i]==Sender )
		{
			TakeSkill(i);
			return true;
		}
	}
	return false;
}
// A perk taken, and the screen closed (taking the one already held only closes it)
function TakeSkill(int i)
{
	local KFPlayerController PC;

	if( bTaken )
		return;
	bTaken = True;
	ChosenClass = SkillsCl[i];
	PC = KFPlayerController(PlayerOwner());
	if( PC!=None && (KFPlayerReplicationInfo(PC.PlayerReplicationInfo)==None
	 || KFPlayerReplicationInfo(PC.PlayerReplicationInfo).ClientVeteranSkill!=ChosenClass) )
		PC.SelectVeterancy(ChosenClass);
	Controller.CloseMenu();
}
// Beside the tiles: what the perk under the mouse gives, or what it takes and how far along that is. With the mouse
// on none, the one clicked; with none clicked, the one the player has. And frames round those two.
function InternalOnRendered(Canvas C)
{
	local int i,Show,Chosen;
	local float W,H,XL,YL,HY,Pad,Y;
	local array<string> Lines;
	local string Head;
	local color Col;
	local GUIStyles Sty;
	local eFontScale FS;
	local Class<KFVeterancyTypes> Mine;

	Show = -1;
	Chosen = -1;
	if( KFPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo)!=None )
		Mine = KFPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo).ClientVeteranSkill;
	for( i=0; i<bSkills.Length; i++ )
	{
		if( ChosenClass!=None && SkillsCl[i]==ChosenClass )
			Chosen = i;
		if( bSkills[i].MenuState==MSAT_Watched || bSkills[i].MenuState==MSAT_Pressed )
			Show = i;
	}
	if( Show<0 )
		Show = Chosen;
	for( i=0; i<bSkills.Length && Show<0; i++ )
	{
		if( Mine!=None && SkillsCl[i]==Mine )
			Show = i;
	}
	C.Style = 5;
	// the perk held: a steady dim frame; the one picked: a bright one that beats, waiting for the click that takes it
	PulseTime += Controller.RenderDelta;
	for( i=0; i<bSkills.Length; i++ )
	{
		if( Mine!=None && SkillsCl[i]==Mine && i!=Chosen )
			TileFrame(C,i,MineFrame);
	}
	if( Chosen>=0 )
	{
		Col = PickFrame;
		Col.A = byte(float(PickFrame.A)*(0.67+0.33*Cos(PulseTime*6.0)));
		TileFrame(C,Chosen,Col);
	}
	if( Show>=0 && Show<SkillText.Length )
	{
		if( PanelFontFor!=C.ClipY )
			PickPanelFonts(C);
		C.Font = PanelFont;
		C.TextSize("Wg",XL,YL);
		C.Font = PanelHeadFont;
		C.TextSize("Wg",XL,HY);
		Pad = YL*0.9;
		W = FMin(C.ClipX*0.44,C.ClipX-PanelX-C.ClipX/60.0);
		C.Font = PanelFont;
		C.WrapStringToArray(SkillText[Show],Lines,W-2.0*Pad,"|");
		// (what a perk gives begins with its name, which is its heading; what one takes does not, and gets the name)
		if( bSkills[Show].bNoSelectMe )
			Head = Caps(SkillsCl[Show].Default.VeterancyName);
		while( Lines.Length>0 && Lines[0]=="" )
			Lines.Remove(0,1);
		if( Head=="" && Lines.Length>0 )
		{
			Head = Lines[0];
			Lines.Remove(0,1);
		}
		while( Lines.Length>0 && Lines[0]=="" )
			Lines.Remove(0,1);
		while( Lines.Length>0 && Lines[Lines.Length-1]=="" )
			Lines.Remove(Lines.Length-1,1);
		H = 2.0*Pad+HY+YL*0.6+float(Lines.Length)*YL;
		// the old tooltip's framed box, over a dark backing so the game behind does not show through the words
		C.SetDrawColor(0,0,0,UnderAlpha);
		C.SetPos(PanelX,PanelY);
		C.DrawTile(Texture'Engine.WhiteTexture',W,H,0,0,1,1);
		Sty = Controller.GetStyle("VetToolTipStyle",FS);
		if( Sty!=None )
			Sty.Draw(C,MSAT_Blurry,PanelX,PanelY,W,H);
		C.Style = 5;
		Y = PanelY+Pad;
		C.Font = PanelHeadFont;
		PanelText(C,Head,PanelX+Pad,Y,HeadColor);
		Y += HY+YL*0.3;
		C.DrawColor = RuleColor;
		C.SetPos(PanelX+Pad,Y);
		C.DrawTile(Texture'Engine.WhiteTexture',W-2.0*Pad,FMax(1.0,float(int(YL/12.0))),0,0,1,1);
		Y += YL*0.3;
		C.Font = PanelFont;
		for( i=0; i<Lines.Length; i++ )
		{
			PanelText(C,Lines[i],PanelX+Pad,Y,BodyColor);
			Y += YL;
		}
	}
	C.Style = 1;
	C.SetDrawColor(255,255,255,255);
}

// The panel's lettering: Neuzeit, as the old tooltip had, the biggest no taller than a share of the screen's height;
// the heading the next size up
function PickPanelFonts(Canvas C)
{
	local int i;

	PanelFontFor = C.ClipY;
	for( i=0; i<ArrayCount(NeuzeitSizes)-1; i++ )
	{
		if( NeuzeitSizes[i]<=C.ClipY*TextShare )
			break;
	}
	PanelFont = Font(DynamicLoadObject("UT2003Fonts.FontNeuzeit"$NeuzeitSizes[i],class'Font'));
	PanelHeadFont = Font(DynamicLoadObject("UT2003Fonts.FontNeuzeit"$NeuzeitSizes[Max(i-1,0)],class'Font'));
	if( PanelFont==None )
		PanelFont = class'HudBase'.static.LoadFontStatic(5);
	if( PanelHeadFont==None )
		PanelHeadFont = PanelFont;
}
// A frame round a perk's tile
function TileFrame(Canvas C, int i, color Col)
{
	local float L,T,BW,BH,F;

	L = bSkills[i].ActualLeft();
	T = bSkills[i].ActualTop();
	BW = bSkills[i].ActualWidth();
	BH = bSkills[i].ActualHeight();
	F = FMax(2.0,float(int(BW/60.0)));
	C.DrawColor = Col;
	C.SetPos(L,T);
	C.DrawTile(Texture'Engine.WhiteTexture',BW,F,0,0,1,1);
	C.SetPos(L,T+BH-F);
	C.DrawTile(Texture'Engine.WhiteTexture',BW,F,0,0,1,1);
	C.SetPos(L,T);
	C.DrawTile(Texture'Engine.WhiteTexture',F,BH,0,0,1,1);
	C.SetPos(L+BW-F,T);
	C.DrawTile(Texture'Engine.WhiteTexture',F,BH,0,0,1,1);
}
// A line of the panel, with a faint shadow under it
function PanelText(Canvas C, string S, float X, float Y, color Col)
{
	local float Off;

	if( S=="" )
		return;
	Off = FMax(1.0,float(int(PanelFontFor/720.0)));
	C.SetDrawColor(0,0,0,Col.A);
	C.SetPos(X+Off,Y+Off);
	C.DrawTextClipped(S);
	C.DrawColor = Col;
	C.SetPos(X,Y);
	C.DrawTextClipped(S);
}

// A click on a perk that can be had picks it; a second click on it, quick or slow, takes it
function bool InternalOnClick(GUIComponent Sender)
{
	local int i;
	if( GUIVeterancyButton(Sender)!=None && !GUIVeterancyButton(Sender).bNoSelectMe )
	{
		for( i=0; i<bSkills.Length; i++ )
		{
			if( bSkills[i]==Sender )
			{
				if( ChosenClass==SkillsCl[i] )
					TakeSkill(i);
				else
				{
					ChosenClass = SkillsCl[i];
					PulseTime = 0;
				}
				break;
			}
		}
	}
	return true;
}

function InternalOnMouseRelease(GUIComponent Sender)
{
    if (Sender == Self)
        Controller.CloseMenu();
}

function InternalOnClose(optional Bool bCanceled)
{
    local PlayerController pc;

    pc = PlayerOwner();

    // Turn pause off if currently paused
    if(pc != None && pc.Level.Pauser != None)
        pc.SetPause(false);

    Super.OnClose(bCanceled);
}


function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
	local string Bound;

	// The escape key's release, left from the press that opened this screen from the menu, is swallowed. (Its first
	// event was swallowed whatever it was: when the game opened the screen itself, it took two presses to leave.)
	if( bIgnoreEsc && Key==0x1B )
	{
		bIgnoreEsc = false;
		if( State==3 )
			return true;
	}
	// the key that opens this screen closes it as well
	if( State==1 && Key!=0x1B && Key!=0x01 && Key!=0x02 && Key!=0x04 )
	{
		Bound = PlayerOwner().ConsoleCommand("KEYBINDING"@PlayerOwner().ConsoleCommand("KEYNAME"@Key));
		if( InStr(Caps(Bound),"OPENVETERANCYMENU")>=0 )
		{
			Controller.CloseMenu();
			return true;
		}
	}
	return false;
}

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    local PlayerController PC;

    Super.InitComponent(MyController, MyOwner);
    PC = PlayerOwner();
}

defaultproperties
{
     Begin Object Class=GUIImage Name=MGHeader
         ImageStyle=ISTY_Stretched
         ImageRenderStyle=MSTY_Normal
         WinTop=600.000000
         WinWidth=0.350000
         WinHeight=0.250000
     End Object
     MyHeader=GUIImage'KFGui.GUIVeterancyBinder.MGHeader'



     bIgnoreEsc=True
     bRenderWorld=True
     bAllowedAsLast=True
     OnClose=GUIVeterancyBinder.InternalOnClose
     WinTop=0.475000
     WinHeight=1.000000
     OnPreDraw=GUIVeterancyBinder.InternalOnPreDraw
     OnRendered=GUIVeterancyBinder.InternalOnRendered
     NeuzeitSizes(0)=37
     NeuzeitSizes(1)=29
     NeuzeitSizes(2)=24
     NeuzeitSizes(3)=21
     NeuzeitSizes(4)=17
     NeuzeitSizes(5)=14
     NeuzeitSizes(6)=12
     NeuzeitSizes(7)=11
     NeuzeitSizes(8)=9
     NeuzeitSizes(9)=8
     TextShare=0.016667
     HeadColor=(R=255,G=45,B=35,A=255)
     BodyColor=(R=250,G=100,B=100,A=255)
     MineFrame=(R=250,G=150,B=140,A=170)
     PickFrame=(R=255,G=70,B=60,A=255)
     RuleColor=(R=150,G=20,B=15,A=220)
     UnderAlpha=170
     OnMouseRelease=GUIVeterancyBinder.InternalOnMouseRelease
     OnKeyEvent=GUIVeterancyBinder.InternalOnKeyEvent
}
