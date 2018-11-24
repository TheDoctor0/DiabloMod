#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>

#include <diablo_nowe.inc>

#define PLUGIN	"Gold statue"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iHeal[ 33 ] , bool:bUsedItem[ 33 ] , sprite_white;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Zlota Statua" , 250 );
	
	set_task( 5.0 , "healTime" , 666 , .flags = "b" );
	
	register_think("Effect_Healing_Totem","Effect_Healing_Totem_Think")
}

public plugin_precache(){
	precache_model( "models/diablomod/totem_heal.mdl" );
	
	sprite_white = precache_model("sprites/white.spr") 
}

public healTime(){
	for( new i = 0 ; i < 33 ; i++ ){
		if( !is_user_alive( i ) || iHeal[ i ] == 0 )
			continue;
		
		diablo_add_hp( i , iHeal[ i ] );
	}
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Regeneruje %i hp co kazde 5 sekund. Uzyj, zeby polozyc totem, ktory bedzie leczyl wszystkich w zasiegu 300" , iHeal[ id ] )
}

public diablo_item_reset( id ){
	iHeal[ id ]			=	0;
	bUsedItem[ id ]		=	false;
}

public diablo_item_set_data( id ){
	iHeal[ id ]			=	random_num( 5 , 10 );
	bUsedItem[ id ]		=	false;
}

public diablo_copy_item( iFrom , iTo ){
	iHeal[ iTo ]	=	iHeal[ iFrom ];
	iHeal[ iFrom ]	=	0;
	bUsedItem[ iFrom ]	=	false;
	bUsedItem[ iTo ]	=	false;
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Zyskasz +x hp co kazde 5 sekund. Uzyj aby polozyc leczacy totem na 7 sekund")
	}
	else{
		formatex( szMessage , iLen , "Zyskasz +%i hp co kazde 5 sekund. Uzyj aby polozyc leczacy totem na 7 sekund" , iHeal[ id ] )
	}
}

public diablo_upgrade_item( id ){
	iHeal[ id ] += random_num( 0 , 2 );
}

public diablo_item_player_spawned( id ){
	bUsedItem[ id ]		=	false;
}

public diablo_item_skill_used( id ){
	if( bUsedItem[ id ] ){
		
		diablo_show_hudmsg( id,2.0,"Leczacy Totem mozesz uzyc raz na runde!" )
		
		return PLUGIN_CONTINUE
	}
	
	bUsedItem[id] = true
	
	new origin[3]
	pev(id,pev_origin,origin)
	
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Healing_Totem")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_solid,SOLID_TRIGGER)
	set_pev(ent,pev_origin,origin)
	set_pev(ent,pev_ltime, halflife_time() + 7 + 0.1)
	
	engfunc(EngFunc_SetModel, ent, "models/diablomod/totem_heal.mdl")  	
	set_rendering ( ent, kRenderFxGlowShell, 255,0,0, kRenderFxNone, 255 ) 	
	engfunc(EngFunc_DropToFloor,ent)
	
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
	
	return PLUGIN_CONTINUE
	
}

stock Spawn_Ent(const classname[]) 
{
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classname))
	set_pev(ent, pev_origin, {0.0, 0.0, 0.0})    
	dllfunc(DLLFunc_Spawn, ent)
	return ent
}

public Effect_Healing_Totem_Think(ent)
{
	if( !pev_valid( ent ) ){
		return PLUGIN_CONTINUE;
	}

	new id = pev(ent,pev_owner)
	new amount_healed = iHeal[id]
	new totem_dist = 300
	
	//We have emitted beam. Apply effect (this is delayed)
	if (pev(ent,pev_iuser2) == 1)
	{		
		new Float:forigin[3], origin[3]
		pev(ent,pev_origin,forigin)	
		FVecIVec(forigin,origin)
		
		//Find people near and damage them
		new entlist[513]
		new numfound = find_sphere_class(0, "player", totem_dist + 0.0, entlist, 512, forigin)
		
		for (new i=0; i < numfound; i++)
		{		
			new pid = entlist[i]
			
			if (get_user_team(pid) != get_user_team(id))
			continue
			
			if (is_user_alive(pid)) diablo_add_hp( pid , amount_healed )
		}
		
		set_pev(ent, pev_iuser2, 0)
		set_pev(ent, pev_nextthink, halflife_time() + 1.5)
		
		return PLUGIN_CONTINUE
	}
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	//If this object is almost dead, apply some render to make it fade out
	if (pev(ent,pev_ltime)-2.0 < halflife_time())
	set_rendering ( ent, kRenderFxNone, 255,255,255, kRenderTransAlpha, 100 ) 
	
	set_pev(ent, pev_iuser2, 1)
	set_pev(ent, pev_nextthink, halflife_time() + 0.5)
	
	new Float:forigin[3], origin[3]
	pev(ent,pev_origin,forigin)	
	FVecIVec(forigin,origin)
	
	//Find people near and give them health
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY, origin );
	write_byte( TE_BEAMCYLINDER );
	write_coord( origin[0] );
	write_coord( origin[1] );
	write_coord( origin[2] );
	write_coord( origin[0] );
	write_coord( origin[1] + totem_dist );
	write_coord( origin[2] + totem_dist );
	write_short( sprite_white );
	write_byte( 0 ); // startframe
	write_byte( 0 ); // framerate
	write_byte( 10 ); // life
	write_byte( 10 ); // width
	write_byte( 255 ); // noise
	write_byte( 255 ); // r, g, b
	write_byte( 100 ); // r, g, b
	write_byte( 100 ); // r, g, b
	write_byte( 128 ); // brightness
	write_byte( 5 ); // speed
	message_end();
	
	return PLUGIN_CONTINUE

}