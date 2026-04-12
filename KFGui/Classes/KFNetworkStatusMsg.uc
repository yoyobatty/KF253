class KFNetworkStatusMsg extends UT2k4NetWorkStatusMsg;

defaultproperties
{
     Begin Object Class=GUIScrollTextBox Name=Scroller
         bNoTeletype=True
         OnCreateComponent=Scroller.InternalOnCreateComponent
         WinTop=0.133333
         WinLeft=0.033108
         WinWidth=0.925338
         WinHeight=0.790203
     End Object
     stbNetworkMessage=GUIScrollTextBox'KFGui.KFNetworkStatusMsg.Scroller'

     StatusMessages(3)="Sorry, This Killing Floor server does not accept late joiners."
     StatusMessages(9)="This copy of Killing Floor is not compatible with the server you are connecting to."
     StatusTitle(3)="No Late Joiners"
     StatusCodes(3)="FC_NoLateJoiners"
}
