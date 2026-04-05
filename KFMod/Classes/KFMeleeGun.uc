class KFMeleeGun extends KFWeapon;

//var name TPAnim;
//var name TPAnim2;
var bool btryHit ;
var float THMax, THMin, dmg ;
var class<damageType> hitDamType ;
var vector momOffset ;
var Actor HitObject ;
var array <sound> MeleeHitSounds ;
var byte MeleeHitVolume ;

var float hitTimeout ;
var bool bCanHit ;//, bAnimating ;

var float ChopSlowRate; // percentage your speed gets reduced to when chopping

// Bloody Weapons. By Alex.
// Gibby, when you re-do the melee code, you may have to move the code I put in Tick.

var Material BloodyMaterial; // When you slash someone and draw blood, switch to this skin.
var int BloodSkinSwitchArray; // In case the material array number varies between weapons, switch this num in defprops. (usually it's "2")
var bool bDoCombos; // DISABLE FOR NOW

var float MeleeWeaponRange; // How far the weapon can reach. Used for bots to anticipate attacks. Just a helper, don't set this in defaultproperties!
var float DamDelay; // How long it takes to do damage after the attack is initiated. Used for bots to anticipate attacks. Just a helper, don't set this in defaultproperties!

function GiveTo(pawn other, optional pickup pickup)
{
	local KFMeleeFire F;
	local int i;

	Super.GiveTo(other, pickup);
	for( i=0; i<2; ++i )
	{
		F = KFMeleeFire(GetFireMode(i));
		if( F!=None )
		{
			MeleeWeaponRange = F.WeaponRange;
			DamDelay = F.DamagedelayMin;
		}
	}
}

function DoReflectEffect(int Drain)
{
}

simulated function BringUp(optional Weapon PrevWeapon)
{
	if(BloodyMaterial!=none && Skins[BloodSkinSwitchArray] == BloodyMaterial )
	{
		Skins[BloodSkinSwitchArray] = default.Skins[BloodSkinSwitchArray];
		Texture = default.Texture;
	}
	super.BringUp(PrevWeapon);
}

function bool AllowReload()
{
	return false;
}

simulated function bool HasAmmo()
{
	return true;
}

function playServerSound()
{
	local sound hitSoundToPlay;

	if(MeleeHitSounds[0] != none)
	{
		HitSoundToPlay = MeleeHitSounds[Rand(MeleeHitSounds.length)] ;
		PlaySound(HitSoundToPlay, SLOT_None, MeleeHitVolume) ;
	}
}

simulated function DisplayDebug(Canvas Canvas, out float YL, out float YPos)
{
	local vector boxscreenloc,endpoint,eyepoint;

	boxscreenloc = Canvas.WorldToScreen( GetBoneCoords('tip').Origin );
	Canvas.SetDrawColor(0,255,0,255);
	Canvas.SetPos(boxscreenloc.X-10,boxscreenloc.Y-10);
	Canvas.DrawBox(Canvas,20,20);

	eyepoint = Instigator.Location;
	eyepoint.Z += Instigator.Eyeheight;
	endpoint = (Normal(GetBoneCoords('tip').Origin-eyepoint)*1000)+eyepoint;
	boxscreenloc = Canvas.WorldToScreen(endpoint);
	Canvas.SetDrawColor(255,0,0,255);
	Canvas.SetPos(boxscreenloc.X-10,boxscreenloc.Y-10);
	Canvas.DrawBox(Canvas,20,20);

	boxscreenloc = Canvas.WorldToScreen(eyepoint);
	Canvas.SetDrawColor(0,0,255,255);
	Canvas.SetPos(boxscreenloc.X-10,boxscreenloc.Y-10);
	Canvas.DrawBox(Canvas,20,20);
	Super.DisplayDebug(Canvas,YL,YPos);
}

// Stop chopping the air!
function bool CanAttack(Actor Other)
{
    local vector PredictedLoc;
    local vector EnemyVel;
    local float PredictedDist;
	
    if (Other == None || Instigator == None)
        return false;

    // Try to get enemy velocity (works for Pawns)
    if (Pawn(Other) != None)
        EnemyVel = Pawn(Other).Velocity;

    PredictedLoc = Other.Location + (EnemyVel - Instigator.Velocity) * DamDelay; 

    // Check if predicted location will be in range
    PredictedDist = VSize(PredictedLoc - Instigator.Location);
	if (PredictedDist <= MeleeWeaponRange)
	{
		//log("Owner:" $Owner.GetHumanReadableName()$ " Target: " $Other.GetHumanReadableName()$ " PredictedDist: " $ PredictedDist $ " MeleeWeaponRange: " $ MeleeWeaponRange);
		return true;
	}
}

function byte BestMode()
{
	return 0;
}

function float GetAIRating()
{
	local Bot B;
	local float Rating;

	B = Bot(Instigator.Controller);
	
	if (B == None)
		return AIRating;

	Rating = AIRating;
	if(B.Enemy != None)
	{
		if( VSize(B.Enemy.Location - Instigator.Location) <= MeleeWeaponRange*2 ) //make it 2, so we're ready to take it out before an enemy is too close
			Rating*=1.5;
		else Rating*=0.5; //Try to use our range weapon first
		if (Normal(B.Enemy.Location - Instigator.Location) dot vector(B.Enemy.Rotation) > 0.0) //back stabs encourage this weapon
			Rating += 0.1;
		//else Rating*=0.5;
	}
	//log("KFMeleeGun.GetAIRating: " $ B.GetHumanReadableName() $ " Rating: " $ Rating);
	return Rating;
}

function float SuggestAttackStyle()
{
    return 1;
}

function float SuggestDefenseStyle()
{
    return -1;
}

defaultproperties
{
	MeleeHitVolume=255
	ChopSlowRate=0.500000
	BloodSkinSwitchArray=2
	PutDownAnim="PutDown"
	AIRating=0.100000
	CurrentRating=0.100000
	bMeleeWeapon=True
	SmallViewOffset=(Z=-20.000000)
	PlayerViewOffset=(Z=-10.000000)
	MeleeWeaponRange=75.000000
	bModeZeroCanDryFire=false
}
