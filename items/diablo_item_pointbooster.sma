#include <amxmodx>
#include <amxmisc>

#include <diablo_nowe.inc>

#define PLUGIN	"Point Booster"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iPoints[ 33 ]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Naszyjnik Wiedzy" , 250 );
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Zyskasz +%i do wszystkich statystyk", iPoints[ id ] )
	diablo_set_extra_str( id , iPoints[ id ] );
	diablo_set_extra_int( id , iPoints[ id ] );
	diablo_set_extra_agi( id , iPoints[ id ] );
	diablo_set_extra_dex( id , iPoints[ id ] );
}

public diablo_item_set_data( id ){
	iPoints[ id ]	=	random_num( 3 , 5 );
}

public diablo_copy_item( iFrom , iTo ){
	iPoints[ iTo ]	=	iPoints[ iFrom ];
	iPoints[ iFrom ]	=	0;
}

public diablo_item_reset( id ){
	iPoints[ id ]	=	0;
	diablo_set_extra_str( id , 0 );
	diablo_set_extra_int( id , 0 );
	diablo_set_extra_agi( id , 0 );
	diablo_set_extra_dex( id , 0 );
}

public diablo_upgrade_item( id ){
	iPoints[ id ] += random_num( 0 , 2 );
	diablo_set_extra_str( id , iPoints[ id ] );
	diablo_set_extra_int( id , iPoints[ id ] );
	diablo_set_extra_agi( id , iPoints[ id ] );
	diablo_set_extra_dex( id , iPoints[ id ] );
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Zyskasz +x do wszystkich statystyk" )
	}
	else{
		formatex( szMessage , iLen , "Zyskasz +%i do wszystkich statystyk", iPoints[ id ] )
	}
}