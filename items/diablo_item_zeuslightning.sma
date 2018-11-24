#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

#include <diablo_nowe.inc>

#define PLUGIN	"Zeus Lightning"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iThunder[ 33 ];
new sprite_smoke;
new sprite_lgt;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	diablo_register_item( "Piorun Zeusa" , 250 );
}

public plugin_precache()
{
	sprite_smoke = precache_model("sprites/steam1.spr");
	sprite_lgt = precache_model("sprites/lgtning.spr");
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Masz 1/%i szansy na uderzenie piorunem (25 + int obrazen) podczas trafienia wroga", iThunder[ id ]);
}

public diablo_item_reset( id )
	iThunder[ id ]	=	0;
	
public diablo_item_set_data( id )
	iThunder[ id ]	=	random_num(6, 9);

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Masz 1/x szansy na uderzenie piorunem (25 + int obrazen) podczas trafienia wroga");
	}
	else{
		formatex( szMessage , iLen , "Masz 1/%i szansy na uderzenie piorunem (25 + int obrazen) podczas trafienia wroga", iThunder[ id ]);
	}
}

public diablo_damage_item_do(iVictim,iAttacker,&Float:fDamage,damageBits){
	if( iThunder[ iAttacker ] && random_num( 1, iThunder[ iAttacker ]) == 1 && is_user_alive( iVictim ))
		thunder_lightning( iAttacker, iVictim )
}

public diablo_copy_item( iFrom , iTo ){
	iThunder[ iTo ]	=	iThunder[ iFrom ];
	iThunder[ iFrom ]	=	0;
}

public diablo_upgrade_item( id ){
	iThunder[ id ] += random_num( -1 , 1 );
}

public thunder_lightning(attacker_id, id)
{
	if(get_user_team(attacker_id) == get_user_team(id))
		return HAM_IGNORED
		
	new Float:fl_Origin[3], Float:fl_Speed, Float:fl_Velocity[3];
	pev(id, pev_origin, fl_Origin);

	pev(id, pev_maxspeed, fl_Speed);
	pev(id, pev_maxspeed, fl_Velocity);
	set_pev(id, pev_velocity, Float:{0.0,0.0,0.0});
	set_pev(id, pev_maxspeed, 5.0);

	thunder_effects(fl_Origin)
	ExecuteHam(Ham_TakeDamage, id, attacker_id, attacker_id, 25.0+diablo_get_user_int(attacker_id)*0.2, 1);
	
	set_pev(id, pev_velocity, fl_Velocity);
	set_pev(id, pev_maxspeed, fl_Speed);

	return PLUGIN_HANDLED
}

public thunder_effects(Float:fl_Origin[3])
{
	new Float:fX = fl_Origin[0], Float:fY = fl_Origin[1], Float:fZ = fl_Origin[2]
	// Beam effect between two points
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, fl_Origin, 0)
	write_byte(TE_BEAMPOINTS)		// 0
	engfunc(EngFunc_WriteCoord, fX + 150.0)	// start position
	engfunc(EngFunc_WriteCoord, fY + 150.0)
	engfunc(EngFunc_WriteCoord, fZ + 800.0)
	engfunc(EngFunc_WriteCoord, fX)	// end position
	engfunc(EngFunc_WriteCoord, fY)
	engfunc(EngFunc_WriteCoord, fZ)
	write_short(sprite_lgt)	// sprite index
	write_byte(1)					// starting frame
	write_byte(15)					// frame rate in 0.1's
	write_byte(10)					// life in 0.1's
	write_byte(80)					// line width in 0.1's
	write_byte(30)					// noise amplitude in 0.01's
	write_byte(255)					// red
	write_byte(255)					// green
	write_byte(255)					// blue
	write_byte(255)					// brightness
	write_byte(200)					// scroll speed in 0.1's
	message_end()

	// Sparks
	message_begin(MSG_PVS, SVC_TEMPENTITY)
	write_byte(TE_SPARKS)			// 9
	engfunc(EngFunc_WriteCoord, fX)	// position
	engfunc(EngFunc_WriteCoord, fY)
	engfunc(EngFunc_WriteCoord, fZ + 10.0)
	message_end()

	// Smoke
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, fl_Origin, 0)
	write_byte(TE_SMOKE)			// 5
	engfunc(EngFunc_WriteCoord, fX)	// position
	engfunc(EngFunc_WriteCoord, fY)
	engfunc(EngFunc_WriteCoord, fZ + 10.0)
	write_short(sprite_smoke)		// sprite index
	write_byte(10)					// scale in 0.1's
	write_byte(10)					// framerate
	message_end()
	
	// Blood
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, fl_Origin, 0)
	write_byte(TE_LAVASPLASH)		// 10
	engfunc(EngFunc_WriteCoord, fX)	// position
	engfunc(EngFunc_WriteCoord, fY)
	engfunc(EngFunc_WriteCoord, fZ + 12.0)
	message_end()
}