#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;

init()
{
	precachemodel( "char_ger_honorgd_bodyz1_1_m" );
	precachemodel( "char_ger_honorgd_bodyz1_2_m" );
	precachemodel( "char_ger_honorgd_bodyz2_1_m" );
	precachemodel( "char_ger_honorgd_bodyz2_2_m" );

	precacheItem("zombie_shrinkray");
	precacheItem("zombie_shrinkray_upgraded");

	level._effect[ "shrink" ]							= loadfx( "baby_gun/babygun_impact" );
	level._effect[ "unshrink" ]							= loadfx( "baby_gun/babygun_shrink" );

	set_zombie_var( "shrink_ray_cylinder_radius",		60 );
	set_zombie_var( "shrink_ray_cylinder_radius_upgraded",		84 );

	set_zombie_var( "shrink_ray_sizzle_range",		480 );
	set_zombie_var( "shrink_ray_sizzle_range_upgraded",		1200 );

	set_zombie_var( "shrink_ray_shrink_time",		2.5 );
	set_zombie_var( "shrink_ray_shrink_time_upgraded",		5 );

	level thread shrink_ray_on_player_connect();

	thread setup_callbacks();
}

setup_callbacks()
{
	wait 0.25;

	level.shrinkrayoldoverridedamage = level.overridePlayerDamage;
	level.overridePlayerDamage = ::shrink_ray_melee_damage_reduction;

	level.callbackActorDamageShrinkPrev = level.callbackActorDamage;
	level.callbackActorDamage = ::callbackActorDamageShrink;
}

callbackActorDamageShrink( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, iModelIndex, iTimeOffset )
{
	if ( (sWeapon == "zombie_shrinkray" || sWeapon == "zombie_shrinkray_upgraded") && (isDefined( self.shrinked ) && self.shrinked) && sMeansOfDeath == "MOD_PISTOL_BULLET" )
	{
		iDamage = 0;
		sMeansOfDeath = "MOD_UNKNOWN";
	}

	self [[level.callbackActorDamageShrinkPrev]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, iModelIndex, iTimeOffset );
}

shrink_ray_melee_damage_reduction( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime )
{
	if ( isDefined( eAttacker.shrinked ) && eAttacker.shrinked )
	{
		iDamage = 5;
	}

	self [[ level.shrinkrayoldoverridedamage ]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime );
}

shrink_ray_on_player_connect()
{
	for( ;; )
	{
		level waittill( "connecting", player );
		player thread wait_for_shrink_ray_fired();
	}
}

wait_for_shrink_ray_fired()
{
	self endon( "death" );
	self endon( "disconnect" );

	for( ;; )
	{
		self waittill( "weapon_fired" );
		currentweapon = self GetCurrentWeapon();

		if( currentweapon == "zombie_shrinkray" )
			self thread shrink_ray_fired( false );

		if( currentweapon == "zombie_shrinkray_upgraded" )
			self thread shrink_ray_fired( true );
	}
}

shrink_ray_fired( upgraded )
{
	shrink_ray_sizzle_enemies = self shrink_ray_get_enemies_in_range( upgraded );

	shrink_ray_network_mini_count = 0;

	for ( i = 0; i < shrink_ray_sizzle_enemies.size; i++ )
	{
		shrink_ray_network_mini_count++;

		if ( !(shrink_ray_network_mini_count % 10) )
		{
			wait_network_frame();
			wait_network_frame();
			wait_network_frame();
		}

		shrink_ray_sizzle_enemies[i] thread shrink_zombie( self, upgraded );
	}
}

