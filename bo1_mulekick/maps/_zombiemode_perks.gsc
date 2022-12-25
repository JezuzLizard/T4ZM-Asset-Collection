#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;

init()
{
	vending_triggers = GetEntArray( "zombie_vending", "targetname" );

	if ( vending_triggers.size < 1 )
	{
		return;
	}

	vending_upgrade_trigger = GetEntArray("zombie_vending_upgrade", "targetname");

	if ( vending_upgrade_trigger.size >= 1 )
	{
		array_thread( vending_upgrade_trigger, ::vending_upgrade );;
	}


	// this map uses atleast 1 perk machine
	PrecacheItem( "zombie_perk_bottle_doubletap" );
	PrecacheItem( "zombie_perk_bottle_jugg" );
	PrecacheItem( "zombie_perk_bottle_revive" );
	PrecacheItem( "zombie_perk_bottle_sleight" );
	PrecacheItem( "zombie_knuckle_crack" );

	PrecacheShader( "specialty_juggernaut_zombies" );
	PrecacheShader( "specialty_fastreload_zombies" );
	PrecacheShader( "specialty_doubletap_zombies" );
	PrecacheShader( "specialty_quickrevive_zombies" );

	//PI ESM - sumpf vending machine
	if (isDefined(level.script) && level.script == "nazi_zombie_sumpf")
	{
		PrecacheModel("zombie_vending_jugg_on_price");
		PrecacheModel("zombie_vending_doubletap_price");
		PrecacheModel("zombie_vending_revive_on_price");
		PrecacheModel("zombie_vending_sleight_on_price");
	}
	else
	{
		PrecacheModel("zombie_vending_jugg_on");
		PrecacheModel("zombie_vending_doubletap_on");
		PrecacheModel("zombie_vending_revive_on");
		PrecacheModel("zombie_vending_sleight_on");
		precachemodel("zombie_vending_packapunch_on");
	}

	level._effect["sleight_light"] = loadfx("misc/fx_zombie_cola_on");
	level._effect["doubletap_light"] = loadfx("misc/fx_zombie_cola_dtap_on");
	level._effect["jugger_light"] = loadfx("misc/fx_zombie_cola_jugg_on");
	level._effect["revive_light"] = loadfx("misc/fx_zombie_cola_revive_on");
	level._effect["packapunch_fx"] = loadfx("maps/zombie/fx_zombie_packapunch");

	if( !isDefined( level.packapunch_timeout ) )
	{
		level.packapunch_timeout = 15;
	}

	PrecacheString( &"ZOMBIE_PERK_JUGGERNAUT" );
	PrecacheString( &"ZOMBIE_PERK_QUICKREVIVE" );
	PrecacheString( &"ZOMBIE_PERK_FASTRELOAD" );
	PrecacheString( &"ZOMBIE_PERK_DOUBLETAP" );
	PrecacheString( &"ZOMBIE_PERK_PACKAPUNCH" );

	set_zombie_var( "zombie_perk_cost",					2000 );
	set_zombie_var( "zombie_perk_juggernaut_health",	160 );

	vending_triggers[vending_triggers.size] = level init_mulekick(( -1089, -1366, 67 ), ( 0, 90, 0 ));

	// this map uses atleast 1 perk machine
	array_thread( vending_triggers, ::vending_trigger_think );
	array_thread( vending_triggers, :: electric_perks_dialog);


	level thread turn_jugger_on();
	level thread turn_doubletap_on();
	level thread turn_sleight_on();
	level thread turn_revive_on();
	level thread turn_PackAPunch_on();


	level thread machine_watcher();
	level.speed_jingle = 0;
	level.revive_jingle = 0;
	level.doubletap_jingle = 0;
	level.jugger_jingle = 0;
	level.packa_jingle = 0;

}

init_mulekick(origin, angles)
{
	PrecacheModel( "zombie_vending_three_gun" );
	PrecacheModel( "zombie_vending_three_gun_on" );
	PrecacheShader( "specialty_three_guns_zombies" );
	PrecacheItem( "zombie_perk_bottle_mule" );
	level._effect[ "additionalprimaryweapon_light" ] = loadfx( "misc/fx_zombie_cola_arsenal_on" );

	model = spawn( "script_model", origin );
	model.angles = angles;
	model SetModel( "zombie_vending_three_gun" );
	model.script_sound = "mx_mule_kick_jingle";

	col = spawncollision( "collision_geo_32x32x128", "collider", model.origin - ( 0, 0, -64 ), model.angles );

	trig = Spawn( "trigger_radius", model.origin + ( 0, 0, 30 ), 0, 20, 70 );
	trig.script_noteworthy = "specialty_extraammo";
	trig.targetname = "audio_bump_trigger";
	trig.script_sound = "perks_rattle";
	trig.script_activated = 1;

	trig thread bump_trig();

	models = [];
	models[0] = model;
	level thread turn_mule_on(models);

	// make mulekick work!
	replaceFunc(maps\_zombiemode_weapons::weapon_give, ::weapon_give_func);
	replaceFunc(maps\_zombiemode_weapons::treasure_chest_give_weapon, ::treasure_chest_give_weapon_func);

	// watch guns
	thread watch_guns();

	return trig;
}

bump_trig()
{
	while(1)
	{

		self waittill("trigger", who);
				
//		iprintlnbold("Triggered:");

		//Store sound to play in script_sound/ alias name
		if(IsDefined (self.script_sound) && self.script_activated)
		{	
			playsoundatposition(self.script_sound, self.origin);
//		iprintlnbold(self.script_sound);
		}
		while(IsDefined (who) && (who) IsTouching (self))
		{
			wait(0.1);
		}		
	}
}

is_weapon_included( weapon_name )
{
	if( !IsDefined( level.zombie_weapons ) )
	{
		return false;
	}

	return IsDefined( level.zombie_weapons[weapon_name] );
}

