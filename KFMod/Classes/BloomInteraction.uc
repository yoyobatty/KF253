//-----------------------------------------------------------
// Renders the bloom-mesh several times to create a blur effect
//-----------------------------------------------------------
class BloomInteraction extends Interaction;
 
var ScriptedTexture St;
var Actor BMesh;
var float dist;
var float fov;
var float dev;
var bool bEnableBloom,bXBloom;
var float devX;
var vector CamPos,X,Y,Z;
var Rotator CamRot;
 
event NotifyLevelChange()
{
        Master.RemoveInteraction(self);
        assert( St != None );
        ViewportOwner.Actor.Level.ObjectPool.FreeObject( St );
 
    //  (destroy any actors spawned by this interaction)
    //  (clean up any uscript objects that have been loaded)
}
 
function bool KeyEvent(EInputKey Key, EInputAction Action, FLOAT Delta )
{
 
    if ((Key == IK_PageUp) && (Action == IST_Release)) devX+=0.25;
    if ((Key == IK_PageDown) && (Action == IST_Release) && (devX>0)) devX-=0.25;
    if ((Key == IK_Home) && (Action == IST_Release))bEnableBloom=!bEnableBloom;
    if ((Key == IK_End) && (Action == IST_Release))bXBloom=!bXBloom;
    if ((Key == IK_Insert) && (Action == IST_Release)) dev+=0.05;
    if ((Key == IK_Delete) && (Action == IST_Release) && (dev>0)) dev-=0.05;
    log("dev");
    log(dev);
    
    return true;
}
 
//not used currently
function RenderBloomLayer(Canvas c, float devX, float mZ, float mY, float dev)
{
    bMesh.SetLocation(campos+(dist-devX)*vector(camrot)+(mZ*Z+mY*Y)*dev);
    C.DrawActor(bMesh,false,true);
}
 
function PostRender(canvas Canvas)
{
 
 
    local Font UsedFont;
    if(!bEnableBloom)return;
        if(UsedFont==None){
        UsedFont = Font(DynamicLoadObject("SECFonts.Arial", class'Font'));
    }
        Canvas.Font = UsedFont;
        Canvas.FontScaleX = 1;
        Canvas.FontScaleY = 1;
    Canvas.Style=ViewportOwner.Actor.ERenderStyle.STY_Normal;
 
 
    Canvas.DrawColor.R=255;
    Canvas.DrawColor.G=255;
    Canvas.DrawColor.B=255;
    //calc this frame
    st.Revision++;
 
    Canvas.GetCameraLocation(campos,camrot);
 
 
    bMesh.SetRotation(camrot);
    ViewportOwner.Actor.GetAxes(camrot,X,Y,Z);
 
    //moved to init
    //FinalBlend(bMesh.Skins[0]).Material=st;
 
 
    Canvas.SetPos(10,240);
 
 
 
 
    if(!bXBloom)
    {
    bMesh.SetLocation(campos+(dist-devX)*vector(camrot)+Z*dev);
    Canvas.DrawActor(bMesh,false,true);
    bMesh.SetLocation(campos+(dist-devX)*vector(camrot)-Z*dev);
    Canvas.DrawActor(bMesh,false,true);
    bMesh.SetLocation(campos+(dist-devX)*vector(camrot)+Y*dev);
    Canvas.DrawActor(bMesh,false,true);
    bMesh.SetLocation(campos+(dist-devX)*vector(camrot)-Y*dev);
    Canvas.DrawActor(bMesh,false,true);
    Canvas.DrawText("XBloom");
    }
    else
    {
    bMesh.SetLocation(campos+(dist-devX)*vector(camrot)+(Z+Y)*dev);
    Canvas.DrawActor(bMesh,false,true);
    bMesh.SetLocation(campos+(dist-devX)*vector(camrot)+(-Z+Y)*dev);
    Canvas.DrawActor(bMesh,false,true);
    bMesh.SetLocation(campos+(dist-devX)*vector(camrot)+(-X-Y)*dev);
    Canvas.DrawActor(bMesh,false,true);
    bMesh.SetLocation(campos+(dist-devX)*vector(camrot)+(-Y+Z)*dev);
    Canvas.DrawActor(bMesh,false,true);
    Canvas.DrawText("DoubleBloom");
    }
 
    Canvas.SetPos(10,200);
    Canvas.DrawText("Bloom Active");
 
    //innerglow
 
    if(!bXBloom)
    {
    bMesh.SetLocation(campos+(dist-devX/2)*vector(camrot)+Z*dev/2);
    Canvas.DrawActor(bMesh,false,true);
    bMesh.SetLocation(campos+(dist-devX/2)*vector(camrot)-Z*dev/2);
    Canvas.DrawActor(bMesh,false,true);
    bMesh.SetLocation(campos+(dist-devX/2)*vector(camrot)+Y*dev/2);
    Canvas.DrawActor(bMesh,false,true);
    bMesh.SetLocation(campos+(dist-devX/2)*vector(camrot)-Y*dev/2);
    Canvas.DrawActor(bMesh,false,true);
 
    }
    else
    {
    bMesh.SetLocation(campos+(dist-devX/2)*vector(camrot)+(Z+Y)*dev/2);
    Canvas.DrawActor(bMesh,false,true);
    bMesh.SetLocation(campos+(dist-devX/2)*vector(camrot)+(-Z+Y)*dev/2);
    Canvas.DrawActor(bMesh,false,true);
    bMesh.SetLocation(campos+(dist-devX/2)*vector(camrot)+(-Y-Z)*dev/2);
    Canvas.DrawActor(bMesh,false,true);
    bMesh.SetLocation(campos+(dist-devX/2)*vector(camrot)+(-Y+Z)*dev/2);
    Canvas.DrawActor(bMesh,false,true);
 
    }
}

defaultproperties
{
	Dist=40.000000
	FOV=90.000000
	Dev=0.280000
	bEnableBloom=True
	devX=1.600000
	bVisible=True
}
