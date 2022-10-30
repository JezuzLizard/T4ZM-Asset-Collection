#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;

init()
{
	include_weapon( "zm_galil" );
	include_weapon( "zm_galil_upgraded", false );
	maps\_zombiemode_weapons::add_zombie_weapon( "zm_galil", "Press & Hold &&1 To Buy Galil [Cost: 2000]", 		2000,	"vox_mg",	9 );
	maps\_zombiemode_weapons::add_zombie_weapon( "zm_galil_upgraded", "Press & Hold &&1 To Buy Galil [Cost: 2000]", 		2000,	"vox_mg",	9 );
}