shrink_ray_get_enemies_in_range( upgraded )
{
	enemies = [];

	view_pos = self getTagOrigin( "tag_eye" );

	range = level.zombie_vars[ "shrink_ray_sizzle_range" ];
	if (upgraded)
		range = level.zombie_vars[ "shrink_ray_sizzle_range_upgraded" ];

	radius = level.zombie_vars[ "shrink_ray_cylinder_radius" ];
	if (upgraded)
		radius = level.zombie_vars[ "shrink_ray_cylinder_radius_upgraded" ];

	zombies = get_array_of_closest( view_pos, GetAISpeciesArray("axis", "all"), undefined, undefined, range * 1.1);

	sizzle_range_squared = range*range;
	cylinder_radius_squared = radius*radius;

	forward_view_angles = anglesToForward( self getPlayerAngles() );
	end_pos = view_pos + ( forward_view_angles * range );

	for ( i = 0; i < zombies.size; i++ )
	{
		if ( !IsDefined( zombies[i] ) || !IsAlive( zombies[i] ) )
		{
			// guy died on us
			continue;
		}

		test_origin = zombies[i] getcentroid();
		test_range_squared = DistanceSquared( view_pos, test_origin );

		if ( test_range_squared > sizzle_range_squared )
			break;

		if (isDefined(zombies[i].magic_bullet_shield) && zombies[i].magic_bullet_shield)
			continue;

		normal = VectorNormalize( test_origin - view_pos );
		dot = VectorDot( forward_view_angles, normal );
		if ( 0 > dot )
			continue;

		radial_origin = PointOnSegmentNearestToPoint( view_pos, end_pos, test_origin );
		if ( DistanceSquared( test_origin, radial_origin ) > cylinder_radius_squared )
			continue;

		if ( zombies[i] DamageConeTrace( view_pos, self ) <= 0 )
			continue;

		enemies[enemies.size] = zombies[i];
	}

	return enemies;
}

shrink_zombie( player, upgraded )
{
	self endon( "death" );

	if( !IsDefined( self ) || !IsAlive( self ) )
		return;

	if(level.zombie_vars["zombie_insta_kill"])
	{
		self DoDamage( self.health + 666, player.origin, player );
		return;
	}

	if( isDefined(self.shrinked) && self.shrinked )
		return;

	shrinkTime = level.zombie_vars[ "shrink_ray_shrink_time" ];
	if( upgraded )
		shrinkTime = level.zombie_vars[ "shrink_ray_shrink_time_upgraded" ];

	shrinkTime += randomfloatrange(0.0, 0.5);
	if( upgraded )
		shrinkTime += randomfloatrange(0.0, 0.5);

	self.shrinked = true;

	if ( !self enemy_is_dog() && self.has_legs == true && self.gibbed == false )
	{
		// save values on this zombie
		normalModel = self.model;
		health = self.health;
		hatModel = self.hatModel;

		attachedModels = [];
		numModels = self GetAttachSize();
		for( i = numModels-1; i >= 0; i-- )
		{
			model = self GetAttachModelName( i );
			tag = self GetAttachTagName(i);

			isHat = isDefined(self.hatModel) && (self.hatModel == model);
			if(isHat)
			{
				self.hatModel = undefined;	//So no one tries to remove it.
			}

			//Save detached models do they can be put back
			attachedModels[attachedModels.size] = model;

			self Detach( model );
		}

		// play efx
		self playsound( "evt_shrink" );
		PlayFx(level._effect[ "shrink" ], self getTagOrigin("J_MainRoot"));

		self maps\_zombiemode_spawner::zombie_eye_glow_stop();

		//Set to small body
		self setModel( normalModel + "_m" );
		self attach(self.headModel, "", true);

		// insta kill him
		self.health = 1;

		// setup threads
		self thread play_ambient_vox();
		self thread watch_for_kicked();
		self thread watch_for_death();

		// wait for time
		wait shrinkTime;

		// lets unshrink
		self playsound( "evt_unshrink" );
		PlayFx(level._effect[ "unshrink" ], self getTagOrigin("J_MainRoot"));

		wait 0.5;

		// Detach all current attachments
		numModels = self GetAttachSize();
		for( i = numModels-1; i >=0 ; i-- )
		{
			model = self GetAttachModelName( i );

			self Detach( model );
		}

		// restore shit
		self.hatModel = hatModel;

		//Attach all previous attachements
		for(i=0; i<attachedModels.size; i++)
		{
			self Attach( attachedModels[i] );
		}

		//Grow back
		self setModel( normalModel );

		self.health = health;

		self maps\_zombiemode_spawner::zombie_eye_glow();
		self notify("unshrink");
		self.shrinked = false;

		if (isDefined(self.shrinkTrigger))
			self.shrinkTrigger delete();
	}
	else
	{
		if( self.animname == "zombie_dog" )
		{
			self.a.nodeath = undefined;

			wait( 0.1 );

			self DoDamage( self.health + 666, player.origin, player );
		}
		else
		{
			fling_range_squared = 480 * 480;
			view_pos = player getTagOrigin( "tag_eye" );
			test_origin = self getcentroid();
			test_range_squared = DistanceSquared( view_pos, test_origin );

			dist_mult = (fling_range_squared - test_range_squared) / fling_range_squared;
			fling_vec = VectorNormalize( test_origin - view_pos );

			fling_vec = (fling_vec[0], fling_vec[1], abs( fling_vec[2] ));
			fling_vec = fling_vec * (100 + 100 * dist_mult );

			self StartRagdoll();
			self LaunchRagdoll( fling_vec );
			self DoDamage( self.health + 666, player.origin, player );
		}
	}
}

