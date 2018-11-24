#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fun>

#include <diablo_nowe.inc>

#define PLUGIN	"Ghost Rope"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iGhost[ 33 ] , bool:bUsedItem [ 33 ];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Szata Ducha" , 250 );
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Mozesz przenikac przez sciany przez %i sekund" , iGhost[ id ] )
}

public diablo_item_reset( id ){
	iGhost[ id ]	=	0;
	bUsedItem [ id ]	=	false;
}

public diablo_item_set_data( id ){
	iGhost[ id ]	=	random_num( 3 , 6 );
	bUsedItem [ id ]	=	false;
}

public diablo_item_player_spawned( id ){
	bUsedItem [ id ]	=	false;
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Uzyj tego przedmiotu, aby przenikac przez sciany przez x sekund")
	}
	else{
		formatex( szMessage , iLen , "Uzyj tego przedmiotu, aby przenikac przez sciany przez %i sekund" , iGhost[ id ] )
	}
}

public diablo_item_skill_used( id ){
	if(  bUsedItem[ id ]  ){
		diablo_show_hudmsg(id,3.0,"Ta umiejetnosc mozesz uzyc raz na runde!")
		
		return PLUGIN_CONTINUE;
	}
	
	bUsedItem[ id ]	=	true;
	
	set_user_noclip(id,1)
	
	message_begin( MSG_ONE, get_user_msgid("BarTime"), {0,0,0}, id ) 
	write_byte( iGhost[ id ] + 1 ) 
	write_byte( 0 ) 
	message_end() 
	
	set_task( float( iGhost[ id ] ) , "ghostOff" , id );
	
	return PLUGIN_CONTINUE;
	
}

public ghostOff( id ){
	if(  !is_user_alive( id )  ){
		return PLUGIN_CONTINUE;
	}
	
	set_user_noclip(id,0)
	new Float:aOrigin[3]
	entity_get_vector(id,EV_VEC_origin,aOrigin)	
	
	if (PointContents (aOrigin) != -1)
	{
		user_kill(id,1)	
	}
	else
	{
		aOrigin[2]+=10
		entity_set_vector(id,EV_VEC_origin,aOrigin)
	}
	
	return PLUGIN_CONTINUE;
	
}

public diablo_upgrade_item( id ){
	iGhost[ id ] -= random_num(0,1)
}

public diablo_copy_item( iFrom , iTo ){
	iGhost[ iTo ]	=	iGhost[ iFrom ];
	iGhost[ iFrom ]	=	0;
	
	bUsedItem[ iTo ]		=	false;
	bUsedItem[ iFrom ]	=	false;
}