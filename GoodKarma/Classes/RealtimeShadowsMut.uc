//////////////////////////////////////////////
//                                          //
// Realtime Shadows Mutator V1.0 (c) Mutant //
//                                          //
//////////////////////////////////////////////
class RealtimeShadowsMut extends Mutator
		config(UTRealtimeShadows);

struct SkyInfo
{
     var Vector DirNorm;
     var Actor Sun;
     var array<ZoneInfo> Zones;
     var SkyZoneInfo Sky;
};
var array<SkyInfo> SkySuns;

struct ZoneSun
{
     var Vector DirNorm;
     var Actor Sun;
     var ZoneInfo Zone;
};
var array<ZoneSun> ZoneSuns;
var array<Actor> StaticLights;
var array<Actor> DynamicLights;
var bool bDynLightsDetected;

var config byte ShadowResolution;
var config byte ShadowsPerPawn;
var config bool bDynamicLightShadows;
var config bool bSunShadows;
var config bool bRagdollShadows;
var config bool bDisabled;

static function FillPlayInfo(PlayInfo PlayInfo)
{
	Super.FillPlayInfo(PlayInfo);

	PlayInfo.AddSetting(default.GameGroup, "ShadowResolution", "Shadow Resolution", 0, 0, "Select", "0;Low;1;Medium;2;High");
	PlayInfo.AddSetting(default.GameGroup, "ShadowsPerPawn", "Shadows Per Character", 0, 1, "Text", "1;1:3");
	PlayInfo.AddSetting(default.GameGroup, "bDynamicLightShadows", "Dynamic Light Shadows", 0, 2, "Check");
	PlayInfo.AddSetting(default.GameGroup, "bSunShadows", "Sun Shadows", 0, 3, "Check");
	PlayInfo.AddSetting(default.GameGroup, "bRagdollShadows", "Ragdoll Shadows", 0, 4, "Check");
	PlayInfo.AddSetting(default.GameGroup, "bDisabled", "Disabled", 0, 5, "Check");
}

static event string GetDescriptionText(string PropName)
{  
	switch (PropName)
	{
		case "ShadowResolution":	return "Defines how sharp shadows are. The higher the resolution the higher is the impact on the performance.";
		case "ShadowsPerPawn":		return "Defines how many shadows each player/monster can hold at once.";
		case "bDynamicLightShadows":	return "Enable shadow casting from dynamically spawned light sources such as flashlights. This can affect the performance.";
		case "bSunShadows":		return "Enables shadow casting from possible suns.";
		case "bRagdollShadows":		return "Keep shadows of dead players/monsters until they disappear. Otherwise shadows will be removed on death.";
		case "bDisabled":		return "This option is meant for clients who don't want to have realtime shadows on a server running this mutator.";
	}
}

