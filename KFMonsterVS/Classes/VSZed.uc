// What every player's specimen shares (the Awesome classes): their aim, view, jump, held movement and ability bar
class VSZed extends Info
	abstract;

// The survivor (or door) a player's specimen strikes: the nearest one in reach in front of its view
static final function Actor MeleeTarget( KFMonster M )
{
	local Controller C;
	local Pawn P, Best;
	local vector Dir, HL, HN, Start;
	local float Reach, Dist, BestDist;
	local Actor A;

	Dir = vector(M.Controller.Rotation);
	Reach = M.MeleeRange * 1.4 + M.CollisionRadius;
	BestDist = 100000;
	for( C=M.Level.ControllerList; C!=None; C=C.NextController )
	{
		P = C.Pawn;
		if( P==None || P.Health<=0 || KFMonster(P)!=None || !C.bIsPlayer )
			continue;
		Dist = VSize(P.Location-M.Location) - P.CollisionRadius;
		if( Dist>Reach || Dist>BestDist || (Normal(P.Location-M.Location) Dot Dir)<0.5 || !M.FastTrace(P.Location,M.Location) )
			continue;
		Best = P;
		BestDist = Dist;
	}
	if( Best!=None )
		return Best;
	// (past its own extra collision, which a Crawler's body puts in the way)
	Start = M.Location + Dir*M.CollisionRadius*0.9;
	foreach M.TraceActors(class'Actor',A,HL,HN,Start+Dir*(Reach-M.CollisionRadius*0.4),Start)
	{
		if( A==M || A.Owner==M )
			continue;
		if( KFDoorMover(A)!=None || (KFHumanPawn(A)!=None && Pawn(A).Health>0) )
			return A;
		if( A.bWorldGeometry || LevelInfo(A)!=None )
			break;
	}
	return None;
}

// The player's own machine plays only the animations the server sends it
simulated static final function bool AllowAnim( KFMonster M, bool bFromServer )
{
	return M.Level.NetMode!=NM_Client || bFromServer || M.Controller==None || M.Level.GetLocalPlayerController()!=M.Controller;
}

// The server sends a remote player the animations their specimen plays
static final function bool SendAnim( KFMonster M )
{
	return M.Level.NetMode!=NM_Client && PlayerController(M.Controller)!=None && NetConnection(PlayerController(M.Controller).Player)!=None;
}

// This machine's player drives the specimen
simulated static final function bool IsMine( KFMonster M )
{
	return M.Health>0 && PlayerController(M.Controller)!=None && Viewport(PlayerController(M.Controller).Player)!=None;
}

// How much of the player's movement an action holds: 1 no strafing or jumping, 2 none at all
simulated static final function byte ActionLock( KFMonster M, name N )
{
	if( N=='StunState' || N=='KnockDown' || N=='BlastStaggerF' || N=='BlastStaggerB' || N=='BlastStaggerL' || N=='BlastStaggerR' )
		return 2;
	if( N=='Claw' || N==M.MeleeAnims[0] || N==M.MeleeAnims[1] || N==M.MeleeAnims[2] )
		return 1;
	return 0;
}

simulated static final function LockInput( PlayerController PC, byte Lock )
{
	if( PC==None || Lock==0 )
		return;
	PC.bPressedJump = false;
	PC.aStrafe = 0;
	if( Lock>=2 )
		PC.aForward = 0;
}

// The view from the specimen's eyes (kept out of walls)
simulated static final function bool HeadView( KFMonster M, out vector CamPos, out rotator CamRot )
{
	local Coords C;
	local vector HL, HN;

	if( M.Level.NetMode==NM_DedicatedServer || M.Health<=0 || M.Level.GetLocalPlayerController().bBehindView )
		return false;
	M.LastRenderTime = M.Level.TimeSeconds;
	if( M.Controller==None )
		CamRot = M.Rotation;
	else CamRot = M.Controller.Rotation;
	C = M.GetBoneCoords(M.HeadBone);
	CamPos = C.Origin + (M.HeadHeight * M.HeadScale * C.XAxis);
	if( M.Trace(HL,HN,CamPos,M.Location,false,vect(10,10,10))!=None )
		CamPos = HL;
	return true;
}

// A straight jump (the AI's adds a shove along the world's X)
static final function bool Jump( KFMonster M )
{
	if( M.Physics!=PHYS_Walking && M.Physics!=PHYS_Ladder && M.Physics!=PHYS_Spider )
		return false;
	M.PlayOwnedSound(M.ZJumpSound, SLOT_Pain, M.GruntVolume,,80);
	if( M.Physics==PHYS_Spider )
		M.Velocity += (M.JumpZ - (M.Velocity Dot M.Floor)) * M.Floor;
	else if( M.Physics==PHYS_Ladder )
		M.Velocity.Z = 0;
	else M.Velocity.Z = M.JumpZ;
	if( M.Base!=None && !M.Base.bWorldGeometry )
		M.Velocity += M.Base.Velocity;
	M.SetPhysics(PHYS_Falling);
	return true;
}

// A bar near the top of the screen for an ability's charge (0 to 1)
simulated static final function DrawCharge( Canvas C, float Val, string Label, optional float Y )
{
	local float X, XS, YS, XL, YL;

	C.Style = ERenderStyle.STY_Alpha;
	XS = C.ClipX*0.12;
	YS = C.ClipY*0.022;
	X = C.ClipX*0.5 - XS*0.5;
	if( Y==0 )
		Y = C.ClipY*0.06;
	C.SetDrawColor(0,0,0,150);
	C.SetPos(X,Y);
	C.DrawTile(Texture'Engine.WhiteSquareTexture',XS,YS,0,0,1,1);
	Val = FClamp(Val,0,1);
	if( Val>=1 )
		C.SetDrawColor(255,60,40,230);
	else C.SetDrawColor(200,200,200,200);
	C.SetPos(X+2,Y+2);
	C.DrawTile(Texture'Engine.WhiteSquareTexture',(XS-4)*Val,YS-4,0,0,1,1);
	if( Label!="" )
	{
		C.Font = class'HUDKillingFloor'.static.GetConsoleFont(C);
		C.StrLen(Label,XL,YL);
		C.SetDrawColor(255,255,255,220);
		C.SetPos(C.ClipX*0.5-XL*0.5,Y+YS+2);
		C.DrawText(Label,false);
	}
}