play_ambient_vox()
{
	self endon("unshrink");
	self endon("stepped_on");
	self endon("kicked");
	self endon("death");

	wait(randomfloatrange(.2,.5));

	while(1)
	{
		self playsound( "zmb_mini_ambient0" + randomint(4) );
		wait(randomfloatrange(1,2.25));
	}
}

watch_for_kicked()
{
	self endon("death");
	self endon("unshrink");

	self.shrinkTrigger = spawn( "trigger_radius", self.origin, 0, 30, 24 );
	self.shrinkTrigger setHintString( "" );
	self.shrinkTrigger setCursorHint( "HINT_NOICON" );

	self.shrinkTrigger EnableLinkTo();
	self.shrinkTrigger LinkTo( self );

	while(1)
	{
		self.shrinkTrigger waittill("trigger", who);
		if(!isPlayer(who))
		{
			continue;
		}

		//Movement Dir
		movement = who GetNormalizedMovement();
		if ( Length(movement) < .1)
		{
			continue;
		}

		//Direction to enemy
		toEnemy = self.origin - who.origin;
		toEnemy = (toEnemy[0], toEnemy[1], 0);
		toEnemy = VectorNormalize( toEnemy );

		//Facing Direction
		forward_view_angles = AnglesToForward(who.angles);

		dotFacing = VectorDot( forward_view_angles, toEnemy );	//Check player is facing enemy

		//Kick if facing enemy
		if( dotFacing > 0.5 && movement[0] > 0.0)
		{
			//Kick if in front
			self notify("kicked");
			self kicked_death( who );
		}
		else
		{
			//Step on
			self notify("stepped_on");
			self shrink_death( who );
		}
	}
}

kicked_death(killer)
{
	if( isDefined(self.shrinkTrigger))
	{
		self.shrinkTrigger Delete();
	}

	self thread kicked_sound();

	kickAngles = killer.angles;
	kickAngles += (RandomFloatRange(-30, -20), RandomFloatRange(-5, 5), 0); //pitch up the angle
	launchDir = AnglesToForward(kickAngles);

	launchForce = RandomFloatRange(350, 400);

	self setContents(0);
	self StartRagdoll();
	self launchragdoll(launchDir * launchForce);
	wait_network_frame();

	// Make sure they're dead...physics launch didn't kill them.
	self dodamage(self.health + 666, self.origin, killer);
}

kicked_vox_network_choke()
{
	while(1)
	{
		level._num_kicked_vox = 0;
		wait_network_frame();
	}
}

kicked_sound()
{
	if( !IsDefined( level._num_kicked_vox ) )
		level thread kicked_vox_network_choke();

	if( level._num_kicked_vox > 3 )
		return;

	level._num_kicked_vox++;

	playsoundatposition("zmb_mini_kicked0" + randomint(4), self.origin);
}

shrink_death( killer )
{
	if( isDefined( self.shrinkTrigger ) )
		self.shrinkTrigger Delete();

	playsoundatposition("zmb_mini_squashed0" + randomint(4), self.origin);

	self setContents(0);
	self thread maps\_zombiemode_spawner::zombie_eye_glow_stop();
	wait_network_frame();
	self Hide();
	self dodamage(self.health + 666, self.origin, killer);
}

watch_for_death()
{
	self endon("unshrink");
	self endon("stepped_on");
	self endon("kicked");

	self waittill("death");

	self shrink_death();
}
