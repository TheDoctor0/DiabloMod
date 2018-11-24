#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fun>
#include <fakemeta>

#include <diablo_nowe.inc>

#define PLUGIN	"Damage Light"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

native diablo_get_user_render1(id);
native diablo_get_user_render2(id);
native diablo_get_user_render3(id);

new bool:bHas[ 33 ];
new Light[ 33 ];
new render[ 33 ];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Lustrzany Blysk" , 250 );
	
	register_event("HLTV", "NowaRunda", "a", "1=0", "2=0");
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Ninja po zadaniu ci obrazen jest naswietlony przez %i sekundy", Light[id]);
	
	bHas[ id ] = true;
	
	remove_task(id);
}

public diablo_copy_item( iFrom , iTo ){
	bHas[ iTo ] = true;
	bHas[ iFrom ] = false;
	Light[ iTo ] = Light[ iFrom ];
	Light[ iFrom ] = 0;
	
	remove_task(iTo);
}

public diablo_item_reset( id ){
	bHas[id] = false;
	Light[id] 		=	0;
	
	remove_task(id);
}

public diablo_item_set_data( id ){
	bHas[id] = true;
	Light[id] 		=	random_num(3, 4);
	
	remove_task(id);
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Ninja po zadaniu ci obrazen jest naswietlony przez x sekundy.")
	}
	else{
		formatex( szMessage , iLen , "Ninja po zadaniu ci obrazen jest naswietlony przez %i sekundy.", Light[id])
	}
}

public diablo_damage_item_do(iVictim,iAttacker,&Float:fDamage,damageBits){
	new szClass[ 64 ];
	diablo_get_class_name( diablo_get_user_class( iAttacker ) , szClass , charsmax( szClass ) ) ;
	if(bHas[iVictim] && equal(szClass, "Ninja"))
		NinjaLight(iAttacker, iVictim);
}

public diablo_upgrade_item( id ){
	Light[ id ] += random_num( 0 , 1 );
}

public NinjaLight(victim, id)
{
	if(!is_user_alive(id) || !bHas[id])
		return PLUGIN_CONTINUE;
		
	if (is_user_alive(victim) && get_user_team(id) != get_user_team(victim) )
	{
		new szItem[ 64 ];
		diablo_get_item_name( diablo_get_user_item( victim ) , szItem , charsmax( szItem ) ) ;
		if(equal(szItem, "Avoid the Lights"))
			return PLUGIN_CONTINUE;
				
		diablo_set_user_render(victim,kRenderFxGlowShell,random_num(0,255),random_num(0,255),random_num(0,255),kRenderNormal,4,float(Light[id]));
		
		diablo_display_icon( victim , 2 , "dmg_bio" , 255 , 0 , 0 )
		remove_task( victim + 4637 )
		set_task( float(Light[id]) , "offIcon" , victim + 4637 )
		render[victim] = 10
		remove_task( victim + 4638 )
		set_task( float(Light[id]) , "Render" , victim + 4638 )
	}
	
	return PLUGIN_CONTINUE;
}

public offIcon( id ){
	id	-=	4637;
	
	if( is_user_connected( id ) ){
		diablo_display_icon( id , 0 , "dmg_bio" , 255 , 0 , 0 )
	}
}

public Render( id ){
	id	-=	4638;
	
	if( is_user_connected( id ) ){
		diablo_set_user_render( id, .render = kRenderTransAlpha , .amount = render[id] )
	}
}

public NowaRunda(){
	new maxplayers = get_maxplayers();
	for(new i=1; i<=maxplayers; i++){
		if(!is_user_connected(i) || is_user_hltv(i) || is_user_bot(i))
			return;
		
		remove_task( i + 4637 )
		remove_task( i + 4638 )
	}
}