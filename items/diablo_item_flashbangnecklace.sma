#include <amxmodx>
#include <amxmisc>
#include <cstrike>

#include <diablo_nowe.inc>

#define PLUGIN	"Flashbang necklace"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new bool:iFlash[ 33 ]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Naszyjnik Ciemnosci" , 250 );
	
	register_message(get_user_msgid("ScreenFade"), "BlockEffect");
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Flashbangi na ciebie nie dzialaja" )
	iFlash[ id ] = true;
}

public diablo_copy_item( iFrom , iTo ){
	iFlash[ iFrom ] = iFlash[ iTo ] 
}

public diablo_item_reset( id ){
	iFlash[ id ] = false;
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Flashbangi na ciebie nie dzialaja")
	}
	else{
		formatex( szMessage , iLen , "Flashbangi na ciebie nie dzialaja" )
	}
}

public BlockEffect(msgId, msgType, id)
{
	if(!iFlash[id]) 
		return PLUGIN_CONTINUE;  
	
	if(get_msg_arg_int(4) == 255 && get_msg_arg_int(5) == 255 && get_msg_arg_int(6) == 255 && get_msg_arg_int(7) > 199)
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}