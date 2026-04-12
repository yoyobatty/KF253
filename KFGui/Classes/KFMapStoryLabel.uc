// Text Box for our Lobby. includes a little blurb about the map. (to make peace with myself for removing intro cutscenes :-/ )

class KFMapStoryLabel extends GUIScrollTextBox ;

var string StoryString;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
  
    Super.InitComponent(MyController, MyOwner);
    
    /*
    
 if (PlayerOwner().Level != none)
   StoryString = PlayerOwner().Level.Description ;


   SetContent(StoryString);




    if (DefaultListClass != "")
    {
        MyScrollText = GUIScrollText(AddComponent(DefaultListClass));
        if (MyScrollText == None)
        {
            log(Class$".InitComponent - Could not create default list ["$DefaultListClass$"]");
            return;
        }
    }

    if (MyScrollText == None)
    {
        Warn("Could not initialize list!");
        return;
    }

    InitBaseList(MyScrollText);
    */
}

function LoadStoryText()
{
 if (PlayerOwner().Level != none)
   StoryString = PlayerOwner().Level.Description ;


   SetContent(StoryString);
}

defaultproperties
{
     bNoTeletype=True
     CharDelay=0.010000
     EOLDelay=0.010000
     bVisibleWhenEmpty=True
     StyleName="TextLabel"
     WinTop=0.100000
     WinLeft=0.470000
     WinWidth=0.480000
     WinHeight=0.400000
     bAcceptsInput=False
     bNeverFocus=True
}
