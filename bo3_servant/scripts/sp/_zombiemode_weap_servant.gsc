#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;

#using_animtree( "generic_human" );

init()
{
	level._effect["servant_portal"]	= loadfx( "servant/servant_hole" );
	level._effect["servant_implode"] = loadfx( "servant/servant_implode" );

	include_weapon( "servant" );
	include_weapon( "servant_upgraded", false );
	maps\_zombiemode_weapons::add_zombie_weapon( "servant", "Press & Hold &&1 To Buy Servant [Cost: 2000]", 		2000,	"vox_panzer",	5 );
	maps\_zombiemode_weapons::add_zombie_weapon( "servant_upgraded", "Press & Hold &&1 To Buy Servant [Cost: 2000]", 		2000,	"vox_panzer",	5 );

	maps\_zombiemode_weapons::add_limited_weapon( "servant", 1 );

	level thread serv_on_player_connect();

	set_zombie_var( "servant_radius",				210 );
	set_zombie_var( "servant_radius_ug",			250 );
	set_zombie_var( "servant_radius_explode",				300 );
	set_zombie_var( "servant_radius_explode_ug",			500 );
	set_zombie_var( "servant_time",			7 );
	set_zombie_var( "servant_time_ug",		12 );

	level._zombie_servant_death["zombie"] 			= % ai_zombie_blackhole_walk_fast_v1;
	level._zombie_servant_death["quad_zombie"] 	= % ai_zombie_quad_blackhole_crawl_fast_v1;
	level._zombie_servant_crawl_death["zombie"] 		= % ai_zombie_blackhole_crawl_fast_v1;
}

serv_on_player_connect()
{
	for ( ;; )
	{
		level waittill( "connecting", player );
		player thread watch_for_servant();
	}
}

watch_for_servant()
{
	self endon( "death" );
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "projectile_impact", weapon, point );

		if ( weapon == "servant" )
			self thread servant_explode( point, false );

		else if ( weapon == "servant_upgraded" )
			self thread servant_explode( point, true );
	}
}

servant_explode( point, up )
{
	point = point + ( 0, 0, 30 );

	time = level.zombie_vars[ "servant_time" ];

	if ( up )
		time = level.zombie_vars[ "servant_time_ug" ];

	soundemitter = Spawn( "script_model", point );
	soundemitter setmodel( "tag_origin" );

	PlayFXOnTag( level._effect["servant_portal"], soundemitter, "tag_origin" );

	soundemitter playloopsound( "servant_portal_loop", 1 );
	soundemitter playsound( "servant_portal_start" );
	soundemitter thread servant_portal( time, self, up );

	wait ( time );
	soundemitter stoploopsound();

	PlayFXOnTag( level._effect["servant_implode"], soundemitter, "tag_origin" );
	soundemitter playsound( "servant_portal_end" );
	earthquake( .4, .6, point, 750 );

	wait 4;
	soundemitter delete ();
}

servant_portal( time, player, up )
{
	radius = level.zombie_vars[ "servant_radius" ];

	if ( up )
		radius = level.zombie_vars[ "servant_radius_ug" ];

	org = self.origin;

	while ( time > 0 )
	{
		earthquake( .2, .3, org, 500 );

		zombies = get_array_of_closest( org, getAiSpeciesArray( "axis" ), undefined, undefined, radius );

		if ( zombies.size > 0 )
		{
			for ( i = 0; i < zombies.size; i++ )
			{
				if ( !isDefined( zombies[i] ) || !isAlive( zombies[i] ) )
					continue;

				if ( isDefined( zombies[i].magic_bullet_shield ) && zombies[i].magic_bullet_shield )
					continue;

				if ( isDefined( zombies[i].marked ) && zombies[i].marked )
					continue;

				if ( !isDefined( zombies[i].in_servant ) || !zombies[i].in_servant )
				{
					zombies[i].in_servant = true;
					zombies[i] thread servant_damage( player, self );
				}
			}
		}

		wait .1;
		time = time - 0.1;
	}



	radius = level.zombie_vars[ "servant_radius_explode" ];

	if ( up )
		radius = level.zombie_vars[ "servant_radius_explode_ug" ];

	zombies = get_array_of_closest( org, getAiSpeciesArray( "axis" ), undefined, undefined, radius );

	for ( i = 0; i < zombies.size; i++ )
	{
		if ( !isDefined( zombies[i] ) || !isAlive( zombies[i] ) )
			continue;

		if ( isDefined( zombies[i].magic_bullet_shield ) && zombies[i].magic_bullet_shield )
			continue;

		if ( isDefined( zombies[i].marked ) && zombies[i].marked )
			continue;

		zombies[i] maps\_zombiemode_spawner::zombie_eye_glow_stop();
		zombies[i] hide();

		playfx( level._effect["dog_gib"], zombies[i].origin );

		if ( isDefined( player ) )
			zombies[i] dodamage( zombies[i].health + 666, zombies[i].origin, player );
		else
			zombies[i] dodamage( zombies[i].health + 666, zombies[i].origin );
	}
}

servant_damage( player, portal )
{
	wait ( RandomInt( 21 ) * 0.05 );

	if ( !isDefined( self ) || !isAlive( self ) )
		return;

	servant_anim = undefined;

	if ( self.has_legs )
		servant_anim = level._zombie_servant_death[self.animname];
	else
		servant_anim =  level._zombie_servant_crawl_death["zombie"];

	normalModel = self.model;
	normalHead = self.headModel;
	hatModel = self.hatModel;

	self maps\_zombiemode_spawner::zombie_eye_glow_stop();
	self hide();

	if ( isDefined( player ) )
		self dodamage( self.health + 666, self.origin, player );
	else
		self dodamage( self.health + 666, self.origin );

	if ( self.animname == "zombie_dog" )
	{
		playfx( level._effect["dog_gib"], self.origin );
		return;
	}

	zombie = spawn( "script_model", self.origin );
	zombie.angles = self.angles;
	zombie SetModel( normalModel );

	if ( IsDefined( self.headModel ) )
		zombie Attach( normalHead );

	if ( IsDefined( self.hatModel ) )
		zombie Attach( hatModel );

	zombie UseAnimTree( #animtree );
	zombie setanim( servant_anim );

	zombie MoveTo( portal.origin, 1 );

	zombie waittill( "movedone" );
	zombie hide();

	zombie playSound( "crush_end_0" + randomint( 2 ) );
	playFxOnTag( level._effect["dog_gib"], zombie, "tag_origin" );

	wait 2;
	zombie delete ();
}