watch_guns()
{
	for (;;)
	{
		wait 0.05;

		players = get_players();
		for (h = 0; h < players.size; h++)
		{
			player = players[h];

			count = 2;
			if (player hasperk("specialty_extraammo"))
				count++;

			primary_weapons_that_can_be_taken = [];
			primaryWeapons = player GetWeaponsListPrimaries();
			cur_weap = player GetCurrentWeapon();
			for ( i = 0; i < primaryWeapons.size; i++ )
			{
				if ("mine_bouncing_betty" == primaryWeapons[i] )
					continue;

				if ( is_weapon_included( primaryWeapons[i] ) || maps\_zombiemode_weapons::is_weapon_upgraded( primaryWeapons[i] ) )
				{
					primary_weapons_that_can_be_taken[primary_weapons_that_can_be_taken.size] = primaryWeapons[i];
				}
			}

			if ( primary_weapons_that_can_be_taken.size > count )
			{
				weapon_to_take = primary_weapons_that_can_be_taken[primary_weapons_that_can_be_taken.size - 1];
				if ( weapon_to_take == cur_weap )
				{
					player SwitchToWeapon( primary_weapons_that_can_be_taken[0] );
				}
				player TakeWeapon( weapon_to_take );
			}
		}
	}
}

treasure_chest_give_weapon_func( weapon_string )
{
	primaryWeapons = self GetWeaponsListPrimaries();

	if( self HasWeapon( weapon_string ) )
	{
		self GiveMaxAmmo( weapon_string );
		self SwitchToWeapon( weapon_string );
		return;
	}

	count = 2;
	if (self hasperk("specialty_extraammo"))
		count++;

	current_weapon = self getCurrentWeapon(); // get hiss current weapon

	// This should never be true for the first time.
	if( primaryWeapons.size >= count ) // he has two weapons
	{
		if ( current_weapon == "mine_bouncing_betty" )
		{
			current_weapon = undefined;
		}

		if( isdefined( current_weapon ) )
		{
			if( !( weapon_string == "fraggrenade" || weapon_string == "stielhandgranate" || weapon_string == "molotov" || weapon_string == "zombie_cymbal_monkey" ) )
			{
				// PI_CHANGE_BEGIN
				// JMA - player dropped the tesla gun
				if( isDefined(level.script) && (level.script == "nazi_zombie_sumpf" || level.script == "nazi_zombie_factory") )
				{
					if( current_weapon == "tesla_gun" )
					{
						level.player_drops_tesla_gun = true;
					}
				}
				// PI_CHANGE_END

				self TakeWeapon( current_weapon );
		}
	}
	}

	if( IsDefined( primaryWeapons ) && !isDefined( current_weapon ) )
	{
		for( i = 0; i < primaryWeapons.size; i++ )
		{
			if( primaryWeapons[i] == "zombie_colt" )
			{
				continue;
			}

			if( weapon_string != "fraggrenade" && weapon_string != "stielhandgranate" && weapon_string != "molotov" && weapon_string != "zombie_cymbal_monkey" )
			{
				// PI_CHANGE_BEGIN
				// JMA - player dropped the tesla gun
				if( isDefined(level.script) && (level.script == "nazi_zombie_sumpf" || level.script == "nazi_zombie_factory") )
				{
					if( primaryWeapons[i] == "tesla_gun" )
					{
						level.player_drops_tesla_gun = true;
					}
				}
				// PI_CHANGE_END

				self TakeWeapon( primaryWeapons[i] );
			}
		}
	}

	self play_sound_on_ent( "purchase" );

	if( weapon_string == "molotov" || weapon_string == "molotov_zombie" )
	{
		// PI_CHANGE_BEGIN
		// JMA 051409 sanity check to see if we have the weapon before we remove it
		has_weapon = self HasWeapon( "zombie_cymbal_monkey" );
		if( isDefined(has_weapon) && has_weapon )
		{
			self TakeWeapon( "zombie_cymbal_monkey" );
		}
		// PI_CHANGE_END
	}
	if( weapon_string == "zombie_cymbal_monkey" )
	{
		// PI_CHANGE_BEGIN
		// JMA 051409 sanity check to see if we have the weapon before we remove it
		has_weapon = self HasWeapon( "molotov" );
		if( isDefined(has_weapon) && has_weapon )
		{
			self TakeWeapon( "molotov" );
		}

		if( isDefined(level.zombie_weapons) && isDefined(level.zombie_weapons["molotov_zombie"]) )
		{
			has_weapon = self HasWeapon( "molotov_zombie" );
			if( isDefined(has_weapon) && has_weapon )
			{
				self TakeWeapon( "molotov_zombie" );
			}
		}
		// PI_CHANGE_END

		self maps\_zombiemode_cymbal_monkey::player_give_cymbal_monkey();
		maps\_zombiemode_weapons::play_weapon_vo(weapon_string);
		return;
	}

	self GiveWeapon( weapon_string, 0 );
	self GiveMaxAmmo( weapon_string );
	self SwitchToWeapon( weapon_string );

	maps\_zombiemode_weapons::play_weapon_vo(weapon_string);

	// self playsound (level.zombie_weapons[weapon_string].sound);
}

weapon_give_func( weapon, is_upgrade )
{
	primaryWeapons = self GetWeaponsListPrimaries();
	current_weapon = undefined;

	//if is not an upgraded perk purchase
	if( !IsDefined( is_upgrade ) )
	{
		is_upgrade = false;
	}

	count = 2;
	if (self hasperk("specialty_extraammo"))
		count++;

	// This should never be true for the first time.
	if( primaryWeapons.size >= count ) // he has two weapons
	{
		current_weapon = self getCurrentWeapon(); // get his current weapon

		if ( current_weapon == "mine_bouncing_betty" )
		{
			current_weapon = undefined;
		}

		if( isdefined( current_weapon ) )
		{
			if( !( weapon == "fraggrenade" || weapon == "stielhandgranate" || weapon == "molotov" || weapon == "zombie_cymbal_monkey" ) )
			{
				self TakeWeapon( current_weapon );
			}
		}
	}

	if( weapon == "zombie_cymbal_monkey" )
	{
		// PI_CHANGE_BEGIN
		// JMA 051409 sanity check to see if we have the weapon before we remove it
		has_weapon = self HasWeapon( "molotov" );
		if( isDefined(has_weapon) && has_weapon )
		{
			self TakeWeapon( "molotov" );
		}

		if( isDefined(level.zombie_weapons) && isDefined(level.zombie_weapons["molotov_zombie"]) )
		{
			has_weapon = self HasWeapon( "molotov_zombie" );
			if( isDefined(has_weapon) && has_weapon )
			{
				self TakeWeapon( "molotov_zombie" );
			}
		}
		// PI_CHANGE_END

		self maps\_zombiemode_cymbal_monkey::player_give_cymbal_monkey();
		maps\_zombiemode_weapons::play_weapon_vo( weapon );
		return;
	}
	if( (weapon == "molotov" || weapon == "molotov_zombie") )
	{
			self TakeWeapon( "zombie_cymbal_monkey" );
	}

	self play_sound_on_ent( "purchase" );
	self GiveWeapon( weapon, 0 );
	self GiveMaxAmmo( weapon );
	self SwitchToWeapon( weapon );

	maps\_zombiemode_weapons::play_weapon_vo(weapon);
}

