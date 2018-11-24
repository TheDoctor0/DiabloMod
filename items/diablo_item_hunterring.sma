#include <amxmodx>
#include <hamsandwich>

#include <diablo_nowe.inc>

#define PLUGIN	"Hunter ring"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new bool:bHas[33];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Sygnet Lowcy" , 250 );
	
	RegisterHam(Ham_Spawn, "player", "Spawn", 1);
}

public diablo_item_give( id , szRet[] , iLen ){
	new szClass[ 64 ];
	diablo_get_class_name( diablo_get_user_class( id ) , szClass , charsmax( szClass ) ) ;
	if( !equal( szClass , "Ninja" ) ){
		diablo_give_user_bow(id);
		formatex( szRet , iLen , "Posiadasz kusze Lowcy. Jej obrazenia zaleza od inteligencji." )
	}
	else
		formatex( szRet , iLen , "Posiadasz kusze Lowcy (jest zablokowana na klasie Ninja). Jej obrazenia zaleza od inteligencji." )
	bHas[id] = true;
}

public diablo_item_reset( id ){
	if(!diablo_is_this_class(id, "Lowca"))
		diablo_give_user_bow(id, false);
	bHas[id] = false;
}

public diablo_copy_item( iFrom , iTo ){
	bHas[ iFrom ] = bHas[ iTo ] 
	diablo_give_user_bow(iTo, true);
	if(!diablo_is_this_class(iFrom, "Lowca"))
		diablo_give_user_bow(iFrom, false);
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Posiadasz kusze Lowcy. Jej obrazenia zaleza od inteligencji.")
	}
	else{
		formatex( szMessage , iLen , "Posiadasz kusze Lowcy. Jej obrazenia zaleza od inteligencji." )
	}
}

public Spawn(id)
{
	if(is_user_alive(id) && bHas[id]){
		new szClass[ 64 ];
		diablo_get_class_name( diablo_get_user_class( id ) , szClass , charsmax( szClass ) ) ;
		if( !equal( szClass , "Ninja" ) ){
			diablo_give_user_bow(id);
			client_print(id, print_chat, "Kusza na klasie Ninja jest zablokowana.");
		}
	}
}