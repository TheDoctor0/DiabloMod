#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>

#include <diablo_nowe.inc>

#define PLUGIN	"Dagon I"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new bool:bUsed[ 33 ] , iLevel[ 33 ] , sprite_lgt;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Laska Ognia" , 250 );
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Uzyj zeby uderzyc twojego przeciwnika piorunem ognia")
}

public diablo_item_reset( id ){
	iLevel[ id ]	=	0;
	bUsed[ id ]		=	false;
}

public diablo_item_set_data( id ){
	iLevel[ id ]	=	1;
	bUsed[ id ]		=	false;
}

public diablo_item_player_spawned( id ){
	bUsed[ id ]		=	false;
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Uzyj, zeby udezyc wroga ognistym promieniem (inteligencja zwieksza zasieg i obrazenia przedmiotu)")
	}
	else{
		formatex( szMessage , iLen , "Uzyj, zeby udezyc wroga ognistym promieniem (inteligencja zwieksza zasieg i obrazenia przedmiotu)")
	}
}

public diablo_upgrade_item( id ){
	iLevel[ id ] += random_num(0,1)
}

public diablo_copy_item( iFrom , iTo ){
	iLevel[ iTo ]	=	iLevel[ iFrom ];
	iLevel[ iFrom ]	=	0;
}

public diablo_item_skill_used( id ){
	if (bUsed[ id ])
	{
		set_hudmessage(220, 30, 30, -1.0, 0.40, 0, 3.0, 2.0, 0.2, 0.3, 5)
		show_hudmessage(id, "Tego przedmiotu mozesz uzyc raz na runde") 
		return PLUGIN_HANDLED
	}
	//Target nearest non-friendly player
	new target = UTIL_FindNearestOpponent(id,600+diablo_get_user_int( id )*20)
	
	if (target == -1) 
		return PLUGIN_HANDLED
	
	new DagonDamage = ( iLevel[id]*20 ) + diablo_get_user_int( id );
	new Red = 0
	
	if (iLevel[id] == 1) Red = 175
	else if (iLevel[id] == 2) Red = 225
	else if (iLevel[id] > 2) Red = 255
	
	
	new Hit[3]
	get_user_origin(target,Hit)

	//Create Lightning
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(1) // TE_BEAMENTPOINT
	write_short(id)
	write_coord(Hit[0])
	write_coord(Hit[1])
	write_coord(Hit[2])
	write_short(sprite_lgt)
	write_byte(0)
	write_byte(1)
	write_byte(3)
	write_byte(10)	//WITD
	write_byte(60)
	write_byte(Red)
	write_byte(0)
	write_byte(0)
	write_byte(100)	//BRIGT
	write_byte(0)
	message_end()
	
	bUsed[ id ] = true
	
	//Apply damage

	diablo_damage( target , id , float( DagonDamage ) , diabloDamageKnife );
	diablo_display_fade(target,2600,2600,0,255,0,0,15)
	diablo_show_hudmsg(id,2.0,"Twoje ciosy dagon zadaly %i dmg", DagonDamage)

	return PLUGIN_HANDLED
}

public plugin_precache(){
	sprite_lgt = precache_model("sprites/lgtning.spr")
}

public UTIL_FindNearestOpponent(id,maxdist)
{
	new best = 99999
	new entfound = -1
	new MyOrigin[3]
	get_user_origin(id,MyOrigin)
	
	for (new i=1; i < 33; i++)
	{
		if (i == id || !is_user_connected(i) || !is_user_alive(i) || get_user_team(id) == get_user_team(i))
			continue
		
		new TempOrigin[3],Float:fTempOrigin[3]
		get_user_origin(i,TempOrigin)
		IVecFVec(TempOrigin,fTempOrigin)
		
		if (!UTIL_IsInView(id,i))
			continue
		
		
		new dist = get_distance ( MyOrigin,TempOrigin ) 
		
		if ( dist < maxdist && dist < best)
		{
			best = dist
			entfound = i
		}		
	}
	
	return entfound
}

public bool:UTIL_IsInView(id,target)
{
	new Float:IdOrigin[3], Float:TargetOrigin[3], Float:ret[3] 
	new iIdOrigin[3], iTargetOrigin[3]
	
	get_user_origin(id,iIdOrigin,1)
	get_user_origin(target,iTargetOrigin,1)
	
	IVecFVec(iIdOrigin,IdOrigin)
	IVecFVec(iTargetOrigin, TargetOrigin)
	
	if ( trace_line ( 1, IdOrigin, TargetOrigin, ret ) == target)
		return true
	
	if ( get_distance_f(TargetOrigin,ret) < 10.0)
		return true
	
	return false
	
}