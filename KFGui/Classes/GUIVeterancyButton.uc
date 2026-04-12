class GUIVeterancyButton extends GUIButton;

#exec obj load file="UT2003Fonts.utx"

var Material PerksIcon;
var bool bNoSelectMe;

function MakeMeUnavailable()
{
	OnClickSound = CS_None;
	bNoSelectMe = True;
	bMouseOverSound = False;
}
function bool RenderPerkIcon(Canvas Canvas, eMenuState MenuState, float left, float top, float width, float height)
{
	local Material T;
	local float TX,TY,XL,YL;

	TX = Canvas.ClipX;
	TY = Canvas.ClipY;
	Canvas.OrgX = left;
	Canvas.OrgY = top;
	Canvas.ClipX = width;
	Canvas.ClipY = height;
	Canvas.CurX = 0;
	Canvas.CurY = 0;

	if( bNoSelectMe )
		MenuState = MSAT_Disabled;
	T = Style.Images[MenuState];
	if( T!=None )
		Canvas.DrawTile(T,width,height,0,0,T.MaterialUSize(),T.MaterialVSize());
	if( PerksIcon!=None )
	{
		Canvas.CurX = 0;
		Canvas.CurY = 0;
		Canvas.DrawColor.A = 255;
		if( MenuState==MSAT_Disabled )
			Canvas.SetDrawColor(120,120,120,180);
		Canvas.DrawTile(PerksIcon,width,height,0,0,PerksIcon.MaterialUSize(),PerksIcon.MaterialVSize());
	}
	if( Len(Caption)>0 )
	{
		if( MenuState==MSAT_Disabled )
			Canvas.SetDrawColor(120,120,120,200);
		else Canvas.SetDrawColor(250,100,100,225);
		Canvas.Font = Font'jFontSmallText';
		Canvas.TextSize(Caption,XL,YL);
		Canvas.CurX = Canvas.ClipX/2-XL/2;
		Canvas.CurY = Canvas.ClipY-YL-1;
		Canvas.DrawTextClipped(Caption,False);
	}
	Canvas.OrgX = 0;
	Canvas.OrgY = 0;
	Canvas.ClipX = TX;
	Canvas.ClipY = TY;
	Canvas.SetDrawColor(255,255,255,255);
	Return True;
}

defaultproperties
{
	Begin Object Class=GUIVeterancyToolTip Name=GUIVetToolTip
	End Object
	ToolTip=GUIVetToolTip
	Begin Object Class=VetButtonStyles Name=GUIVetButStyle
		OnDraw=RenderPerkIcon
		FontColors(0)=(R=200,G=200,B=200,A=200)
    	FontColors(1)=(R=200,G=200,B=200,A=200)
    	FontColors(2)=(R=200,G=200,B=200,A=200)
    	FontColors(3)=(R=200,G=200,B=200,A=200)
    	FontColors(4)=(R=200,G=200,B=200,A=200)
		Images(0)=Texture'25Tex.Common.VetbutTemplate'
		Images(1)=Texture'25Tex.Common.VetbutTemplateSelect'
		Images(2)=Texture'25Tex.Common.VetbutTemplateSelect'
		Images(3)=Texture'25Tex.Common.VetbutTemplateSelect'
		Images(4)=Texture'25Tex.Common.VetbutTemplateDisabled'
		ImgColors(0)=(R=255,G=255,B=255,A=255)
    	ImgColors(1)=(R=255,G=255,B=255,A=255)
    	ImgColors(2)=(R=255,G=255,B=255,A=255)
    	ImgColors(3)=(R=255,G=255,B=255,A=255)
    	ImgColors(4)=(R=128,G=128,B=128,A=255)
	End Object
	Style=GUIVetButStyle
	StyleName="VeterancyButtonStyle"

}
