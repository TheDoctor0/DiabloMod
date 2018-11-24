#include <amxmodx>
#include <amxmisc>

#include <diablo_nowe.inc>

#define PLUGIN	"Vampyric Scepter"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iVampire[ 33 ];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Berlo Wampira" , 250 );
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Wysysasz %i hp przeciwnikowi" , iVampire[ id ] )
}

public diablo_item_reset( id ){
	iVampire[ id ]	=	0;
}

public diablo_item_set_data( id ){
	iVampire[ id ]	=	random_num( 6 , 9 );
}

public diablo_copy_item( iFrom , iTo ){
	iVampire[ iTo ]	=	iVampire[ iFrom ];
	iVampire[ iFrom ]	=	0;
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Wysysasz hp przeciwnikowi")
	}
	else{
		formatex( szMessage , iLen , "Kradnie %i hp przy trafieniu wroga" , iVampire[ id ] )
	}
}

public diablo_damage_item_do(iVictim,iAttacker,&Float:fDamage,damageBits){
	fDamage += float( iVampire[ iAttacker ] );
	diablo_add_hp( iAttacker , iVampire[ iAttacker ] );
}

public diablo_upgrade_item( id ){
	iVampire[ id ] += random_num( 0 , 2 );
}