#include <amxmodx>

#include <diablo_nowe.inc>

#define PLUGIN	"Avoid the Lights"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Swietlna Tarcza" , 250 );
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Chroni przed naswietleniem latarka" )
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Chroni przed naswietleniem latarka")
	}
	else{
		formatex( szMessage , iLen , "Chroni przed naswietleniem latarka" )
	}
}