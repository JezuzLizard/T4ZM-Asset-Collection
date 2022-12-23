#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;

init()
{
	PrecacheShader( "hud_crossbow_indicator" );
	PrecacheModel( "t5_weapon_crossbow_bolt" );

	level._effect[ "crossbow_ex" ] 		= 	loadfx( "crossbow/fx_crossbow_explosion" );
	level._effect[ "crossbow" ] 		= 	loadfx( "crossbow/crossbow_green" );
	level._effect[ "crossbow_ug" ] 		= 	loadfx( "crossbow/crossbow_red" );

	include_weapon( "zm_crossbow" );
	include_weapon( "zm_crossbow_upgraded", false );
	maps\_zombiemode_weapons::add_zombie_weapon( "zm_crossbow", "Press & Hold &&1 To Buy Crossbow [Cost: 2000]", 		2000,	"vox_panzer",	5 );
	maps\_zombiemode_weapons::add_zombie_weapon( "zm_crossbow_upgraded", "Press & Hold &&1 To Buy Crossbow [Cost: 2000]", 		2000,	"vox_panzer",	5 );

	maps\_zombiemode_weapons::add_limited_weapon( "zm_crossbow", 1 );

	set_zombie_var( "crossbow_radius",						150 );
	set_zombie_var( "crossbow_radius_ug",						300 );
	set_zombie_var( "crossbow_damage",						900 );
	set_zombie_var( "crossbow_damage_ug",						1500 );
	set_zombie_var( "crossbow_time",						2 );
	set_zombie_var( "crossbow_time_ug",					4 );

	level thread wonder_connect();
}

wonder_connect()
{
	for ( ;; )
	{
		level waittill( "connecting", player );
		player thread wait_for_wonder_weapon_fired();
	}
}

wait_for_wonder_weapon_fired()
{
	self endon( "death" );
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill ( "grenade_fire", grenade, weaponName );

		if ( weaponName == "zm_crossbow" )
			grenade thread crossbow_think( self, false, weaponName );
		else if ( weaponName == "zm_crossbow_upgraded" )
			grenade thread crossbow_think( self, true, weaponName );
	}
}

wait_for_attractor_positions_complete()
{
	self endon( "death" );

	self waittill( "attractor_positions_generated" );

	self.attract_to_origin = false;
}

boltmodel_failsafe_cleanup()
{
	self endon( "death" );
	wait 30;
	self delete ();
}

cleanup_model_fx( model )
{
	self endon( "death" );

	self.doing_fx = true;
	model waittill( "death" );
	self.doing_fx = false;

	// explode, then delete
	PlayFXOnTag( level._effect["crossbow_ex"], self, "tag_origin" );
	EarthQuake( 0.4, 1, self.origin, 400 );

	self playsound( "fly_crossbow_explode" );

	wait 5;
	self delete ();
}

projectile_hud( model )
{
	origin = model.origin;

	projectile_hud = NewClientHudElem( self );
	projectile_hud setShader( "hud_crossbow_indicator", 64, 64 );
	projectile_hud setWaypoint( true, "hud_crossbow_indicator" );
	projectile_hud.alpha = 1;
	projectile_hud.x = origin[0];
	projectile_hud.y = origin[1];
	projectile_hud.z = origin[2];

	while ( isDefined( self ) && isDefined( model ) && model.doing_fx )
	{
		origin = model.origin;
		dist = distance( self.origin, origin );
		alpha = 1 / ( dist / 100 );

		if ( alpha < 0.12 ) alpha = 0;

		projectile_hud.alpha = alpha;
		projectile_hud.x = origin[0];
		projectile_hud.y = origin[1];
		projectile_hud.z = origin[2];

		wait 0.05;
	}

	if ( isDefined( projectile_hud ) )
		projectile_hud destroy();
}

watch_for_crossbow_fx( fx, upgraded )
{
	self endon( "death" );

	while ( self.doing_fx )
	{
		self playsound( "fly_crossbow_beep_beep" );

		PlayFXOnTag( fx, self, "tag_origin" );

		wait( crossbow_timer_bomb( upgraded ) );
	}
}

