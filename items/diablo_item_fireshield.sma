#include <amxmodx>
#include <engine>
#include <fakemeta>

#include <diablo_nowe.inc>

#define PLUGIN	"Fireshield"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new sprite_blood_drop = 0;
new sprite_blood_spray = 0;
new bool:usedItem[ 33 ];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Ognista Tarcza" , 250 );
	
	register_think("Effect_Rot","Effect_Rot_Think");
	register_think("Effect_Slow","Effect_Slow_Think");
}

public plugin_precache()
{
	sprite_blood_drop = precache_model("sprites/blood.spr");
	sprite_blood_spray = precache_model("sprites/bloodspray.spr");
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Chroni od natychmiastowego zabicia HE i kulami" )
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Chroni od natychmiastowego zabicia HE i kulami. Uzyj, zeby zadac obrazenia, spowolnic i oslepic kazdego wroga wokol ciebie.")
	}
	else{
		formatex( szMessage , iLen , "Chroni od natychmiastowego zabicia HE i kulami. Uzyj, zeby zadac obrazenia, spowolnic i oslepic kazdego wroga wokol ciebie." )
	}
}

public diablo_item_reset( id ){
	usedItem[ id ]	=	false;
}

public diablo_item_set_data( id ){
	usedItem[ id ]	=	false;
}

public diablo_copy_item( iFrom , iTo ){
	usedItem[ iFrom ]	=	false;
	usedItem[ iTo ]	=	false;
}

public diablo_item_skill_used( id ){
	if( usedItem[ id ] ){
		diablo_render_cancel( id );
		usedItem[ id ]	=	false;
	}
	else{
		usedItem[ id ]	=	true;

		if (find_ent_by_owner(-1,"Effect_Rot",id) > 0)
			return PLUGIN_CONTINUE
		
		new ent = Spawn_Ent("info_target");
		set_pev(ent,pev_classname,"Effect_Rot");
		set_pev(ent,pev_owner,id);
		set_pev(ent,pev_solid,SOLID_NOT);
		set_pev(ent,pev_nextthink, halflife_time() + 0.1);
		
		if(!(diablo_is_this_class(id,"Ninja")))
			diablo_set_user_render( id,kRenderFxGlowShell,255,255,0, kRenderFxNone, 10 , 0.2 );
		else
			diablo_set_user_render( id , .render = kRenderTransAlpha, .amount = 20);
	}
	
	return PLUGIN_CONTINUE
}

public Effect_Rot_Think(ent)
{
	if( !pev_valid( ent ) ){
		return PLUGIN_CONTINUE;
	}
	new id = pev(ent,pev_owner)
	
	if (!is_user_alive(id) || !usedItem[ id ] || diablo_is_freezetime() )
	{
		usedItem[ id ]	=	false;
		
		if(!(diablo_is_this_class(id,"Ninja")))
			diablo_render_cancel( id );
		
		diablo_reset_speed( id );
		
		diablo_display_icon( id,0,"dmg_bio",255,255,0 );
		
		remove_entity(ent);
		
		return PLUGIN_CONTINUE
	}
	
	diablo_reset_speed( id );
	
	diablo_add_speed(id, 15.0);
	
	diablo_display_icon( id,1,"dmg_bio",255,150,0 );
	
	if(!(diablo_is_this_class(id,"Ninja")))
		diablo_render_cancel( id );
	
	new entlist[512];
	new numfound = find_sphere_class(id,"player",250.0,entlist,511);
	
	for (new i=0; i < numfound; i++)
	{		
		new pid = entlist[i];
			
		if (pid == id || !is_user_alive(pid))
			continue;
			
		if (get_user_team(id) == get_user_team(pid))
			continue;
		
		if (random_num(1, 2) == 1) diablo_display_fade(id,1<<14,1<<14,1<<16,255,155,50,230);
		
		diablo_damage(pid, id, 45.0, diabloDamageKnife);
		
		Effect_Bleed(pid, 100);
		
		Create_Slow(pid, 3);
	}
	
	diablo_damage(id, id, 10.0, diabloDamageKnife);
		
	set_pev(ent,pev_nextthink, halflife_time() + 0.8);
	return PLUGIN_CONTINUE;
}

stock Create_Slow(id,seconds)
{		
	new ent = Spawn_Ent("info_target");
	set_pev(ent,pev_classname,"Effect_Slow");
	set_pev(ent,pev_owner,id);
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1);
	set_pev(ent,pev_solid,SOLID_NOT);
	set_pev(ent,pev_nextthink, halflife_time() + 0.1);
}

public Effect_Slow_Think(ent)
{
	new id = pev(ent,pev_owner)
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		diablo_display_icon( id,0,"dmg_heat",255,255,0 );
		
		diablo_reset_speed( id );
		
		remove_entity(ent);
		
		return PLUGIN_CONTINUE;
	}
	
	diablo_reset_speed( id );
	
	diablo_add_speed(id, -50.0);
	
	diablo_display_icon( id,1,"dmg_heat",255,255,0 );
	
	set_pev(ent,pev_nextthink, halflife_time() + 1.0);
	
	return PLUGIN_CONTINUE;
}

stock Spawn_Ent(const classname[]) 
{
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classname));
	set_pev(ent, pev_origin, {0.0, 0.0, 0.0});    
	dllfunc(DLLFunc_Spawn, ent);
	return ent;
}

stock Effect_Bleed(id,color)
{
	new origin[3];
	get_user_origin(id,origin);
	
	new dx, dy, dz;
	
	for(new i = 0; i < 3; i++) 
	{
		dx = random_num(-15,15);
		dy = random_num(-15,15);
		dz = random_num(-20,25);
		
		for(new j = 0; j < 2; j++) 
		{
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
			write_byte(TE_BLOODSPRITE);
			write_coord(origin[0]+(dx*j));
			write_coord(origin[1]+(dy*j));
			write_coord(origin[2]+(dz*j));
			write_short(sprite_blood_spray);
			write_short(sprite_blood_drop);
			write_byte(color); // color index
			write_byte(8); // size
			message_end();
		}
	}
}