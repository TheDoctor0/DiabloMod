#include <amxmodx>
#include <fun>

#include <diablo_nowe.inc>

#define PLUGIN	"Life Thief"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new bool:bHas[ 33 ];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Zlodziej Zycia" , 250 );
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Wysysasz przeciwnikowi zycie rowne polowie zadanych obrazen");
	bHas[ id ]	=	true;
}

public diablo_item_reset( id )
	bHas[ id ]	=	false;
	
public diablo_item_set_data( id )
	bHas[ id ]	=	true;

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Wysysasz przeciwnikowi zycie rowne polowie zadanych obrazen");
	}
	else{
		formatex( szMessage , iLen , "Wysysasz przeciwnikowi zycie rowne polowie zadanych obrazen");
	}
}

public diablo_damage_item_do(iVictim,iAttacker,&Float:fDamage,damageBits){
	if( bHas[ iAttacker ] && iVictim != iAttacker)
		set_user_health(iAttacker, min(get_user_health(iAttacker) + floatround(fDamage * 0.5), diablo_get_max_hp(iAttacker)));
}

public diablo_copy_item( iFrom , iTo ){
	bHas[ iTo ]	=	bHas[ iFrom ];
	bHas[ iFrom ]	=	false;
}