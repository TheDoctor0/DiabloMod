/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fun>
#include <stripweapons>

#include <diablo_nowe.inc>

#define PLUGIN "Ninja"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

new NINJA_VIEW[]       = "models/diablomod/v_ninja.mdl"

new bool:bKlasa[33];
new speed[33];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_class("Ninja",140,"<br>Na starcie posiada: 140HP.<br>Jest prawie niewidoczny, szybki, wysoko skacze.<br>Moze chodzic tylko z nozem.<br>Umiejetnosc ladowana na nozu: Dodatkowa predkosc.<br><br>");
	
	RegisterHam(Ham_Touch, "weaponbox", "HamTouchPre", 0) 
	RegisterHam(Ham_Touch, "armoury_entity", "HamTouchPre", 0) 
	
	register_clcmd("cl_setautobuy","ninjablock")
	register_clcmd("cl_autobuy","ninjablock")
	register_clcmd("cl_setrebuy","ninjablock")
	register_clcmd("cl_rebuy","ninjablock")
	register_clcmd("buy","ninjablock")
	register_clcmd("fn57","ninjablock")
	register_clcmd("m3","ninjablock")
	register_clcmd("autoshotgun","ninjablock")
	register_clcmd("mac10","ninjablock")
	register_clcmd("tmp","ninjablock")
	register_clcmd("mp5","ninjablock")
	register_clcmd("ump45","ninjablock")
	register_clcmd("p90","ninjablock")
	register_clcmd("galil","ninjablock")
	register_clcmd("ak47","ninjablock")
	register_clcmd("scout","ninjablock")
	register_clcmd("sg552","ninjablock")
	register_clcmd("awp","ninjablock")
	register_clcmd("g3sg1","ninjablock")
	register_clcmd("famas","ninjablock")
	register_clcmd("m4a1","ninjablock")
	register_clcmd("bullpup","ninjablock")
	register_clcmd("sg550","ninjablock")
	register_clcmd("m249","ninjablock")
	register_clcmd("shield","ninjablock")
	register_clcmd("primammo","ninjablock")
	register_clcmd("nvgs","ninjablock")
	register_clcmd("nvgs","ninjablock")
	register_clcmd("p228","ninjablock")
	register_clcmd("elite","ninjablock")
	register_clcmd("fiveseven","ninjablock")
	register_clcmd("usp","ninjablock")
	register_clcmd("glock18","ninjablock")
	register_clcmd("deagle","ninjablock")
	register_clcmd("shield","ninjablock")
	register_clcmd("hegrenade","ninjablock")
	register_clcmd("smokegrenade","ninjablock")
	register_clcmd("flashbang","ninjablock")
	register_clcmd("weapon_sg550", "ninjablock")
	register_clcmd("weapon_mac10", "ninjablock")
	register_clcmd("weapon_aug", "ninjablock")
	register_clcmd("weapon_xm1014", "ninjablock")
	register_clcmd("weapon_p90", "ninjablock")
	register_clcmd("weapon_tmp", "ninjablock")
	register_clcmd("weapon_mp5navy", "ninjablock")
	register_clcmd("weapon_ump45", "ninjablock")
	register_clcmd("weapon_m4a1", "ninjablock")
	register_clcmd("weapon_awp", "ninjablock")
	register_clcmd("weapon_g3sg1", "ninjablock")
	register_clcmd("weapon_sg552", "ninjablock")
	register_clcmd("weapon_scout", "ninjablock")
	register_clcmd("weapon_m3", "ninjablock")
	register_clcmd("weapon_m249", "ninjablock")
	register_clcmd("weapon_ak47", "ninjablock")
	register_clcmd("weapon_p228", "ninjablock")
	register_clcmd("weapon_elite", "ninjablock")
	register_clcmd("weapon_fiveseven", "ninjablock")
	register_clcmd("weapon_usp", "ninjablock")
	register_clcmd("weapon_glock18", "ninjablock")
	register_clcmd("weapon_deagle", "ninjablock")
	register_clcmd("weapon_shield", "ninjablock")
	register_clcmd("weapon_hegrenade", "ninjablock")
	register_clcmd("weapon_flashbang", "ninjablock")
	register_clcmd("weapon_smokegrenade", "ninjablock")
}

public HamTouchPre(weapon, id) 
{
	if(!pev_valid(weapon) || !is_user_alive(id) || !bKlasa[id])
		return HAM_IGNORED;
	
	new name[20];
	pev(weapon, pev_model, name, 19);
	if(containi(name, "w_backpack") != -1)
		return HAM_IGNORED;

	return HAM_SUPERCEDE;
}

public ninjablock(id)
{
	if(bKlasa[id])
		return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}

public diablo_class_disabled(id){
	bKlasa[id]	=	false;
}

public diablo_class_enabled(id){
	bKlasa[id]	=	true;
	diablo_class_spawned(id);
}

public diablo_set_data(id){
	speed[id]	=	0;
	diablo_set_user_render(id,.render = kRenderTransAlpha,.amount = 10);
}

public diablo_clean_data(id){
	speed[id]	=	0;
	diablo_set_user_render(id,.render = kRenderTransAlpha,.amount = 255);
}

public plugin_precache(){
	precache_model(NINJA_VIEW);
}

public diablo_weapon_deploy(id,wpnID,weaponEnt){
	if(bKlasa[id] && wpnID != CSW_C4 && wpnID != CSW_KNIFE){
		client_cmd(id,"weapon_knife")
		engclient_cmd(id,"weapon_knife")
		StripWeapons( id , Primary )
		StripWeapons( id , Secondary )
		StripWeapons( id , Grenades )
	}
	
	if(bKlasa[id] && wpnID == CSW_KNIFE){
		entity_set_string(id, EV_SZ_viewmodel, NINJA_VIEW) 
	}
}

public Float:diablo_cast_time(id,Float:standardTime){
	return standardTime * 2.0;
}

public diablo_call_cast(id){
	set_hudmessage(60, 200, 25, -1.0, 0.25, 0, 1.0, 2.0, 0.1, 0.2, 2)
	speed[id]++
	if(speed[id]>4)
	{
		speed[id]=4
		show_hudmessage(id, "Osiagnales limit predkosci")  
	}
	else {
		show_hudmessage(id, "Zwiekszyles sobie tymczasowo predkosc")  
		diablo_add_speed( id, 25.0 );
	}
}

public diablo_class_spawned(id){
	if(!bKlasa[id])
		return PLUGIN_CONTINUE;
		
	StripWeapons( id , Primary );
	StripWeapons( id , Secondary );
	StripWeapons( id , Grenades );
	
	diablo_add_user_grav( id , -0.65 );
	
	diablo_set_knife( id , 5 + floatround ( float(diablo_get_user_int(id))/10.0 , floatround_floor ))
	
	diablo_set_user_render( id , .render = kRenderTransAlpha, .amount = 10 );
	
	return PLUGIN_CONTINUE
}
