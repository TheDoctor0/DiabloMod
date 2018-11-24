#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <hamsandwich>

#include <diablo_nowe.inc>

#define PLUGIN	"Techies scepter"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new bool:bUsed[ 33 ]
new sprite_blast;
new const Mine[] = "models/mine.mdl"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Berlo Technokraty" , 250 );
	
	register_touch("mine", "player",  "TouchMine");

	register_event("HLTV", "NowaRunda", "a", "1=0", "2=0");
}

public plugin_precache()
{
	precache_model(Mine);
	sprite_blast = precache_model("sprites/dexplo.spr");
}

public client_disconnect(id)
{
	new entMiny = find_ent_by_class(0, "mine");
	while(entMiny > 0)
	{
		if(entity_get_edict(entMiny, EV_ENT_owner) == id)
			remove_entity(entMiny);
		entMiny = find_ent_by_class(entMiny, "mine");
	}
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Uzyj, zeby polozyc niewidzialna mine" )
}

public diablo_item_set_data( id ){
	bUsed[ id ]		=	false;
}

public diablo_copy_item( iFrom , iTo ){
	bUsed[ iFrom ]		=	bUsed[ iTo ];
}

public diablo_item_reset( id ){
	bUsed[ id ]		=	false;
}

public diablo_item_player_spawned( id ){
	bUsed[ id ]		=	false;
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Uzyj, zeby polozyc niewidzialna mine")
	}
	else{
		formatex( szMessage , iLen , "Uzyj, zeby polozyc niewidzialna mine" )
	}
}

public diablo_item_skill_used( id ){
	if (bUsed[ id ]){
		diablo_show_hudmsg(id, 2.0,"Tego przedmiotu mozesz uzyc raz na runde") 
		return PLUGIN_HANDLED
	}
	
	new Float:origin[3];
	entity_get_vector(id, EV_VEC_origin, origin);

	new ent = create_entity("info_target");
	entity_set_string(ent ,EV_SZ_classname, "mine");
	entity_set_edict(ent ,EV_ENT_owner, id);
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_TOSS);
	entity_set_origin(ent, origin);
	entity_set_int(ent, EV_INT_solid, SOLID_BBOX);

	entity_set_model(ent, Mine);
	entity_set_size(ent,Float:{-16.0,-16.0,0.0},Float:{16.0,16.0,2.0});

	drop_to_floor(ent);

	set_rendering(ent,kRenderFxNone, 0,0,0, kRenderTransTexture,0);
	
	bUsed[ id ] = true;

	return PLUGIN_HANDLED
}

public TouchMine(ent, id)
{
	if(!is_valid_ent(ent))
		return;

	new attacker = entity_get_edict(ent, EV_ENT_owner);
	if (get_user_team(attacker) != get_user_team(id))
	{
		new Float:fOrigin[3];
		entity_get_vector( ent, EV_VEC_origin, fOrigin);

		new iOrigin[3];
		for(new i=0;i<3;i++)
			iOrigin[i] = floatround(fOrigin[i]);

		message_begin(MSG_BROADCAST,SVC_TEMPENTITY, iOrigin);
		write_byte(TE_EXPLOSION);
		write_coord(iOrigin[0]);
		write_coord(iOrigin[1]);
		write_coord(iOrigin[2]);
		write_short(sprite_blast);
		write_byte(32);
		write_byte(20);
		write_byte(0);
		message_end();

		new entlist[33];
		new numfound = find_sphere_class(ent,"player", 90.0 ,entlist, 32);

		for (new i=0; i < numfound; i++)
		{
			new pid = entlist[i];

			if (!is_user_alive(pid) || get_user_team(attacker) == get_user_team(pid))
				continue;

			ExecuteHam(Ham_TakeDamage, pid, attacker, attacker, 75.0, 1);
		}
		remove_entity(ent);
	}
}

public NowaRunda()
{
	new entMiny = find_ent_by_class(-1, "mine");
	while(entMiny > 0)
	{
		remove_entity(entMiny);
		entMiny = find_ent_by_class(entMiny, "mine");
	}
}