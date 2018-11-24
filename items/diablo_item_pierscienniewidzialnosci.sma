#include <amxmodx>
#include <amxmisc>
#include <fun>

#include <diablo_nowe.inc>

#define PLUGIN	"Stalkers ring"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new bool:bHas[ 33 ]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Pierscien Przesladowcy" , 250 )
	
	register_event( "Health" , "Health" , "be" )
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Masz 5 punktow zycia i jestes prawie niewidoczny")
	bHas[ id ]	=	true
	
	new szClass[ 64 ];
	diablo_get_class_name( diablo_get_user_class( id ) , szClass , charsmax( szClass ) ) ;
	if( !equal( szClass , "Ninja" ) )
		diablo_set_user_render( id , .render = kRenderTransAlpha , .amount = 5 )
	else
		diablo_set_user_render( id , .render = kRenderTransAlpha , .amount = 0 )
	set_user_health( id , 5 )
	diablo_set_max_hp( id , 5 )
}

public diablo_item_reset( id ){
	bHas[ id ]	=	false;
	new szClass[ 64 ];
	diablo_get_class_name( diablo_get_user_class( id ) , szClass , charsmax( szClass ) ) ;
	if( !equal( szClass , "Ninja" ) )
		diablo_render_cancel( id );
	else
		diablo_set_user_render( id , .render = kRenderTransAlpha , .amount = 10 )
}

public diablo_copy_item( iFrom , iTo ){
	bHas[ iTo ]	=	true;
	bHas[ iFrom ]	=	false;
	diablo_set_max_hp( iTo , 5 )
	new szClass[ 64 ];
	diablo_get_class_name( diablo_get_user_class( iFrom ) , szClass , charsmax( szClass ) ) ;
	if( !equal( szClass , "Ninja" ) )
		diablo_render_cancel( iFrom );
	else
		diablo_set_user_render( iFrom , .render = kRenderTransAlpha , .amount = 10 )
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Masz 5 punktow zycia i jestes prawie niewidoczny")
	}
	else{
		formatex( szMessage , iLen , "Masz 5 punktow zycia i jestes prawie niewidoczny" )
	}
}

public diablo_item_player_spawned( id ){
	if(bHas[id]){
		set_task(0.1, "Stalker", id);
	}
}

public Reset(id){
	if(is_user_connected(id) && is_user_alive(id))
		set_user_health( id , 5 );
}

public Stalker( id ){
	new szClass[ 64 ];
	diablo_get_class_name( diablo_get_user_class( id ) , szClass , charsmax( szClass ) ) ;
	if( !equal( szClass , "Ninja" ) )
		diablo_set_user_render( id , .render = kRenderTransAlpha , .amount = 5 )
	else
		diablo_set_user_render( id , .render = kRenderTransAlpha , .amount = 0 )
	set_task(0.1, "Reset", id);
}

public Health(id){
	if(bHas[ id ] && is_user_alive( id ) && read_data(1) > 5 )
		set_task(0.1, "Reset", id);
}