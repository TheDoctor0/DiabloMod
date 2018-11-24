#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <hamsandwich>

#include <diablo_nowe.inc>

#define PLUGIN	"Totem amulet"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iRange[ 33 ], bool:bUsedItem[ 33 ], bool:iFire[ 33 ], sprite_ignite, sprite_smoke, sprite_white, bool:freeze_ended, g_msg_statusicon;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Totem Ognia" , 250 );
	
	register_event("Damage", "Damage", "b", "2!0")
	
	register_think("Effect_Ignite_Totem", "Effect_Ignite_Totem_Think")
	
	register_think("Effect_Ignite", "Effect_Ignite_Think")
	
	g_msg_statusicon = get_user_msgid("StatusIcon")
	
	register_logevent("PoczatekRundy", 2, "1=Round_Start")
}

public plugin_precache(){
	precache_model( "models/diablomod/totem_ignite.mdl" )
	
	sprite_ignite = precache_model("sprites/flame.spr")
	
	sprite_smoke = precache_model("sprites/steam1.spr")
	
	sprite_white = precache_model("sprites/white.spr") 
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Uzyj, aby polozyc wybuchowy totem ognia")
}

public diablo_item_reset( id ){
	iRange[ id ]			=	0;
	bUsedItem[ id ]		=	false;
}

public diablo_item_set_data( id ){
	iRange[ id ]			=	random_num( 250 , 400 );
	bUsedItem[ id ]		=	false;
}

public diablo_copy_item( iFrom , iTo ){
	iRange[ iTo ]	=	iRange[ iFrom ];
	iRange[ iFrom ]	=	0;
	bUsedItem[ iFrom ]	=	false;
	bUsedItem[ iTo ]	=	false;
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Uzyj, aby polozyc wybuchowy totem ognia")
	}
	else{
		formatex( szMessage , iLen , "Uzyj, aby polozyc wybuchowy totem ognia")
	}
}

public diablo_upgrade_item( id ){
	iRange[ id ] += random_num( 0 , 50 );
}

public diablo_item_player_spawned( id ){
	bUsedItem[ id ]		=	false;
}

public diablo_item_skill_used( id ){
	if( bUsedItem[ id ] ){
		
		diablo_show_hudmsg( id,2.0,"Ognistego Totemu mozesz uzyc raz na runde!" )
		
		return PLUGIN_CONTINUE
	}
	
	bUsedItem[id] = true
	
	new origin[3]
	pev(id,pev_origin,origin)
	
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Ignite_Totem")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_solid,SOLID_TRIGGER)
	set_pev(ent,pev_origin,origin)
	set_pev(ent,pev_ltime, halflife_time() + 7.0 + 0.1)
	
	engfunc(EngFunc_SetModel, ent, "models/diablomod/totem_ignite.mdl")  	
	set_rendering ( ent, kRenderFxGlowShell, 250,150,0, kRenderFxNone, 255 ) 	
	engfunc(EngFunc_DropToFloor,ent)
	
	set_pev(ent,pev_euser3,0)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
	
	return PLUGIN_CONTINUE
	
}

public PoczatekRundy()
{
	freeze_ended = true
	
	for(new i=1; i<=32; i++)
		iFire[i] = false
}

public Effect_Ignite_Totem_Think(ent)
{
	//Safe check because effect on death
	if (!freeze_ended)
		remove_entity(ent)
	
	if (!is_valid_ent(ent))
		return PLUGIN_CONTINUE
	
	new id = pev(ent,pev_owner)
	
	//Apply and destroy
	if (pev(ent,pev_euser3) == 1)
	{
		new entlist[513]
		new numfound = find_sphere_class(ent,"player",iRange[id]+0.0,entlist,512)
		
		for (new i=0; i < numfound; i++)
		{		
			new pid = entlist[i]
			
			//This totem can hit the caster
			if (pid == id && is_user_alive(id))
			{
				Effect_Ignite(pid,id,4)
				diablo_show_hudmsg( id,5.0,"Palisz sie. Strzel do kogos, aby przestac sie palic!")
				continue
			}
			
			if (!is_user_alive(pid) || get_user_team(id) == get_user_team(pid))
				continue
			
			//Dextery makes the fire damage less
			if (diablo_get_user_dex(pid) > 20)
				Effect_Ignite(pid,id,1)
			else if (diablo_get_user_dex(pid) > 15)
				Effect_Ignite(pid,id,2)
			else if (diablo_get_user_dex(pid) > 10)
				Effect_Ignite(pid,id,3)
			else
				Effect_Ignite(pid,id,4)
			
			diablo_show_hudmsg( id,5.0,"Palisz sie. Strzel do kogos, aby przestac sie palic!")
		}
		
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time())
	{
		set_pev(ent,pev_euser3,1)
		
		//Show animation and die
		
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
		write_coord( origin[1] + iRange[id]);
		write_coord( origin[2] + iRange[id]);
		write_short( sprite_white );
		write_byte( 0 ); // startframe
		write_byte( 0 ); // framerate
		write_byte( 10 ); // life
		write_byte( 10 ); // width
		write_byte( 255 ); // noise
		write_byte( 150 ); // r, g, b
		write_byte( 150 ); // r, g, b
		write_byte( 0 ); // r, g, b
		write_byte( 128 ); // brightness
		write_byte( 5 ); // speed
		message_end();
		
		set_pev(ent,pev_nextthink, halflife_time() + 0.2)
		
	}
	else	
	{
		set_pev(ent,pev_nextthink, halflife_time() + 1.5)
	}
	
	return PLUGIN_CONTINUE
}

