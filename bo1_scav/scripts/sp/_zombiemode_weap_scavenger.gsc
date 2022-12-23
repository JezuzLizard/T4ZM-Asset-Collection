#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;

init()
{
	PrecacheShader( "hud_indicator_sniper_explosive" );
	PrecacheModel( "bo1_t5_weapon_zom_sniper_projectile" );

	level._effect["zombie_blood_expl"] = loadfx( "scavenger/scavenger_blood" );
	level._effect["scavenger_ex"] = loadfx( "scavenger/scavenger_ex" );
	level._effect["scavenger_ex_ug"] = loadfx( "scavenger/scavenger_ex_ug" );

	include_weapon( "zm_scavenger" );
	include_weapon( "zm_scavenger_upgraded", false );
	maps\_zombiemode_weapons::add_zombie_weapon( "zm_scavenger", "Press & Hold &&1 To Buy Scavenger [Cost: 2000]", 		2000,	"vox_panzer",	5 );
	maps\_zombiemode_weapons::add_zombie_weapon( "zm_scavenger_upgraded", "Press & Hold &&1 To Buy Scavenger [Cost: 2000]", 		2000,	"vox_panzer",	5 );

	maps\_zombiemode_weapons::add_limited_weapon( "zm_scavenger", 1 );

	set_zombie_var( "scavenger_radius",				400 );
	set_zombie_var( "scavenger_radius_ug",			600 );
	set_zombie_var( "scavenger_damage",				5660 );
	set_zombie_var( "scavenger_damage_ug",			11320 );
	set_zombie_var( "scavenger_fuse_time",			2.5 );
	set_zombie_var( "scavenger_fuse_time_ug",		3.5 );

	level.default_vision = "zombie_factory";

	level thread scavenger_on_player_connect();

	level thread setup_callbacks();
}

setup_callbacks()
{
	wait 1;
	level.callbackActorKilledScavPrev = level.callbackActorKilled;
	level.callbackActorKilled = ::callbackActorKilledScav;
}

callbackActorKilledScav( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, iTimeOffset )
{
	if ( isPlayer( eAttacker ) )
	{
		weapon = eAttacker getcurrentweapon();

		if ( weapon == "zm_scavenger_upgraded" || weapon == "zm_scavenger" )
		{
			PlayFx( level._effect["zombie_blood_expl"], self getTagOrigin( "J_MainRoot" ) );
			self hide();
		}
	}


	self [[level.callbackActorKilledScavPrev]]( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, iTimeOffset );
}

scavenger_on_player_connect()
{
	for ( ;; )
	{
		level waittill( "connecting", player );
		player thread watch_for_sniper_bolt();
		player thread infared_scope();
	}
}

infared_scope()
{
	self endon( "death" );
	self endon( "disconnect" );

	has_custom_vision = false;

	for ( ;; )
	{
		wait 0.05;

		if ( self PlayerAds() < 1 || self getcurrentweapon() != "zm_scavenger_upgraded" )
		{
			if ( !self maps\_laststand::player_is_in_laststand() && has_custom_vision )
			{
				has_custom_vision = false;
				self VisionSetNaked( level.default_vision, 0.5 );
			}
		}
		else
		{
			self VisionSetNaked( "infared_vision", 0.5 );
			has_custom_vision = true;
		}
	}
}

watch_for_sniper_bolt()
{
	self endon( "death" );
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "projectile_impact", weapon, point );

		if ( weapon == "zm_scavenger" )
			self thread sniper_explode( point, false, weapon );
		else if ( weapon == "zm_scavenger_upgraded" )
			self thread sniper_explode( point, true, weapon );
	}
}

projectile_hud( model )
{
	origin = model.origin;

	projectile_hud = NewClientHudElem( self );
	projectile_hud setShader( "hud_indicator_sniper_explosive", 64, 64 );
	projectile_hud setWaypoint( true, "hud_indicator_sniper_explosive" );
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

boltmodel_failsafe_cleanup()
{
	self endon( "death" );
	wait 30;
	self delete ();
}

cleanup_model_fx( model, sound, fx )
{
	self endon( "death" );

	self playsound( "scavenger_rampup" );
	self.doing_fx = true;
	model waittill( "death" );
	self.doing_fx = false;

	// explode, then delete
	PlayFXOnTag( fx, self, "tag_origin" );
	EarthQuake( 0.4, 1, self.origin, 400 );

	self playsound( sound );

	wait 5;
	self delete ();
}

sniper_explode( point, upgraded, weaponName )
{
	// get the vals
	radius = sniper_radius( upgraded );
	time = sniper_time( upgraded );

	// create the bolt model
	model = Spawn( "script_model", point );
	model thread boltmodel_failsafe_cleanup();
	model.angles = self getplayerangles();
	model SetModel( "bo1_t5_weapon_zom_sniper_projectile" );

	// play the sounds and fx
	model_fx_emitter = Spawn( "script_model", point );
	model_fx_emitter SetModel( "tag_origin" );
	model_fx_emitter LinkTo( model );
	model_fx_emitter thread cleanup_model_fx( model, sniper_sound( upgraded ), sniper_fx( upgraded ) );

	// kill this thread if something bad happens
	model endon( "death" );

	// show the hud to players
	players = get_players();

	for ( i = 0; i < players.size; i++ )
		players[i] thread projectile_hud( model_fx_emitter );

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

	if ( isDefined( self ) )
		model RadiusDamage( explode_orig, radius, sniper_damage( upgraded ), sniper_damage_min( upgraded ), self, "MOD_GRENADE_SPLASH", weaponName );
	else
		model RadiusDamage( explode_orig, radius, sniper_damage( upgraded ), sniper_damage_min( upgraded ), undefined, "MOD_GRENADE_SPLASH", weaponName );

	// delete
	model delete ();
}

sniper_radius( upgraded )
{
	if ( upgraded )	return level.zombie_vars[ "scavenger_radius_ug" ];
	else	return level.zombie_vars[ "scavenger_radius" ];
}

sniper_time( upgraded )
{
	if ( upgraded )	return level.zombie_vars[ "scavenger_fuse_time_ug" ];
	else	return level.zombie_vars[ "scavenger_fuse_time" ];
}

sniper_fx( upgraded )
{
	if ( upgraded )	return level._effect[ "scavenger_ex_ug" ];
	else	return level._effect[ "scavenger_ex" ];
}

sniper_damage( upgraded )
{
	if ( upgraded )	return level.zombie_vars[ "scavenger_damage_ug" ];
	else	return level.zombie_vars[ "scavenger_damage" ];
}

sniper_damage_min( upgraded )
{
	if ( upgraded )	return sniper_damage( upgraded ) / 1;
	else	return sniper_damage( upgraded ) / 1;
}

sniper_sound( upgraded )
{
	if ( upgraded )	return "scavenger_explode_ug";
	else	return "scavenger_explode";
}
