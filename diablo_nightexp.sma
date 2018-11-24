#include <amxmodx>
#include <amxmisc>
#include <colorchat>

#define PLUGIN "DiabloMod: Night Exp"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define minut(%1) ((%1)*60.0)

new pcvarFromHour,
     pcvarToHour;

#define MULTIPLIER 2

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)

	pcvarFromHour = register_cvar("diablo_nightexp_from", "24");
	pcvarToHour = register_cvar("diablo_nightexp_to", "8");

	register_concmd("diablo_nightexp", "NightExp", ADMIN_BAN);
}

public plugin_cfg(){
	set_task(1.0, "NightExp");
}

public NightExp()
{
	new timestr[3];

	get_time("%H", timestr, 2);
	new currentHour = str_to_num(timestr);

	new bool:active;

	new fromHour = get_pcvar_num(pcvarFromHour),
	     toHour = get_pcvar_num(pcvarToHour);

	if(fromHour > toHour)
	{
		if(currentHour >= fromHour || currentHour < toHour)
			active = true;
	}
	else
	{
		if(currentHour >= fromHour && currentHour < toHour)
			active = true;
	}

	if(active)
	{
		server_cmd("diablo_dmg_exp %i;wait;diablo_xpbonus %i;wait;diablo_xpbonus2 %i", get_cvar_num("diablo_dmg_exp") * MULTIPLIER, get_cvar_num("diablo_xpbonus") * MULTIPLIER , get_cvar_num("diablo_xpbonus2") * MULTIPLIER );
		server_exec();
		return;
	}

	get_time("%M", timestr, 2);
	new minute = str_to_num(timestr);

	set_task(minut(60-minute), "NightExp");
}
