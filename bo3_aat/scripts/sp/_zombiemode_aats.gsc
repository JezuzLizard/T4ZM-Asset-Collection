#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;

init()
{
	PrecacheShader( "dead_wire_icon" );
	PrecacheShader( "dead_wire_reticle" );

	PrecacheShader( "blast_furnace_icon" );
	PrecacheShader( "blast_furnace_reticle" );
	level._effect[ "fx_blast_furnace" ]			= loadfx( "aat/fx_blast_furnace" );
	level._effect[ "fx_blast_furnace_torso" ]	= loadfx( "aat/fx_blast_furnace_torso" );

	PrecacheShader( "fire_works_icon" );
	PrecacheShader( "fire_works_reticle" );
	level._effect[ "fx_fire_works" ]	= loadfx( "aat/fx_fire_works" );

	PrecacheShader( "thunderwall_icon" );
	PrecacheShader( "thunderwall_reticle" );
	level._effect[ "fx_thunder_wall" ]			= loadfx( "aat/fx_thunder_wall" );

	PrecacheShader( "turned_icon" );
	PrecacheShader( "turned_reticle" );
	level._effect[ "fx_turned" ]				= loadfx( "aat/fx_turned" );


	set_zombie_var( "turned_proc_chance", 15 );
	set_zombie_var( "turned_cooldown", 15 );
	set_zombie_var( "turned_radius", 90, undefined, true );
	set_zombie_var( "turned_kill_count", 3 );
	set_zombie_var( "turned_time", 20, undefined, true );
	set_zombie_var( "turned_attack_dist", 48, undefined, true );

	set_zombie_var( "fire_works_proc_chance", 10 );
	set_zombie_var( "fire_works_cooldown", 20 );
	set_zombie_var( "fire_works_radius", 600, undefined, true );
	set_zombie_var( "fire_works_num_frames", 10 );
	set_zombie_var( "fire_works_num_los", 3 );
	set_zombie_var( "fire_works_init_wait_min", 0.35, undefined, true );
	set_zombie_var( "fire_works_init_wait_max", 0.75, undefined, true );

	set_zombie_var( "thunder_wall_proc_chance", 25 );
	set_zombie_var( "thunder_wall_cooldown", 10 );
	set_zombie_var( "thunder_wall_radius", 25, undefined, true );
	set_zombie_var( "thunder_wall_range", 180, undefined, true );
	set_zombie_var( "thunder_wall_wait_min", 0, undefined, true );
	set_zombie_var( "thunder_wall_wait_max", 0.2, undefined, true );
	set_zombie_var( "thunder_wall_kill_count", 6 );

	set_zombie_var( "blast_furnace_proc_chance", 15 );
	set_zombie_var( "blast_furnace_cooldown", 15 );
	set_zombie_var( "blast_furnace_radius", 120, undefined, true );
	set_zombie_var( "blast_furnace_kill_count", 24 );
	set_zombie_var( "blast_furnace_init_wait_min", 0, undefined, true );
	set_zombie_var( "blast_furnace_init_wait_max", 0.05, undefined, true );
	set_zombie_var( "blast_furnace_tick_damage_precent_min", 0.10, undefined, true );
	set_zombie_var( "blast_furnace_tick_damage_precent_max", 0.25, undefined, true );
	set_zombie_var( "blast_furnace_chain_wait_min", 0.35, undefined, true );
	set_zombie_var( "blast_furnace_chain_wait_max", 0.75, undefined, true );

	set_zombie_var( "dead_wire_proc_chance", 20 );
	set_zombie_var( "dead_wire_cooldown", 5 );
	set_zombie_var( "dead_wire_radius", 120, undefined, true );
	set_zombie_var( "dead_wire_kill_count", 8 );
	set_zombie_var( "dead_wire_init_wait_min", 0, undefined, true );
	set_zombie_var( "dead_wire_init_wait_max", 0.25, undefined, true );
	set_zombie_var( "dead_wire_chain_wait_min", 0.25, undefined, true );
	set_zombie_var( "dead_wire_chain_wait_max", 0.5, undefined, true );


	thread setup_callbacks();
	level thread on_player_connect();
}

setup_callbacks()
{
	wait 2;

	level.callbackActorDamageAatPrev = level.callbackActorDamage;
	level.callbackActorDamage = ::callbackActorDamageAat;

	level.callbackPlayerDamageAatPrev = level.callbackPlayerDamage;
	level.callbackPlayerDamage = ::callbackPlayerDamageAat;
}

callbackPlayerDamageAat( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, iModelIndex, iTimeOffset )
{
	// do0nt damage from fireworks!
	if ( isDefined( eAttacker ) && isDefined( eAttacker.fire_works_owner ) )
		return;

	self [[level.callbackPlayerDamageAatPrev]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, iModelIndex, iTimeOffset );
}

