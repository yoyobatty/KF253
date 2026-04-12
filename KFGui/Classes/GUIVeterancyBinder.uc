class GUIVeterancyBinder extends  UT2K4GUIPage;

var Automated GUIImage MyHeader;
var Automated GUIButton bContinue;

var Automated array<GUIVeterancyButton> bSkills;
var array< Class<KFVeterancyTypes> > SkillsCl;
var Class<KFVeterancyTypes> ChosenClass;

var bool bIgnoreEsc,bPerButtonSizes,bHasAddedPerks;

function AddSkill( Class<KFVeterancyTypes> VCl, bool bEnabled )
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
	else S = VCl.Default.VeterancyRequirement;
	ReplaceText(S,"|",Chr(10));
	bSkills[i].Hint = S;
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
		if( PC.ClientStatsState==2 )
		{
			for( i=0; i<PC.ActStats.Length; i++ )
				AddSkill(PC.ActStats[i].VetCl,PC.ActStats[i].bNotified);
			bHasAddedPerks = True;
			bStillInit = True;
		}
		else PC.RequestForClasses();
	}
	SX = FClamp(Canvas.ClipX/10,20,140);
	SY = FClamp(Canvas.ClipX/13,15,120);

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
	return false;
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
     OnMouseRelease=GUIVeterancyBinder.InternalOnMouseRelease
     OnKeyEvent=GUIVeterancyBinder.InternalOnKeyEvent
}
