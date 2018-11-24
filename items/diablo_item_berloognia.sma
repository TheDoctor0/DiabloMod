#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>

#include <diablo_nowe.inc>

#define PLUGIN	"Fireball scepter"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iPromien[ 33 ] , bool:skillUsed[ 33 ] , sprite_beam;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Berlo Ognia" , 250 );
}

public plugin_precache(){
	sprite_beam = precache_model("sprites/zbeam4.spr") 
	precache_model( "models/rpgrocket.mdl" )
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Uszkadza wszystko w promieniu %i" , iPromien[ id ] )
}

public diablo_item_reset( id ){
	iPromien[ id ]	=	0;
	skillUsed[ id ]	=	false;
}

public diablo_item_set_data( id ){
	iPromien[ id ]	=	random_num( 100 , 200 );
	skillUsed[ id ]	=	false;
}

public diablo_copy_item( iFrom , iTo ){
	iPromien[ iTo ]	=	iPromien[ iFrom ];
	iPromien[ iFrom ]	=	0;
	skillUsed[ iFrom ]	=	false;
	skillUsed[ iTo	]	=	false;
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Mozesz wyczarowac ognista kule uzywajac tego przedmiotu. Zabije ona ludzi w okreslonym zasiegu. Im wiecej masz inteligencji tym wieksze zadasz obrazenia")
	}
	else{
		formatex( szMessage , iLen , "Mozesz wyczarowac ognista kule uzywajac tego przedmiotu. Zabije ona ludzi w zasiegu %i. Im wiecej masz inteligencji tym wieksze zadasz obrazenia" , iPromien[ id ] )
	}
}

public diablo_item_player_spawned( id ){
	skillUsed[ id ]	=	false;
}

public diablo_upgrade_item( id ){
	iPromien[ id ] += random_num( 0 , 33 );
}

public diablo_item_skill_used( id ){
	if ( skillUsed[ id ] )
	{
		diablo_show_hudmsg(id,2.0,"Ognistej kuli mozesz uzyc raz na runde!")
		return PLUGIN_HANDLED
	}
	
	if (is_user_alive(id))
	{
		skillUsed[ id ]	=	true;
		
		new Float:vOrigin[3]
		new fEntity
		entity_get_vector(id,EV_VEC_origin, vOrigin)
		fEntity = create_entity("info_target")
		entity_set_model(fEntity, "models/rpgrocket.mdl")
		entity_set_origin(fEntity, vOrigin)
		entity_set_int(fEntity,EV_INT_effects,64)
		entity_set_string(fEntity,EV_SZ_classname,"fireball2")
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
	
	return PLUGIN_CONTINUE;
}

public pfn_touch ( ptr, ptd )
{	
	if (ptd == 0)	return PLUGIN_CONTINUE
	
	new szClassName[64]
	
	if(pev_valid(ptd))	entity_get_string(ptd, EV_SZ_classname, szClassName, charsmax( szClassName) )
	else return PLUGIN_HANDLED;
	
	if(equal(szClassName, "fireball2"))
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