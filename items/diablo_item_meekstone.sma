#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>

#include <diablo_nowe.inc>

#define PLUGIN	"Meekstone"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new bool:usedSkill[ 33 ] , bombPlanted[ 33 ] , sprite_white , sprite_fire , sprite_gibs;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Kamien Pokory" , 250 );
}

public plugin_precache(){
	precache_model("models/w_backpack.mdl");
	
	sprite_white = precache_model("sprites/white.spr") 
	sprite_fire = precache_model("sprites/explode1.spr") 
	sprite_gibs = precache_model("models/hgibs.mdl")
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Uzyj, aby podlozyc sztuczna bombe")
	
	usedSkill[ id ]		=	false;
	bombPlanted[ id ]	=	0;
}

public diablo_item_reset( id ){
	usedSkill[ id ]		=	false;
	bombPlanted[ id ]	=	0;
}

public diablo_copy_item( iFrom , iTo ){
	bombPlanted[ iTo ]	=	0;
	bombPlanted[ iFrom ]	=	0;
	usedSkill[ iFrom ]	=	false;
	usedSkill[ iTo ]	=	false;
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Mozesz polozyc falszywa bombe uzywajac klawisz E.")
	}
	else{
		formatex( szMessage , iLen , "Mozesz polozyc falszywa bombe uzywajac klawisz E.")
	}
}

public diablo_item_player_spawned( id ){
	usedSkill[ id ] 	=	false;
	bombPlanted[ id ]	=	0;
}

public diablo_item_skill_used( id ){
	if( usedSkill[ id ] && bombPlanted[ id ] == 0){
		diablo_show_hudmsg( id,2.0,"Meekstone mozesz uzyc raz na runde!" );
		
		return PLUGIN_CONTINUE;
	}
	
	if (is_user_alive(id) && bombPlanted[ id ] != 0 && pev_valid( bombPlanted[ id ] ) )
	{
		new Float:fOrigin[ 3 ] , iOrigin[ 3 ];
		
		pev( bombPlanted[ id ] , pev_origin , fOrigin );
		
		FVecIVec( fOrigin , iOrigin )
		
		explode(iOrigin , id)
		
		for(new a = 1; a < 33; a++) 
		{ 
			if (is_user_connected(a) && is_user_alive(a) || a == id)
			{			
				new origin1[3]
				get_user_origin(a,origin1) 
				
				if(get_distance(iOrigin,origin1) < 300 && get_user_team(a) != get_user_team(id))
				{
					diablo_kill( a , id , diabloDamageGrenade );
				}
			}
		}
		
		remove_entity( bombPlanted[ id ] )
		
		bombPlanted[ id ]	=	0;
	}
	else if (is_user_alive(id) && bombPlanted[ id ] == 0){
		new Float:pOrigin[3];
		entity_get_vector(id,EV_VEC_origin, pOrigin)
		bombPlanted[id] = create_entity("info_target")
		
		entity_set_model(bombPlanted[id],"models/w_backpack.mdl")
		entity_set_origin(bombPlanted[id],pOrigin)
		entity_set_string(bombPlanted[id],EV_SZ_classname,"fakec4")
		entity_set_edict(bombPlanted[id],EV_ENT_owner,id)
		entity_set_int(bombPlanted[id],EV_INT_movetype,6)
		
		usedSkill[ id ]	=	true;
	}
	
	
	
	return PLUGIN_CONTINUE;
}

public diablo_new_round(){
	remove_entity_name( "fakec4" );
}

public explode (vec1[3],playerid)
{ 
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1) 
	write_byte( 21 ) 
	write_coord(vec1[0]) 
	write_coord(vec1[1]) 
	write_coord(vec1[2] + 32) 
	write_coord(vec1[0]) 
	write_coord(vec1[1]) 
	write_coord(vec1[2] + 1000)
	write_short( sprite_white ) 
	write_byte( 0 ) 
	write_byte( 0 ) 
	write_byte( 3 ) 
	write_byte( 10 ) 
	write_byte( 0 ) 
	write_byte( 188 ) 
	write_byte( 220 ) 
	write_byte( 255 ) 
	write_byte( 255 ) 
	write_byte( 0 ) 
	message_end() 
	
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY) 
	write_byte( 12 ) 
	write_coord(vec1[0]) 
	write_coord(vec1[1]) 
	write_coord(vec1[2]) 
	write_byte( 188 ) 
	write_byte( 10 ) 
	message_end() 
	
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1) 
	write_byte( 3 ) 
	write_coord(vec1[0]) 
	write_coord(vec1[1]) 
	write_coord(vec1[2]) 
	write_short( sprite_fire ) 
	write_byte( 65 ) 
	write_byte( 10 ) 
	write_byte( 0 ) 
	message_end() 
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY,{0,0,0},playerid) 
	write_byte(107) 
	write_coord(vec1[0]) 
	write_coord(vec1[1]) 
	write_coord(vec1[2]) 
	write_coord(175) 
	write_short (sprite_gibs) 
	write_short (25)  
	write_byte (10) 
	message_end() 
}