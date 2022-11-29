#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;

init()
{
	include_weapon( "an94" );
	include_weapon( "an94_upgraded", false );
	maps\_zombiemode_weapons::add_zombie_weapon( "an94", "Press & Hold &&1 To Buy AN94 [Cost: 2000]", 		2000,	"vox_mg",	9 );
	maps\_zombiemode_weapons::add_zombie_weapon( "an94_upgraded", "Press & Hold &&1 To Buy AN94 [Cost: 2000]", 		2000,	"vox_mg",	9 );
}
