#include <amxmodx>
#include <amxmisc>

#include <diablo_nowe.inc>

#define PLUGIN	"Invisibility Armor"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iNiewidka[ 33 ], bool:bHas[ 33 ];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Zbroja Niewidzialnosci" , 250 );
}

public plugin_natives()
{
	register_native("diablo_get_user_render_armor","getUserRender");
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "+%i premii niewidocznosci" , 255-iNiewidka[ id ] )
	bHas[ id ] = true;
	new szClass[ 64 ];
	diablo_get_class_name( diablo_get_user_class( id ) , szClass , charsmax( szClass ) ) ;
	if( !equal( szClass , "Ninja" ) ){
		diablo_set_user_render( id , kRenderFxNone, 0, 0, 0, kRenderTransAlpha, iNiewidka[ id ] , 0.0);
	}
}

public diablo_item_reset( id ){
	iNiewidka[ id ]	=	0;
	bHas[ id ] = true;
	new szClass[ 64 ];
	diablo_get_class_name( diablo_get_user_class( id ) , szClass , charsmax( szClass ) ) ;
	if( !equal( szClass , "Ninja" ) )
		diablo_render_cancel( id );
}

public diablo_item_set_data( id ){
	iNiewidka[ id ]	=	random_num(70,100);
	bHas[ id ] = true;
	new szClass[ 64 ];
	diablo_get_class_name( diablo_get_user_class( id ) , szClass , charsmax( szClass ) ) ;
	if( !equal( szClass , "Ninja" ) )
		diablo_render_cancel( id );
}

public diablo_copy_item( iFrom , iTo ){
	iNiewidka[ iTo ]	=	iNiewidka[ iFrom ];
	iNiewidka[ iFrom ]	=	0;
	new szClass[ 64 ];
	diablo_get_class_name( diablo_get_user_class( iTo ) , szClass , charsmax( szClass ) ) ;
	if( !equal( szClass , "Ninja" ) )
		diablo_set_user_render( iTo , kRenderFxNone, 0, 0, 0, kRenderTransAlpha, iNiewidka[ iTo ] , 0.0);
	new szClass2[ 64 ];
	diablo_get_class_name( diablo_get_user_class( iFrom ) , szClass2 , charsmax( szClass2 ) ) ;
	if( !equal( szClass2 , "Ninja" ) )
		diablo_render_cancel( iFrom );
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Twoja widocznosc jest zredukowana z 255")
	}
	else{
		formatex( szMessage , iLen , "Twoja widocznosc jest zredukowana z 255 do %d" , iNiewidka[ id ] )
	}
}

public diablo_item_player_spawned( id ){
	if(bHas[ id ]){
		new szClass[ 64 ];
		diablo_get_class_name( diablo_get_user_class( id ) , szClass , charsmax( szClass ) ) ;
		if( !equal( szClass , "Ninja" ) )
			diablo_set_user_render( id , kRenderFxNone, 0, 0, 0, kRenderTransAlpha, iNiewidka[ id ] , 0.0);
	}
}

public diablo_upgrade_item( id ){
	iNiewidka[ id ]	-=	random_num(-10,10)
}

public getUserRender(plugin, params){
	if( params != 1 || !bHas[ get_param(1) ])
		return PLUGIN_CONTINUE;
		
	return iNiewidka[ get_param(1) ];
}
