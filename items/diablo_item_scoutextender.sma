#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>

#include <diablo_nowe.inc>

#define PLUGIN	"Scout Extender"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

#define DMG_BULLET (1<<1)

new iKill[ 33 ]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Scout Extender" , 250 );
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "1/%i szans do natychmiastowego zabicia scoutem" , iKill[ id ] )
}

public diablo_item_reset( id ){
	iKill[ id ]			=	0;
}

public diablo_item_set_data( id ){
	iKill[ id ]			=	random_num( 3 , 4 );
}

public diablo_copy_item( iFrom , iTo ){
	iKill[ iTo ]	=	iKill[ iFrom ];
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "1/x szans do natychmiastowego zabicia scoutem")
	}
	else{
		formatex( szMessage , iLen , "1/%i szans do natychmiastowego zabicia scoutem" , iKill[ id ] )
	}
}

public diablo_damage_item_do(iVictim,iAttacker,&Float:fDamage,damageBits){
	if( get_user_weapon( iAttacker ) == CSW_SCOUT && random_num( 1 , iKill[ iAttacker ] ) == 1 && damageBits & DMG_BULLET){
		fDamage = float( get_user_health( iVictim ) * 2);
	}
}

public diablo_upgrade_item( id ){
	if(iKill[ id ] > 1)
		iKill[ id ] -= random_num( -1 , 1 );
}