class GUIVeterancyBinder extends  UT2K4GUIPage;

var Automated GUIImage MyHeader;
var Automated GUIButton bContinue;

var Automated array<GUIVeterancyButton> bSkills;
var array< Class<KFVeterancyTypes> > SkillsCl;
var Class<KFVeterancyTypes> ChosenClass;

var bool bIgnoreEsc,bPerButtonSizes,bHasAddedPerks,bAsked;
var array<string> SkillText;	// what each perk gives, or what it takes and how far along that is
var float PanelX,PanelY;		// where the panel that says so is drawn: beside the tiles

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
	local int i,Y,XLeft,FYL;
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

	bContinue.WinWidth = FMax(SX,100);
	bContinue.WinLeft = Canvas.ClipX / 60;
	bContinue.WinHeight = FMax(SX/2,20);

	// Starting Y position
	Y = Canvas.ClipY / 30.0;   // +-24
	FYL = Y;
	MYL = Canvas.ClipY/5.f*4.f-bContinue.WinHeight;
	XLeft = bContinue.WinLeft;
	for (i = 0; i < Components.Length; i++)
	{
		if (GUIButton(Components[i]) != None && Components[i]!=bContinue )
		{
			Components[i].WinTop = Y;
			Components[i].WinLeft = XLeft;
			Components[i].WinWidth = SX;
			Components[i].WinHeight = SY;
			Y+=SY;
			if( FYL<Y )
				FYL = Y;
			if( Y>MYL )
			{
				Y = Canvas.ClipY / 30.0;
				XLeft+=SX;
			}
		}
	}
	bContinue.WinTop = FYL+2;
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
			ChosenClass = SkillsCl[i];
			KFPlayerController(PlayerOwner()).SelectVeterancy(ChosenClass);
			Controller.CloseMenu();
			return true;
		}
	}
	return false;
}
// Beside the tiles: what the perk under the mouse gives, or what it takes and how far along that is. With the mouse
// on none, the one clicked; with none clicked, the one the player has. And a frame round the one clicked.
function InternalOnRendered(Canvas C)
{
	local int i,Show,Chosen;
	local float W,H,XL,YL,Pad,Y,L,T,BW,BH;
	local array<string> Lines;
	local string Foot;
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
	if( Chosen>=0 )
	{
		L = bSkills[Chosen].ActualLeft();
		T = bSkills[Chosen].ActualTop();
		BW = bSkills[Chosen].ActualWidth();
		BH = bSkills[Chosen].ActualHeight();
		C.SetDrawColor(250,100,100,255);
		C.SetPos(L,T);
		C.DrawTile(Texture'Engine.WhiteTexture',BW,2,0,0,1,1);
		C.SetPos(L,T+BH-2);
		C.DrawTile(Texture'Engine.WhiteTexture',BW,2,0,0,1,1);
		C.SetPos(L,T);
		C.DrawTile(Texture'Engine.WhiteTexture',2,BH,0,0,1,1);
		C.SetPos(L+BW-2,T);
		C.DrawTile(Texture'Engine.WhiteTexture',2,BH,0,0,1,1);
	}
	if( Show>=0 && Show<SkillText.Length )
	{
		// the biggest of the HUD's fonts whose lines are no taller than a thirty-eighth of the screen
		for( i=0; i<8; i++ )
		{
			C.Font = class'HudBase'.static.LoadFontStatic(i);
			C.TextSize("Wg",XL,YL);
			if( YL<=C.ClipY/38.0 )
				break;
		}
		Pad = YL*0.6;
		W = FMin(C.ClipX*0.44,C.ClipX-PanelX-C.ClipX/60.0);
		C.WrapStringToArray(SkillText[Show],Lines,W-2.0*Pad,"|");
		// (what a perk gives begins with its name; what one takes does not, and gets the name as a heading)
		H = float(Lines.Length+3)*YL+2.0*Pad;
		if( bSkills[Show].bNoSelectMe )
			H += YL;
		C.SetDrawColor(0,0,0,200);
		C.SetPos(PanelX,PanelY);
		C.DrawTile(Texture'Engine.WhiteTexture',W,H,0,0,1,1);
		Y = PanelY+Pad;
		if( bSkills[Show].bNoSelectMe )
		{
			C.SetDrawColor(250,100,100,255);
			C.SetPos(PanelX+Pad,Y);
			C.DrawText(SkillsCl[Show].Default.VeterancyName);
			Y += YL;
		}
		Foot = "";
		for( i=0; i<Lines.Length; i++ )
		{
			// (its first line that says anything is the heading)
			if( !bSkills[Show].bNoSelectMe && Foot=="" && Lines[i]!="" )
			{
				Foot = Lines[i];
				C.SetDrawColor(250,100,100,255);
			}
			else C.SetDrawColor(220,220,220,255);
			C.SetPos(PanelX+Pad,Y);
			C.DrawText(Lines[i]);
			Y += YL;
		}
		if( bSkills[Show].bNoSelectMe )
			Foot = "Not earned yet";
		else if( Mine!=None && SkillsCl[Show]==Mine )
			Foot = "This is your perk now";
		else Foot = "Double-click to take it";
		Y += YL;
		C.SetDrawColor(250,100,100,255);
		C.SetPos(PanelX+Pad,Y);
		C.DrawText(Foot);
	}
	C.Style = 1;
	C.SetDrawColor(255,255,255,255);
}

function bool InternalOnClick(GUIComponent Sender)
{
	local int i;
	if(Sender==bContinue) // CONTINUE
	{
		if( ChosenClass!=None )
			KFPlayerController(PlayerOwner()).SelectVeterancy(ChosenClass);
		Controller.CloseMenu(); // Close _all_ menus
	}
	else if( GUIVeterancyButton(Sender)!=None && !GUIVeterancyButton(Sender).bNoSelectMe )
	{
		for( i=0; i<bSkills.Length; i++ )
		{
			if( bSkills[i]==Sender )
			{
				ChosenClass = SkillsCl[i];
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
    // Swallow first escape key event (key up from key down that opened menu)
    if(bIgnoreEsc && Key == 0x1B)
    {
        bIgnoreEsc = false;
        return true;
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

     Begin Object Class=GUIButton Name=ContMatchButton
         Caption="ACCEPT"
         TabOrder=0
         OnClick=GUIVeterancyBinder.InternalOnClick
         OnKeyEvent=ContMatchButton.InternalOnKeyEvent
     End Object
     bContinue=GUIButton'KFGui.GUIVeterancyBinder.ContMatchButton'

     bIgnoreEsc=True
     bRenderWorld=True
     bAllowedAsLast=True
     OnClose=GUIVeterancyBinder.InternalOnClose
     WinTop=0.475000
     WinHeight=1.000000
     OnPreDraw=GUIVeterancyBinder.InternalOnPreDraw
     OnRendered=GUIVeterancyBinder.InternalOnRendered
     OnMouseRelease=GUIVeterancyBinder.InternalOnMouseRelease
     OnKeyEvent=GUIVeterancyBinder.InternalOnKeyEvent
}