callbackActorDamageAat( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, iModelIndex, iTimeOffset )
{
	// check for attacker and inflictor are the same, and are a player, make sure its correct mod type
	// also make sure zmb isnt already being aat'd and random chance.
	if ( isDefined( eAttacker ) && isPlayer( eAttacker ) && isDefined( eInflictor ) && eInflictor == eAttacker && ( sMeansOfDeath == "MOD_PISTOL_BULLET" || sMeansOfDeath == "MOD_RIFLE_BULLET" ) && !isDefined( self.marked ) && ( !isDefined( self.magic_bullet_shield ) || !self.magic_bullet_shield ) && eAttacker.aat_fire_time != GetTime() )
	{
		eAttacker.aat_fire_time = GetTime();

		// deadwire is active
		if ( isDefined( eAttacker.dead_wire_is_active ) && eAttacker.dead_wire_is_active && randomInt( 100 ) < level.zombie_vars["dead_wire_proc_chance"] )
			self thread try_deadwire( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, iModelIndex, iTimeOffset );

		// blast_furnace is active
		else if ( isDefined( eAttacker.blast_furnace_is_active ) && eAttacker.blast_furnace_is_active && randomInt( 100 ) < level.zombie_vars["blast_furnace_proc_chance"] )
			self thread try_blastfurnace( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, iModelIndex, iTimeOffset );

		// thunderwall is active
		else if ( isDefined( eAttacker.thunder_wall_is_active ) && eAttacker.thunder_wall_is_active && randomInt( 100 ) < level.zombie_vars["thunder_wall_proc_chance"] )
			self thread try_thunderwall( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, iModelIndex, iTimeOffset );

		// fireworks is active
		else if ( isDefined( eAttacker.fire_works_is_active ) && eAttacker.fire_works_is_active && randomInt( 100 ) < level.zombie_vars["fire_works_proc_chance"] )
			self thread try_fireworks( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, iModelIndex, iTimeOffset );

		// turned is active
		else if ( isDefined( eAttacker.turned_is_active ) && eAttacker.turned_is_active && randomInt( 100 ) < level.zombie_vars["turned_proc_chance"] )
			self thread try_turned( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, iModelIndex, iTimeOffset );
	}

	// check for fireworks model!
	if ( isDefined( eAttacker ) && isDefined( eAttacker.fire_works_owner ) && ( !isDefined( self.magic_bullet_shield ) || !self.magic_bullet_shield ) )
	{
		self thread gib_and_kill( eAttacker.fire_works_owner );
		return;
	}

	self [[level.callbackActorDamageAatPrev]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, iModelIndex, iTimeOffset );
}

gib_and_kill( player )
{
	if ( !self enemy_is_dog() )
	{
		refs = [];
		refs[refs.size] = "guts";
		refs[refs.size] = "right_arm";
		refs[refs.size] = "left_arm";
		refs[refs.size] = "right_leg";
		refs[refs.size] = "left_leg";
		refs[refs.size] = "no_legs";

		self.a.gib_ref = animscripts\death::get_random( refs );
		self thread animscripts\death::do_gib();

		if ( RandomInt( 100 ) < level.zombie_vars[ "tesla_head_gib_chance" ] )
			self thread maps\_zombiemode_spawner::zombie_head_gib();
	}

	if ( isDefined( player ) )
		self doDamage( self.maxHealth + 666, self.origin, player );
	else
		self doDamage( self.maxHealth + 666, self.origin );
}

on_player_connect()
{
	for ( ;; )
	{
		level waittill( "connecting", player );

		player.aat_fire_time = GetTime();

		player.dead_wire_cooldown_time_remaining = undefined;
		player.dead_wire_is_active = undefined;

		player.blast_furnace_cooldown_time_remaining = undefined;
		player.blast_furnace_is_active = undefined;

		player.thunder_wall_cooldown_time_remaining = undefined;
		player.thunder_wall_is_active = undefined;

		player.fire_works_cooldown_time_remaining = undefined;
		player.fire_works_is_active = undefined;

		player.turned_cooldown_time_remaining = undefined;
		player.turned_is_active = undefined;

		player thread create_and_watch_aat_hudelem();
		player thread watch_weapons();
	}
}

watch_weapons()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "weapon_change", weap );

		self.dead_wire_is_active = undefined;
		self.blast_furnace_is_active = undefined;
		self.thunder_wall_is_active = undefined;
		self.fire_works_is_active = undefined;
		self.turned_is_active = undefined;

		if ( !maps\_zombiemode_weapons::is_weapon_upgraded( weap ) )
			continue;

		a = randomInt( 6 );

		if ( a == 1 )
			self.dead_wire_is_active = true;

		if ( a == 2 )
			self.blast_furnace_is_active = true;

		if ( a == 3 )
			self.thunder_wall_is_active = true;

		if ( a == 4 )
			self.fire_works_is_active = true;

		if ( a == 5 )
			self.turned_is_active = true;
	}
}

