#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <fun>

#include <diablo_nowe.inc>

#define PLUGIN	"Wheel of Fortune"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iNum[ 33 ], iDamage[ 33 ], iVampire [ 33 ]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Kolo Fortuny" , 250 );
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Zyskasz jedna z %i premii w kazdej rundzie" , iNum[ id ] )
}

public diablo_item_reset( id ){
	iNum[ id ]			=	0;
}

public diablo_item_set_data( id ){
	iNum[ id ]			=	random_num( 2 , 3 );
}

public diablo_copy_item( iFrom , iTo ){
	iNum[ iTo ]	=	iNum[ iFrom ];
	iNum[ iFrom ]	=	0;
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Zyskasz jedna z x premii w kazdej rundzie")
	}
	else{
		formatex( szMessage , iLen , "Zyskasz jedna z %i premii w kazdej rundzie" , iNum[ id ] )
	}
}

public diablo_item_player_spawned( id ){
	iDamage[id] = 0;
	iVampire[id] = 0;
	set_user_gravity(id, 1.0)
	
	set_hudmessage(220, 115, 70, -1.0, 0.40, 0, 3.0, 2.0, 0.2, 0.3, 5)
	new roll = random_num(1, iNum[id])
	switch(roll){
		case 1: {
			show_hudmessage(id, "Premia rundy: +5 obrazen")
			iDamage[id] = 5
		}
		case 2:
		{
			show_hudmessage(id, "Premia rundy: +5 do wyzszego skoku")
			set_user_gravity(id,1.0*(1.0-5/12.0))
		}
		case 3:
		{
			show_hudmessage(id, "Premia rundy: +5 obrazen wampira")
			iVampire[id] = 5
		}
	}
}

public diablo_damage_item_do(iVictim,iAttacker,&Float:fDamage,damageBits){
	fDamage += float( iDamage[ iAttacker ] );
	
	fDamage += float( iVampire[ iAttacker ] );
	diablo_add_hp( iAttacker , iVampire[ iAttacker ] );
}