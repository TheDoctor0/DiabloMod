#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <fun>

#include <diablo_nowe.inc>

#define PLUGIN	"Four leaf Clover"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iNum[ 33 ], iDamage[ 33 ], iVampire[ 33 ], iHeal[ 33 ], iGrenade[ 33 ]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Czterolistna Koniczyna" , 250 );
	
	set_task( 5.0 , "healTime" , 666 , .flags = "b" );
}

public healTime(){
	for( new i = 0 ; i < 33 ; i++ ){
		if( !is_user_alive( i ) || iHeal[ i ] == 0 )
			continue;
		
		diablo_add_hp( i , iHeal[ i ] );
	}
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Zyskasz jedna z %i premii w kazdej rundzie" , iNum[ id ] )
}

public diablo_item_reset( id ){
	iNum[ id ]			=	0;
	iDamage[id]			=	0;
	iVampire[id]			=	0;
	iHeal[id]			=	0;
	iGrenade[id] = 0;
	if(!(diablo_is_this_class(id,"Ninja")))
		set_user_gravity(id, 1.0);
}

public diablo_item_set_data( id ){
	iNum[ id ]			=	random_num( 4 , 5 );
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
	iHeal[id] = 0;
	iGrenade[id] = 0;
	
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
			if(!(diablo_is_this_class(id,"Ninja")))
				set_user_gravity(id,1.0*(1.0-5/12.0));
		}
		case 3:
		{
			show_hudmessage(id, "Premia rundy: +5 obrazen wampira")
			iVampire[id] = 5
		}
		case 4:
		{
			show_hudmessage(id, "Premia rundy: +10 hp co kazde 5 sekund")
			iHeal[id] = 5
		}
		case 5:
		{
			show_hudmessage(id, "Premia rundy: 1/3 szansy do natychmiastowego zabicia HE")
			iGrenade[id] = 3
		}
	}
}

public diablo_damage_item_do(iVictim,iAttacker,&Float:fDamage,damageBits){
	fDamage += float( iDamage[ iAttacker ] );
	
	fDamage += float( iVampire[ iAttacker ] );
	diablo_add_hp( iAttacker , iVampire[ iAttacker ] );
	
	if( damageBits & (1<<24) && random_num( 1 , iGrenade[ iAttacker ] ) == 1 && iGrenade[ iAttacker ] > 0){
		fDamage = float( get_user_health( iVictim ) * 2);
	}
}