create_and_watch_aat_hudelem()
{
	self endon( "disconnect" );

	hudelem = newClientHudElem( self );
	hudelem endon( "death" );

	hudelem.horzAlign = "right";
	hudelem.vertAlign = "bottom";
	hudelem.x = -48;
	hudelem.y = -36;
	hudelem.alpha = 0;
	hudelem.archived = true;

	last_shader = "";
	dw_shader = "dead_wire_icon";
	bf_shader = "blast_furnace_icon";
	tw_shader = "thunderwall_icon";
	fw_shader = "fire_works_icon";
	t_shader = "turned_icon";

	for ( ;; )
	{
		wait 0.05;

		if ( isDefined( self.dead_wire_is_active ) && self.dead_wire_is_active )
		{
			if ( last_shader != dw_shader )
			{
				last_shader = dw_shader;
				hudelem.alpha = 1;
				hudelem SetShader( dw_shader, 24, 24 );
			}
		}
		else if ( isDefined( self.blast_furnace_is_active ) && self.blast_furnace_is_active )
		{
			if ( last_shader != bf_shader )
			{
				last_shader = bf_shader;
				hudelem.alpha = 1;
				hudelem SetShader( bf_shader, 24, 24 );
			}
		}
		else if ( isDefined( self.thunder_wall_is_active ) && self.thunder_wall_is_active )
		{
			if ( last_shader != tw_shader )
			{
				last_shader = tw_shader;
				hudelem.alpha = 1;
				hudelem SetShader( tw_shader, 24, 24 );
			}
		}
		else if ( isDefined( self.fire_works_is_active ) && self.fire_works_is_active )
		{
			if ( last_shader != fw_shader )
			{
				last_shader = fw_shader;
				hudelem.alpha = 1;
				hudelem SetShader( fw_shader, 24, 24 );
			}
		}
		else if ( isDefined( self.turned_is_active ) && self.turned_is_active )
		{
			if ( last_shader != t_shader )
			{
				last_shader = t_shader;
				hudelem.alpha = 1;
				hudelem SetShader( t_shader, 24, 24 );
			}
		}
		else
		{
			if ( hudelem.alpha != 0 )
				hudelem.alpha = 0;

			last_shader = "";
		}
	}
}

double_pap_show_hitmarker( image )
{
	self playlocalsound( "hitmarker_sound" );

	hitmarker = newClientHudElem( self );
	hitmarker endon( "death" );

	hitmarker.horzAlign = "center";
	hitmarker.vertAlign = "middle";
	hitmarker.x = -12;
	hitmarker.y = -12;
	hitmarker.alpha = 1;
	hitmarker.archived = true;
	hitmarker SetShader( image, 24, 48 );
	wait .5;

	while ( 1 )
	{
		hitmarker.alpha -= .05;

		if ( hitmarker.alpha <= 0 )
			break;

		wait .05;
	}

	hitmarker destroy();
}

// TURNED

try_turned( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, iModelIndex, iTimeOffset )
{
	// check cooldown
	if ( isDefined( eAttacker.turned_cooldown_time_remaining ) && eAttacker.turned_cooldown_time_remaining > 0 )
		return;

	if ( self enemy_is_dog() )
		return;

	playable_area = getentarray( "playable_area", "targetname" );
	in_playable_area = false;

	if ( !isDefined( playable_area ) || playable_area.size < 1 )
	{
		in_playable_area = true;
	}

	if ( !in_playable_area )
	{
		for ( p = 0; p < playable_area.size; p++ )
		{
			if ( self isTouching( playable_area[ p ] ) && isAlive( self ) )
			{
				in_playable_area = true;
				break;
			}
		}
	}

	if ( !in_playable_area )
		return;

	// do it
	self.marked = true;
	eAttacker thread turned_cooldown_timer( level.zombie_vars["turned_cooldown"] );
	eAttacker thread double_pap_show_hitmarker( "turned_reticle" );

	self thread turned_icon();
	self thread turned_fx_loop();
	self thread turned_timeout( eAttacker );

	self thread turned_zmb();
	self thread turned_target( eAttacker );

	eAttacker thread turned_area_of_effect( self );
}

turned_zmb()
{
	self endon( "death" );
	self endon( "stop_turned" );

	if ( !self enemy_is_dog() && self.has_legs )
	{
		self.zombie_move_speed = "sprint";

		var = randomintrange( 1, 4 );
		self set_run_anim( "sprint" + var );
		self.run_combatanim = level.scr_anim[ self.animname ][ "sprint" + var ];
	}

	self setCanDamage( false );
	self.meleeAttackDist = 1;
	self.magic_bullet_shield = true;
	self.maxHealth = 999999;
	self.health = self.maxHealth;
	self.ignoreall = true;
	self.favoriteenemy = self;
	self.turned = true;

	for ( ;; )
	{
		self notify( "zombie_acquire_enemy" );
		self.zombie_path_timer = GetTime() + level.zombie_vars["turned_time"] + 1000;

		wait 0.05;
		waittillframeend;
	}
}

turned_target( owner )
{
	self endon( "death" );

	dist = level.zombie_vars["turned_attack_dist"];
	dist *= dist;

	while ( 1 )
	{
		zombies = self turned_get_zombies_in_playable();

		if ( isDefined( zombies ) && zombies.size > 0 )
		{
			self.favoriteenemy = zombies[ 0 ];

			if ( distancesquared( self.favoriteenemy.origin, self.origin ) < dist )
				self turned_zombie_attack( owner );
			else
				self SetGoalPos( zombies[ 0 ].origin );
		}
		else
		{
			self SetGoalPos( self.origin );
			self.favoriteenemy = self;
		}

		wait .05;
	}
}

