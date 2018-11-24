#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>

#include <diablo_nowe.inc>

#define PLUGIN	"Medicine Glar"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iHp[ 33 ] , bool:bUsed[ 33 ] , sprite_laser;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Rekawice Lekarza" , 250 );
	
	register_think("Effect_Teamshield","Effect_Teamshield_Think")
}

public plugin_precache(){
	sprite_laser = precache_model("sprites/laserbeam.spr")
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Tworzy tarcze na graczu - wcisnij E, zeby uzyc" , iHp[ id ] )
}

public diablo_item_reset( id ){
	iHp[ id ]	=	0;
}

public diablo_item_set_data( id ){
	iHp[ id ]	=	random_num( 10 , 20 );
}

public diablo_copy_item( iFrom , iTo ){
	iHp[ iTo ]	=	iHp[ iFrom ];
	iHp[ iFrom ]	=	0;
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Uzyj, aby aktywowac tarcze na graczu. Cale uszkodzenia tarczy sa odzwierciedlone.")
	}
	else{
		formatex( szMessage , iLen , "Uzyj, aby aktywowac tarcze na graczu. Cale uszkodzenia tarczy sa odzwierciedlone.")
	}
}

public diablo_upgrade_item( id ){
	iHp[ id ] += random_num( 0 , 5 )
}

public diablo_item_skill_used( id ){
	if ( bUsed[ id ] ){
		bUsed[ id ]	=	false
	}
	else{
		new target = Find_Best_Angle(id,1000.0,true)
		
		if (!is_valid_ent(target))
		{
			diablo_show_hudmsg(id,2.0,"Zaden cel nie jest zasiegu do tarczy")
			return PLUGIN_CONTINUE
		}
		
		if (pev(target,pev_rendermode) == kRenderTransTexture || diablo_is_this_class( target , "Ninja" ) )
		{
			diablo_show_hudmsg(id,2.0,"Nie mozna wyczarowac tarczy na niewidzialnym graczu")
			return PLUGIN_CONTINUE
		}
		
		if (find_ent_by_owner(-1,"Effect_Teamshield",id) > 0)
			return PLUGIN_CONTINUE
	
		diablo_add_hp( target , iHp[ id ] );
		
		new ent = Spawn_Ent("info_target")
		set_pev(ent,pev_classname,"Effect_Teamshield")
		set_pev(ent,pev_owner,id)
		set_pev(ent,pev_solid,SOLID_NOT)
		set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
		set_pev(ent,pev_iuser2, target)	
		
		diablo_set_user_render( target , kRenderFxGlowShell, 0,200,0, kRenderFxNone, 0 , 0.0 );
		bUsed[id] = true
	}
	
	return PLUGIN_CONTINUE
}

public diablo_damage_taken_pre( iKiller , iVictim , &Float:fDamage ){
	new owner = find_owner_by_euser(iVictim,"Effect_Teamshield")
	if( is_user_connected( owner ) && bUsed[ owner ] ){
		if (is_user_alive(owner)){                             
			diablo_damage(iKiller , owner , fDamage , diabloDamageShot );
			fDamage /= 2.0;
		}
	}
}

public find_owner_by_euser(target,classname[])
{
	new ent = -1
	ent = find_ent_by_class(ent,classname)

	while (ent > 0)
	{
		if (pev(ent,pev_iuser2) == target)
		return pev(ent,pev_owner)
		ent = find_ent_by_class(ent,classname)
	}
	
	return -1
}

public Effect_Teamshield_Think(ent)
{
	if( !pev_valid( ent ) ){
		return PLUGIN_CONTINUE;
	}
	new id = pev(ent,pev_owner)
	new victim = pev(ent,pev_iuser2)
	
	new Float: vec1[3]
	new Float: vec2[3]
	new Float: vec3[3]
	
	entity_get_vector(id,EV_VEC_origin,vec1)
	entity_get_vector(victim ,EV_VEC_origin,vec2)
	
	new hit = trace_line ( id, vec1, vec2, vec3 )
	
	if (hit != victim || !is_user_alive(id) || !is_user_alive(victim) || !Can_Trace_Line(id,victim) || !UTIL_In_FOV(id,victim) || diablo_is_freezetime()){
		bUsed[ id ]	=	false
		diablo_render_cancel( victim )
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	else		
	set_pev(ent,pev_nextthink, halflife_time() + 0.3)
	
	new origin1[3]
	new origin2[3]
	
	get_user_origin(id,origin1)
	get_user_origin(victim,origin2)
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY) 
	write_byte (TE_BEAMPOINTS)
	write_coord(origin1[0])
	write_coord(origin1[1])
	write_coord(origin1[2]+8)
	write_coord(origin2[0])
	write_coord(origin2[1])
	write_coord(origin2[2]+8)
	write_short(sprite_laser);
	write_byte(1) // framestart 
	write_byte(1) // framerate 
	write_byte(3) // life 
	write_byte(5) // width 
	write_byte(10) // noise 
	write_byte(0) // r, g, b (red)
	write_byte(255) // r, g, b (green)
	write_byte(0) // r, g, b (blue)
	write_byte(45) // brightness 
	write_byte(5) // speed 
	message_end()    
	
	return PLUGIN_CONTINUE
}

