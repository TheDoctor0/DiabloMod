#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>

#include <diablo_nowe.inc>

#define PLUGIN	"Illusionists Cape"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

#define TASK_INVISIBLE 5746

new bool:bUsed[ 33 ]
new gmsgBartimer
new bool:use_addtofullpack
new bool:Invisible[ 33 ]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Illusionists Cape" , 250 )
	
	gmsgBartimer = get_user_msgid("BarTime")
	
	register_forward(FM_AddToFullPack, "client_AddToFullPack")
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Uzyj, aby stac sie niewidoczny dla wszystkich" )
}

public diablo_item_set_data( id ){
	bUsed[ id ]		=	false;
}

public diablo_copy_item( iFrom , iTo ){
	bUsed[ iFrom ]		=	bUsed[ iTo ]
}

public diablo_item_reset( id ){
	bUsed[ id ]		=	false;
}

public diablo_item_player_spawned( id ){
	bUsed[ id ]		=	false;
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Uzyj, aby stac sie niewidoczny dla wszystkich")
	}
	else{
		formatex( szMessage , iLen , "Uzyj, aby stac sie niewidoczny dla wszystkich" )
	}
}

public diablo_item_skill_used( id ){
	if (bUsed[ id ]){
		diablo_show_hudmsg(id, 2.0,"Tego przedmiotu mozesz uzyc raz na runde") 
		return PLUGIN_HANDLED
	}
	
	message_begin( MSG_ONE, gmsgBartimer, {0,0,0}, id ) 
	write_byte( 7 ) 
	write_byte( 0 ) 
	message_end( )
	
	use_addtofullpack = true
	
	Invisible[id] = true
	
	set_task(7.0, "RemoveInvisible", id+TASK_INVISIBLE)

	return PLUGIN_HANDLED
}

public RemoveInvisible(id)
{
	id -= TASK_INVISIBLE
	
	use_addtofullpack = false
	Invisible[id] = false
	bUsed[ id ] = true
}

public client_AddToFullPack(ent_state,e,edict_t_ent,edict_t_host,hostflags,player,pSet) 
{
	if (!use_addtofullpack)
		return FMRES_HANDLED
		
	if (!pev_valid(e)|| !pev_valid(edict_t_ent) || !pev_valid(edict_t_host))
		return FMRES_HANDLED
			
	new classname[32]
	pev(e,pev_classname,classname,31)
	
	new hostclassname[32]
	pev(edict_t_host,pev_classname,hostclassname,31)
		
	if (equal(classname,"player") && equal(hostclassname,"player") && player)
	{
		// only take effect if both players are alive & and not somthing else like a ladder
		if (is_user_alive(e) && is_user_alive(edict_t_host) && e != edict_t_host) 
		{
			if (Invisible[e])
				return FMRES_SUPERCEDE
						
			if (Invisible[edict_t_host])
				return FMRES_SUPERCEDE			
		}			
	}	
	return FMRES_HANDLED
}