class BullpupReflectManager extends Actor;

var ScriptedTexture     ViewMap;
var TexEnvMap           EnvMap;
var Actor               CamActor;
var bool                bUseDirection;
var float               UpdateSpeed;
var float               OtherUpdateSpeed;
var int                 ReflectSize;
var bool                bBoundToWeapon;
var() Shader            ReflectShader;  // The shader at mesh material index 5

simulated function PostBeginPlay()
{
    ViewMap = ScriptedTexture(Level.ObjectPool.AllocateObject(class'ScriptedTexture'));
    ViewMap.SetSize(ReflectSize, ReflectSize);
    ViewMap.Client = Self;

    EnvMap = TexEnvMap(Level.ObjectPool.AllocateObject(class'TexEnvMap'));
    EnvMap.EnvMapType = EM_WorldSpace;
    EnvMap.Material = ViewMap;

    SetTimer(UpdateSpeed, True);
    Enable('Timer');
}

simulated function BindToWeapon()
{
    local Bullpup Gun;

    Gun = Bullpup(Owner);
    if (Gun == None || EnvMap == None || ReflectShader == None)
        return;

    // Set the EnvMap as the specular channel of the existing shader
    ReflectShader.Specular = EnvMap;
    // Override the mesh material at index 5 with our modified shader
    Gun.Skins[5] = ReflectShader;
    bBoundToWeapon = true;
}

simulated function UpdateCamPosition()
{
    local Bullpup Gun;
    local PlayerController PC;

    Gun = Bullpup(Owner);
    if (Gun == None || Gun.Instigator == None || CamActor == None)
        return;

    PC = PlayerController(Gun.Instigator.Controller);
    if (PC != None)
    {
        CamActor.SetLocation(Gun.Instigator.Location + Gun.Instigator.EyePosition());
        CamActor.SetRotation(PC.GetViewRotation());
    }
}

simulated function Timer()
{
    if (Owner == None)
        return;

    if (Bullpup(Owner) != None && Bullpup(Owner).Instigator != None
        && PlayerController(Bullpup(Owner).Instigator.Controller) != None
        && Level.GetLocalPlayerController() == Bullpup(Owner).Instigator.Controller)
        SetTimer(UpdateSpeed, True);
    else
        SetTimer(OtherUpdateSpeed, True);

    if (Level.bDropDetail)
        return;

    if (!bBoundToWeapon)
        BindToWeapon();

    UpdateCamPosition();

    if (ViewMap != None)
        ViewMap.Revision++;
}

simulated event RenderTexture(ScriptedTexture Tex)
{
    local vector Tmp;
    local rotator Heh;

    if (Owner == None || CamActor == None)
        return;

    if (bUseDirection)
    {
        Tmp = (CamActor.Location + Owner.Location) * 0.5;
        Heh = rotator(CamActor.Location - Tmp);
    }
    else
        Heh = rotator(CamActor.Location - Owner.Location);
    Heh.Pitch = 0;

    Tex.DrawPortal(0, 0, Tex.USize, Tex.VSize, CamActor, CamActor.Location, Heh, 120, True);
}

defaultproperties
{
    ReflectShader=Shader'KillingFloorWeapons.L85.l85XHairShader'
    bUseDirection=False
    UpdateSpeed=0.080000
    OtherUpdateSpeed=5.000000
    ReflectSize=128
    bAlwaysRelevant=True
    RemoteRole=ROLE_None
    bHidden=True
}