simulated event PostNetBeginPlay()
{
	local Actor A;
	local int i, j, l;
	local array<Actor> SunLights;
	local array<Actor> OtherLights;
	local Actor Sun;
	local ZoneInfo Zone;
	local bool bAdd;

	ShadowResolution = Clamp(ShadowResolution, 0, 2);
	ShadowsPerPawn = Clamp(ShadowsPerPawn, 1, 3);
	SaveConfig();

	if ( Level.NetMode != NM_DedicatedServer )
	{
		if ( bDisabled )
			return;

		foreach AllActors( class'Actor', A ) //Optimize for actor lights too, add skyzone check here
		{
			if ( !A.bStatic )
				continue;

			if ( bSunShadows && SkyZoneInfo(A) != None ) //Get suns placed in skyzones
			{
				foreach ZoneInfo(A).ZoneActors(class'Actor', Sun) //Get all suns in this skyzone
				{
					if ( Sun.LightEffect == LE_Sunlight && Sun.LightType == LT_Steady )
						SunLights[SunLights.Length] = Sun;
				}

				Sun = None;
				for ( i=0; i<SunLights.Length; i++ ) //Filter out brightest sun
				{
					if ( Sun == None || Sun.LightBrightness < SunLights[i].LightBrightness )
						Sun = SunLights[i];
				}

				if ( Sun != None )
				{
					SkySuns.Insert(SkySuns.Length, 1);
					SkySuns[SkySuns.Length-1].Sky = SkyZoneInfo(A);
					SkySuns[SkySuns.Length-1].Sun = Sun;
					SkySuns[SkySuns.Length-1].DirNorm = Normal(Vector(Sun.Rotation));
					Sun = None;
					SunLights.Remove(0, SunLights.Length);
				}
			}
			else if ( bSunShadows && ZoneInfo(A) != None ) //Get suns placed in zones
			{
				foreach ZoneInfo(A).ZoneActors(class'Actor', Sun)
				{
					if ( Sun.LightEffect == LE_Sunlight && Sun.LightType == LT_Steady )
						SunLights[SunLights.Length] = Sun;
				}

				Sun = None;
				for ( i=0; i<SunLights.Length; i++ ) //Filter out brightest sun
				{
					if ( Sun == None || Sun.LightBrightness < SunLights[i].LightBrightness )
						Sun = SunLights[i];
				}

				if ( Sun != None )
				{
					ZoneSuns.Insert(ZoneSuns.Length, 1);
					ZoneSuns[ZoneSuns.Length-1].Sun = Sun;
					ZoneSuns[ZoneSuns.Length-1].DirNorm = Normal(Vector(Sun.Rotation));
					ZoneSuns[ZoneSuns.Length-1].Zone = Sun.Region.Zone;
					Sun = None;
					SunLights.Remove(0, SunLights.Length);
				}
			}
			else if ( !A.bSpecialLit && A.LightEffect != LE_Sunlight && ((A.bCorona && Light(A) != None && Light(A).MaxCoronaSize > 30) || (A.LightBrightness > 30 && A.LightRadius > 15 && (A.LightBrightness+A.LightRadius) > 55 && A.LightType == LT_Steady)) ) //Filter out ambient lights, try to get only lights that also have a visible representation
			{
				if ( A.bCorona ) //Prefer Coronas, as they are most likely the better reference to the light source.
				{
					bAdd = true;
					for ( i=StaticLights.Length-1; i>=0; i-- )
					{
						if ( VSize(StaticLights[i].Location-A.Location) < 64 )
						{
							bAdd = false;
							break;
						}
					}

					if ( bAdd )
					{
						StaticLights[j] = A;
						j++;
					}
				}
				else
				{
					OtherLights[l] = A;
					l++;
				}
			}
		}

		for ( i=OtherLights.Length-1; i>=0; i-- ) //Add in other lights that aren't coronas.
		{
			bAdd = true;
			for ( l=StaticLights.Length-1; l>=0; l-- )
			{
				if ( VSize(StaticLights[l].Location-OtherLights[i].Location) < 64 )
				{
					bAdd = false;
					break;
				}
			}

			if ( bAdd )
			{
				StaticLights[j] = OtherLights[i];
				j++;
			}
		}

		if ( bSunShadows )
		{
			if ( SkySuns.Length > 0 )
			{
				j = 0;
				foreach AllActors( class'ZoneInfo', Zone ) //Assign Zones that are affected by its skyzone
				{
					for ( i=0; i<SkySuns.Length; i++ )
					{
						if ( Zone.SkyZone == None )
							Zone.LinkToSkybox();

						if ( SkySuns[i].Sky == Zone.SkyZone )
						{
							SkySuns[i].Zones[j] = Zone;
							j++;
						}
					}
				}
			}

			for ( i=0; i<SkySuns.Length; i++ ) //Check that every Zone really has only one best sun as suns can be in skybox and the affected zone!
			{
				for ( j=0; j<ZoneSuns.Length; j++ )
				{
					for ( l=0; l<SkySuns[i].Zones.Length; l++ )
					{
						if ( SkySuns[i].Zones[l] == ZoneSuns[j].Zone )
						{
							if ( SkySuns[i].Sun.LightBrightness > ZoneSuns[j].Sun.LightBrightness )
							{
								ZoneSuns.Remove(j, 1);
								j--;
							}
							else
							{
								SkySuns[i].Zones.Remove(l, 1);
								l--;

								if ( SkySuns[i].Zones.Length == 0 )
								{
									SkySuns.Remove(i, 1);
									i--;
								}
							}
						}
					}

				}
			}
		}

		bSunShadows = (SkySuns.Length > 0 || ZoneSuns.Length > 0); //No sun is available, so we don't need to check for them

		if ( bDynamicLightShadows )
			SetTimer(0.1, true);
		else
			SetTimer(0.6, true);
	}
}

//Detect new relevant pawns and supply each with a shadow controller
simulated event Timer()
{
	local Actor A;
	local xPawn P;
	local int i;

	if ( !bDynamicLightShadows )
	{
		foreach DynamicActors(class'xPawn', P)
		{
			if ( P != None )
			{
				if ( RTS_ShadowController(P.PlayerShadow) == None && P.bPlayerShadows && !P.bBlobShadow )
				{
					if ( P.PlayerShadow != None )
						P.PlayerShadow.Destroy();

					P.PlayerShadow = Spawn(class'RTS_ShadowController', P,, P.Location);

					if ( P.PlayerShadow != None )
						RTS_ShadowController(P.PlayerShadow).Initialize(self);
				}
			}
		}
	}
	else
	{
		DynamicLights.Remove(0, DynamicLights.Length);
		bDynLightsDetected = false;

		foreach DynamicActors(class'Actor', A)
		{
			P = xPawn(A);
			if ( P != None )
			{
				if ( RTS_ShadowController(P.PlayerShadow) == None && P.bPlayerShadows && !P.bBlobShadow ) //Replace full shadows only
				{
					if ( P.PlayerShadow != None )
						P.PlayerShadow.Destroy();

					P.PlayerShadow = Spawn(class'RTS_ShadowController', P,, P.Location);

					if ( P.PlayerShadow != None )
						RTS_ShadowController(P.PlayerShadow).Initialize(self);
				}
			}
		
			if ( A.bDynamicLight && A.LightType != LT_None && A.LightRadius > 0 && i < 200 ) //200-item limit, to avoid too much slow-down
			{
				DynamicLights[i] = A;
				i++;

				if ( !bDynLightsDetected )
					bDynLightsDetected = true;
			}
		}
	}
}

defaultproperties
{
	ShadowsPerPawn=1
	bSunShadows=True
	bRagdollShadows=True
	bAddToServerPackages=True
	GroupName="KF-RealtimeShadows"
	FriendlyName="Realtime Shadows (KF)"
	Description="This adds fancy realtime-calculated shadows to players. This is a highly modified version of SquirrelZero's realtime shadows.|Created by Mutant."
	bAlwaysRelevant=True
	RemoteRole=ROLE_SimulatedProxy
}