turned_zombie_attack( owner )
{
	angles = VectorToAngles( self.favoriteenemy.origin - self.origin );
	self OrientMode( "face angle", angles[ 1 ] );

	dist = level.zombie_vars["turned_attack_dist"] + 10;
	dist *= dist;

	self animMode( "zonly_physics" );
	self SetGoalPos( self.favoriteenemy.origin );

	if ( !self enemy_is_dog() )
	{
		if ( self.has_legs )
			self animscripted( "melee_zombies", self.origin, self.angles, level._zombie_run_melee[ "zombie" ][ randomInt( 3 ) ] );
		else
			self animscripted( "melee_zombies", self.origin, self.angles, level._zombie_melee_crawl[ "zombie" ][ randomInt( 1 ) ] );
	}

	while ( 1 )
	{
		self waittill( "melee_zombies", note );

		if ( note == "fire" )
		{
			if ( isDefined( self.favoriteenemy ) && distancesquared( self.favoriteenemy.origin, self.origin ) < dist )
			{
				self.favoriteenemy thread gib_and_kill( owner );
				wait .2;
				self stopAnimScripted();
				break;
			}
		}

		if ( note == "end" )
			break;
	}

	self animMode( "none" );
}

turned_fx_loop()
{
	fxObj = spawn( "script_origin", self.origin );
	fxObj setModel( "tag_origin" );

	tag = "J_SpineUpper";

	if ( self enemy_is_dog() )
		tag = "J_Spine1";

	fxObj linkto( self, tag, ( 0, 0, 0 ), ( 0, 0, 0 ) );
	self.play_turned_fx = true;

	while ( isDefined( self ) && isAlive( self ) && isDefined( self.play_turned_fx ) )
	{
		fxObj playsound( "turned_sound" );
		playFxOnTag( level._effect[ "fx_turned" ], self, tag );
		wait .5;
	}

	fxObj delete ();
}

turned_get_zombies_in_playable()
{
	array = [];

	ai = getAiSpeciesArray( "axis", "all" );

	if ( !isDefined( ai ) || ai.size < 1 )
		return array;

	zombies = get_array_of_closest( self.origin, ai );

	if ( !isDefined( zombies ) || zombies.size < 1 )
		return array;

	playable_area = getentarray( "playable_area", "targetname" );

	if ( !isDefined( playable_area ) || playable_area.size < 1 )
		return array;

	for ( i = 0; i < zombies.size; i++ )
	{
		if ( isDefined( zombies[ i ].marked ) && zombies[ i ].marked )
			continue;

		if ( zombies[ i ] == self )
			continue;

		for ( p = 0; p < playable_area.size; p++ )
		{
			if ( zombies[ i ] isTouching( playable_area[ p ] ) )
				array[ array.size ] = zombies[ i ];
		}
	}

	return array;
}

turned_timeout( player )
{
	self endon( "death" );

	wait level.zombie_vars["turned_time"] - 1;
	self.play_turned_fx = undefined;
	wait 1;

	self notify( "stop_turned" );

	self.magic_bullet_shield = false;
	self setCanDamage( true );

	if ( !self enemy_is_dog() )
	{
		playFx( level._effect["dog_gib"], self GetCentroid() );
		playsoundatposition( "zombie_head_gib", self.origin );
	}

	self thread gib_and_kill( player );
}

turned_icon()
{
	hud_elem = newHudElem();
	hud_elem setWaypoint( false, "turned_icon" );
	hud_elem.hidewheninmenu = 1;
	hud_elem.immunetodemogamehudsettings = 1;

	been_dead = 0;
	after_time = 3;

	while ( isDefined( self ) )
	{
		org = self GetTagOrigin( "j_head" ) + ( 0, 0, 8 );
		hud_elem.x = org[ 0 ];
		hud_elem.y = org[ 1 ];
		hud_elem.z = org[ 2 ];

		if ( !isAlive( self ) )
			been_dead += 0.05;

		if ( been_dead >= after_time )
			break;

		wait .05;
	}

	while ( been_dead < after_time )
	{
		been_dead += 0.05;
		wait 0.05;
	}

	hud_elem destroy();
}

turned_cooldown_timer( time )
{
	self endon( "disconnect" );

	self notify( "turned_cooldown_timer" );
	self endon( "turned_cooldown_timer" );

	self.turned_cooldown_time_remaining = time;

	while ( self.turned_cooldown_time_remaining > 0 )
	{
		wait 1;

		self.turned_cooldown_time_remaining--;
	}

	self.turned_cooldown_time_remaining = undefined;
}

turned_fling( player )
{
	fling_vec = vectorScale( ( RandomFloatRange( -1, 1 ), RandomFloatRange( -1, 1 ), RandomFloatRange( -1, 1 ) ), RandomFloatRange( 25, 75 ) );

	if ( !self enemy_is_dog() )
	{
		self setContents( 0 );
		self startRagdoll();
		self launchRagdoll( fling_vec );
		wait_network_frame();
	}
	else
	{
		self.a.nodeath = true;
	}

	if ( !isDefined( self ) )
		return;

	if ( isDefined( player ) )
		self doDamage( self.maxHealth + 666, self.origin, player );
	else
		self doDamage( self.maxHealth + 666, self.origin );
}

