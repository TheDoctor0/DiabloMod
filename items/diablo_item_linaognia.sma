#include <amxmodx>
#include <amxmisc>
#include <engine>

#include <diablo_nowe.inc>

#define PLUGIN	"Firerope"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iGrenade[ 33 ];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Ognisty Pas" , 250 );
	
	register_event("SendAudio","eventGrenade","bc","2=%!MRAD_FIREINHOLE")
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Masz 1/%i szanse do natychmiastowego zabicia HE" , iGrenade[ id ] )
}

public diablo_item_reset( id ){
	iGrenade[ id ]	=	0;
}

public diablo_item_set_data( id ){
	iGrenade[ id ]	=	random_num( 3 , 6 );
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Masz 1/x szanse do natychmiastowego zabicia HE")
	}
	else{
		formatex( szMessage , iLen , "Masz 1/%i szanse do natychmiastowego zabicia HE" , iGrenade[ id ] )
	}
}

public diablo_damage_item_do(iVictim,iAttacker,&Float:fDamage,damageBits){
	if( damageBits & (1<<24) && random_num( 1 , iGrenade[ iAttacker ] ) == 1){
		fDamage = float( get_user_health( iVictim ) * 2);
	}
}

public diablo_upgrade_item( id ){
	iGrenade[ id ] -= random_num(-1,1)
}

public diablo_copy_item( iFrom , iTo ){
	iGrenade[ iTo ]	=	iGrenade[ iFrom ];
	iGrenade[ iFrom ]	=	0;
}

public eventGrenade(id) 
{
	new id = read_data(1)
	if (iGrenade[ id ] > 0)
		set_task(0.1, "makeGlow", id)
}

public makeGlow(id) 
{
	new grenade
	new greModel[100]
	grenade = get_grenade(id) 
	
	if( grenade ) 
	{	
		entity_get_string(grenade, EV_SZ_model, greModel, 99)
		
		if(equali(greModel, "models/w_hegrenade.mdl" ) && iGrenade[ id ] > 0 )	
			set_rendering(grenade, kRenderFxGlowShell, 255,0,0, kRenderNormal, 255)
	}
}