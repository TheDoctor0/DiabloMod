#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>

#include <diablo_nowe.inc>

#define PLUGIN	"Sorcerers ring"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iRespawn[ 33 ];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Kamien Wskrzeszenia" , 250 );
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "1/%i szans do ponownego odrodzenia sie po smierci" , iRespawn[ id ] )
}

public diablo_item_reset( id ){
	iRespawn[ id ]	=	0;
}

public diablo_item_set_data( id ){
	iRespawn[ id ]	=	random_num( 2 , 3 );
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Masz 1/x szanse do odrodzenia sie po smierci")
	}
	else{
		formatex( szMessage , iLen , "Masz 1/%i szanse do odrodzenia sie po smierci" , iRespawn[ id ] )
	}
}

public diablo_death( iKiller , killerClass , iVictim , victimClass ){
	if( iRespawn[ iVictim ] > 0 && random_num( 1 , iRespawn[ iVictim] ) == 1 ){
		remove_task( iVictim );
		set_task( 2.0 , "getLife" , iVictim );
	}
}

public getLife( iVictim ){
	if( !is_user_alive( iVictim ) ){
		ExecuteHamB( Ham_CS_RoundRespawn , iVictim )
	}
}

public diablo_upgrade_item( id ){
	iRespawn[ id ]	-=	random_num( -1 , 1 )
}

public diablo_copy_item( iFrom , iTo ){
	iRespawn[ iTo ]	=	iRespawn[ iFrom ];
	iRespawn[ iFrom ]	=	0;
}