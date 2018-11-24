#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

#include <diablo_nowe.inc>

#define PLUGIN	"Chaos Orb"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iZasieg[ 33 ];
new szItem[ 64];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Kula Chaosu" , 250 );
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Wybuchniesz zaraz po smierci w promieniu %i" ,iZasieg[ id ] )
}

public diablo_copy_item( iFrom , iTo ){
	iZasieg[ iTo ]	=	iZasieg[ iFrom ];
	iZasieg[ iFrom ]	=	0;
}

public diablo_item_reset( id ){
	iZasieg[ id ]	=	0;
}

public diablo_item_set_data( id ){
	iZasieg[ id ]	=	random_num( 150, 275 );
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Gdy umierasz wybuchniesz zadajac 75 obrazen wokol ciebie - im wiecej masz inteligencji tym wiekszy zasieg wybuchu")
	}
	else{
		formatex( szMessage , iLen , "Gdy umierasz wybuchniesz w promieniu %i zadaje 75 obrazen wokol ciebie - im wiecej masz inteligencji tym wiekszy zasieg wybuchu" , iZasieg[ id ] )
	}
}

public diablo_death( iKiller , killerClass , iVictim , victimClass ){
	if( iZasieg[ iVictim ] > 0 ){
		diablo_get_item_name( diablo_get_user_item( iKiller ), szItem, charsmax(szItem) )
		if(!equal(szItem, "Ognista Tarcza")){
			new Float:fOrigin[ 3 ];
			pev( iVictim , pev_origin , fOrigin );
			diablo_create_explode( iVictim , fOrigin , 75.0 , float( iZasieg[ iVictim ] + diablo_get_user_int( iVictim ) * 2 ) );
		}
	}
}

public diablo_upgrade_item( id ){
	iZasieg[ id ] += random_num( 0 , 25 );
}