turned_area_of_effect( my_guy )
{
	zombies = getAiSpeciesArray( "axis", "all" );

	if ( !isDefined( zombies ) || zombies.size < 1 )
		return;

	// limit dist to 100
	zombies = get_array_of_closest( my_guy.origin, zombies, undefined, undefined, level.zombie_vars["turned_radius"] );

	if ( !isDefined( zombies ) || zombies.size < 1 )
		return;

	count = 0;

	for ( i = 0; i < zombies.size; i++ )
	{
		if ( !IsDefined( zombies[i] ) )
		{
			// guy died on us
			continue;
		}

		if ( isDefined( zombies[i].magic_bullet_shield ) && zombies[i].magic_bullet_shield )
			continue;

		// cap dw to 10
		if ( count >= level.zombie_vars["turned_kill_count"] )
			return;

		// make sure he isnt already aat'd
		if ( isDefined( zombies[ i ].marked ) )
			continue;

		// makem sure he is alive
		if ( isAlive( zombies[ i ] ) )
		{
			// kill the dude
			zombies[ i ].marked = true;

			// play effect of arc moving from guy to other dudes and kill
			zombies[ i ] thread turned_fling( self );
		}

		count++;
	}
}

// FIREWORKS

try_fireworks( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, iModelIndex, iTimeOffset )
{
	// check cooldown
	if ( isDefined( eAttacker.fire_works_cooldown_time_remaining ) && eAttacker.fire_works_cooldown_time_remaining > 0 )
		return;

	// do it
	self.marked = true;
	eAttacker thread fire_works_cooldown_timer( level.zombie_vars["fire_works_cooldown"] );
	eAttacker thread double_pap_show_hitmarker( "fire_works_reticle" );

	// do aoe and fx
	eAttacker thread fire_works_area_of_effect( self );

	// kill him!
	self thread gib_and_kill( eAttacker );
}

fire_works_cooldown_timer( time )
{
	self endon( "disconnect" );

	self notify( "fire_works_cooldown_timer" );
	self endon( "fire_works_cooldown_timer" );

	self.fire_works_cooldown_time_remaining = time;

	while ( self.fire_works_cooldown_time_remaining > 0 )
	{
		wait 1;

		self.fire_works_cooldown_time_remaining--;
	}

	self.fire_works_cooldown_time_remaining = undefined;
}

fire_works_get_los_zmb()
{
	zombies = getAiSpeciesArray( "axis", "all" );
	zombies = array_randomize( zombies );

	los_checks = 0;
	range_sq = level.zombie_vars["fire_works_radius"];
	range_sq *= range_sq;

	for ( i = 0; i < zombies.size; i++ )
	{
		zombie = zombies[i];
		test_origin = zombie getcentroid();

		if ( !isDefined( zombie ) || !isAlive( zombie ) || ( isDefined( zombie.magic_bullet_shield ) && zombie.magic_bullet_shield ) )
			continue;

		if ( DistanceSquared( self.origin, test_origin ) > range_sq )
			continue;

		if ( los_checks < level.zombie_vars["fire_works_num_los"] && !zombie DamageConeTrace( self.origin, self ) )
		{
			los_checks++;
			continue;
		}

		return zombie;
	}

	if ( zombies.size )
		return zombies[0];

	return undefined;
}

fire_works_area_of_effect( my_guy )
{
	weapon = self GetCurrentWeapon();
	target_origin = my_guy.origin;

	firing_pos = target_origin + ( 0, 0, 56 );

	start_yaw = VectorToAngles( firing_pos - target_origin );
	start_yaw = ( 0, start_yaw[1], 0 );

	model = spawn( "script_model", target_origin );
	model setModel( GetWeaponModel( weapon ) );
	model.fire_works_owner = self;

	origin = playerPhysicsTrace( target_origin, target_origin + ( 0, 0, -1000 ) );
	fxObj = spawn( "script_model", origin );
	fxObj setModel( "tag_origin" );
	fxObj.angles = ( 270, 0, 0 );

	playFxOnTag( level._effect[ "fx_fire_works" ], fxObj, "tag_origin" );
	fxObj PlaySound( "fireworks_sound" );

	model MoveTo( firing_pos, randomFloatRange( level.zombie_vars["fire_works_init_wait_min"], level.zombie_vars["fire_works_init_wait_max"] ) );
	model waittill( "movedone" );

	for ( i = 0 ; i < level.zombie_vars["fire_works_num_frames"]; i++ )
	{
		zmb = model fire_works_get_los_zmb();

		if ( !IsDefined( zmb ) )
		{
			//if no target available, just pick a random yaw
			curr_yaw = ( 0, RandomIntRange( 0, 360 ), 0 );
			target_pos = model.origin + VectorScale( AnglesToForward( curr_yaw ), 40 );
		}
		else
		{
			target_pos = zmb GetCentroid();
		}

		model.angles = VectorToAngles( target_pos - model.origin );
		flash_pos = model GetTagOrigin( "tag_flash" );
		model DontInterpolate();

		// FIRE!
		MagicBullet( weapon, flash_pos, target_pos, model );

		wait 0.1;
	}

	model MoveTo( target_origin, randomFloatRange( level.zombie_vars["fire_works_init_wait_min"], level.zombie_vars["fire_works_init_wait_max"] ) );
	model waittill( "movedone" );

	wait 0.3;
	model delete ();
	wait 5;
	fxObj delete ();
}