turn_mule_on(machine)
{
	level waittill("sleight_on");
	level notify("mule_on");

	for( i = 0; i < machine.size; i++ )
	{
		machine[i] setmodel("zombie_vending_three_gun_on");
		machine[i] vibrate((0,-100,0), 0.3, 0.4, 3);
		playsoundatposition("perks_power_on", machine[i].origin);
		machine[i] thread perk_fx( "additionalprimaryweapon_light" );

		machine[i] thread perks_a_cola_jingle();
	}

	level notify( "specialty_extraammo_power_on" );
}

third_person_weapon_upgrade( current_weapon, origin, angles, packa_rollers, perk_machine )
{
	forward = anglesToForward( angles );
	interact_pos = origin + (forward*-25);

	worldgun = spawn( "script_model", interact_pos );
	worldgun.angles  = self.angles;
	worldgun setModel( GetWeaponModel( current_weapon ) );
	PlayFx( level._effect["packapunch_fx"], origin+(0,1,-34), forward );

	worldgun rotateto( angles+(0,90,0), 0.35, 0, 0 );
	wait( 0.5 );
	worldgun moveto( origin, 0.5, 0, 0 );
	packa_rollers playsound( "packa_weap_upgrade" );
	if( isDefined( perk_machine.wait_flag ) )
	{
		perk_machine.wait_flag rotateto( perk_machine.wait_flag.angles+(179, 0, 0), 0.25, 0, 0 );
	}
	wait( 0.35 );
	worldgun delete();
	wait( 3 );
	packa_rollers playsound( "packa_weap_ready" );
	worldgun = spawn( "script_model", origin );
	worldgun.angles  = angles+(0,90,0);
	worldgun setModel( GetWeaponModel( current_weapon+"_upgraded" ) );
	worldgun moveto( interact_pos, 0.5, 0, 0 );
	if( isDefined( perk_machine.wait_flag ) )
	{
		perk_machine.wait_flag rotateto( perk_machine.wait_flag.angles-(179, 0, 0), 0.25, 0, 0 );
	}
	wait( 0.5 );
	worldgun moveto( origin, level.packapunch_timeout, 0, 0);
	return worldgun;
}

vending_upgrade()
{
	perk_machine = GetEnt( self.target, "targetname" );
	if( isDefined( perk_machine.target ) )
	{
		perk_machine.wait_flag = GetEnt( perk_machine.target, "targetname" );
	}

	self UseTriggerRequireLookAt();
	self SetHintString( &"ZOMBIE_FLAMES_UNAVAILABLE" );
	self SetCursorHint( "HINT_NOICON" );
	level waittill("Pack_A_Punch_on");

	self thread maps\_zombiemode_weapons::decide_hide_show_hint();

	packa_rollers = spawn("script_origin", self.origin);
	packa_timer = spawn("script_origin", self.origin);
	packa_rollers playloopsound("packa_rollers_loop");

	self SetHintString( &"ZOMBIE_PERK_PACKAPUNCH" );
	cost = level.zombie_vars["zombie_perk_cost"];

	for( ;; )
	{
		self waittill( "trigger", player );
		index = maps\_zombiemode_weapons::get_player_index(player);
		cost = 5000;
		plr = "plr_" + index + "_";

		if( !player maps\_zombiemode_weapons::can_buy_weapon() )
		{
			wait( 0.1 );
			continue;
		}

		if (player maps\_laststand::player_is_in_laststand() )
		{
			wait( 0.1 );
			continue;
		}

		if( player isThrowingGrenade() )
		{
			wait( 0.1 );
			continue;
		}

		if( player isSwitchingWeapons() )
		{
			wait(0.1);
			continue;
		}

		current_weapon = player getCurrentWeapon();

		if( !IsDefined( level.zombie_include_weapons[current_weapon] ) || !IsDefined( level.zombie_include_weapons[current_weapon + "_upgraded"] ) )
		{
			continue;
		}

		if ( player.score < cost )
		{
			//player iprintln( "Not enough points to buy Perk: " + perk );
			self playsound("deny");
			player thread play_no_money_perk_dialog();
			continue;
		}
		player maps\_zombiemode_score::minus_to_player_score( cost );
		self achievement_notify("perk_used");
		sound = "bottle_dispense3d";
		playsoundatposition(sound, self.origin);
		rand = randomintrange(1,100);

		if( rand <= 8 )
		{
			player thread play_packa_wait_dialog(plr);
		}

		self thread play_vendor_stings("mx_packa_sting");

		origin = self.origin;
		angles = self.angles;

		if( isDefined(perk_machine))
		{
			origin = perk_machine.origin+(0,0,35);
			angles = perk_machine.angles+(0,90,0);
		}

		self disable_trigger();

		player thread do_knuckle_crack();

		// Remember what weapon we have.  This is needed to check unique weapon counts.
		self.current_weapon = current_weapon;

		weaponmodel = player third_person_weapon_upgrade( current_weapon, origin, angles, packa_rollers, perk_machine );

		self enable_trigger();
		self SetHintString( &"ZOMBIE_GET_UPGRADED" );
		self setvisibletoplayer( player );

		self thread wait_for_player_to_take( player, current_weapon, packa_timer );
		self thread wait_for_timeout( packa_timer );

		self waittill_either( "pap_timeout", "pap_taken" );

		self.current_weapon = "";
		weaponmodel delete();
		self SetHintString( &"ZOMBIE_PERK_PACKAPUNCH" );
		self setvisibletoall();
	}
}

