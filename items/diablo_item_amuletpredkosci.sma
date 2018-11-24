#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#include <diablo_nowe.inc>

#define PLUGIN	"Lothars Edge"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iSpeed[ 33 ] , bUsed[ 33 ] , bool:bHas[ 33 ];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Amulet Predkosci" , 250 );
	
	RegisterHam(Ham_Spawn, "player", "Spawn", 1);
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Uzyj a staniesz sie niewidzialny przez %i sekund i w tym czasie nie mozesz atakowac, ale za to szybko biegasz" , iSpeed[ id ] )
	bHas[ id ] = true;
}

public diablo_item_reset( id ){
	new szClass[ 64 ];
	diablo_get_class_name( diablo_get_user_class( id ) , szClass , charsmax( szClass ) ) ;
	if( !equal( szClass , "Ninja" ) ){
		diablo_render_cancel( id );
	}
	iSpeed[ id ]	=	0;
	bUsed[ id ]	=	0;
	bHas[id] = false;
}

public diablo_item_set_data( id ){
	iSpeed[ id ]	=	random_num( 3 , 5 );
	bUsed[ id ]	=	0;
	bHas[ id ] = true;
}

public diablo_item_skill_used( id ){
	if( !bHas[ id ] )
		return PLUGIN_CONTINUE;
	
	if( bUsed [ id ] == 1 || bUsed [ id ] == 2){
		diablo_show_hudmsg( id , 3.0 , "Ten przedmiot mozesz uzyc raz na runde!" );
		return PLUGIN_CONTINUE;
	}
	
	diablo_show_hudmsg( id , 1.5 , "Jestes teraz szybki i niewidzialny!" );
	
	bUsed[ id ] = 1
	
	engclient_cmd(id,"weapon_knife") 
	
	diablo_add_speed(id, 250.0)
	
	diablo_set_user_render(id,kRenderFxNone, 0,0,0, kRenderTransTexture, 1, 0.0)
	
	set_task( float( iSpeed[id] ),"resetSpeed",id) 
	
	message_begin( MSG_ONE, get_user_msgid("BarTime") , {0,0,0}, id ) 
	write_byte( iSpeed[ id ] ) 
	write_byte( 0 ) 
	message_end() 
	
	return PLUGIN_CONTINUE;
}

public resetSpeed( id ){

	diablo_show_hudmsg( id , 1.0 , "Koniec mocy Lothars Edge!" );
	
	bUsed[ id ] = 2;
	
	new szClass[ 64 ];
	diablo_get_class_name( diablo_get_user_class( id ) , szClass , charsmax( szClass ) ) ;
	if( !equal( szClass , "Ninja" ) ){
		diablo_render_cancel( id );
	}
	else
		diablo_set_user_render( id , .render = kRenderTransAlpha, .amount = 10 );
	
	if( is_user_alive( id ) )
		diablo_reset_speed(id);
}

public diablo_weapon_deploy(id,wpnID,weaponEnt){
	if( iSpeed[ id ] > 0 && bUsed[ id ] == 1 && wpnID != CSW_KNIFE ){
		engclient_cmd(id,"weapon_knife") 
	}
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Uzyj, zeby stac sie niewidzialny. W tym czasie nie bedziesz mogl atakowac, ale za to staniesz sie szybszy na x sekund")
	}
	else{
		formatex( szMessage , iLen , "Uzyj a staniesz sie niewidzialny przez %i sekund i w tym czasie nie mozesz atakowac, ale za to szybko biegasz" , iSpeed[ id ] )
	}
}

public diablo_preThink( id ){
	new buttons = pev(id,pev_button)
	
	buttons &= ~IN_ATTACK;
	buttons &= ~IN_ATTACK2;
	
	set_pev(id,pev_button,buttons);
}

public diablo_upgrade_item( id ){
	iSpeed[ id ] += random_num(0,1)
}

public diablo_copy_item( iFrom , iTo ){
	iSpeed[ iTo ]	=	iSpeed[ iFrom ];
	iSpeed[ iFrom ]	=	0;
	
	bUsed[ iTo ]	=	0;
	bUsed[ iFrom ]	=	0;
	
	bHas[ iTo ] = true;
	bHas[ iFrom ]	=	false;
	
	new szClass[ 64 ];
	diablo_get_class_name( diablo_get_user_class( iFrom ) , szClass , charsmax( szClass ) ) ;
	if( !equal( szClass , "Ninja" ) ){
		diablo_render_cancel( iFrom );
	}
	else
		diablo_set_user_render( iFrom , .render = kRenderTransAlpha, .amount = 10 );
}

public Spawn(id)
{
	if(is_user_connected(id) && iSpeed[id] > 0)
		bUsed[ id ]	=	0;
}