// THUNDERWALL

try_thunderwall( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, iModelIndex, iTimeOffset )
{
	// check cooldown
	if ( isDefined( eAttacker.thunder_wall_cooldown_time_remaining ) && eAttacker.thunder_wall_cooldown_time_remaining > 0 )
		return;

	// do it
	self.marked = true;
	eAttacker thread thunder_wall_cooldown_timer( level.zombie_vars["thunder_wall_cooldown"] );
	eAttacker thread double_pap_show_hitmarker( "thunderwall_reticle" );

	// kill others
	self thread thunder_wall_fx( eAttacker );

	eAttacker thread thunder_wall_area_of_effect( self );

	// kill it
	self thread thunder_wall_fling_and_kill( eAttacker );
}

thunder_wall_cooldown_timer( time )
{
	self endon( "disconnect" );

	self notify( "thunder_wall_cooldown_timer" );
	self endon( "thunder_wall_cooldown_timer" );

	self.thunder_wall_cooldown_time_remaining = time;

	while ( self.thunder_wall_cooldown_time_remaining > 0 )
	{
		wait 1;

		self.thunder_wall_cooldown_time_remaining--;
	}

	self.thunder_wall_cooldown_time_remaining = undefined;
}

thunder_wall_fx( player )
{
	origin = self.origin;

	if ( self enemy_is_dog() )
		origin = self GetTagOrigin( "J_Spine1" );
	else
		origin = self GetTagOrigin( "j_spineupper" );

	fxOrg = Spawn( "script_model", origin );
	fxOrg SetModel( "tag_origin" );
	fxOrg.angles = player.angles;

	playFxOnTag( level._effect[ "fx_thunder_wall" ], fxOrg, "tag_origin" );
	playsoundatposition( "thunderwall_sound", fxOrg.origin );

	wait 2;
	fxOrg delete ();
}

thunder_wall_fling_and_kill( player )
{
	wait randomFloatRange( level.zombie_vars["thunder_wall_wait_min"], level.zombie_vars["thunder_wall_wait_max"] );

	if ( !isDefined( self ) || !isDefined( player ) )
		return;

	angle = vectorToAngles( self.origin - player.origin );
	angle = anglesToForward( angle ) + anglesToUp( angle );
	fling_vec = vectorScale( angle, RandomFloatRange( 150, 250 ) );

	if ( !self enemy_is_dog() )
	{
		self setContents( 0 );
		self startRagdoll();
		self launchRagdoll( fling_vec );
		wait_network_frame();
	}
	else
	{
		self.a.nodeath = true;
	}

	if ( !isDefined( self ) )
		return;

	if ( isDefined( player ) )
		self doDamage( self.maxHealth + 666, self.origin, player );
	else
		self doDamage( self.maxHealth + 666, self.origin );
}

thunder_wall_area_of_effect( my_guy )
{
	view_pos = self getTagOrigin( "tag_eye" );
	range = level.zombie_vars[ "thunder_wall_range" ];
	radius = level.zombie_vars[ "thunder_wall_radius" ];

	zombies = get_array_of_closest( view_pos, GetAISpeciesArray( "axis", "all" ), undefined, undefined, range * 1.1 );

	range_squared = range * range;
	radius_squared = radius * radius;

	forward_view_angles = anglesToForward( self getPlayerAngles() );
	end_pos = view_pos + ( forward_view_angles * range );

	count = 0;

	for ( i = 0; i < zombies.size; i++ )
	{
		if ( !IsDefined( zombies[i] ) || !IsAlive( zombies[i] ) )
		{
			// guy died on us
			continue;
		}

		if ( count >= level.zombie_vars["thunder_wall_kill_count"] )
			return;

		// make sure he isnt already aat'd
		if ( isDefined( zombies[ i ].marked ) )
			continue;

		test_origin = zombies[i] getcentroid();
		test_range_squared = DistanceSquared( view_pos, test_origin );

		if ( test_range_squared > range_squared )
			break;

		if ( isDefined( zombies[i].magic_bullet_shield ) && zombies[i].magic_bullet_shield )
			continue;

		normal = VectorNormalize( test_origin - view_pos );
		dot = VectorDot( forward_view_angles, normal );

		if ( 0 > dot )
			continue;

		radial_origin = PointOnSegmentNearestToPoint( view_pos, end_pos, test_origin );

		if ( DistanceSquared( test_origin, radial_origin ) > radius_squared )
			continue;

		if ( zombies[i] DamageConeTrace( view_pos, self ) <= 0 )
			continue;

		// kill the dude
		zombies[ i ].marked = true;
		zombies[ i ] thread thunder_wall_fling_and_kill( self );
		count++;
	}
}

// BLASTFURNACE