wait_for_player_to_take( player, weapon, packa_timer )
{
	index = maps\_zombiemode_weapons::get_player_index(player);
	plr = "plr_" + index + "_";

	self endon( "pap_timeout" );
	while( true )
	{
		packa_timer playloopsound( "ticktock_loop" );
		self waittill( "trigger", trigger_player );
		packa_timer stoploopsound(.05);
		if( trigger_player == player )
		{
			if( !player maps\_laststand::player_is_in_laststand() )
			{
				self notify( "pap_taken" );
				primaries = player GetWeaponsListPrimaries();

				count = 2;
				if (player hasperk("specialty_extraammo"))
					count++;

				if( isDefined( primaries ) && primaries.size >= count )
				{
					player maps\_zombiemode_weapons::weapon_give( weapon+"_upgraded" );
				}
				else
				{
					player GiveWeapon( weapon+"_upgraded" );
					player GiveMaxAmmo( weapon+"_upgraded" );
				}

				player SwitchToWeapon( weapon+"_upgraded" );
				player achievement_notify( "DLC3_ZOMBIE_PAP_ONCE" );
				player achievement_notify( "DLC3_ZOMBIE_TWO_UPGRADED" );
				player thread play_packa_get_dialog(plr);
				return;
			}
		}
		wait( 0.05 );
	}
}

wait_for_timeout( packa_timer )
{
	self endon( "pap_taken" );

	wait( level.packapunch_timeout );

	self notify( "pap_timeout" );
	packa_timer stoploopsound(.05);
	packa_timer playsound( "packa_deny" );
}

do_knuckle_crack()
{
	gun = self upgrade_knuckle_crack_begin();

	self.is_drinking = 1;
	self waittill_any( "fake_death", "death", "player_downed", "weapon_change_complete" );

	self upgrade_knuckle_crack_end( gun );
	self.is_drinking = undefined;
}

upgrade_knuckle_crack_begin()
{
	self DisableOffhandWeapons();
	self DisableWeaponCycling();

	self AllowLean( false );
	self AllowAds( false );
	self AllowSprint( false );
	self AllowProne( false );
	self AllowMelee( false );

	if ( self GetStance() == "prone" )
	{
		self SetStance( "crouch" );
	}

	primaries = self GetWeaponsListPrimaries();

	gun = self GetCurrentWeapon();
	weapon = "zombie_knuckle_crack";

	if ( gun != "none" && gun != "mine_bouncing_betty" )
	{
		self TakeWeapon( gun );
	}
	else
	{
		return;
	}

	if( primaries.size <= 1 )
	{
		self GiveWeapon( "zombie_colt" );
	}

	self GiveWeapon( weapon );
	self SwitchToWeapon( weapon );

	return gun;
}

upgrade_knuckle_crack_end( gun )
{
	assert( gun != "zombie_perk_bottle_doubletap" );
	assert( gun != "zombie_perk_bottle_revive" );
	assert( gun != "zombie_perk_bottle_jugg" );
	assert( gun != "zombie_perk_bottle_sleight" );
	assert( gun != "syrette" );

	self EnableOffhandWeapons();
	self EnableWeaponCycling();

	self AllowLean( true );
	self AllowAds( true );
	self AllowSprint( true );
	self AllowProne( true );
	self AllowMelee( true );
	weapon = "zombie_knuckle_crack";

	// TODO: race condition?
	if ( self maps\_laststand::player_is_in_laststand() )
	{
		self TakeWeapon(weapon);
		return;
	}

	self TakeWeapon(weapon);
	primaries = self GetWeaponsListPrimaries();
	if( isDefined( primaries ) && primaries.size > 0 )
	{
		self SwitchToWeapon( primaries[0] );
	}
	else
	{
		self SwitchToWeapon( "zombie_colt" );
	}
}

// PI_CHANGE_BEGIN
// JMA - in order to have multiple Pack-A-Punch machines in a map we're going to have
//			to run a thread on each on.
//	NOTE:  In the .map, you'll have to make sure that each Pack-A-Punch machine has a unique targetname
turn_PackAPunch_on()
{
	level waittill("Pack_A_Punch_on");

	vending_upgrade_trigger = GetEntArray("zombie_vending_upgrade", "targetname");
	for(i=0; i<vending_upgrade_trigger.size; i++ )
	{
		perk = getent(vending_upgrade_trigger[i].target, "targetname");
		if(isDefined(perk))
		{
			perk thread activate_PackAPunch();
		}
	}
}

activate_PackAPunch()
{
	self setmodel("zombie_vending_packapunch_on");
	self playsound("perks_power_on");
	self vibrate((0,-100,0), 0.3, 0.4, 3);
	/*
	self.flag = spawn( "script_model", machine GetTagOrigin( "tag_flag" ) );
	self.angles = machine GetTagAngles( "tag_flag" );
	self.flag setModel( "zombie_sign_please_wait" );
	self.flag linkto( machine );
	self.flag.origin = (0, 40, 40);
	self.flag.angles = (0, 0, 0);
	*/
	timer = 0;
	duration = 0.05;

	level notify( "Carpenter_On" );
}
// PI_CHANGE_END

turn_sleight_on()
{
	machine = getentarray("vending_sleight", "targetname");
	level waittill("sleight_on");

	for( i = 0; i < machine.size; i++ )
	{
		machine[i] setmodel("zombie_vending_sleight_on");
		machine[i] vibrate((0,-100,0), 0.3, 0.4, 3);
		machine[i] playsound("perks_power_on");
		machine[i] thread perk_fx( "sleight_light" );
	}

	level notify( "specialty_fastreload_power_on" );
}

turn_revive_on()
{
	machine = getentarray("vending_revive", "targetname");
	level waittill("revive_on");


	for( i = 0; i < machine.size; i++ )
	{
		machine[i] setmodel("zombie_vending_revive_on");
		machine[i] playsound("perks_power_on");
		machine[i] vibrate((0,-100,0), 0.3, 0.4, 3);
		machine[i] thread perk_fx( "revive_light" );
	}

	level notify( "specialty_quickrevive_power_on" );


}

turn_jugger_on()
{
	machine = getentarray("vending_jugg", "targetname");
	//temp until I can get the wire to jugger.
	level waittill("juggernog_on");

	for( i = 0; i < machine.size; i++ )
	{
		machine[i] setmodel("zombie_vending_jugg_on");
		machine[i] vibrate((0,-100,0), 0.3, 0.4, 3);
		machine[i] playsound("perks_power_on");
		machine[i] thread perk_fx( "jugger_light" );

	}
	level notify( "specialty_armorvest_power_on" );

}

turn_doubletap_on()
{
	machine = getentarray("vending_doubletap", "targetname");
	level waittill("doubletap_on");

	for( i = 0; i < machine.size; i++ )
	{
		machine[i] setmodel("zombie_vending_doubletap_on");
		machine[i] vibrate((0,-100,0), 0.3, 0.4, 3);
		machine[i] playsound("perks_power_on");
		machine[i] thread perk_fx( "doubletap_light" );
	}
	level notify( "specialty_rof_power_on" );
}

