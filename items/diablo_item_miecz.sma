#include <amxmodx>
#include <amxmisc>
#include <engine>

#include <diablo_nowe.inc>

#define PLUGIN	"Sword"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new bool:bHas[ 33 ], iSword[ 33 ];

new SWORD_VIEW[]         = "models/diablomod/v_knife.mdl" 
new SWORD_PLAYER[]       = "models/diablomod/p_knife.mdl" 

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Miecz" , 250 );
}

public plugin_precache(){
	precache_model( SWORD_VIEW );
	precache_model( SWORD_PLAYER );
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Masz 1/%i szansy na natychmiastowe zabicie nozem", iSword[ id ] )
	
	bHas[ id ]	=	true;
}

public diablo_item_reset( id ){
	bHas[ id ]	=	false;
	iSword[ id ] = 0;
}

public diablo_item_set_data( id ){
	iSword[ id ]	=	random_num( 5 , 7 );
}

public diablo_upgrade_item( id ){
	iSword[ id ] += random_num( -1 , 1 );
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Masz 1/x szansy na natychmiastowe zabicie nozem")
	}
	else{
		formatex( szMessage , iLen , "Masz 1/%i szansy na natychmiastowe zabicie nozem", iSword[ id ] )
	}
}

public diablo_damage_item_do(iVictim,iAttacker,&Float:fDamage,damageBits){
	if( get_user_weapon( iAttacker ) == CSW_KNIFE && bHas[ iAttacker ] && random_num( 1 , iSword[ iAttacker ] ) == 1 ){
		diablo_kill( iVictim , iAttacker , diabloDamageKnife );
	}
}

public diablo_weapon_deploy(id,wpnID,weaponEnt){
	if( bHas[ id ] && wpnID == CSW_KNIFE ){
		entity_set_string(id, EV_SZ_viewmodel, SWORD_VIEW)  
		entity_set_string(id, EV_SZ_weaponmodel, SWORD_PLAYER)  
	}
}

public diablo_copy_item( iFrom , iTo ){
	bHas[ iTo ]	=	true;
	bHas[ iFrom ]	=	false;
	
	iSword[ iTo ]	=	iSword[ iFrom ];
	iSword[ iFrom ]	=	0;
}