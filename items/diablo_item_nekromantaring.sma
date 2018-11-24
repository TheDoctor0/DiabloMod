#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>

#include <diablo_nowe.inc>

#define PLUGIN	"Nekromanta ring"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

#define TASK_RESPAWN 6240

new iRespawn[ 33 ], iVampire[ 33 ];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Ksiega Nekromanty" , 250 );
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Dzieki temu przedmiotowi masz 1/%i szansy na ponowne odrodzenie sie, dodatkowo wysysasz zycie wrogowi" , iRespawn[ id ] )
}

public diablo_item_reset( id ){
	iRespawn[ id ]	=	0;
	iVampire[ id ]	=	0;
}

public diablo_item_set_data( id ){
	iRespawn[ id ]	=	random_num( 2 , 4 );
	iVampire[ id ]	=	random_num( 3 , 5 );
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Dzieki temu przedmiotowi masz szanse na ponowne odrodzenie sie, dodatkowo wysysasz zycie wrogowi")
	}
	else{
		formatex( szMessage , iLen , "Dzieki temu przedmiotowi masz 1/%i szansy na ponowne odrodzenie sie, dodatkowo wysysasz zycie wrogowi" , iRespawn[ id ] )
	}
}

public diablo_damage_item_do(iVictim,iAttacker,&Float:fDamage,damageBits){
	fDamage += float( iVampire[ iAttacker ] );
	diablo_add_hp( iAttacker , iVampire[ iAttacker ] );
}

public diablo_death( iKiller , killerClass , iVictim , victimClass ){
	if( iRespawn[ iVictim ] > 0 && random_num( 1 , iRespawn[ iVictim] ) == 1 ){
		set_task(0.1, "Respawn", iVictim+TASK_RESPAWN);
	}
}

public Respawn(id)
	ExecuteHamB(Ham_CS_RoundRespawn, id-TASK_RESPAWN);

public diablo_upgrade_item( id ){
	iRespawn[ id ]	-=	random_num( -1 , 1 )
}

public diablo_copy_item( iFrom , iTo ){
	iRespawn[ iTo ]	=	iRespawn[ iFrom ];
	iRespawn[ iFrom ]	=	0;
	iVampire[ iTo ]	=	iVampire[ iFrom ];
	iVampire[ iFrom ]	=	0;
}