perk_fx( fx )
{
	wait(3);
	playfxontag( level._effect[ fx ], self, "tag_origin" );
}




electric_perks_dialog()
{

	self endon ("warning_dialog");
	level endon("switch_flipped");
	timer =0;
	while(1)
	{
		wait(0.5);
		players = get_players();
		for(i = 0; i < players.size; i++)
		{
			dist = distancesquared(players[i].origin, self.origin );
			if(dist > 70*70)
			{
				timer = 0;
				continue;
			}
			if(dist < 70*70 && timer < 3)
			{
				wait(0.5);
				timer ++;
			}
			if(dist < 70*70 && timer == 3)
			{

				players[i] thread do_player_vo("vox_start", 5);
				wait(3);
				self notify ("warning_dialog");
				iprintlnbold("warning_given");
			}
		}
	}
}
vending_trigger_think()
{

	//self thread turn_cola_off();
	perk = self.script_noteworthy;


	self SetHintString( &"ZOMBIE_FLAMES_UNAVAILABLE" );

	self SetCursorHint( "HINT_NOICON" );

	if (self.classname == "trigger_use")
		self UseTriggerRequireLookAt();

	notify_name = perk + "_power_on";
	level waittill( notify_name );

	perk_hum = spawn("script_origin", self.origin);
	perk_hum playloopsound("perks_machine_loop");

	self thread check_player_has_perk(perk);

	self vending_set_hintstring(perk);

	last_time = GetTime();

	for( ;; )
	{
		self waittill( "trigger", player );

		// normally, radiant perk triggers are trigger_use, trigger_radius perks are spawned via script
		if (self.classname == "trigger_radius")
		{
			if (!player UseButtonPressed())
				continue;
		}

		index = maps\_zombiemode_weapons::get_player_index(player);

		cost = level.zombie_vars["zombie_perk_cost"];
		switch( perk )
		{
		case "specialty_armorvest":
			cost = 2500;
			break;

		case "specialty_quickrevive":
			cost = 1500;
			break;

		case "specialty_fastreload":
			cost = 3000;
			break;

		case "specialty_rof":
			cost = 2000;
			break;

		case "specialty_extraammo":
			cost = 4000;
			break;

		}

		if (player maps\_laststand::player_is_in_laststand() )
		{
			continue;
		}

		if(player in_revive_trigger())
		{
			continue;
		}

		if( player isThrowingGrenade() )
		{
			continue;
		}

		if( player isSwitchingWeapons() )
		{
			continue;
		}

		if( player GetCurrentWeapon() == "mine_bouncing_betty" )
		{
			continue;
		}

		if (isDefined(player.is_drinking) && player.is_drinking)
		{
			continue;
		}

		if ( player HasPerk( perk ) )
		{
			cheat = false;

			/#
			if ( GetDVarInt( "zombie_cheat" ) >= 5 )
			{
				cheat = true;
			}
			#/

			if ( cheat != true )
			{
				//player iprintln( "Already using Perk: " + perk );
				continue;
			}
		}

		if ( player.score < cost )
		{
			//player iprintln( "Not enough points to buy Perk: " + perk );
			if (self.classname == "trigger_use" || GetTime() - last_time > 500)
			{
				last_time = GetTime();
				playsoundatposition("deny", self.origin);
			}

			player thread play_no_money_perk_dialog();
			continue;
		}

		sound = "bottle_dispense3d";
		player achievement_notify( "perk_used" );
		playsoundatposition(sound, self.origin);
		player maps\_zombiemode_score::minus_to_player_score( cost );
		///bottle_dispense
		switch( perk )
		{
		case "specialty_armorvest":
			sound = "mx_jugger_sting";
			break;

		case "specialty_quickrevive":
			sound = "mx_revive_sting";
			break;

		case "specialty_fastreload":
			sound = "mx_speed_sting";
			break;

		case "specialty_rof":
			sound = "mx_doubletap_sting";
			break;

		case "specialty_extraammo":
			sound = "mx_mule_kick_sting";
			break;

		default:
			sound = "mx_jugger_sting";
			break;
		}

		self thread play_vendor_stings(sound);

		//		self waittill("sound_done");


		thread give_player_perk(player, perk);

	}
}

give_player_perk(player, perk)
{
	player endon("disconnect");

	// do the drink animation
	gun = player perk_give_bottle_begin( perk );
	player.is_drinking = 1;
	player waittill_any( "fake_death", "death", "player_downed", "weapon_change_complete" );

	// restore player controls and movement
	player perk_give_bottle_end( gun, perk );
	player.is_drinking = undefined;
	// TODO: race condition?
	if ( player maps\_laststand::player_is_in_laststand() )
	{
		return;
	}

	player SetPerk( perk );
	player thread perk_vo(perk);
	player setblur( 4, 0.1 );
	wait(0.1);
	player setblur(0, 0.1);
	//earthquake (0.4, 0.2, self.origin, 100);
	if(perk == "specialty_armorvest")
	{
		player.maxhealth = level.zombie_vars["zombie_perk_juggernaut_health"];
		player.health = level.zombie_vars["zombie_perk_juggernaut_health"];
		//player.health = 160;
	}


	player perk_hud_create( perk );

	//stat tracking
	player.stats["perks"]++;

	//player iprintln( "Bought Perk: " + perk );

	player thread perk_think( perk );
}