try_blastfurnace( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, iModelIndex, iTimeOffset )
{
	// check cooldown
	if ( isDefined( eAttacker.blast_furnace_cooldown_time_remaining ) && eAttacker.blast_furnace_cooldown_time_remaining > 0 )
		return;

	// do it
	self.marked = true;
	eAttacker thread blast_furnace_cooldown_timer( level.zombie_vars["blast_furnace_cooldown"] );
	eAttacker thread double_pap_show_hitmarker( "blast_furnace_reticle" );

	// kill others
	playsoundatposition( "blastfurnace_sound", self.origin );
	playFx( level._effect[ "fx_blast_furnace" ], self.origin );

	eAttacker thread blast_furnace_area_of_effect( self );

	wait RandomFloatRange( level.zombie_vars["blast_furnace_init_wait_min"], level.zombie_vars["blast_furnace_init_wait_max"] );

	if ( !isDefined( self ) )
		return;

	// kill it
	self thread blast_furnace_death_fx( 0 );
	self thread blast_furnace_dot( eAttacker ); // failsafe

	// do damage
	setPlayerIgnoreRadiusDamage( true );

	if ( isDefined( eAttacker ) )
		eAttacker radiusDamage( self.origin, 5, self.maxhealth + 666, self.maxhealth + 666, eAttacker, sMeansOfDeath );

	setPlayerIgnoreRadiusDamage( false );
}

blast_furnace_cooldown_timer( time )
{
	self endon( "disconnect" );

	self notify( "blast_furnace_cooldown_timer" );
	self endon( "blast_furnace_cooldown_timer" );

	self.blast_furnace_cooldown_time_remaining = time;

	while ( self.blast_furnace_cooldown_time_remaining > 0 )
	{
		wait 1;

		self.blast_furnace_cooldown_time_remaining--;
	}

	self.blast_furnace_cooldown_time_remaining = undefined;
}

blast_furnace_death_fx( arc )
{
	joints = [];

	if ( self enemy_is_dog() )
	{
		joints[ 0 ] = "j_spine4";
		joints[ 1 ] = "j_hip_le";
		joints[ 2 ] = "j_hip_ri";
		joints[ 3 ] = "j_knee_le";
		joints[ 4 ] = "j_knee_ri";
		joints[ 5 ] = "j_pelvis";
	}
	else
	{
		joints[ 0 ] = "j_spinelower";
		joints[ 1 ] = "j_spineupper";
		joints[ 2 ] = "j_shoulder_le";
		joints[ 3 ] = "j_shoulder_ri";
		joints[ 4 ] = "j_elbow_ri";
		joints[ 5 ] = "j_elbow_le";
		joints[ 6 ] = "j_knee_le";
		joints[ 7 ] = "j_knee_ri";
	}

	for ( i = 0; i < 30; i++ )
	{
		index = randomInt( joints.size );

		if ( isDefined( self ) )
		{
			playfxontag( level._effect[ "fx_blast_furnace_torso" ], self, joints[ index ] );
			self playSound( "blastfurnace_sizzle" );
		}

		wait RandomFloatRange( .05, .35 );
	}
}

blast_furnace_dot( killer )
{
	self endon( "death" );

	while ( isDefined( self ) && isAlive( self ) )
	{
		dmg_amt = self.maxHealth * randomFloatRange( level.zombie_vars["blast_furnace_tick_damage_precent_min"], level.zombie_vars["blast_furnace_tick_damage_precent_max"] );

		if ( isDefined( killer ) )
			self doDamage( dmg_amt, self.origin, killer );

		wait RandomFloatRange( level.zombie_vars["blast_furnace_chain_wait_min"], level.zombie_vars["blast_furnace_chain_wait_max"] );
	}
}

blast_furnace_area_of_effect( my_guy )
{
	zombies = getAiSpeciesArray( "axis", "all" );

	if ( !isDefined( zombies ) || zombies.size < 1 )
		return;

	// limit dist to 100
	zombies = get_array_of_closest( my_guy.origin, zombies, undefined, undefined, level.zombie_vars["blast_furnace_radius"] );

	if ( !isDefined( zombies ) || zombies.size < 1 )
		return;

	count = 0;

	for ( i = 0; i < zombies.size; i++ )
	{
		if ( !IsDefined( zombies[i] ) )
		{
			// guy died on us
			continue;
		}

		if ( isDefined( zombies[i].magic_bullet_shield ) && zombies[i].magic_bullet_shield )
			continue;

		// cap dw to 10
		if ( count >= level.zombie_vars["blast_furnace_kill_count"] )
			return;

		// make sure he isnt already aat'd
		if ( isDefined( zombies[ i ].marked ) )
			continue;

		// makem sure he is alive
		if ( isAlive( zombies[ i ] ) )
		{
			// kill the dude
			zombies[ i ].marked = true;
			zombies[ i ] thread blast_furnace_death_fx( 1 );
			zombies[ i ] thread blast_furnace_dot( self );
		}

		count++;
	}
}

// DEADWIRE