stock Find_Best_Angle(id,Float:dist, same_team = false)
{
	new Float:bestangle = 0.0
	new winner = -1
	
	for (new i=0; i < 33; i++)
	{
		if (!is_user_alive(i) || i == id || (get_user_team(i) == get_user_team(id) && !same_team))
		continue
		
		if (get_user_team(i) != get_user_team(id) && same_team)
		continue
		
		//User has spell immunity, don't target
		
		new Float:c_angle = Find_Angle(id,i,dist)
		
		if (c_angle > bestangle && Can_Trace_Line(id,i))
		{
			winner = i
			bestangle = c_angle
		}
		
	}
	
	return winner
}

//This is an interpolation. We make tree lines with different height as to make sure
stock bool:Can_Trace_Line(id, target)
{	
	for (new i=-35; i < 60; i+=35)
	{		
		new Float:Origin_Id[3]
		new Float:Origin_Target[3]
		new Float:Origin_Return[3]
		
		pev(id,pev_origin,Origin_Id)
		pev(target,pev_origin,Origin_Target)
		
		Origin_Id[2] = Origin_Id[2] + i
		Origin_Target[2] = Origin_Target[2] + i
		
		trace_line(-1, Origin_Id, Origin_Target, Origin_Return) 
		
		if (get_distance_f(Origin_Return,Origin_Target) < 25.0)
		return true
		
	}
	
	return false
}

stock Spawn_Ent(const classname[]) 
{
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classname))
	set_pev(ent, pev_origin, {0.0, 0.0, 0.0})    
	dllfunc(DLLFunc_Spawn, ent)
	return ent
}

stock Float:Find_Angle(Core,Target,Float:dist)
{
	new Float:vec2LOS[2]
	new Float:flDot	
	new Float:CoreOrigin[3]
	new Float:TargetOrigin[3]
	new Float:CoreAngles[3]
	
	pev(Core,pev_origin,CoreOrigin)
	pev(Target,pev_origin,TargetOrigin)
	
	if (get_distance_f(CoreOrigin,TargetOrigin) > dist)
	return 0.0
	
	pev(Core,pev_angles, CoreAngles)
	
	for ( new i = 0; i < 2; i++ )
	vec2LOS[i] = TargetOrigin[i] - CoreOrigin[i]
	
	new Float:veclength = Vec2DLength(vec2LOS)
	
	//Normalize V2LOS
	if (veclength <= 0.0)
	{
		vec2LOS[0] = 0.0
		vec2LOS[1] = 0.0
	}
	else
	{
		new Float:flLen = 1.0 / veclength;
		vec2LOS[0] = vec2LOS[0]*flLen
		vec2LOS[1] = vec2LOS[1]*flLen
	}
	
	//Do a makevector to make v_forward right
	engfunc(EngFunc_MakeVectors,CoreAngles)
	
	new Float:v_forward[3]
	new Float:v_forward2D[2]
	get_global_vector(GL_v_forward, v_forward)
	
	v_forward2D[0] = v_forward[0]
	v_forward2D[1] = v_forward[1]
	
	flDot = vec2LOS[0]*v_forward2D[0]+vec2LOS[1]*v_forward2D[1]
	
	if ( flDot > 0.5 )
	{
		return flDot
	}
	
	return 0.0	
}

stock Float:Vec2DLength( Float:Vec[2] )  
{ 
	return floatsqroot(Vec[0]*Vec[0] + Vec[1]*Vec[1] )
}

stock bool:UTIL_In_FOV(id,target)
{
	if (Find_Angle(id,target,9999.9) > 0.0)
	return true
	
	return false
}