play_no_money_perk_dialog()
{

	index = maps\_zombiemode_weapons::get_player_index(self);

	player_index = "plr_" + index + "_";
	if(!IsDefined (self.vox_nomoney_perk))
	{
		num_variants = maps\_zombiemode_spawner::get_number_variants(player_index + "vox_nomoney_perk");
		self.vox_nomoney_perk = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_nomoney_perk[self.vox_nomoney_perk.size] = "vox_nomoney_perk_" + i;
		}
		self.vox_nomoney_perk_available = self.vox_nomoney_perk;
	}
	sound_to_play = random(self.vox_nomoney_perk_available);

	self.vox_nomoney_perk_available = array_remove(self.vox_nomoney_perk_available,sound_to_play);

	if (self.vox_nomoney_perk_available.size < 1 )
	{
		self.vox_nomoney_perk_available = self.vox_nomoney_perk;
	}

	self maps\_zombiemode_spawner::do_player_playdialog(player_index, sound_to_play, 0.25);




}
check_player_has_perk(perk)
{
	/#
		if ( GetDVarInt( "zombie_cheat" ) >= 5 )
		{
			return;
		}
#/

		dist = 128 * 128;
		while(true)
		{
			players = get_players();
			for( i = 0; i < players.size; i++ )
			{
				if(DistanceSquared( players[i].origin, self.origin ) < dist)
				{
					if(!players[i] hasperk(perk) && !(players[i] in_revive_trigger()))
					{
						//PI CHANGE: this change makes it so that if there are multiple players within the trigger for the perk machine, the hint string is still
						//                   visible to all of them, rather than the last player this check is done for
						if (IsDefined(level.script) && level.script == "nazi_zombie_theater")
							self setinvisibletoplayer(players[i], false);
						else
							self setvisibletoplayer(players[i]);
						//END PI CHANGE
						//iprintlnbold("turn it off to player");

					}
					else
					{
						self SetInvisibleToPlayer(players[i]);
						//iprintlnbold(players[i].health);
					}
				}


			}

			wait(0.1);

		}

}


vending_set_hintstring( perk )
{
	switch( perk )
	{

	case "specialty_armorvest":
		self SetHintString( &"ZOMBIE_PERK_JUGGERNAUT" );
		break;

	case "specialty_quickrevive":
		self SetHintString( &"ZOMBIE_PERK_QUICKREVIVE" );
		break;

	case "specialty_fastreload":
		self SetHintString( &"ZOMBIE_PERK_FASTRELOAD" );
		break;

	case "specialty_rof":
		self SetHintString( &"ZOMBIE_PERK_DOUBLETAP" );
		break;

	case "specialty_extraammo":
		self SetHintString( "Press and hold &&1 to buy Mule Kick [Cost: 4000]" );
		break;

	default:
		self SetHintString( perk + " Cost: " + level.zombie_vars["zombie_perk_cost"] );
		break;

	}
}


perk_think( perk )
{
	/#
		if ( GetDVarInt( "zombie_cheat" ) >= 5 )
		{
			if ( IsDefined( self.perk_hud[ perk ] ) )
			{
				return;
			}
		}
#/

		self waittill_any( "fake_death", "death", "player_downed" );

		self UnsetPerk( perk );
		self.maxhealth = 100;
		self perk_hud_destroy( perk );
		//self iprintln( "Perk Lost: " + perk );
}


perk_hud_create( perk )
{
	if ( !IsDefined( self.perk_hud ) )
	{
		self.perk_hud = [];
	}

	/#
		if ( GetDVarInt( "zombie_cheat" ) >= 5 )
		{
			if ( IsDefined( self.perk_hud[ perk ] ) )
			{
				return;
			}
		}
#/


		shader = "";

		switch( perk )
		{
		case "specialty_armorvest":
			shader = "specialty_juggernaut_zombies";
			break;

		case "specialty_quickrevive":
			shader = "specialty_quickrevive_zombies";
			break;

		case "specialty_fastreload":
			shader = "specialty_fastreload_zombies";
			break;

		case "specialty_rof":
			shader = "specialty_doubletap_zombies";
			break;

		case "specialty_extraammo":
			shader = "specialty_three_guns_zombies";
			break;

		default:
			shader = "";
			break;
		}

		hud = create_simple_hud( self );
		hud.foreground = true;
		hud.sort = 1;
		hud.hidewheninmenu = false;
		hud.alignX = "left";
		hud.alignY = "bottom";
		hud.horzAlign = "left";
		hud.vertAlign = "bottom";
		hud.x = self.perk_hud.size * 30;
		hud.y = hud.y - 70;
		hud.alpha = 1;
		hud SetShader( shader, 24, 24 );

		self.perk_hud[ perk ] = hud;
}


perk_hud_destroy( perk )
{
	self.perk_hud[ perk ] destroy_hud();
	self.perk_hud[ perk ] = undefined;
}

perk_give_bottle_begin( perk )
{
	self DisableOffhandWeapons();
	self DisableWeaponCycling();

	self AllowLean( false );
	self AllowAds( false );
	self AllowSprint( false );
	self AllowProne( false );
	self AllowMelee( false );

	wait( 0.05 );

	if ( self GetStance() == "prone" )
	{
		self SetStance( "crouch" );
	}

	gun = self GetCurrentWeapon();
	weapon = "";

	switch( perk )
	{
	case "specialty_armorvest":
		weapon = "zombie_perk_bottle_jugg";
		break;

	case "specialty_quickrevive":
		weapon = "zombie_perk_bottle_revive";
		break;

	case "specialty_fastreload":
		weapon = "zombie_perk_bottle_sleight";
		break;

	case "specialty_rof":
		weapon = "zombie_perk_bottle_doubletap";
		break;

	case "specialty_extraammo":
		weapon = "zombie_perk_bottle_mule";
		break;
	}

	self GiveWeapon( weapon );
	self SwitchToWeapon( weapon );

	return gun;
}


perk_give_bottle_end( gun, perk )
{
	assert( gun != "zombie_perk_bottle_doubletap" );
	assert( gun != "zombie_perk_bottle_revive" );
	assert( gun != "zombie_perk_bottle_jugg" );
	assert( gun != "zombie_perk_bottle_sleight" );
	assert( gun != "syrette" );

	self EnableOffhandWeapons();
	self EnableWeaponCycling();

	self AllowLean( true );
	self AllowAds( true );
	self AllowSprint( true );
	self AllowProne( true );
	self AllowMelee( true );
	weapon = "";
	switch( perk )
	{
	case "specialty_armorvest":
		weapon = "zombie_perk_bottle_jugg";
		break;

	case "specialty_quickrevive":
		weapon = "zombie_perk_bottle_revive";
		break;

	case "specialty_fastreload":
		weapon = "zombie_perk_bottle_sleight";
		break;

	case "specialty_rof":
		weapon = "zombie_perk_bottle_doubletap";
		break;

	case "specialty_extraammo":
		weapon = "zombie_perk_bottle_mule";
		break;
	}

	// TODO: race condition?
	if ( self maps\_laststand::player_is_in_laststand() )
	{
		self TakeWeapon(weapon);
		return;
	}

	if ( gun != "none" && gun != "mine_bouncing_betty" )
	{
		self SwitchToWeapon( gun );
	}
	else
	{
		// try to switch to first primary weapon
		primaryWeapons = self GetWeaponsListPrimaries();
		if( IsDefined( primaryWeapons ) && primaryWeapons.size > 0 )
		{
			self SwitchToWeapon( primaryWeapons[0] );
		}
	}

	self TakeWeapon(weapon);
}