try_deadwire( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, iModelIndex, iTimeOffset )
{
	// check cooldown
	if ( isDefined( eAttacker.dead_wire_cooldown_time_remaining ) && eAttacker.dead_wire_cooldown_time_remaining > 0 )
		return;

	// do it
	self.marked = true;
	eAttacker thread dead_wire_cooldown_timer( level.zombie_vars["dead_wire_cooldown"] );
	eAttacker thread double_pap_show_hitmarker( "dead_wire_reticle" );

	// kill others
	eAttacker thread dead_wire_area_of_effect( self );

	wait RandomFloatRange( level.zombie_vars["dead_wire_init_wait_min"], level.zombie_vars["dead_wire_init_wait_max"] );

	if ( !isDefined( self ) )
		return;

	// kill it
	self thread dead_wire_death_fx( 0 );

	// do damage
	setPlayerIgnoreRadiusDamage( true );

	if ( isDefined( eAttacker ) )
		eAttacker radiusDamage( self.origin, 5, self.maxhealth + 666, self.maxhealth + 666, eAttacker, sMeansOfDeath );

	setPlayerIgnoreRadiusDamage( false );

	// failsafe
	if ( isAlive( self ) )
		self doDamage( self.maxHealth + 666, self.origin );
}

dead_wire_cooldown_timer( time )
{
	self endon( "disconnect" );

	self notify( "dead_wire_cooldown_timer" );
	self endon( "dead_wire_cooldown_timer" );

	self.dead_wire_cooldown_time_remaining = time;

	while ( self.dead_wire_cooldown_time_remaining > 0 )
	{
		wait 1;

		self.dead_wire_cooldown_time_remaining--;
	}

	self.dead_wire_cooldown_time_remaining = undefined;
}

dead_wire_death_fx( arc_num )
{
	tag = "tag_origin";

	// shock death anim
	if ( self enemy_is_dog() )
	{
		self.a.nodeath = undefined;
		tag = "J_Spine1";
	}
	else
	{
		if ( self.has_legs )
			self.deathanim = random( level._zombie_tesla_death[ self.animname ] );
		else
			self.deathanim = random( level._zombie_tesla_crawl_death[ self.animname ] );

		tag = "J_SpineUpper";
	}

	fx = "tesla_shock";

	if ( arc_num > 0 )
		fx = "tesla_shock_secondary";

	playfxontag( level._effect[ fx ], self, tag );
	self playsound( "imp_tesla" );

	if ( !self enemy_is_dog() )
	{
		if ( RandomInt( 100 ) < level.zombie_vars[ "tesla_head_gib_chance" ] )
		{
			wait( RandomFloat( 0.53, 1.0 ) );

			if ( isDefined( self ) )
				self maps\_zombiemode_spawner::zombie_head_gib();
		}
		else
			playfxontag( level._effect[ "tesla_shock_eyes" ], self, "j_eyeball_le" );
	}
}

dead_wire_arc_fx( guy, dude )
{
	from = guy.origin;

	if ( guy enemy_is_dog() )
		from = guy GetTagOrigin( "J_Spine1" );
	else
		from = guy GetTagOrigin( "j_spineupper" );

	to = dude.origin;

	if ( guy enemy_is_dog() )
		to = dude GetTagOrigin( "J_Spine1" );
	else
		to = dude GetTagOrigin( "j_spineupper" );


	// play bounce fx
	fxOrg = Spawn( "script_model", from );

	fxOrg SetModel( "tag_origin" );

	playFxOnTag( level._effect[ "tesla_bolt" ], fxOrg, "tag_origin" );
	playsoundatposition( "tesla_bounce", fxOrg.origin );

	fxOrg MoveTo( to, RandomFloatRange( level.zombie_vars["dead_wire_chain_wait_min"], level.zombie_vars["dead_wire_chain_wait_max"] ) );
	fxOrg waittill( "movedone" );
	fxOrg delete ();

	if ( !isDefined( dude ) )
		return;

	// kill him
	dude thread dead_wire_death_fx( 1 );

	if ( isDefined( self ) )
		dude doDamage( dude.maxHealth + 666, dude.origin, self );
}

dead_wire_area_of_effect( my_guy )
{
	zombies = getAiSpeciesArray( "axis", "all" );

	if ( !isDefined( zombies ) || zombies.size < 1 )
		return;

	// limit dist to 100
	zombies = get_array_of_closest( my_guy.origin, zombies, undefined, undefined, level.zombie_vars["dead_wire_radius"] );

	if ( !isDefined( zombies ) || zombies.size < 1 )
		return;

	count = 0;

	for ( i = 0; i < zombies.size; i++ )
	{
		if ( !IsDefined( zombies[i] ) )
		{
			// guy died on us
			continue;
		}

		if ( isDefined( zombies[i].magic_bullet_shield ) && zombies[i].magic_bullet_shield )
			continue;

		// cap dw to 10
		if ( count >= level.zombie_vars["dead_wire_kill_count"] )
			return;

		// make sure he isnt already aat'd
		if ( isDefined( zombies[ i ].marked ) )
			continue;

		// makem sure he is alive
		if ( isAlive( zombies[ i ] ) )
		{
			// kill the dude
			zombies[ i ].marked = true;

			// play effect of arc moving from guy to other dudes and kill
			self thread dead_wire_arc_fx( my_guy, zombies[ i ] );
		}

		count++;
	}
}
