class ShadowProjectorMid extends ShadowProjector;

var() vector ProjLocationOffset;

function InitShadow()
{
	local Plane		BoundingSphere;

	if(ShadowActor != None)
	{
		BoundingSphere = ShadowActor.GetRenderBoundingSphere();
		FOV = (Atan(BoundingSphere.W*2 + 160, LightDistance) * 180/PI)*0.9;

		ShadowTexture = Effect_ShadowBitmapMaterialMedium(Level.ObjectPool.AllocateObject(class'Effect_ShadowBitmapMaterialMedium'));
		ProjTexture = ShadowTexture;

		if(ShadowTexture != None)
		{
			//SetDrawScale(LightDistance * tan(0.5 * FOV * PI / 180) / (0.5 * ShadowTexture.USize));
            SetDrawScale( (LightDistance*0.82) * tan(0.5*FOV*PI/180) / (0.45*ShadowTexture.USize));

			ShadowTexture.Invalid = False;
			ShadowTexture.bBlobShadow = bBlobShadow;
			ShadowTexture.ShadowActor = ShadowActor;
			ShadowTexture.LightDirection = Normal(LightDirection);
			ShadowTexture.LightDistance = LightDistance;
			ShadowTexture.LightFOV = FOV;
			ShadowTexture.CullDistance = CullDistance; 
    
			Enable('Tick');
			UpdateShadow();
		}
		else
			Log(Name$".InitShadow: Failed to allocate texture");
	}
	else
		Log(Name$".InitShadow: No actor");
}

function Effect_TacLightProjector GetNearbyTacLight()
{
    local Effect_TacLightProjector G;

    foreach RadiusActors(class'Effect_TacLightProjector', G, 1000)
    {
		if(!G.bHasLight)
			continue;
        return G;
    }
    return None;
}

function UpdateShadow()
{
    local Plane               BoundingSphere;
    local Effect_TacLightProjector Tac;
    local vector              Dir, ActorCenter;
	local vector HitLocation, HitNormal, DesiredLoc;
	local float MinDist, MaxDist, MinBackoff, MaxBackoff, Alpha;

    DetachProjector(true);

    if ( (ShadowActor != None) && !ShadowActor.bHidden
         && (Level.TimeSeconds - ShadowActor.LastRenderTime < 4)
         && (ShadowTexture != None) && bShadowActive )
    {
        if (ShadowTexture.Invalid)
            Destroy();
        else
        {
			ActorCenter = ShadowActor.Location;// + Vect(0,0,5);

			// Desired location based on current logic (could pierce walls)
			DesiredLoc = ActorCenter + ProjLocationOffset;

            // React to nearby tac light
            Tac = GetNearbyTacLight();
			/* 
            if (Tac != None)
            {
				//From the owner's eye position 
                //Dir = ActorCenter - (Pawn(Tac.Owner).Location + Pawn(Tac.Owner).EyePosition());
				Dir = ActorCenter - Tac.Location;
                LightDirection = Normal(-Dir);
                // Example: derive a distance
                LightDistance = VSize(Dir);
				ProjLocationOffset = LightDirection * 100.f;
            }*/
			if (Tac != None)
			{
				Dir = ActorCenter - Tac.Location;
				LightDirection = Normal(-Dir);
				LightDistance  = VSize(Dir);

				// dynamic backoff based on distance
				MinDist    = 200.0;
				MaxDist    = 300.0;
				MinBackoff = 0.0;
				MaxBackoff = 20.0;

				LightDistance = FClamp(LightDistance, MinDist, MaxDist);
				Alpha = 1.0 - ((LightDistance - MinDist) / (MaxDist - MinDist));
				ProjLocationOffset = LightDirection * (MinBackoff + Alpha * (MaxBackoff - MinBackoff));
			}
			else 
			{
				LightDirection = Vect(1,1,3);
				LightDistance = 300.0;
			}
		

			// Trace from actor toward desired projector location along light direction
			// (You can also trace exactly ShadowActor.Location -> DesiredLoc if you prefer)
			if (Trace(HitLocation, HitNormal, DesiredLoc, ActorCenter, false) != None)
			{
				// We hit world/geometry; place projector slightly before the hit
				SetLocation(HitLocation - LightDirection * 4.0);
			}
			else
			{
				// No obstruction, use desired location
				SetLocation(DesiredLoc);
			}


            // Clamp LightDistance
			LightDistance = FClamp(LightDistance, 180.0, 300.0);

            SetRotation(Rotator(Normal(-LightDirection)));

            ShadowTexture.LightDistance = LightDistance;

            BoundingSphere = ShadowActor.GetRenderBoundingSphere();
            FOV = (Atan(BoundingSphere.W*2 + 160, LightDistance) * 180/PI)*0.9;

			SetDrawScale( (LightDistance*0.82) * tan(0.5*FOV*PI/180) / (0.45*ShadowTexture.USize));

            ShadowTexture.LightDirection = Normal(LightDirection);
            ShadowTexture.LightFOV       = FOV;

            ShadowTexture.Dirty = true;

            AttachProjector();
        }
    }
}

defaultproperties
{
	//bHidden=false
	bNoProjectOnOwner=True
}