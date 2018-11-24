#include <amxmodx>

#include <diablo_nowe.inc>

#define PLUGIN	"Godly Armor"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iDmg[ 33 ];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Niebianska Zbroja" , 250 );
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Otrzymywane obrazenia sa zredukowane o %i" , iDmg[ id ] )
}

public diablo_item_reset( id ){
	iDmg[ id ]	=	0;
}

public diablo_item_set_data( id ){
	iDmg[ id ]	=	random_num( 10 , 15 );
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Obniza obrazenia zadawane graczowi")
	}
	else{
		formatex( szMessage , iLen , "Otrzymywane obrazenia sa zredukowane o %i" , iDmg[ id ] )
	}
}

public diablo_damage_item_taken(iVictim,iAttacker,&Float:fDamage,damageBits){
	fDamage -= float( iDmg[ iVictim ] );
}

public diablo_upgrade_item( id ){
	iDmg[ id ] += random_num( -1 , 2 );
}

public diablo_copy_item(  iFrom , iTo ){
	iDmg[ iTo ]		=	iDmg[ iFrom ];
	iDmg[ iFrom ]	=	0;
}