perk_vo(type)
{
	self endon("death");
	self endon("disconnect");

	index = maps\_zombiemode_weapons::get_player_index(self);
	sound = undefined;

	if(!isdefined (level.player_is_speaking))
	{
		level.player_is_speaking = 0;
	}
	player_index = "plr_" + index + "_";
	//wait(randomfloatrange(1,2));

//TUEY We need to eventually store the dialog in an array so you can add multiple variants...but we only have 1 now anyway.
	switch(type)
	{
	case "specialty_armorvest":
		sound_to_play = "vox_perk_jugga_0";
		break;
	case "specialty_fastreload":
		sound_to_play = "vox_perk_speed_0";
		break;
	case "specialty_quickrevive":
		sound_to_play = "vox_perk_revive_0";
		break;
	case "specialty_rof":
		sound_to_play = "vox_perk_doubletap_0";
		break;
	default:
		sound_to_play = "vox_perk_jugga_0";
		break;
	}

	wait(1.0);
	self maps\_zombiemode_spawner::do_player_playdialog(player_index, sound_to_play, 0.25);
}
machine_watcher()
{
	//PI ESM - support for two level switches for Factory
	if (isDefined(level.script) && level.script == "nazi_zombie_factory" || level.script == "nazi_zombie_paris" || level.script == "nazi_zombie_coast")
	{
		level thread machine_watcher_factory("juggernog_on");
		level thread machine_watcher_factory("sleight_on");
		level thread machine_watcher_factory("doubletap_on");
		level thread machine_watcher_factory("revive_on");
		level thread machine_watcher_factory("Pack_A_Punch_on");
	}
	else
	{
		level waittill("master_switch_activated");
		//array_thread(getentarray( "zombie_vending", "targetname" ), ::perks_a_cola_jingle);

	}

}

//PI ESM - added for support for two switches in factory
machine_watcher_factory(vending_name)
{
	level waittill(vending_name);
	switch(vending_name)
	{
		case "juggernog_on":
			temp_script_sound = "mx_jugger_jingle";
			break;

		case "sleight_on":
			temp_script_sound = "mx_speed_jingle";
			break;

		case "doubletap_on":
			temp_script_sound = "mx_doubletap_jingle";
			break;

		case "revive_on":
			temp_script_sound = "mx_revive_jingle";
			break;

		case "Pack_A_Punch_on":
			temp_script_sound = "mx_packa_jingle";
			break;

		default:
			temp_script_sound = "mx_jugger_jingle";
			break;
	}


	temp_machines = getstructarray("perksacola", "targetname");
	for (x = 0; x < temp_machines.size; x++)
	{
		if (temp_machines[x].script_sound == temp_script_sound)
			temp_machines[x] thread perks_a_cola_jingle();
	}

}

play_vendor_stings(sound)
{
	if(!IsDefined (level.speed_jingle))
	{
		level.speed_jingle = 0;
	}
	if(!IsDefined (level.revive_jingle))
	{
		level.revive_jingle = 0;
	}
	if(!IsDefined (level.doubletap_jingle))
	{
		level.doubletap_jingle = 0;
	}
	if(!IsDefined (level.jugger_jingle))
	{
		level.jugger_jingle = 0;
	}
	if(!IsDefined (level.packa_jingle))
	{
		level.packa_jingle = 0;
	}
	if(!IsDefined (level.eggs))
	{
		level.eggs = 0;
	}
	if (level.eggs == 0)
	{
		if(sound == "mx_speed_sting" && level.speed_jingle == 0 )
		{
//			iprintlnbold("stinger speed:" + level.speed_jingle);
			level.speed_jingle = 1;
			temp_org_speed_s = spawn("script_origin", self.origin);
			temp_org_speed_s playsound (sound, "sound_done");
			temp_org_speed_s waittill("sound_done");
			level.speed_jingle = 0;
			temp_org_speed_s delete();
//			iprintlnbold("stinger speed:" + level.speed_jingle);
		}
		else if(sound == "mx_revive_sting" && level.revive_jingle == 0)
		{
			level.revive_jingle = 1;
//			iprintlnbold("stinger revive:" + level.revive_jingle);
			temp_org_revive_s = spawn("script_origin", self.origin);
			temp_org_revive_s playsound (sound, "sound_done");
			temp_org_revive_s waittill("sound_done");
			level.revive_jingle = 0;
			temp_org_revive_s delete();
//			iprintlnbold("stinger revive:" + level.revive_jingle);
		}
		else if(sound == "mx_doubletap_sting" && level.doubletap_jingle == 0)
		{
			level.doubletap_jingle = 1;
//			iprintlnbold("stinger double:" + level.doubletap_jingle);
			temp_org_dp_s = spawn("script_origin", self.origin);
			temp_org_dp_s playsound (sound, "sound_done");
			temp_org_dp_s waittill("sound_done");
			level.doubletap_jingle = 0;
			temp_org_dp_s delete();
//			iprintlnbold("stinger double:" + level.doubletap_jingle);
		}
		else if(sound == "mx_jugger_sting" && level.jugger_jingle == 0)
		{
			level.jugger_jingle = 1;
//			iprintlnbold("stinger juggernog" + level.jugger_jingle);
			temp_org_jugs_s = spawn("script_origin", self.origin);
			temp_org_jugs_s playsound (sound, "sound_done");
			temp_org_jugs_s waittill("sound_done");
			level.jugger_jingle = 0;
			temp_org_jugs_s delete();
//			iprintlnbold("stinger juggernog:"  + level.jugger_jingle);
		}
		else if(sound == "mx_packa_sting" && level.packa_jingle == 0)
		{
			level.packa_jingle = 1;
//			iprintlnbold("stinger packapunch:" + level.packa_jingle);
			temp_org_pack_s = spawn("script_origin", self.origin);
			temp_org_pack_s playsound (sound, "sound_done");
			temp_org_pack_s waittill("sound_done");
			level.packa_jingle = 0;
			temp_org_pack_s delete();
//			iprintlnbold("stinger packapunch:"  + level.packa_jingle);
		}
		else if(sound == "mx_mule_kick_sting" && level.packa_jingle == 0)
		{
			level.packa_jingle = 1;
//			iprintlnbold("stinger packapunch:" + level.packa_jingle);
			temp_org_pack_s = spawn("script_origin", self.origin);
			temp_org_pack_s playsound (sound, "sound_done");
			temp_org_pack_s waittill("sound_done");
			level.packa_jingle = 0;
			temp_org_pack_s delete();
//			iprintlnbold("stinger packapunch:"  + level.packa_jingle);
		}
	}
}

