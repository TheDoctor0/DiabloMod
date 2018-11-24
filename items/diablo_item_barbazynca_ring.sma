#include <amxmodx>
#include <fakemeta>

#include <diablo_nowe.inc>

#define PLUGIN	"Barbarzynca ring"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iPoints[ 33 ]

new iZasieg[ 33 ];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Pierscien Barbarzyncy" , 250 );
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Ten przedmiot dodaje ci +%i sily i jak zginiesz wybuchasz.", iPoints[ id ] )
	diablo_set_extra_str( id , iPoints[ id ] );
}

public diablo_item_set_data( id ){
	iPoints[ id ]	=	5;
	iZasieg[ id ]	=	random_num( 120 , 330 );
}

public diablo_copy_item( iFrom , iTo ){
	iPoints[ iTo ]	=	iPoints[ iFrom ];
	iPoints[ iFrom ]	=	0;
	iZasieg[ iTo ]	=	iZasieg[ iFrom ];
	iZasieg[ iFrom ]	=	0;
}

public diablo_item_reset( id ){
	iPoints[ id ]	=	0;
	diablo_set_extra_str( id , 0 );
	iZasieg[ id ]	=	0;
}

public diablo_upgrade_item( id ){
	iPoints[ id ] += random_num( 0 , 2 );
	diablo_set_extra_str( id , iPoints[ id ] );
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Ten przedmiot dodaje ci +5 sily i jak zginiesz wybuchasz." )
	}
	else{
		formatex( szMessage , iLen , "Ten przedmiot dodaje ci +%i sily i jak zginiesz wybuchasz.", iPoints[ id ] )
	}
}

public diablo_death( iKiller , killerClass , iVictim , victimClass ){
	if( iZasieg[ iVictim ] > 0 ){
		new Float:fOrigin[ 3 ];
		pev( iVictim , pev_origin , fOrigin );
		diablo_create_explode( iVictim , fOrigin , 75.0 , float( iZasieg[ iVictim ] + diablo_get_user_int( iVictim ) * 2 ) );
	}
}