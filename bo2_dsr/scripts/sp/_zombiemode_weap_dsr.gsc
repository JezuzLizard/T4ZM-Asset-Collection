#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;

main()
{
	include_weapon( "zombie_dsr50" );
	include_weapon( "zombie_dsr50_upgraded", false );
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_dsr50", "Press & Hold &&1 To Buy DSR 50 [Cost: 200]", 		200,	"vox_crappy",	9 );
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_dsr50_upgraded", "Press & Hold &&1 To Buy DSR 50 [Cost: 200]", 		200,	"vox_crappy",	9 );

	// replace kar with dsr wallbuys
	weapon_spawns = GetEntArray( "weapon_upgrade", "targetname" );

	for ( i = 0; i < weapon_spawns.size; i++ )
	{
		weapon_spawn = weapon_spawns[i];

		if ( !isDefined( weapon_spawn.zombie_weapon_upgrade ) || weapon_spawn.zombie_weapon_upgrade != "zombie_kar98k" )
			continue;

		model = getent( weapon_spawn.target, "targetname" );
		brush = getent( model.target, "targetname" );

		model setModel("t6_wpn_sniper_dsr50_world");
		weapon_spawn.zombie_weapon_upgrade = "zombie_dsr50";

		break;
	}
}
