#include <amxmodx>
#include <amxmisc>

#include <diablo_nowe.inc>

#define PLUGIN	"Silver Amplifier"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iDamage[ 33 ];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Wzmacniacz z Srebra" , 250 );
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Zadaje %i dodatkowe obrazenia za kazdym razem jak uderzysz wroga" , iDamage[ id ] )
}

public diablo_item_reset( id ){
	iDamage[ id ]	=	0;
}

public diablo_item_set_data( id ){
	iDamage[ id ]	=	random_num( 3 , 6 );
}

public diablo_copy_item( iFrom , iTo ){
	iDamage[ iTo ]	=	iDamage[ iFrom ];
	iDamage[ iFrom ]	=	0;
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Zadaje x dodatkowe obrazenia za kazdym razem jak uderzysz wroga")
	}
	else{
		formatex( szMessage , iLen , "Zadaje %i dodatkowe obrazenia za kazdym razem jak uderzysz wroga" , iDamage[ id ] )
	}
}

public diablo_damage_item_do(iVictim,iAttacker,&Float:fDamage,damageBits){
	fDamage += float( iDamage[ iAttacker ] );
}

public diablo_upgrade_item( id ){
	iDamage[ id ] += random_num( 0 , 3 );
}