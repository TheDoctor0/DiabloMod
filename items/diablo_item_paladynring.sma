#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fun>

#include <diablo_nowe.inc>

#define PLUGIN	"Paladyn ring"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iRedukcja[ 33 ], iOslepienie[ 33 ], bool:bHas[ 33 ];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Helm Paladyna" , 250 );
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Redukuje normalne obrazenia i masz szanse na oslepienie wroga")
	bHas[ id ] = true;
}

public diablo_item_reset( id ){
	iRedukcja[ id ]	=	0;
	iOslepienie[ id ]	=	0;
	bHas[ id ] = false;
}

public diablo_item_set_data( id ){
	iRedukcja[ id ]	=	random_num( 7 , 17 );
	iOslepienie[ id ]	=	random_num( 3 , 4 );
	bHas[ id ] = true;
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Redukuje obrazenia o x i masz 1/x szansy na oslepienie wroga")
	}
	else{
		formatex( szMessage , iLen , "Redukuje obrazenia o %i i masz 1/%i szansy na oslepienie wroga" , iRedukcja[ id ], iOslepienie[ id ] )
	}
}

public diablo_damage_item_taken(iVictim,iAttacker,&Float:fDamage,damageBits){
	if(bHas[iVictim])
		fDamage-float(iRedukcja[iVictim]);
}

public diablo_damage_item_do(iVictim,iAttacker,&Float:fDamage,damageBits){
	if( random_num( 1 , iOslepienie[ iAttacker ] ) == 1 ){
		diablo_display_fade(iVictim,1<<14,1<<14 ,1<<16,255,155,50,230)
	}
}

public diablo_upgrade_item( id ){
	iOslepienie[ id ]	-=	random_num( -1 , 1 )
	iRedukcja[ id ]  -=	random_num( 0 , 2 )
}

public diablo_copy_item( iFrom , iTo ){
	iOslepienie[ iTo ]	=	iOslepienie[ iFrom ];
	iOslepienie[ iFrom ]	=	0;
	iRedukcja[ iTo ]	=	iRedukcja[ iFrom ];
	iRedukcja[ iFrom ]	=	0;
}