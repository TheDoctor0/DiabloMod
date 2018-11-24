#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta_util> 
#include <hamsandwich> 

#include <diablo_nowe.inc>

#define PLUGIN	"Iron Spikes"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new bool:iSmoke[ 33 ]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Zabojczy Dym" , 250 );
	
	register_event("SendAudio","eventGrenade","bc","2=%!MRAD_FIREINHOLE")
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Jezeli trafisz kogos granatem dymnym, to on zginie" )
	iSmoke[ id ] = true;
}

public diablo_copy_item( iFrom , iTo ){
	iSmoke[ iFrom ] = iSmoke[ iTo ] 
}

public diablo_item_reset( id ){
	iSmoke[ id ] = false;
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Jezeli trafisz kogos granatem dymnym, to on zgini")
	}
	else{
		formatex( szMessage , iLen , "Jezeli trafisz kogos granatem dymnym, to on zgini" )
	}
}

public pfn_touch ( ptr, ptd )
{	
	if (ptd == 0)
		return PLUGIN_CONTINUE
	
	new szClassName[32]
	if(pev_valid(ptd))
		entity_get_string(ptd, EV_SZ_classname, szClassName, 31)
	else 
		return PLUGIN_HANDLED
	
	if (ptr != 0 && pev_valid(ptr))
	{
		new szClassNameOther[32]
		entity_get_string(ptr, EV_SZ_classname, szClassNameOther, 31)
		
		if(equal(szClassName, "grenade") && equal(szClassNameOther, "player"))
		{
			new greModel[64]
			entity_get_string(ptd, EV_SZ_model, greModel, 63)
			
			if(equali(greModel, "models/w_smokegrenade.mdl" ))	
			{
				new id = entity_get_edict(ptd,EV_ENT_owner)
				
				if (is_user_connected(id) 
				&& is_user_connected(ptr) 
				&& is_user_alive(ptr) 
				&& iSmoke[id]
				&& get_user_team(id) != get_user_team(ptr))
				ExecuteHam(Ham_TakeDamage, ptr, id, id, 999.0, 1);
			}
		}
	}
	return PLUGIN_CONTINUE
}

public eventGrenade(id) 
{
	new id = read_data(1)
	if (iSmoke[id])
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

		if(equali(greModel, "models/w_smokegrenade.mdl" ))	
			set_rendering(grenade, kRenderFxGlowShell, 0,255,255, kRenderNormal, 255)
	}
}