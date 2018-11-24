#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>

#include <diablo_nowe.inc>

#define PLUGIN	"Arch angel wings"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iGrav[ 33 ] , Float:gravitytimer[ 33 ] , earthstomp[ 33 ] , bool:falling[ 33 ] , Float:oldGrav[ 33 ];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Skrzydla Archaniola" , 250 );
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "+%i premia wyzszego skoku - Wcisnij e zeby uzyc" , iGrav[ id ] )
	
	new classname[64]
	diablo_get_class_name(diablo_get_user_class(id), classname, charsmax(classname))
	if(equali(classname, "Ninja"))
		diablo_add_user_grav( id , -0.1 )
	else
		diablo_add_user_grav( id , ( 1.0 - iGrav[ id ] ) / 5.0 )
}

public diablo_item_reset( id ){
	iGrav[ id ]			=	0;
	gravitytimer[ id ]	=	0.0;
	earthstomp[ id ]	=	0;
	falling[ id ]		=	false;
	oldGrav[ id ]		=	0.0;
	new classname[64]
	diablo_get_class_name(diablo_get_user_class(id), classname, charsmax(classname))
	if(equali(classname, "Ninja"))
		diablo_add_user_grav( id , 0.1 )
	else
		diablo_set_user_grav( id, 1.0 )
}

public diablo_copy_item( iFrom , iTo ){
	iGrav[ iTo ]			=	iGrav[ iFrom ];
	gravitytimer[ iTo ]	=	0.0;
	earthstomp[ iTo ]	=	0;
	falling[ iTo ]		=	false;
	oldGrav[ iTo ]		=	0.0;
	
	iGrav[ iFrom ]			=	0;
	gravitytimer[ iFrom ]	=	0.0;
	earthstomp[ iFrom ]	=	0;
	falling[ iFrom ]		=	false;
	oldGrav[ iFrom ]		=	0.0;
	new classname[64]
	diablo_get_class_name(diablo_get_user_class(iFrom), classname, charsmax(classname))
	if(equali(classname, "Ninja"))
		diablo_add_user_grav( iFrom , 0.1 )
	else
		diablo_set_user_grav( iFrom, 1.0 )
	
}

public diablo_item_set_data( id ){
	iGrav[ id ]			=	random_num( 5 , 9 );
	gravitytimer[ id ]	=	0.0;
	earthstomp[ id ]	=	0;
	falling[ id ]		=	false;
	oldGrav[ id ]		=	0.0;
}

public diablo_item_player_spawned( id ){
	new classname[64]
	diablo_get_class_name(diablo_get_user_class(id), classname, charsmax(classname))
	if(equali(classname, "Ninja"))
		diablo_add_user_grav( id , -0.1 )
	else
		diablo_add_user_grav( id , ( 1.0 - iGrav[ id ] ) / 13.0 )
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "premia wyzszego skoku - Wcisnij e zeby uzyc")
	}
	else{
		formatex( szMessage , iLen , "Wysoki skok jest zredukowany do %i Uzyj tego przedmiotu jak bedziesz w powietrzu. Uszkodzenia zaleza od wysokosci skoku i twojej sily" , iGrav[ id ] )
	}
}

public diablo_upgrade_item( id ){
	iGrav[ id ] += random_num( 0 , 1 );
}

public diablo_item_skill_used( id ){
	if (pev(id,pev_flags) & FL_ONGROUND) 
	{
		diablo_show_hudmsg(id,2.0,"Musisz byc w powietrzu!")
		return PLUGIN_CONTINUE
	}
	
	if (halflife_time()-gravitytimer[id] <= 15)
	{
		diablo_show_hudmsg(id,2.0,"Ten przedmiot, moze byc uzyty co kazde 15 sekund")
		return PLUGIN_CONTINUE
	}
	
	gravitytimer[id] = halflife_time()
	
	new origin[3]
	get_user_origin(id,origin)
	
	if (origin[2] == 0)
		earthstomp[id] = 1
	else
		earthstomp[id] = origin[2]
	
	oldGrav[ id ]	=	diablo_get_user_grav( id );
	
	diablo_set_user_grav( id , 5.0 );
	
	falling[id] = true
	
	
	return PLUGIN_CONTINUE
}

public client_PostThink( id )
{
	if (earthstomp[id] != 0 && is_user_alive(id))
	{
		if (!falling[id]) add_bonus_stomp(id)
		else set_pev(id,pev_watertype,-3)
	}
}

public client_PreThink( id ){
	if (earthstomp[id] != 0 && is_user_alive(id))
	{
		static Float:fallVelocity;
		pev(id,pev_flFallVelocity,fallVelocity);

		if(fallVelocity) falling[id] = true
		else falling[id] = false;
	}
}

public add_bonus_stomp(id)
{
	diablo_set_user_grav( id , oldGrav[ id ] );
	
	new origin[3]
	get_user_origin(id,origin)
	
	new dam = earthstomp[id]-origin[2]
	
	earthstomp[id] = 0
	
	//If jump is is high enough, apply some shake effect and deal damage, 300 = down from BOMB A in dust2
	if (dam < 85)
	return PLUGIN_CONTINUE
	
	dam = dam-85
	
	diablo_screen_shake( id , 1 << 14 , 1 << 12 , 1 << 14 )
	
	new entlist[513]
	new numfound = find_sphere_class(id,"player",230.0 + float( diablo_get_user_str( id ) * 2 ),entlist,512)
	

	for (new i=0; i < numfound; i++)
	{		
		new pid = entlist[i]
		
		if (pid == id || !is_user_alive(pid))
		continue
		
		if (get_user_team(id) == get_user_team(pid))
		continue
		
		if (!(pev(pid, pev_flags) & FL_ONGROUND)) continue	
		
		new Float:id_origin[3]
		new Float:pid_origin[3]
		new Float:delta_vec[3]
		
		pev(id,pev_origin,id_origin)
		pev(pid,pev_origin,pid_origin)
		
		
		delta_vec[0] = (pid_origin[0]-id_origin[0])+10
		delta_vec[1] = (pid_origin[1]-id_origin[1])+10
		delta_vec[2] = (pid_origin[2]-id_origin[2])+200
		
		set_pev(pid,pev_velocity,delta_vec)
		
		diablo_screen_shake( pid , 1 << 14 , 1 << 12 , 1 << 14 )
		
		diablo_damage( pid , id , float( dam ) , diabloDamageGrenade );		
	}
	
	return PLUGIN_CONTINUE
}