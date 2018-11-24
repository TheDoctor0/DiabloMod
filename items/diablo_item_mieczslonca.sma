#include <amxmodx>
#include <amxmisc>

#include <diablo_nowe.inc>

#define PLUGIN	"Sword of the sun"
#define AUTHOR	"DarkGL"
#define VERSION	"1.0"

new iBlind[ 33 ];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Miecz Slonca" , 250 );
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "1/%i szans na utrate wzroku kiedy uszkadzasz wroga" , iBlind[ id ] )
}

public diablo_item_reset( id ){
	iBlind[ id ]	=	0;
}

public diablo_item_set_data( id ){
	iBlind[ id ]	=	random_num( 2 , 5 );
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Masz 1/x szans zeby twoj przeciwnik stracil wzrok")
	}
	else{
		formatex( szMessage , iLen , "Masz 1/%i szans zeby twoj przeciwnik stracil wzrok" , iBlind[ id ] )
	}
}

public diablo_damage_item_do(iVictim,iAttacker,&Float:fDamage,damageBits){
	if( random_num( 1 , iBlind[ iAttacker ] ) == 1 ){
		diablo_display_fade(iVictim,1<<14,1<<14 ,1<<16,255,155,50,230)
	}
}

public diablo_upgrade_item( id ){
	iBlind[ id ] += random_num( 0 , 1 );
}

public diablo_copy_item( iFrom , iTo ){
	iBlind[ iTo ]	=	iBlind[ iFrom ];
	iBlind[ iFrom ]	=	0;
}