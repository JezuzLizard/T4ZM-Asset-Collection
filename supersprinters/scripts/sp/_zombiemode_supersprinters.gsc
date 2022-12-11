#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;

#using_animtree( "generic_human" );

main()
{
	if ( getDvar( "zombie_super_sprint_start_round" ) == "" )
		setDvar( "zombie_super_sprint_start_round", 56 );

	if ( getDvar( "zombie_asylum_sprint_spawn_chance" ) == "" )
		setDvar( "zombie_asylum_sprint_spawn_chance", 0 );

	if ( getDvar( "zombie_mega_sprint_spawn_chance" ) == "" )
		setDvar( "zombie_mega_sprint_spawn_chance", 0 );

	level.set_zombie_run_cycle_func = undefined;


	set_zombie_run_cycle_func = getFunction( "maps/_zombiemode_spawner", "set_zombie_run_cycle" );

	if ( isDefined( set_zombie_run_cycle_func ) )
		replaceFunc( set_zombie_run_cycle_func, ::set_zombie_run_cycle );


	init_standard_zombie_anims_func = getFunction( "maps/_zombiemode", "init_standard_zombie_anims" );

	if ( isDefined( init_standard_zombie_anims_func ) )
		replaceFunc( init_standard_zombie_anims_func, ::init_standard_zombie_anims );
}

init_standard_zombie_anims()
{
	func = getFunction( "maps/_zombiemode", "init_standard_zombie_anims" );
	disableDetourOnce( func );
	self [[func]]();

	level.scr_anim["zombie"]["asylum_sprint1"] = % ai_zombie_sprint_v4;
	level.scr_anim["zombie"]["asylum_sprint2"] = % ai_zombie_sprint_v5;

	level.scr_anim["zombie"]["super_sprint1"] = % ai_hazmat_sprint;
	level.scr_anim["zombie"]["super_sprint2"] = % ai_zombie_base_supersprint_bo4_v1;
	level.scr_anim["zombie"]["super_sprint3"] = % ai_zombie_base_supersprint_bo4_v2;
	level.scr_anim["zombie"]["super_sprint4"] = % ai_zombie_base_supersprint_tranzit_fair_v1;
	level.scr_anim["zombie"]["super_sprint5"] = % ai_zombie_fast_sprint_01;
	level.scr_anim["zombie"]["super_sprint6"] = % ai_zombie_fast_sprint_02;

	level.scr_anim["zombie"]["mega_sprint1"] = % ai_zombie_sprint_v12;
}

set_zombie_run_cycle()
{
	func = getFunction( "maps/_zombiemode_spawner", "set_zombie_run_cycle" );
	disableDetourOnce( func );
	self [[func]]();

	if ( isDefined( level.set_zombie_run_cycle_func ) )
	{
		self [[level.set_zombie_run_cycle_func]]();
		return;
	}

	if ( self.animname != "zombie" || self.zombie_move_speed != "sprint" )
		return;

	if ( RandomInt( 100 ) < GetDvarInt( "zombie_asylum_sprint_spawn_chance" ) )
	{
		var = randomintrange( 1, 2 );
		self set_run_anim( "asylum_sprint" + var );
		self.run_combatanim = level.scr_anim[self.animname]["asylum_sprint" + var];
		return;
	}

	if ( RandomInt( 100 ) < GetDvarInt( "zombie_mega_sprint_spawn_chance" ) )
	{
		var = 1;
		self set_run_anim( "mega_sprint" + var );
		self.run_combatanim = level.scr_anim[self.animname]["mega_sprint" + var];
		return;
	}

	if ( level.round_number >= GetDvarInt( "zombie_super_sprint_start_round" ) )
	{
		var = randomintrange( 1, 6 );
		self set_run_anim( "super_sprint" + var );
		self.run_combatanim = level.scr_anim[self.animname]["super_sprint" + var];
		return;
	}
}
