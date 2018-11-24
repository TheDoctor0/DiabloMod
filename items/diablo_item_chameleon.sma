#include <amxmodx>
#include <cstrike>
#include <diablo_nowe.inc>

#define PLUGIN	"Chameleon"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new bHas[ 33 ];
new CT_Skins[4][] = {"sas","gsg9","urban","gign"};
new Terro_Skins[4][] = {"arctic","leet","guerilla","terror"};

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Kameleon" , 250 );
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Wygladasz jak przeciwnik" )
	bHas[ id ] = true;
	ZmienUbranie(id);
}

public diablo_copy_item( iFrom , iTo ){
	bHas[ iTo ] = true;
	bHas[ iFrom ] = false;
}

public diablo_item_reset( id ){
	if(is_user_connected(id)){
		cs_reset_user_model(id);
		bHas[ id ] = false;
	}
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Wygladasz jak przeciwnik")
	}
	else{
		formatex( szMessage , iLen , "Wygladasz jak przeciwnik" )
	}
}

public ZmienUbranie(id){
	new num = random_num(0,3);
	cs_set_user_model(id, (get_user_team(id) == 1)? CT_Skins[num]: Terro_Skins[num]);
}