perks_a_cola_jingle()
{
	self thread play_random_broken_sounds();
	if(!IsDefined(self.perk_jingle_playing))
	{
		self.perk_jingle_playing = 0;
	}
	if (!IsDefined (level.eggs))
	{
		level.eggs = 0;
	}
	while(1)
	{
		//wait(randomfloatrange(60, 120));
		wait(randomfloatrange(31,45));
		if(randomint(100) < 15 && level.eggs == 0)
		{
			level notify ("jingle_playing");
			//playfx (level._effect["electric_short_oneshot"], self.origin);
			playsoundatposition ("electrical_surge", self.origin);

			if(self.script_sound == "mx_speed_jingle" && level.speed_jingle == 0)
			{
				level.speed_jingle = 1;
				temp_org_speed = spawn("script_origin", self.origin);
				wait(0.05);
				temp_org_speed playsound (self.script_sound, "sound_done");
				temp_org_speed waittill("sound_done");
				level.speed_jingle = 0;
				temp_org_speed delete();
			}
			if(self.script_sound == "mx_revive_jingle" && level.revive_jingle == 0)
			{
				level.revive_jingle = 1;
				temp_org_revive = spawn("script_origin", self.origin);
				wait(0.05);
				temp_org_revive playsound (self.script_sound, "sound_done");
				temp_org_revive waittill("sound_done");
				level.revive_jingle = 0;
				temp_org_revive delete();
			}
			if(self.script_sound == "mx_doubletap_jingle" && level.doubletap_jingle == 0)
			{
				level.doubletap_jingle = 1;
				temp_org_doubletap = spawn("script_origin", self.origin);
				wait(0.05);
				temp_org_doubletap playsound (self.script_sound, "sound_done");
				temp_org_doubletap waittill("sound_done");
				level.doubletap_jingle = 0;
				temp_org_doubletap delete();
			}
			if(self.script_sound == "mx_jugger_jingle" && level.jugger_jingle == 0)
			{
				level.jugger_jingle = 1;
				temp_org_jugger = spawn("script_origin", self.origin);
				wait(0.05);
				temp_org_jugger playsound (self.script_sound, "sound_done");
				temp_org_jugger waittill("sound_done");
				level.jugger_jingle = 0;
				temp_org_jugger delete();
			}
			if(self.script_sound == "mx_packa_jingle" && level.packa_jingle == 0)
			{
				level.packa_jingle = 1;
				temp_org_packa = spawn("script_origin", self.origin);
				temp_org_packa playsound (self.script_sound, "sound_done");
				temp_org_packa waittill("sound_done");
				level.packa_jingle = 0;
				temp_org_packa delete();
			}
			if(self.script_sound == "mx_mule_kick_jingle" && level.packa_jingle == 0)
			{
				level.packa_jingle = 1;
				temp_org_packa = spawn("script_origin", self.origin);
				temp_org_packa playsound (self.script_sound, "sound_done");
				temp_org_packa waittill("sound_done");
				level.packa_jingle = 0;
				temp_org_packa delete();
			}

			self thread play_random_broken_sounds();
		}
	}
}
play_random_broken_sounds()
{
	level endon ("jingle_playing");
	if (!isdefined (self.script_sound))
	{
		self.script_sound = "null";
	}
	if (self.script_sound == "mx_revive_jingle")
	{
		while(1)
		{
			wait(randomfloatrange(7, 18));
			playsoundatposition ("broken_random_jingle", self.origin);
		//playfx (level._effect["electric_short_oneshot"], self.origin);
			playsoundatposition ("electrical_surge", self.origin);

		}
	}
	else
	{
		while(1)
		{
			wait(randomfloatrange(7, 18));
		// playfx (level._effect["electric_short_oneshot"], self.origin);
			playsoundatposition ("electrical_surge", self.origin);
		}
	}
}

play_packa_wait_dialog(player_index)
{
	waittime = 0.05;
	if(!IsDefined (self.vox_perk_packa_wait))
	{
		num_variants = maps\_zombiemode_spawner::get_number_variants(player_index + "vox_perk_packa_wait");
		self.vox_perk_packa_wait = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_perk_packa_wait[self.vox_perk_packa_wait.size] = "vox_perk_packa_wait_" + i;
		}
		self.vox_perk_packa_wait_available = self.vox_perk_packa_wait;
	}
	if(!isdefined (level.player_is_speaking))
	{
		level.player_is_speaking = 0;
	}
	sound_to_play = random(self.vox_perk_packa_wait_available);
	self maps\_zombiemode_spawner::do_player_playdialog(player_index, sound_to_play, waittime);
	self.vox_perk_packa_wait_available = array_remove(self.vox_perk_packa_wait_available,sound_to_play);

	if (self.vox_perk_packa_wait_available.size < 1 )
	{
		self.vox_perk_packa_wait_available = self.vox_perk_packa_wait;
	}
}

play_packa_get_dialog(player_index)
{
	waittime = 0.05;
	if(!IsDefined (self.vox_perk_packa_get))
	{
		num_variants = maps\_zombiemode_spawner::get_number_variants(player_index + "vox_perk_packa_get");
		self.vox_perk_packa_get = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_perk_packa_get[self.vox_perk_packa_get.size] = "vox_perk_packa_get_" + i;
		}
		self.vox_perk_packa_get_available = self.vox_perk_packa_get;
	}
	if(!isdefined (level.player_is_speaking))
	{
		level.player_is_speaking = 0;
	}
	sound_to_play = random(self.vox_perk_packa_get_available);
	self maps\_zombiemode_spawner::do_player_playdialog(player_index, sound_to_play, waittime);
	self.vox_perk_packa_get_available = array_remove(self.vox_perk_packa_get_available,sound_to_play);

	if (self.vox_perk_packa_get_available.size < 1 )
	{
		self.vox_perk_packa_get_available = self.vox_perk_packa_get;
	}
}
