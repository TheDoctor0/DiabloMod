#include <amxmodx>
#include <cstrike>
#include <amxmisc>
#include <engine>
#include <fakemeta>

#include <diablo_nowe.inc>

#define PLUGIN	"Small bronze bag"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iMoney[ 33 ] , bool:usedItem[ 33 ];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Maly Worek Brazu" , 250 );
	
	register_think("Effect_MShield","Effect_MShield_Think")
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Dostajesz %i zlota w kazdej rundzie. Uzyj, zeby chronil cie" , iMoney[ id ] )
}

public diablo_item_reset( id ){
	iMoney[ id ]	=	0;
	usedItem[ id ]	=	false;
}

public diablo_item_set_data( id ){
	iMoney[ id ]	=	random_num( 150 , 500 );
	usedItem[ id ]	=	false;
}

public diablo_copy_item( iFrom , iTo ){
	iMoney[ iTo ]	=	iMoney[ iFrom ];
	iMoney[ iFrom ]	=	0;
	usedItem[ iFrom ]	=	false;
	usedItem[ iTo ]	=	false;
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Dostajesz zloto w kazdej rundzie. Uzyj, zeby chronil cie")
	}
	else{
		formatex( szMessage , iLen , "Dodaje %i zlota w kazdej rundzie. Mozesz takze uzyc tego przedmiotu by zredukowac normalne obrazenia o 50%" , iMoney[ id ] )
	}
}

public diablo_upgrade_item( id ){
	iMoney[ id ]	+=	random_num( -100 , 300 )
}

public diablo_item_player_spawned( id ){
	cs_set_user_money( id , cs_get_user_money( id ) + iMoney[ id ] + diablo_get_user_int( id ) * 10 );
}

public diablo_damage_item_taken( iVictim , iAttacker , &Float:fDamage , damageBits ){
	if( usedItem[ iVictim ] ){
		fDamage /= 2.0;
	}
}

public diablo_item_skill_used( id ){
	if( usedItem[ id ] ){
		diablo_render_cancel( id );
		usedItem[ id ]	=	false;
	}
	else{
		usedItem[ id ]	=	true;
		
		if (find_ent_by_owner(-1,"Effect_MShield",id) > 0)
			return PLUGIN_CONTINUE
		
		new ent = Spawn_Ent("info_target")
		set_pev(ent,pev_classname,"Effect_MShield")
		set_pev(ent,pev_owner,id)
		set_pev(ent,pev_solid,SOLID_NOT)		
		set_pev(ent,pev_nextthink, halflife_time() + 0.1)
		
		if(!(diablo_is_this_class(id,"Ninja")))
			diablo_set_user_render( id,kRenderFxGlowShell,0,0,0,kRenderNormal,16 , 0.2 )
		else
			diablo_set_user_render( id , .render = kRenderTransAlpha, .amount = 20);
	}
	
	return PLUGIN_CONTINUE
}

public Effect_MShield_Think(ent)
{
	if( !pev_valid( ent ) ){
		return PLUGIN_CONTINUE;
	}
	new id = pev(ent,pev_owner)
	if (!is_user_alive(id) || cs_get_user_money(id) <= 0 || !usedItem[ id ] || diablo_is_freezetime() )
	{
		usedItem[ id ]	=	false;
		diablo_render_cancel( id );
		
		diablo_display_icon( id,0,"suithelmet_empty",255,255,255 )
		
		remove_entity(ent)
		
		return PLUGIN_CONTINUE
	}
	
	if (cs_get_user_money(id)-250 < 0)
		cs_set_user_money(id,0)
	else
		cs_set_user_money(id,cs_get_user_money(id)-250)
	
	if(!(diablo_is_this_class(id,"Ninja")))
		diablo_set_user_render( id,kRenderFxGlowShell,0,0,0,kRenderNormal,16 , 0.2 )
	
	diablo_display_icon( id,1,"suithelmet_empty",255,255,255 )
	
	set_pev(ent,pev_nextthink, halflife_time() + 1.0)
	
	return PLUGIN_CONTINUE
}

stock Spawn_Ent(const classname[]) 
{
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classname))
	set_pev(ent, pev_origin, {0.0, 0.0, 0.0})    
	dllfunc(DLLFunc_Spawn, ent)
	return ent
}