crossbow_think( shooter, upgraded, weaponName )
{
	// setup the vars
	radius = crossbow_radius( upgraded );
	time = crossbow_time( upgraded );
	fx = crossbow_fx( upgraded );
	angles = shooter getPlayerAngles();
	attract_dist_diff = level.monkey_attract_dist_diff;

	if ( !isDefined( attract_dist_diff ) )
	{
		attract_dist_diff = 45;
	}

	num_attractors = level.num_monkey_attractors;

	if ( !isDefined( num_attractors ) )
	{
		num_attractors = 96;
	}

	max_attract_dist = level.monkey_attract_dist;

	if ( !isDefined( max_attract_dist ) )
	{
		max_attract_dist = 1536;
	}

	// spawn the model
	model = Spawn( "script_model", self.origin );
	model thread boltmodel_failsafe_cleanup();
	model SetModel( "t5_weapon_crossbow_bolt" );
	model hide();
	model linkTo( self );

	// play the sounds and fx
	model_fx_emitter = Spawn( "script_model", self.origin );
	model_fx_emitter SetModel( "tag_origin" );
	model_fx_emitter LinkTo( model );
	model_fx_emitter thread cleanup_model_fx( model );
	model_fx_emitter thread watch_for_crossbow_fx( fx, upgraded );

	// kill this thread if something bad happens
	model endon( "death" );

	// show the hud to players
	players = get_players();

	for ( i = 0; i < players.size; i++ )
		players[i] thread projectile_hud( model_fx_emitter );

	// make zombies attracted to bolt
	if ( upgraded )
	{
		model create_zombie_point_of_interest( max_attract_dist, num_attractors, 10000 );
		model.attract_to_origin = true;

		// hack for slow reacting zombies
		ai = GetAiArray( "axis" );

		for ( i = 0; i < ai.size; i++ )
		{
			ai[i].zombie_path_timer = 0;
		}
	}

	// wait for missile to stop moving
	oldPos = self.origin;
	velocitySq = 10000 * 10000;

	while ( isDefined( self ) && velocitySq != 0 )
	{
		wait( 0.05 );
		velocitySq = distanceSquared( self.origin, oldPos );
		oldPos = self.origin;
	}

	// show the model
	if ( isDefined( self ) )
		self hide();

	model unlink();
	model show();
	model.angles = angles;

	// more zombie attraction for bolt
	if ( upgraded )
	{
		valid_poi = check_point_in_active_zone( model.origin );

		if ( !valid_poi )
		{
			valid_poi = check_point_in_playable_area( model.origin );
		}

		if ( valid_poi )
		{
			model thread create_zombie_point_of_interest_attractor_positions( 4, attract_dist_diff );
			model thread wait_for_attractor_positions_complete();
		}
		else
		{
			model.script_noteworthy = undefined;
		}
	}

	// stick to a zombie
	ai = getAiSpeciesArray( "axis", "all" );
	target = get_closest_living( model.origin, ai, radius );
	attached = false;

	if ( isDefined( target ) && model isTouching( target ) )
	{
		attached = true;
		model LinkTo( target, "J_MainRoot" );
	}
	else
	{
		// stick to a player
		players = get_players();
		target = undefined;

		for ( i = 0; i < players.size; i++ )
		{
			if ( model isTouching( players[i] ) )
			{
				target = players[i];
				break;
			}
		}

		if ( isDefined( target ) )
		{
			attached = true;
			model LinkTo( target, "J_MainRoot" );
		}
	}

	// wait
	wait time;

	// do damage
	explode_orig = model.origin;

	if ( attached )
	{
		explode_orig += ( 0, 0, 10 );
	}

	if ( isDefined( shooter ) )
		model RadiusDamage( explode_orig, radius, crossbow_damage( upgraded ), crossbow_damage_min( upgraded ), shooter, "MOD_GRENADE_SPLASH", weaponName );
	else
		model RadiusDamage( explode_orig, radius, crossbow_damage( upgraded ), crossbow_damage_min( upgraded ), undefined, "MOD_GRENADE_SPLASH", weaponName );

	// delete
	model delete ();
}

crossbow_radius( upgraded )
{
	if ( upgraded )	return level.zombie_vars[ "crossbow_radius_ug" ];
	else	return level.zombie_vars[ "crossbow_radius" ];
}

crossbow_time( upgraded )
{
	if ( upgraded )	return level.zombie_vars[ "crossbow_time_ug" ];
	else	return level.zombie_vars[ "crossbow_time" ];
}

crossbow_fx( upgraded )
{
	if ( upgraded )	return level._effect[ "crossbow_ug" ];
	else	return level._effect[ "crossbow" ];
}

crossbow_damage( upgraded )
{
	if ( upgraded )	return level.zombie_vars[ "crossbow_damage_ug" ];
	else	return level.zombie_vars[ "crossbow_damage" ];
}

crossbow_timer_bomb( upgraded )
{
	if ( upgraded )	return 0.25;
	else	return 0.5;
}

crossbow_damage_min( upgraded )
{
	if ( upgraded )	return crossbow_damage( upgraded ) / 1.5;
	else	return crossbow_damage( upgraded ) / 2;
}
