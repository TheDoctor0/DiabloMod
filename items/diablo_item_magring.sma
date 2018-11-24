#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fun>
#include <fakemeta>

#include <diablo_nowe.inc>

#define PLUGIN	"Mag ring"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iPoints[ 33 ]

new bool:iFireball[33]

new sprite_beam

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Rozdzka Maga" , 250 );
}

public plugin_precache(){
	sprite_beam 	=	precache_model("sprites/zbeam4.spr") 
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Ten przedmiot dodaje ci +%i inteligencji. Uzyj, aby rzucic ognista kule.", iPoints[ id ] )
	diablo_set_extra_int( id , iPoints[ id ] );
}

public diablo_item_set_data( id ){
	iPoints[ id ]	=	5;
	diablo_set_extra_int( id , iPoints[ id ] );
	iFireball[id]	=	true;
}

public diablo_copy_item( iFrom , iTo ){
	iPoints[ iTo ]	=	iPoints[ iFrom ];
	iPoints[ iFrom ]	=	0;
	iFireball[ iFrom ]	=	false;
}

public diablo_item_reset( id ){
	iPoints[ id ]	=	0;
	diablo_set_extra_int( id , 0 );
	iFireball[ id ]	=	false;
}

public diablo_item_player_spawned( id ){
	iFireball[ id ]	=	false;
}

public diablo_upgrade_item( id ){
	iPoints[ id ] += random_num( 0 , 2 );
	diablo_set_extra_int( id , iPoints[ id ] );
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Ten przedmiot dodaje ci +5 inteligencji. Uzyj, aby rzucic ognista kule" )
	}
	else{
		formatex( szMessage , iLen , "Ten przedmiot dodaje ci +%i inteligencji. Uzyj, aby rzucic ognista kule", iPoints[ id ] )
	}
}

public diablo_item_skill_used(id){
	if (!iFireball[id])
	{
		diablo_show_hudmsg( id, 2.0 , "Tego przedmiotu mozesz uzyc raz na runde") 
		
		return PLUGIN_HANDLED
	}
	else
	{
		iFireball[id] = false
		
		new Float:vOrigin[3]
		new fEntity
		entity_get_vector(id,EV_VEC_origin, vOrigin)
		fEntity = create_entity("info_target")
		entity_set_model(fEntity, "models/rpgrocket.mdl")
		entity_set_origin(fEntity, vOrigin)
		entity_set_int(fEntity,EV_INT_effects,64)
		entity_set_string(fEntity,EV_SZ_classname,"fireball3")
		entity_set_int(fEntity, EV_INT_solid, SOLID_BBOX)
		entity_set_int(fEntity,EV_INT_movetype,5)
		entity_set_edict(fEntity,EV_ENT_owner,id)
		
		
		
		//Send forward
		new Float:fl_iNewVelocity[3]
		VelocityByAim(id, 1000, fl_iNewVelocity)
		entity_set_vector(fEntity, EV_VEC_velocity, fl_iNewVelocity)
		
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
		write_byte(22) 
		write_short(fEntity) 
		write_short(sprite_beam) 
		write_byte(45) 
		write_byte(4) 
		write_byte(255) 
		write_byte(0) 
		write_byte(0) 
		write_byte(25)
		message_end() 
	}
	return PLUGIN_CONTINUE
}

public pfn_touch ( ptr, ptd )
{	
	if (ptd == 0)	return PLUGIN_CONTINUE
	
	new szClassName[64]
	
	if(pev_valid(ptd))	entity_get_string(ptd, EV_SZ_classname, szClassName, charsmax( szClassName) )
	else return PLUGIN_HANDLED;
	
	if(equal(szClassName, "fireball3"))
	{
		new owner = pev(ptd,pev_owner)
		
		entity_get_string(ptr, EV_SZ_classname, szClassName, charsmax( szClassName) )
		
		if(equal(szClassName,"worldspawn") || is_user_alive(ptr) || (pev_valid(ptr) && pev(ptr,pev_solid) != SOLID_NOT && pev(ptr,pev_solid) != SOLID_TRIGGER)){
			new Float:fOrigin[3]
			pev(ptd,pev_origin,fOrigin)

			diablo_create_explode(owner,fOrigin,55.0 + float(diablo_get_user_int(owner)),150.0);
			
			remove_entity(ptd)
		}
	}
	
	return PLUGIN_CONTINUE
}