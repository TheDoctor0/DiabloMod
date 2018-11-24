/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <cstrike>
#include <engine>

#include <diablo_nowe.inc>

#define PLUGIN "Barbazynca"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

stock const maxClip[31] = { -1, 13, -1, 10,  1,  7,  1,  30, 30,  1,  30,  20,  25, 30, 35, 25,  12,  20,
	10,  30, 100,  8, 30,  30, 20,  2,  7, 30, 30, -1,  50 };

// max bpammo
stock const maxAmmo[31] = { -1, 52, -1, 90, -1, 32, -1, 100, 90, -1, 120, 100, 100, 90, 90, 90, 100, 100,
	30, 120, 200, 32, 90, 120, 60, -1, 35, 90, 90, -1, 100 }

new bool:bKlasa[33],ultra_armor[33]

new BARBARZYNCA_VIEW[]       = "models/diablomod/v_barbarzynca.mdl"

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_class("Barbarzynca",110,"<br>Na starcie posiada: 110 HP.<br>Zabijajac wroga dostaje dodatkowy magazynek i 10 HP.<br>Umiejetnosc ladowana na nozu: Pancerz, dajacy odpornosc na trafienia.<br><br>")
	
	register_event("DeathMsg", "DeathMsg", "a")
	
	register_forward(FM_TraceLine,"fw_traceline");
}

public Float:diablo_cast_time(id,Float:standardTime){
	return standardTime*1.1;
}

public diablo_set_data(id){
	ultra_armor[id]	=	0;
}

public diablo_clean_data(id){
	ultra_armor[id]	=	0;
}

public fw_traceline(Float:vecStart[3],Float:vecEnd[3],ignoreM,id,trace) // pentToSkip == id, for clarity
{
	if(!is_user_connected(id) || !is_user_alive(id))
		return FMRES_IGNORED;

	new hit = get_tr2(trace, TR_pHit)	
	
	if(!(pev(id,pev_button) & IN_ATTACK))
		return FMRES_IGNORED;
		
	if(is_user_alive(hit) && get_user_team(id) != get_user_team(hit))
	{
		if( ultra_armor[hit]>0 )
		{
			ultra_armor[hit]--
			set_tr2(trace, TR_iHitgroup, 8)
		}
		return FMRES_IGNORED
	}
	
	return FMRES_IGNORED;
}

public diablo_call_cast(id){
	set_hudmessage(60, 200, 25, -1.0, 0.25, 0, 1.0, 2.0, 0.1, 0.2, 2)
	ultra_armor[id]++
	if(ultra_armor[id] > 7)
	{
		show_hudmessage(id, "Maksymalna wartosc pancerza to 7", ultra_armor[id]) 
	}
	else 
		show_hudmessage(id, "Magiczny pancerz wytrzyma %i strzalow", ultra_armor[id]) 

}

public DeathMsg(){
	new iKiller = read_data(1)
	
	if(is_user_alive(iKiller) && bKlasa[iKiller]){
		diablo_add_hp(iKiller,10);
		refill_ammo(iKiller);
		//cs_set_user_armor(iKiller, min(get_user_armor(iKiller)+100,200), CS_ARMOR_VESTHELM)
	}
}

public diablo_class_spawned(id){	
	if(bKlasa[id])
		diablo_add_speed(id,-15.0);
}

public diablo_class_disabled(id){
	bKlasa[id]	=	false;
}

public diablo_class_enabled(id){
	bKlasa[id]	=	true;
}

public plugin_precache(){
	precache_model(BARBARZYNCA_VIEW);
}

public diablo_weapon_deploy(id,wpnID,weaponEnt){
	if(bKlasa[id] && wpnID == CSW_KNIFE){
		entity_set_string(id, EV_SZ_viewmodel, BARBARZYNCA_VIEW) 
	}
}

stock refill_ammo(id)
{	
	new wpnid
	if(!is_user_alive(id) || pev(id,pev_iuser1)) return;
	
	new wpn[32],clip,ammo
	wpnid = get_user_weapon(id, clip, ammo)
	get_weaponname(wpnid,wpn,31)

	new wEnt;
	
	// set clip ammo
	wpnid = get_weaponid(wpn)
	//wEnt = get_weapon_ent(id,wpnid);
	wEnt = get_weapon_ent(id,wpnid);
	cs_set_weapon_ammo(wEnt,maxClip[wpnid]);

}

stock get_weapon_ent(id,wpnid=0,wpnName[]="")
{
	// who knows what wpnName will be
	static newName[32];

	// need to find the name
	if(wpnid) get_weaponname(wpnid,newName,31);

	// go with what we were told
	else formatex(newName,31,"%s",wpnName);

	// prefix it if we need to
	if(!equal(newName,"weapon_",7))
	format(newName,31,"weapon_%s",newName);

	new ent;
	while((ent = engfunc(EngFunc_FindEntityByString,ent,"classname",newName)) && pev(ent,pev_owner) != id) {}

	return ent;
}