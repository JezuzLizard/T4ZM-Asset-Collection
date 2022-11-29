#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;

main()
{
	include_weapon( "an94" );
	include_weapon( "an94_upgraded", false );
	maps\_zombiemode_weapons::add_zombie_weapon( "an94", "Press & Hold &&1 To Buy AN94 [Cost: 1200]", 		1200,	"vox_mg",	9 );
	maps\_zombiemode_weapons::add_zombie_weapon( "an94_upgraded", "Press & Hold &&1 To Buy AN94 [Cost: 1200]", 		1200,	"vox_mg",	9 );

	// replace fg42 with an94 wallbuys
	weapon_spawns = GetEntArray( "weapon_upgrade", "targetname" );

	for ( i = 0; i < weapon_spawns.size; i++ )
	{
		weapon_spawn = weapon_spawns[i];

		if ( !isDefined( weapon_spawn.zombie_weapon_upgrade ) || weapon_spawn.zombie_weapon_upgrade != "zombie_fg42" )
			continue;

		model = getent( weapon_spawn.target, "targetname" );
		brush = getent( model.target, "targetname" );

		model setModel("an94_world_model");
		weapon_spawn.zombie_weapon_upgrade = "an94";

		break;
	}
}
