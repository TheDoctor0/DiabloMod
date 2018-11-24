#include <amxmodx>
#include <amxmisc>
#include <fun>

#include <diablo_nowe.inc>

#define PLUGIN	"Stealth Shoes"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Ciche Buty" , 250 );
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Twoj bieg cichnie" )
	set_user_footsteps( id , 1 )
}

public diablo_item_reset( id ){
	if(!diablo_is_this_class(id, "Zabojca"))
		set_user_footsteps( id , 0 )
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Twoj bieg cichnie")
	}
	else{
		formatex( szMessage , iLen , "Twoj bieg cichnie" )
	}
}

public diablo_item_player_spawned( id ){
	set_user_footsteps( id , 1 )
}