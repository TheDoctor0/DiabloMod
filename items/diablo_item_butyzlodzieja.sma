#include <amxmodx>
#include <amxmisc>
#include <cstrike>

#include <diablo_nowe.inc>

#define PLUGIN	"Arabian Boots"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iMoney[ 33 ];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Buty Zlodzieja" , 250 );
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "1/5 szans by krasc zloto %i za kazdym razem jak uderzasz. Uzyj zeby zamienic zloto w zycia" , iMoney[ id ] )
}

public diablo_item_reset( id ){
	iMoney[ id ]	=	0;
}

public diablo_copy_item( iFrom , iTo ){
	iMoney[ iTo ]	=	iMoney[ iFrom ];
	iMoney[ iFrom ]	=	0;
}

public diablo_item_set_data( id ){
	iMoney[ id ]	=	random_num( 500 , 1000 );
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Masz 1/5 szans na okradniecie kogos za kazdym razem gdy uderzysz swojego wroga. Mozesz uzyc tego przedmiotu zeby zamienic 1000 zlota na 15 HP")
	}
	else{
		formatex( szMessage , iLen , "Masz 1/5  szans na kradziez %i zlota, za kazdym razem gdy uderzysz swojego wroga. Mozesz uzyc tego przedmiotu zeby zamienic 1000 zlota na 15 HP" , iMoney[ id ] )
	}
}

public diablo_damage_item_do(iVictim,iAttacker,&Float:fDamage,damageBits){
	if( random_num( 1 , 5 ) == 1 ){
		if( cs_get_user_money( iVictim ) < iMoney[ iAttacker ] ){
			cs_set_user_money( iAttacker , cs_get_user_money( iAttacker ) + cs_get_user_money( iVictim ) );
			cs_set_user_money( iVictim , 0 );
		}
		else{
			cs_set_user_money( iAttacker , cs_get_user_money( iAttacker ) + iMoney[ iAttacker ] );
			cs_set_user_money( iVictim , cs_get_user_money( iVictim ) - iMoney[ iAttacker] );
		}
	}
}

public diablo_item_skill_used( id ){
	if (cs_get_user_money(id) < 1000)
		diablo_show_hudmsg(id,2.0,"Nie masz wystarczajacej ilosci zlota, zeby zamienic je w zycie")
	else if (get_user_health(id) == diablo_get_max_hp( id ) )
		diablo_show_hudmsg(id,2.0,"Masz maksymalna ilosc zycia")
	else
	{
		cs_set_user_money(id,cs_get_user_money(id)-1000)
		diablo_add_hp( id , 15 )			
		diablo_display_fade(id,2600,2600,0,0,255,0,15)
	}
}

public diablo_upgrade_item( id ){
	iMoney[ id ] += random_num( 0 , 250 );
}
