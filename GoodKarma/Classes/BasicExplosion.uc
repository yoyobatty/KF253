//BasicExplosion as part of the GoodKarma package
//Build 1 Beta 4.5 Release
//By: Jonathan Zepp
//A basic explosion

class BasicExplosion extends Emitter;

#exec OBJ LOAD FILE="..\Textures\ExplosionTex.utx"
#exec OBJ LOAD FILE="..\Textures\AW-2004Particles.utx"

defaultproperties
{
	AutoDestroy=True
	bNoDelete=False
}
