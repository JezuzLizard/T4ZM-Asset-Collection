#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;

init()
{
	PrecacheModel( "zombie_vending_three_gun" );
	PrecacheShader( "specialty_three_guns_zombies" );

	a = spawn( "script_model", ( -1089, -1366, 67 ) );
	a.angles = ( 0, 90, 0 );

	a SetModel( "zombie_vending_three_gun" );
	spawncollision( "collision_geo_32x32x128", "collider", a.origin - ( 0, 0, -64 ), a.angles );

	b = Spawn( "trigger_radius", a.origin + ( 0, 0, 30 ), 0, 20, 70 );
	b SetHintString( "Coming soon(tm)" );
	b SetCursorHint( "HINT_NOICON" );
	b UseTriggerRequireLookAt();

	for ( ;; )
	{
		b waittill( "trigger", who );

		if ( isDefined( who.did_lol ) )
			continue;

		who.did_lol = NewClientHudElem( who );
		who.did_lol.x = 40;
		who.did_lol.y = 40;
		who.did_lol SetShader( "specialty_three_guns_zombies", 24, 24 );

		who thread kill_in_time();
	}
}

kill_in_time()
{
	self endon( "disconnect" );

	wait 5;

	self.did_lol destroy();
}
