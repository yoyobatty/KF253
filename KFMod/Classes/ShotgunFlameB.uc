// The fire that gets spawned when a Fuel puddle is shot. This damages pawns and then dissipates.

class ShotgunFlameB extends Emitter;

defaultproperties
{
     Emitters(0)=SpriteEmitter'KFMod.FlameThrowerFlameB.SpriteEmitter2'

     AutoDestroy=True
     LightType=LT_Flicker
     LightHue=30
     LightSaturation=100
     LightBrightness=300.000000
     LightRadius=4.000000
     bNoDelete=False
     bDynamicLight=True
     bNetTemporary=True
     Physics=PHYS_Trailer
     DrawScale=0.500000
}
