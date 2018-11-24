#include <amxmodx>
#include <fakemeta>
#include <cstrike>
#include <engine>

#include <diablo_nowe.inc>

#define PLUGIN	"Ultra Armor"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iArmor[ 33 ], iArmorLeft[ 33 ];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Boska Szata" , 250 );
	
	register_forward(FM_TraceLine,"fw_traceline");
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Twoj pancerz moze odbic do %i pociskow" , iArmor[ id ] )
}

public diablo_item_player_spawned( id ){
	iArmorLeft[ id ] = iArmor[ id ]
}

public diablo_item_reset( id ){
	iArmor[ id ]	=	0;
}

public diablo_item_set_data( id ){
	iArmor[ id ]	=	random_num( 7 , 11 )
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Twoj pancerz moze odbic do x pociskow")
	}
	else{
		formatex( szMessage , iLen , "Twoj pancerz moze odbic do %i pociskow" , iArmor[ id ] )
	}
}

public diablo_upgrade_item( id ){
	iArmor[ id ] -= random_num(-1,1)
}

public diablo_copy_item( iFrom , iTo ){
	iArmor[ iTo ]	=	iArmor[ iFrom ];
	iArmor[ iFrom ]	=	0;
}

public fw_traceline(Float:vecStart[3],Float:vecEnd[3],ignoreM,id,trace) // pentToSkip == id, for clarity
{
	if(!is_user_connected(id) || !is_user_alive(id))
		return FMRES_IGNORED;

	new hit = get_tr2(trace, TR_pHit)	
	
	if(!(pev(id,pev_button) & IN_ATTACK))
		return FMRES_IGNORED;
		
	if(is_user_alive(hit) && get_user_team(id) != get_user_team(hit))
	{
		if( iArmorLeft[hit]>0 )
		{
			iArmorLeft[hit]--
			set_tr2(trace, TR_iHitgroup, 8)
		}
		return FMRES_IGNORED
	}
	
	return FMRES_IGNORED;
}