stock Spawn_Ent(const classname[]) 
{
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classname))
	set_pev(ent, pev_origin, {0.0, 0.0, 0.0})    
	dllfunc(DLLFunc_Spawn, ent)
	return ent
}

stock Effect_Ignite(id,attacker,damage)
{
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Ignite")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + 99 + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)
	set_pev(ent,pev_euser1,attacker)
	set_pev(ent,pev_iuser2,damage)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
	
	iFire[id] = true
}

public Effect_Ignite_Think(ent)
{
	new id = pev(ent,pev_owner)
	new attacker = pev(ent,pev_euser1)
	new damage = pev(ent,pev_iuser2)
	
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id) || !iFire[id])
	{
		iFire[id] = false
		Remove_All_Tents(id)
		Display_Icon(id ,0 ,"dmg_heat" ,200,0,0)
		
		remove_entity(ent)		
		return PLUGIN_CONTINUE
	}
	
	
	//Display ignite tent and icon
	Display_Tent(id,sprite_ignite,2)
	Display_Icon(id ,1 ,"dmg_heat" ,200,0,0)
	
	new origin[3]
	get_user_origin(id,origin)
	
	//Make some burning effects
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( TE_SMOKE ) // 5
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_short( sprite_smoke )
	write_byte( 22 )  // 10
	write_byte( 10 )  // 10
	message_end()
	
	//Decals
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( TE_GUNSHOTDECAL ) // decal and ricochet sound
	write_coord( origin[0] ) //pos
	write_coord( origin[1] )
	write_coord( origin[2] )
	write_short (0) // I have no idea what thats supposed to be
	write_byte (random_num(199,201)) //decal
	message_end()
	
	
	//Do the actual damage
	new Float:dmg = float(damage)
	ExecuteHam(Ham_TakeDamage, id, attacker, attacker, dmg, DMG_BURN);
	
	set_pev(ent,pev_nextthink, halflife_time() + 1.5)
	
	
	return PLUGIN_CONTINUE
}

stock Display_Icon(id ,enable ,name[] ,red,green,blue)
{
	if (!pev_valid(id) || is_user_bot(id))
		return PLUGIN_HANDLED
	
	message_begin( MSG_ONE, g_msg_statusicon, {0,0,0}, id ) 
	write_byte( enable ) 	
	write_string( name ) 
	write_byte( red ) // red 
	write_byte( green ) // green 
	write_byte( blue ) // blue 
	message_end()
	
	return PLUGIN_CONTINUE
}

stock Display_Tent(id,sprite, seconds)
{
	message_begin(MSG_ALL,SVC_TEMPENTITY)
	write_byte(TE_PLAYERATTACHMENT)
	write_byte(id)
	write_coord(40) //Offset
	write_short(sprite)
	write_short(seconds*10)
	message_end()
}

stock Remove_All_Tents(id)
{
	message_begin(MSG_ALL ,SVC_TEMPENTITY) //message begin
	write_byte(TE_KILLPLAYERATTACHMENTS)
	write_byte(id) // entity index of player
	message_end()
}

public Damage(id)
{
	if (is_user_connected(id))
	{
		new weapon
		new bodypart
		
		if(get_user_attacker(id,weapon,bodypart)!=0)
		{
			new damage = read_data(2)
			new attacker_id = get_user_attacker(id,weapon,bodypart) 
			if (is_user_connected(attacker_id) && attacker_id != id && damage > 0)
			{
				if (iFire[attacker_id])
					iFire[attacker_id] = false
			}
		}
	}
}