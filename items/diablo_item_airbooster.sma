#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

#include <diablo_nowe.inc>

#define PLUGIN	"Air Booster"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new bool:iJump[ 33 ], iJumps[ 33 ]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Powietrzny Wzmacniacz" , 250 );
	
	register_forward(FM_CmdStart, "CmdStart");
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Mozesz zrobic podwojny skok w powietrzu" )
	iJump[ id ] = true;
}

public diablo_copy_item( iFrom , iTo ){
	iJump[ iFrom ] = iJump[ iTo ] 
}

public diablo_item_reset( id ){
	iJump[ id ] = false;
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Mozesz zrobic podwojny skok w powietrzu")
	}
	else{
		formatex( szMessage , iLen , "Mozesz zrobic podwojny skok w powietrzu" )
	}
}

public CmdStart(id, uc_handle)
{
	if(!is_user_connected(id) || !iJump[id])
		return FMRES_IGNORED;
	
	new button = get_uc(uc_handle, UC_Buttons);
	new oldbutton = pev(id, pev_oldbuttons);
	new flags = pev(id, pev_flags);
	if((button & IN_JUMP) && !(flags & FL_ONGROUND) && !(oldbutton & IN_JUMP) && iJumps[id])
	{
		iJumps[id] = 0;
		new Float:velocity[3];
		pev(id, pev_velocity, velocity);
		velocity[2] = random_float(265.0,285.0);
		set_pev(id, pev_velocity, velocity);
	}
	else if(flags & FL_ONGROUND)	
		iJumps[id] = 1;
		
	return FMRES_IGNORED;
}