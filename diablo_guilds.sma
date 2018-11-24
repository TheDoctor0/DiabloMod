#include <amxmodx>
#include <hamsandwich>
#include <fun>
#include <sqlx>
#include <colorchat>
#include <diablo_nowe.inc>

#define PLUGIN "Diablo Guilds"
#define VERSION "1.1"
#define AUTHOR "O'Zone"

#define Set(%2,%1)	(%1 |= (1<<(%2&31)))
#define Rem(%2,%1)	(%1 &= ~(1 <<(%2&31)))
#define Get(%2,%1)	(%1 & (1<<(%2&31)))

#define MAX_PLAYERS 32

enum _:GuildInfo
{
	NAME[64],
	PASSWORD[32],
	LEVEL,
	BANK,
	SPEED,
	EXP,
	DAMAGE,
	HEALTH,
	KILLS,
	MEMBERS,
	Trie:STATUS,
};

enum
{
	NONE = 0,
	MEMBER,
	DEPUTY,
	LEADER
};

new const szCommandGuild[][] = { "say /guild", "say_team /guild", "say /guilds", "say_team /guilds", "say /gildie", "say_team /gildie", "say /gildia", "say_team /gildia", "gildia" };

new const szFile[] = "diablo_guilds.ini";

new iLevelCost, iNextLevelCost, iSpeedCost, iNextSpeedCost, iExpCost, iNextExpCost, iDamageCost, iNextDamageCost, iHealthCost, iNextHealthCost;
new iLevelMax, iSpeedMax, iExpMax, iDamageMax, iHealthMax;
new iMembersPerLevel, iSpeedPerLevel, iExpPerLevel, iDamagePerLevel, iHealthPerLevel;
new iCreateLevel, iMaxMembers;

new szMemberName[MAX_PLAYERS + 1][64], szChosenName[MAX_PLAYERS + 1][64];

new iGuild[MAX_PLAYERS + 1], iChosenID[MAX_PLAYERS + 1];

new iPassword;

new szCache[512], szMessage[2048];

new Handle:hSqlTuple;

new Array:gGuilds;

native diablo_force_password(id);
native diablo_check_password(id);

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_cvar("diablo_guilds_host", "sql.pukawka.pl", FCVAR_SPONLY|FCVAR_PROTECTED); 
	register_cvar("diablo_guilds_user", "509049", FCVAR_SPONLY|FCVAR_PROTECTED); 
	register_cvar("diablo_guilds_pass", "Vd1hRq0EKCe6Mt3", FCVAR_SPONLY|FCVAR_PROTECTED); 
	register_cvar("diablo_guilds_db", "509049_diablomod", FCVAR_SPONLY|FCVAR_PROTECTED); 
	
	for(new i; i < sizeof szCommandGuild; i++)
		register_clcmd(szCommandGuild[i], "GuildMenu");

	register_clcmd("Nazwa", "CmdCreateGuild");
	register_clcmd("UstawHaslo", "CmdSetPassword");
	register_clcmd("PodajHaslo", "CmdCheckPassword");
	register_clcmd("NowaNazwa", "CmdChangeName");
	register_clcmd("IloscExpa", "CmdDonate");
	
	register_event("DeathMsg", "DeathMsg", "a");
	
	register_message(get_user_msgid("SayText"), "HandleSayText");
	
	RegisterHam(Ham_Spawn, "player", "PlayerSpawn", 1);
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage", 0);
	
	gGuilds = ArrayCreate(GuildInfo);
	
	new aGuild[GuildInfo];
	
	aGuild[NAME] = "Brak";
	aGuild[LEVEL] = 0;
	aGuild[BANK] = 0;
	aGuild[SPEED] = 0;
	aGuild[EXP] = 0;
	aGuild[HEALTH] = 0;
	aGuild[DAMAGE] = 0;
	aGuild[PASSWORD] = 0;
	aGuild[MEMBERS] = 0;
	aGuild[STATUS] = _:TrieCreate();
	
	ArrayPushArray(gGuilds, aGuild);
	
	SqlInit();
	ConfigLoad();
}

public plugin_natives()
{
	register_native("diablo_get_user_guild", "getGuild");
	register_native("diablo_get_guild_name", "getGuildName" , 1);
}

public plugin_end()
{
	SQL_FreeHandle(hSqlTuple);
	ArrayDestroy(gGuilds);
}

public client_putinserver(id)
{
	iGuild[id] = 0;
	LoadMember(id);
}

public client_disconnect(id)
{
	Rem(id, iPassword);
	iGuild[id] = 0;
}

public diablo_player_spawned(id)
{
	new aGuild[GuildInfo];
	ArrayGetArray(gGuilds, iGuild[id], aGuild);
	
	diablo_add_max_hp(id, aGuild[HEALTH] * iHealthPerLevel);
}

public PlayerSpawn(id)
{
	if(!is_user_alive(id) || !iGuild[id])
		return HAM_IGNORED;

	new aGuild[GuildInfo];
	ArrayGetArray(gGuilds, iGuild[id], aGuild);
	
	if(equal(aGuild[PASSWORD], "") && get_user_status(id, iGuild[id]) == LEADER)
	{
		ColorChat(id, GREEN, "[DiabloMod]^x01 Nie wpisano hasla zarzadzania gildia. Wpisz je teraz!");
		client_cmd(id, "messagemode UstawHaslo");
	}
	
	diablo_add_speed(id, aGuild[SPEED] * iSpeedPerLevel * 1.0);
	
	return HAM_IGNORED;
}

public TakeDamage(iVictim, iInflictor, iAttacker, Float:Damage, iBits)
{
	if(!is_user_alive(iAttacker) || !is_user_connected(iVictim))
		return HAM_IGNORED;
	
	if(get_user_team(iVictim) == get_user_team(iAttacker) || !iGuild[iAttacker])
		return HAM_IGNORED;
	
	new aGuild[GuildInfo];
	ArrayGetArray(gGuilds, iGuild[iAttacker], aGuild);
	
	if(aGuild[DAMAGE])
		SetHamParamFloat(4, Damage + (iDamagePerLevel*(aGuild[DAMAGE])));
	
	return HAM_IGNORED;
}

public DeathMsg()
{
	new iKiller = read_data(1);
	
	if(!is_user_alive(iKiller) || !iGuild[iKiller])
		return PLUGIN_CONTINUE;
	
	new aGuild[GuildInfo];
	ArrayGetArray(gGuilds, iGuild[iKiller], aGuild);
	
	aGuild[KILLS]++;
	ArraySetArray(gGuilds, iGuild[iKiller], aGuild);
	
	diablo_add_xp(iKiller, aGuild[EXP] * iExpPerLevel);
	
	SaveGuild(iGuild[iKiller]);
	
	return PLUGIN_CONTINUE;
}

public GuildMenu(id)
{	
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
		
	if(!diablo_check_password(id))
	{
		diablo_force_password(id);
		return PLUGIN_HANDLED;
	}
	
	client_cmd(id, "spk DiabloMod/select");
	
	new aGuild[GuildInfo], szMenu[128], menu;
	
	new callback = menu_makecallback("GuildMenu_Callback");
	
	if(iGuild[id])
	{
		ArrayGetArray(gGuilds, iGuild[id], aGuild);
		
		formatex(szMenu, charsmax(szMenu), "\wMenu \rGildii^n\wAktualna Gildia:\y %s^n\w(Czlonkowie: \y%i/%i\w | Skarbiec: \y%i Expa\w)", aGuild[NAME], aGuild[MEMBERS], aGuild[LEVEL]*iMembersPerLevel+iMaxMembers, aGuild[BANK]);
		
		menu = menu_create(szMenu, "GuildMenu_Handler");
		
		if(get_user_status(id, iGuild[id]) > MEMBER)
			menu_additem(menu, "\wZarzadzaj \yGildia", _, _, callback);
		else 
		{
			formatex(szMenu, charsmax(szMenu), "\wZaloz \yGildie \r(Wymagany %i Poziom)", iCreateLevel);
			menu_additem(menu, szMenu, _, _, callback);
		}
	}
	else
	{
		menu = menu_create("\wMenu \rGildii^n\wAktualna Gildia:\y Brak", "GuildMenu_Handler");
		formatex(szMenu, charsmax(szMenu), "\wZaloz \yGildie \r(Wymagany %i Poziom)", iCreateLevel);
		menu_additem(menu, szMenu);
	}

	menu_additem(menu, "\wOpusc \yGildie", _, _, callback);
	menu_additem(menu, "\wCzlonkowie \yGildii", _, _, callback);
	menu_additem(menu, "\wUmiejetnosci \yGildii", _, _, callback);
	menu_additem(menu, "\wWplac \yExp", _, _, callback);
	menu_additem(menu, "\wLista \yWplat", _, _, callback);
	menu_additem(menu, "\wTop15 \yGildii", _, _, callback);
	
	menu_setprop(menu, MPROP_NOCOLORS, 1);
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\r");
	
	menu_setprop(menu, MPROP_EXITNAME, "\wWyjdz");
	
	menu_display(id, menu);
	
	return PLUGIN_CONTINUE;
}

public GuildMenu_Callback(id, menu, item)
{
	switch(item)
	{
		case 0: return get_user_status(id, iGuild[id]) > MEMBER ? ITEM_ENABLED : ITEM_DISABLED;
		case 1, 2, 3, 4, 5: return iGuild[id] ? ITEM_ENABLED : ITEM_DISABLED;
	}
	return ITEM_ENABLED;
}

public GuildMenu_Handler(id, menu, item)
{
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE;
		
	client_cmd(id, "spk DiabloMod/select");
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	switch(item)
	{
		case 0: 
		{
			if(get_user_status(id, iGuild[id]) > MEMBER)
			{
				ShowLeaderMenu(id);
				return PLUGIN_HANDLED;
			}
			
			if(iGuild[id])
			{
				ColorChat(id, GREEN, "[DiabloMod]^x01 Nie mozesz utworzyc gildii, jesli juz w niej jestes!");
				return PLUGIN_HANDLED;
			}
			
			if(diablo_get_user_level(id) < iCreateLevel)
			{
				ColorChat(id, GREEN, "[DiabloMod]^x01 Nie masz wystarczajacego poziomu, aby zalozyc Gildie (Wymagany:^x03 %i^x01 poziom)!", iCreateLevel);
				return PLUGIN_HANDLED;
			}
			
			client_cmd(id, "messagemode Nazwa");
		}
		case 1: ShowLeaveConfirmMenu(id);
		case 2: ShowMembersMenu(id, 0);
		case 3: ShowSkillsMenu(id, 0);
		case 4: 
		{
			client_cmd(id, "messagemode IloscExpa");
			ColorChat(id, GREEN, "[DiabloMod]^x01 Wpisz ilosc Expa, ktora chcesz wplacic do skarbca.");
		}
		case 5: ShowDonations(id);
		case 6: GuildsTop15(id);
	}
	
	menu_destroy(menu);
	return PLUGIN_CONTINUE;
}

public CmdCreateGuild(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
		
	if(!diablo_check_password(id))
	{
		diablo_force_password(id);
		return PLUGIN_HANDLED;
	}
		
	if(iGuild[id])
	{
		ColorChat(id, GREEN, "[DiabloMod]^x01 Nie mozesz utworzyc gildii, jesli juz w niej jestes!");
		return PLUGIN_HANDLED;
	}
	
	if(diablo_get_user_level(id) < iCreateLevel)
	{
		ColorChat(id, GREEN, "[DiabloMod]^x01 Nie masz wystarczajacego poziomu, aby zalozyc Gildie (Wymagany:^x03 %i^x01 poziom)!", iCreateLevel);
		return PLUGIN_HANDLED;
	}
	
	new szName[64], szTempName[64];
	
	read_args(szName, charsmax(szName));
	remove_quotes(szName);
	
	if(equal(szName, ""))
	{
		ColorChat(id, GREEN, "[DiabloMod]^x01 Nie wpisano nazwy gildii!");
		GuildMenu(id);
		return PLUGIN_HANDLED;
	}
	
	mysql_escape_string(szName, szTempName, charsmax(szTempName));
	
	if(CheckGuildName(szTempName))
	{
		ColorChat(id, GREEN, "[DiabloMod]^x01 Gildia z taka nazwa juz istnieje!");
		GuildMenu(id);
		return PLUGIN_HANDLED;
	}
	
	new aGuild[GuildInfo];
	
	copy(aGuild[NAME], charsmax(aGuild[NAME]), szName);
	aGuild[LEVEL] = 0;
	aGuild[BANK] = 0;
	aGuild[SPEED] = 0;
	aGuild[EXP] = 0;
	aGuild[HEALTH] = 0;
	aGuild[DAMAGE] = 0;
	aGuild[PASSWORD] = 0;
	aGuild[MEMBERS] = 0;
	aGuild[STATUS] = _:TrieCreate();
	
	ArrayPushArray(gGuilds, aGuild);
	
	formatex(szCache, charsmax(szCache), "INSERT INTO `guilds` (`guild_name`) VALUES ('%s');", szTempName);
	SQL_ThreadQuery(hSqlTuple, "Table_Handle", szCache);
	
	set_user_guild(id, ArraySize(gGuilds) - 1, 1);
	set_user_status(id, ArraySize(gGuilds) - 1, LEADER);
	
	ColorChat(id, GREEN, "[DiabloMod]^x01 Gratulacje! Pomyslnie zalozyles gildie^x03 %s^01.", szName);
	ColorChat(id, GREEN, "[DiabloMod]^x01 Teraz wpisz haslo, ktore pozwoli ci na pozniejsze zarzadzanie gildia.");
	client_print(id, print_center, "Wpisz haslo pozwalajace zarzadzac gildia!");
	
	client_cmd(id, "messagemode UstawHaslo");
	
	return PLUGIN_HANDLED;
}

public CmdSetPassword(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
		
	if(!diablo_check_password(id))
	{
		diablo_force_password(id);
		return PLUGIN_HANDLED;
	}
	
	if(!iGuild[id])
	{
		ColorChat(id, GREEN, "[DiabloMod]^x01 Nie mozesz ustawic hasla, bo nie masz gildii!");
		return PLUGIN_HANDLED;
	}
	
	new szPassword[32];
	
	read_args(szPassword, charsmax(szPassword));
	remove_quotes(szPassword);
	
	if(equal(szPassword, ""))
	{
		ColorChat(id, GREEN, "[DiabloMod]^x01 Nie wpisano hasla zarzadzania gildia. Wpisz je teraz!");
		client_cmd(id, "messagemode UstawHaslo");
		return PLUGIN_HANDLED;
	}
	
	new aGuild[GuildInfo];
	ArrayGetArray(gGuilds, iGuild[id], aGuild);
	
	if(!equal(aGuild[PASSWORD], ""))
	{
		ColorChat(id, GREEN, "[DiabloMod]^x01 Nie mozesz ustawic hasla zarzadzania gildia, bo juz je masz!");
		GuildMenu(id);
		return PLUGIN_HANDLED;
	}
	
	copy(aGuild[PASSWORD], charsmax(aGuild[PASSWORD]), szPassword);
	ArraySetArray(gGuilds, iGuild[id], aGuild);
	
	SaveGuild(iGuild[id]);
	
	client_print(id, print_center, "Haslo zostalo ustawione!");
	ColorChat(id, GREEN, "[DiabloMod]^x01 Haslo zarzadzania gildia zostalo ustawione.");
	ColorChat(id, GREEN, "[DiabloMod]^x01 Wpisz w konsoli^x03 setinfo ^"_gildia^" ^"%s^"^x01.", szPassword);
	
	Set(id, iPassword);
	
	cmd_execute(id, "setinfo _gildia %s", szPassword);
	cmd_execute(id, "writecfg gildia");
	
	return PLUGIN_HANDLED;
}

public ShowLeaveConfirmMenu(id)
{
	if(!is_user_connected(id) || !iGuild[id])
		return PLUGIN_CONTINUE;
		
	client_cmd(id, "spk DiabloMod/select");
	
	new menu = menu_create("\wJestes \ypewien\w, ze chcesz \ropuscic \wgildie?", "LeaveConfirmMenu_Handler");
	
	menu_additem(menu, "Tak", "0");
	menu_additem(menu, "Nie^n", "1");
	
	menu_setprop(menu, MPROP_EXITNAME, "\wWyjdz");
	
	menu_display(id, menu, 0);
	return PLUGIN_CONTINUE;
}

public LeaveConfirmMenu_Handler(id, menu, item)
{
	if(!is_user_connected(id) || !iGuild[id])
		return PLUGIN_HANDLED;
		
	client_cmd(id, "spk DiabloMod/select");
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new szData[6], iAccess, iCallback;
	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), _, _, iCallback);
	
	new aGuild[GuildInfo];
	ArrayGetArray(gGuilds, iGuild[id], aGuild);
	
	switch(str_to_num(szData))
	{
		case 0: 
		{
			if(get_user_status(id, iGuild[id]) == LEADER)
			{
				ColorChat(id, GREEN, "[DiabloMod]^x01 Oddaj przywodctwo gildii jednemu z czlonkow zanim ja upuscisz.");
				GuildMenu(id);
				return PLUGIN_HANDLED;
			}
			
			set_user_guild(id);
			
			ColorChat(id, GREEN, "[DiabloMod]^x01 Opusciles swoja gildie.");
		}
	}
	
	GuildMenu(id);
	
	return PLUGIN_HANDLED;
}

public CmdCheckPassword(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
		
	if(!diablo_check_password(id))
	{
		diablo_force_password(id);
		return PLUGIN_HANDLED;
	}
	
	if(!iGuild[id] || get_user_status(id, iGuild[id]) < DEPUTY)
		return PLUGIN_HANDLED;
		
	new aGuild[GuildInfo];
	ArrayGetArray(gGuilds, iGuild[id], aGuild);
	
	if(equal(aGuild[PASSWORD], ""))
	{
		ColorChat(id, GREEN, "[DiabloMod]^x01 Twoja gildia nie ma hasla zarzadzania. Wpisz je teraz!");
		client_print(id, print_center, "Wpisz haslo pozwalajace zarzadzac gildia!");
		client_cmd(id, "messagemode UstawHaslo");
		return PLUGIN_HANDLED;
	}
	
	new szPassword[32];
	read_args(szPassword, charsmax(szPassword));
	
	remove_quotes(szPassword);
	
	if(equal(szPassword, ""))
	{
		ColorChat(id, GREEN, "[DiabloMod]^x01 Nie wpisales hasla zarzadzania gildia!");
		GuildMenu(id);
		return PLUGIN_HANDLED;
	}
	
	if(!equal(aGuild[PASSWORD], szPassword))
	{
		ColorChat(id, GREEN, "[DiabloMod]^x01 Podane haslo zarzadzania gildia jest nieprawidlowe!");
		GuildMenu(id);
		return PLUGIN_HANDLED;
	}
	
	Set(id, iPassword);
	
	ColorChat(id, GREEN, "[DiabloMod]^x01 Wpisane haslo jest prawidlowe.");
	
	ShowLeaderMenu(id);
	
	return PLUGIN_HANDLED;
}

public ShowLeaderMenu(id)
{
	if(Get(id, iPassword))
	{
		if(!is_user_connected(id) || !iGuild[id])
			return PLUGIN_CONTINUE;
		
		client_cmd(id, "spk DiabloMod/select");
	
		new menu = menu_create("\wZarzadzaj \rGildia", "LeaderMenu_Handler");
		
		new callback = menu_makecallback("LeaderMenu_Callback");

		menu_additem(menu, "\wRozwiaz \yGildie", _, _, callback);
		menu_additem(menu, "\wRozwin \yUmiejetnosci", _, _, callback);
		menu_additem(menu, "\wZapros \yGracza", _, _, callback);
		menu_additem(menu, "\wZarzadzaj \yCzlonkami", _, _, callback);
		menu_additem(menu, "\wZmien \yNazwe^n", _, _, callback);
		menu_additem(menu, "\wWroc", _, _, callback);
		
		menu_setprop(menu, MPROP_EXITNAME, "\wWyjdz");
	
		menu_display(id, menu, 0);
	}
	else
	{
		client_cmd(id, "messagemode PodajHaslo");
		ColorChat(id, GREEN, "[DiabloMod]^x01 Wpisz jednorazowo haslo zarzadzania gildia.");
		client_print(id, print_center, "Wpisz haslo zarzadzania gildia");
	}
	return PLUGIN_CONTINUE;
}

public LeaderMenu_Callback(id, menu, item)
{
	switch(item)
	{
		case 1: get_user_status(id, iGuild[id]) == LEADER ? ITEM_ENABLED : ITEM_DISABLED;
		case 2: 
		{
			new aGuild[GuildInfo];
			ArrayGetArray(gGuilds, iGuild[id], aGuild);
				
			if(((aGuild[LEVEL]*iMembersPerLevel) + iMaxMembers) <= aGuild[MEMBERS])
				return ITEM_DISABLED;
		}
	}
	return ITEM_ENABLED;
}

public LeaderMenu_Handler(id, menu, item)
{
	if(!is_user_connected(id) || !iGuild[id])
		return PLUGIN_HANDLED;
		
	client_cmd(id, "spk DiabloMod/select");
	
	if(item == MENU_EXIT)
	{
		GuildMenu(id);
		return PLUGIN_HANDLED;
	}
	
	switch(item)
	{
		case 0: ShowDisbandConfirmMenu(id);
		case 1: ShowSkillsMenu(id);
		case 2: ShowInviteMenu(id);
		case 3: ShowMembersMenu(id);
		case 4: client_cmd(id, "messagemode NowaNazwa");
		case 5: GuildMenu(id);
	}
	return PLUGIN_HANDLED;
}

public ShowDisbandConfirmMenu(id)
{
	if(!is_user_connected(id) || !iGuild[id])
		return PLUGIN_CONTINUE;
		
	client_cmd(id, "spk DiabloMod/select");
	
	new menu = menu_create("\wJestes \ypewien\w, ze chcesz \rrozwiazac\w gildie?", "DisbandConfirmMenu_Handler");
	
	menu_additem(menu, "Tak", "0");
	menu_additem(menu, "Nie^n", "1");
	
	menu_setprop(menu, MPROP_EXITNAME, "\wWyjdz");
	
	menu_display(id, menu, 0);
	return PLUGIN_CONTINUE;
}

public DisbandConfirmMenu_Handler(id, menu, item)
{
	if(!is_user_connected(id) || !iGuild[id])
		return PLUGIN_HANDLED;
		
	client_cmd(id, "spk DiabloMod/select");
	
	if(item == MENU_EXIT)
		return PLUGIN_HANDLED;
	
	new szData[6], iAccess, iCallback;
	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), _, _, iCallback);
	
	switch(str_to_num(szData))
	{
		case 0: 
		{
			new szTempName[64], iPlayers[32], aGuild[GuildInfo], iNum, iPlayer, iPlayerGuild;
			
			ArrayGetArray(gGuilds, iGuild[id], aGuild);
			
			get_players(iPlayers, iNum);
			
			for(new i = 0; i < iNum; i++)
			{
				iPlayer = iPlayers[i];
				
				if(iPlayer == id)
					continue;
				
				if(iGuild[id] != iGuild[iPlayer] || is_user_hltv(iPlayer) || !is_user_connected(iPlayer))
					continue;

				set_user_guild(iPlayer);
				
				ColorChat(iPlayer, GREEN, "[DiabloMod]^x01 Twoja gildia zostala rozwiazana.");
			}
			
			iPlayerGuild = iGuild[id];
			set_user_guild(id);
			
			ColorChat(id, GREEN, "[DiabloMod]^x01 Rozwiazales swoja gildie.");
			
			mysql_escape_string(aGuild[NAME], szTempName, charsmax(szTempName));
			
			formatex(szCache, charsmax(szCache), "DELETE FROM `guilds` WHERE guild_name = '%s'", szTempName);
			SQL_ThreadQuery(hSqlTuple, "Table_Handle", szCache);
			
			formatex(szCache, charsmax(szCache), "UPDATE `guild_members` SET flag = '0', guild = '', donated = '0' WHERE guild = '%s'", szTempName);
			SQL_ThreadQuery(hSqlTuple, "Table_Handle", szCache);
			
			ArrayDeleteItem(gGuilds, iPlayerGuild);
			
			GuildMenu(id);
		}
		case 1: GuildMenu(id);
	}
	return PLUGIN_HANDLED;
}

ShowSkillsMenu(id, management = 1)
{	
	if(!is_user_connected(id) || !iGuild[id])
		return PLUGIN_CONTINUE;
		
	client_cmd(id, "spk DiabloMod/select");
		
	new aGuild[GuildInfo];
	ArrayGetArray(gGuilds, iGuild[id], aGuild);
	
	new szMenu[128], menu;
	
	formatex(szMenu, charsmax(szMenu), "\wMenu \rUmiejetnosci^n\wSkarbiec Gildii: \y%i Expa", aGuild[BANK]);
	if(management)
	{
		menu = menu_create(szMenu, "SkillsMenu_Handler");
	
		formatex(szMenu, charsmax(szMenu), "Poziom Gildii \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", aGuild[LEVEL], iLevelMax, iLevelCost+iNextLevelCost*aGuild[LEVEL]);
		menu_additem(menu, szMenu);
		formatex(szMenu, charsmax(szMenu), "Predkosc \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", aGuild[SPEED], iSpeedMax, iSpeedCost+iNextSpeedCost*aGuild[SPEED]);
		menu_additem(menu, szMenu);
		formatex(szMenu, charsmax(szMenu), "Doswiadczenie \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", aGuild[EXP], iExpMax, iExpCost+iNextExpCost*aGuild[EXP]);
		menu_additem(menu, szMenu);
		formatex(szMenu, charsmax(szMenu), "Obrazenia \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", aGuild[DAMAGE], iDamageMax, iDamageCost+iNextDamageCost*aGuild[DAMAGE]);
		menu_additem(menu, szMenu);
		formatex(szMenu, charsmax(szMenu), "Zdrowie \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", aGuild[HEALTH], iHealthMax, iHealthCost+iNextHealthCost*aGuild[HEALTH]);
		menu_additem(menu, szMenu);
	
		menu_setprop(menu, MPROP_NOCOLORS, 1);
		menu_setprop(menu, MPROP_NUMBER_COLOR, "\r");
	}
	else
	{
		menu = menu_create(szMenu, "SkillMenu_Handler");
	
		formatex(szMenu, charsmax(szMenu), "Poziom Gildii \w[\rLevel: \y%i/%i\w] [\yMasz o \r%i\y wiecej mozliwych czlonkow\w]", aGuild[LEVEL], iLevelMax, aGuild[LEVEL] * iMembersPerLevel);
		menu_additem(menu, szMenu);
		formatex(szMenu, charsmax(szMenu), "Predkosc \w[\rLevel: \y%i/%i\w] [\yMasz o \r%i%%\y szybszy bieg\w]", aGuild[SPEED], iSpeedMax, floatround(100.0 * aGuild[SPEED] * iSpeedPerLevel / 255.0));
		menu_additem(menu, szMenu);
		formatex(szMenu, charsmax(szMenu), "Doswiadczenie \w[\rLevel: \y%i/%i\w] [\yMasz o \r%i\y wiecej expa za zabojstwo\w]", aGuild[EXP], iExpMax, aGuild[EXP] * iExpPerLevel);
		menu_additem(menu, szMenu);
		formatex(szMenu, charsmax(szMenu), "Obrazenia \w[\rLevel: \y%i/%i\w] [\yMasz o \r%i\y wiecej obrazen z kazdej broni\w]", aGuild[DAMAGE], iDamageMax, aGuild[DAMAGE] * iDamagePerLevel);
		menu_additem(menu, szMenu);
		formatex(szMenu, charsmax(szMenu), "Zdrowie \w[\rLevel: \y%i/%i\w] [\yMasz o \r%i\y wiecej punktow zycia\w]", aGuild[HEALTH], iHealthMax, aGuild[HEALTH] * iHealthPerLevel);
		menu_additem(menu, szMenu);
	}
	
	menu_setprop(menu, MPROP_EXITNAME, "\wWyjdz");
	
	menu_display(id, menu);
	
	return PLUGIN_CONTINUE;
}

public SkillMenu_Handler(id, menu, item)
{
	if(!is_user_connected(id) || !iGuild[id])
		return PLUGIN_CONTINUE;
		
	client_cmd(id, "spk DiabloMod/select");
		
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		GuildMenu(id);
		return PLUGIN_CONTINUE;
	}
	
	ShowSkillsMenu(id, 0);
	
	return PLUGIN_CONTINUE;
}

public SkillsMenu_Handler(id, menu, item)
{
	if(!is_user_connected(id) || !iGuild[id])
		return PLUGIN_CONTINUE;
		
	client_cmd(id, "spk DiabloMod/select");
		
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		GuildMenu(id);
		return PLUGIN_CONTINUE;
	}
	
	new aGuild[GuildInfo], iUpgraded;
	ArrayGetArray(gGuilds, iGuild[id], aGuild);
	
	switch(item)
	{
		case 0:
		{
			if(aGuild[LEVEL] == iLevelMax)
			{
				ColorChat(id, GREEN, "[DiabloMod]^x01 Twoja gildia ma juz maksymalny Poziom.");
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = aGuild[BANK] - (iLevelCost + iNextLevelCost*aGuild[LEVEL]);
			
			if(iRemaining < 0)
			{
				ColorChat(id, GREEN, "[DiabloMod]^x01 Twoja gildia nie ma wystarczajacej ilosci Expa.");
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			iUpgraded = 1;
			
			aGuild[LEVEL]++;
			aGuild[BANK] = iRemaining;
			
			ColorChat(id, GREEN, "[DiabloMod]^x01 Ulepszyles gildie na^x03 %i Poziom^x01!", aGuild[LEVEL]);
		}
		case 1:
		{
			if(aGuild[SPEED] == iSpeedMax)
			{
				ColorChat(id, GREEN, "[DiabloMod]^x01 Twoja gildia ma juz maksymalny poziom tej umiejetnosci.");
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = aGuild[BANK] - (iSpeedCost + iNextSpeedCost*aGuild[SPEED]);
			
			if(iRemaining < 0)
			{
				ColorChat(id, GREEN, "[DiabloMod]^x01 Twoja gildia nie ma wystarczajacej ilosci Expa.");
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			iUpgraded = 2;
			
			aGuild[SPEED]++;
			aGuild[BANK] = iRemaining;
			
			ColorChat(id, GREEN, "[DiabloMod]^x01 Ulepszyles umiejetnosc^x03 Predkosc^x01 na^x03 %i^x01 poziom!", aGuild[SPEED]);
		}
		case 2:
		{
			if(aGuild[EXP] == iExpMax)
			{
				ColorChat(id, GREEN, "[DiabloMod]^x01 Twoja gildia ma juz maksymalny poziom tej umiejetnosci.");
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = aGuild[BANK] - (iExpCost + iNextExpCost*aGuild[EXP]);
			
			if(iRemaining < 0)
			{
				ColorChat(id, GREEN, "[DiabloMod]^x01 Twoja gildia nie ma wystarczajacej ilosci Expa.");
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			iUpgraded = 3;
			
			aGuild[EXP]++;
			aGuild[BANK] = iRemaining;
			
			ColorChat(id, GREEN, "[DiabloMod]^x01 Ulepszyles umiejetnosc^x03 Doswiadczenie^x01 na^x03 %i^x01 poziom!", aGuild[EXP]);
		}
		case 3:
		{
			if(aGuild[DAMAGE] == iDamageMax)
			{
				ColorChat(id, GREEN, "[DiabloMod]^x01 Twoja gildia ma juz maksymalny poziom tej umiejetnosci.");
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = aGuild[BANK] - (iDamageCost + iNextDamageCost*aGuild[DAMAGE]);
			
			if(iRemaining < 0)
			{
				ColorChat(id, GREEN, "[DiabloMod]^x01 Twoja gildia nie ma wystarczajacej ilosci Expa.");
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			iUpgraded = 4;
			
			aGuild[DAMAGE]++;
			aGuild[BANK] = iRemaining;
			
			ColorChat(id, GREEN, "[DiabloMod]^x01 Ulepszyles umiejetnosc^x03 Obrazenia^x01 na^x03 %i^x01 poziom!", aGuild[DAMAGE]);
		}
		case 4:
		{
			if(aGuild[HEALTH] == iHealthMax)
			{
				ColorChat(id, GREEN, "[DiabloMod]^x01 Twoja gildia ma juz maksymalny poziom tej umiejetnosci.");
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = aGuild[BANK] - (iHealthCost + iNextHealthCost*aGuild[HEALTH]);
			
			if(iRemaining < 0)
			{
				ColorChat(id, GREEN, "[DiabloMod]^x01 Twoja gildia nie ma wystarczajacej ilosci Expa.");
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			iUpgraded = 5;
			
			aGuild[HEALTH]++;
			aGuild[BANK] = iRemaining;
			
			diablo_add_max_hp(id, iHealthPerLevel);
			
			ColorChat(id, GREEN, "[DiabloMod]^x01 Ulepszyles umiejetnosc^x03 Zdrowie^x01 na^x03 %i^x01 poziom!", aGuild[HEALTH]);
		}
	}
	
	ArraySetArray(gGuilds, iGuild[id], aGuild);
	
	new iPlayers[32], iNum, iPlayer, szName[32];
	
	get_players(iPlayers, iNum);
	get_user_name(id, szName, charsmax(szName));
	
	for(new i = 0 ; i < iNum; i++)
	{
		iPlayer = iPlayers[i];
		
		if(iPlayer == id || iGuild[iPlayer] != iGuild[id])
			continue;
		
		switch(iUpgraded)
		{
			case 1: ColorChat(iPlayer, GREEN, "[DiabloMod]^x01^x03 %s^x01 ulepszyl gildia na^x03 %i Poziom^x01!", szName, aGuild[LEVEL]);
			case 2: ColorChat(iPlayer, GREEN, "[DiabloMod]^x01^x03 %s^x01 ulepszyl umiejetnosc^x03 Predkosc^x01 na^x03 %i^x01 poziom!", szName, aGuild[SPEED]);
			case 3: ColorChat(iPlayer, GREEN, "[DiabloMod]^x01^x03 %s^x01 ulepszyl umiejetnosc^x03 Doswiadczenie^x01 na^x03 %i^x01 poziom!", szName, aGuild[EXP]);
			case 4: ColorChat(iPlayer, GREEN, "[DiabloMod]^x01^x03 %s^x01 ulepszyl umiejetnosc^x03 Obrazenia^x01 na^x03 %i^x01 poziom!", szName, aGuild[DAMAGE]);
			case 5: ColorChat(iPlayer, GREEN, "[DiabloMod]^x01^x03 %s^x01 ulepszyl umiejetnosc^x03 Zdrowie^x01 na^x03 %i^x01 poziom!", szName, aGuild[HEALTH]);
		}
	}
	
	SaveGuild(iGuild[id]);
	
	ShowSkillsMenu(id);
	
	return PLUGIN_HANDLED;
}

public ShowInviteMenu(id)
{	
	if(!is_user_connected(id) || !iGuild[id])
		return PLUGIN_CONTINUE;
		
	client_cmd(id, "spk DiabloMod/select");
	
	new szName[32], iPlayers[32], szInfo[6], iNum, iNumPlayers = 0;
	get_players(iPlayers, iNum);
	
	new menu = menu_create("\wWybierz \rGracza \wdo zaproszenia:", "InviteMenu_Handler");
	
	for(new i = 0, iPlayer; i < iNum; i++)
	{
		iPlayer = iPlayers[i];
		
		if(iPlayer == id || iGuild[iPlayer] == iGuild[id] || is_user_hltv(iPlayer) || !is_user_connected(iPlayer))
			continue;

		iNumPlayers++;
		
		get_user_name(iPlayer, szName, charsmax(szName));
		num_to_str(iPlayer, szInfo, charsmax(szInfo));
		menu_additem(menu, szName, szInfo);
	}	
	
	menu_display(id, menu, 0);
	
	if(!iNumPlayers)
	{
		menu_destroy(menu);
		ColorChat(id, GREEN, "[DiabloMod]^x01 Na serwerze nie ma gracza, ktorego moglbys zaprosic do gildii!");
	}
	return PLUGIN_CONTINUE;
}

public InviteMenu_Handler(id, menu, item)
{
	if(!is_user_connected(id) || !iGuild[id])
		return PLUGIN_CONTINUE;
		
	client_cmd(id, "spk DiabloMod/select");
	
	if(item == MENU_EXIT)
	{
		GuildMenu(id);
		return PLUGIN_HANDLED;
	}
	
	new szName[32], szData[6], iAccess, iCallback;
	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
	
	new iPlayer = str_to_num(szData);

	if(!is_user_connected(iPlayer))
		return PLUGIN_HANDLED;
	
	ShowInviteConfirmMenu(id, iPlayer);

	ColorChat(id, GREEN, "[DiabloMod]^x01 Zaprosiles %s do twojej gildii.", szName);
	
	GuildMenu(id);
	
	return PLUGIN_HANDLED;
}

public ShowInviteConfirmMenu(id, iPlayer)
{
	if(!is_user_connected(id) || !iGuild[id])
		return PLUGIN_CONTINUE;
		
	client_cmd(id, "spk DiabloMod/select");
	
	new szMenuTitle[128], szName[32], szInfo[6], aGuild[GuildInfo], menu;
	
	get_user_name(id, szName, charsmax(szName));
	
	ArrayGetArray(gGuilds, iGuild[id], aGuild);
	
	formatex(szMenuTitle, charsmax(szMenuTitle), "%s zaprosil cie do gildii %s", szName, aGuild[NAME]);
	
	menu = menu_create(szMenuTitle, "InviteConfirmMenu_Handler");
	
	num_to_str(iGuild[id], szInfo, charsmax(szInfo));
	
	menu_additem(menu, "Dolacz", szInfo);
	menu_additem(menu, "Odrzuc", "-1");
	
	menu_display(iPlayer, menu, 0);	
	return PLUGIN_CONTINUE;
}

public InviteConfirmMenu_Handler(id, menu, item)
{
	if(!is_user_connected(id) || iGuild[id])
		return PLUGIN_HANDLED;
		
	client_cmd(id, "spk DiabloMod/select");
	
	if(item == MENU_EXIT)
		return PLUGIN_HANDLED;
	
	new szData[6], iAccess, iCallback;
	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), _, _, iCallback);
	
	new iPlayerGuild = str_to_num(szData);
	
	if(!iPlayerGuild) return PLUGIN_HANDLED;
	
	if(get_user_status(id, iGuild[id]) == LEADER)
	{
		ColorChat(id, GREEN, "[DiabloMod]^x01 Nie mozesz dolaczyc do gildii, jesli jestes zalozycielem innej.");
		return PLUGIN_HANDLED;
	}
	
	new aGuild[GuildInfo];
	
	ArrayGetArray(gGuilds, iPlayerGuild, aGuild);
	
	if(((aGuild[LEVEL]*iMembersPerLevel) + iMaxMembers) <= aGuild[MEMBERS])
	{
		ColorChat(id, GREEN, "[DiabloMod]^x01 Niestety, w tej gildii nie ma juz wolnego miejsca.");
		return PLUGIN_HANDLED;
	}
	
	set_user_guild(id, iPlayerGuild);
	
	ColorChat(id, GREEN, "[DiabloMod]^x01 Dolaczyles do gildii^x03 %s^01.", aGuild[NAME]);
	
	return PLUGIN_HANDLED;
}

public CmdChangeName(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
		
	if(!diablo_check_password(id))
	{
		diablo_force_password(id);
		return PLUGIN_HANDLED;
	}
	
	if(!iGuild[id] || get_user_status(id, iGuild[id]) != LEADER)
		return PLUGIN_HANDLED;
	
	new szName[64], szTempName[64], szOldName[64];
	
	read_args(szName, charsmax(szName));
	remove_quotes(szName);
	
	if(equal(szName, ""))
	{
		ColorChat(id, GREEN, "[DiabloMod]^x01 Nie wpisano nowej nazwy gildii.");
		GuildMenu(id);
		return PLUGIN_HANDLED;
	}
	
	mysql_escape_string(szName, szTempName, charsmax(szTempName));
	
	if(CheckGuildName(szTempName))
	{
		ColorChat(id, GREEN, "[DiabloMod]^x01 Gildia z taka nazwa juz istnieje.");
		GuildMenu(id);
		return PLUGIN_HANDLED;
	}
	
	new aGuild[GuildInfo];
	ArrayGetArray(gGuilds, iGuild[id], aGuild);
	
	mysql_escape_string(aGuild[NAME], szOldName, charsmax(szOldName));
	
	copy(aGuild[NAME], charsmax(aGuild[NAME]), szName);
	ArraySetArray(gGuilds, iGuild[id], aGuild);
	
	formatex(szCache, charsmax(szCache), "UPDATE `guild_members` SET guild = '%s' WHERE guild = '%s'", szTempName, szOldName);
	SQL_ThreadQuery(hSqlTuple, "Table_Handle", szCache);
	
	formatex(szCache, charsmax(szCache), "UPDATE `guilds` SET guild_name = '%s' WHERE guild_name = '%s'", szTempName, szOldName);
	SQL_ThreadQuery(hSqlTuple, "Table_Handle", szCache);
	
	ColorChat(id, GREEN, "[DiabloMod]^x01 Zmieniles nazwe gildii na^x03 %s^x01.", aGuild[NAME]);
	
	return PLUGIN_CONTINUE;
}

ShowMembersMenu(id, management = 1)
{
	if(!is_user_connected(id) || !iGuild[id])
		return PLUGIN_CONTINUE;
		
	client_cmd(id, "spk DiabloMod/select");
	
	new szTempName[64], szData[2], aGuild[GuildInfo];
	
	ArrayGetArray(gGuilds, iGuild[id], aGuild);
	
	mysql_escape_string(aGuild[NAME], szTempName, charsmax(szTempName));
	
	szData[0] = id;
	szData[1] = management;
	
	formatex(szCache, charsmax(szCache), "SELECT * FROM `guild_members` WHERE guild = '%s' ORDER BY flag DESC", szTempName);
	SQL_ThreadQuery(hSqlTuple, "MembersMenuHandler", szCache, szData, 2);
	
	return PLUGIN_CONTINUE;
}

public MembersMenuHandler(iFailState, Handle:hQuery, szError[], iError, szData[], iDataSize)
{
	if(iFailState != TQUERY_SUCCESS)
	{
		log_to_file("addons/amxmodx/logs/diablo_guilds.log", "<Query> Error: %s", szError);
		return;
	}

	new szName[33], szInfo[64], iStatus, menu, id = szData[0];
	
	if(szData[1])
		menu = menu_create("\wZarzadzaj \rCzlonkami:^n\rWybierz czlonka, aby pokazac mozliwe opcje.", "MemberMenu_Handler");
	else
		menu = menu_create("\wCzlonkowie \rGildii:", "MembersMenu_Handler");

	while(SQL_MoreResults(hQuery))
	{
		SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "name"), szName, charsmax(szName));
		iStatus = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "flag"));
		
		formatex(szInfo, charsmax(szInfo), "%s#%i", szName, iStatus);
		
		if(get_user_index(szName))
			add(szName, charsmax(szName), " \r[Online]");

		switch(iStatus)
		{
			case MEMBER: add(szName, charsmax(szName), " \y[Czlonek]");
			case DEPUTY: add(szName, charsmax(szName), " \y[Zastepca]");
			case LEADER: add(szName, charsmax(szName), " \y[Przywodca]");
		}
		
		menu_additem(menu, szName, szInfo);
		SQL_NextRow(hQuery);
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepne");
	menu_setprop(menu, MPROP_EXITNAME, "\wWyjdz");
	
	menu_display(id, menu, 0);
}

public MembersMenu_Handler(id, menu, item)
{
	if(!is_user_connected(id) || !iGuild[id])
		return PLUGIN_CONTINUE;

	client_cmd(id, "spk DiabloMod/select");
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		GuildMenu(id);
		return PLUGIN_HANDLED;
	}
	
	ShowMembersMenu(id, 0);
	
	return PLUGIN_HANDLED;
}

public MemberMenu_Handler(id, menu, item)
{
	if(!is_user_connected(id) || !iGuild[id])
		return PLUGIN_HANDLED;
		
	client_cmd(id, "spk DiabloMod/select");
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		GuildMenu(id);
		return PLUGIN_HANDLED;
	}
	
	new szInfo[64], szName[33], szTempFlag[2], iAccess, iCallback, iFlag, iID;
	menu_item_getinfo(menu, item, iAccess, szInfo, charsmax(szInfo), _, _, iCallback);
	
	menu_destroy(menu);

	strtok(szInfo, szName, charsmax(szName), szTempFlag, charsmax(szTempFlag), '#');
	
	iFlag = str_to_num(szTempFlag);
	iID = get_user_index(szName);

	if(iID == id)
	{
		ColorChat(id, GREEN, "[DiabloMod]^x01 Nie mozesz zarzadzac soba!");
		ShowMembersMenu(id);
		return PLUGIN_HANDLED;
	}
	
	if(iGuild[iID])	
		iChosenID[id] = get_user_userid(iID);

	if(iFlag == LEADER)
	{
		ColorChat(id, GREEN, "[DiabloMod]^x01 Nie mozna zarzadzac przywodca gildii!");
		ShowMembersMenu(id);
		return PLUGIN_HANDLED;
	}

	formatex(szChosenName[id], charsmax(szChosenName), szName);
	
	new menu = menu_create("\wWybierz \rOpcje:", "MemberOption_Handler");
	
	if(get_user_status(id, iGuild[id]) == LEADER)
	{
		menu_additem(menu, "Przekaz \yPrzywodctwo", "1");
		
		if(iFlag == MEMBER)
			menu_additem(menu, "Mianuj \yZastepce", "2");

		if(iFlag == DEPUTY)
			menu_additem(menu, "Degraduj \yZastepce", "3");
	}
	menu_additem(menu, "Wyrzuc \yGracza", "4");
	
	menu_setprop(menu, MPROP_EXITNAME, "\wWyjdz");
	
	menu_display(id, menu, 0);
	
	return PLUGIN_CONTINUE;
}

public MemberOption_Handler(id, menu, item)
{
	if(!is_user_connected(id) || !iGuild[id])
		return PLUGIN_HANDLED;
		
	client_cmd(id, "spk DiabloMod/select");
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		GuildMenu(id);
		return PLUGIN_HANDLED;
	}
	
	new szInfo[3], iAccess, iCallback;
	menu_item_getinfo(menu, item, iAccess, szInfo, charsmax(szInfo), _, _, iCallback);

	switch(str_to_num(szInfo))
	{
		case 1: UpdateMember(id, LEADER);
		case 2:	UpdateMember(id, DEPUTY);
		case 3:	UpdateMember(id, MEMBER);
		case 4: UpdateMember(id, NONE);
	}
	
	menu_destroy(menu);
	
	return PLUGIN_CONTINUE;
}

public UpdateMember(id, status)
{
	new iPlayers[32], iNum, iPlayer, bool:bPlayerOnline;
	
	get_players(iPlayers, iNum);

	for(new i = 0; i < iNum; i++)
	{
		iPlayer = iPlayers[i];

		if(iGuild[iPlayer] != iGuild[id] || is_user_hltv(iPlayer) || !is_user_connected(iPlayer))
			continue;
	
		if(get_user_userid(iPlayer) == iChosenID[id])
		{
			switch(status)
			{
				case LEADER:
				{
					set_user_status(id, iGuild[id], DEPUTY);
					set_user_status(iPlayer, iGuild[id], LEADER);
					ColorChat(iPlayer, GREEN, "[DiabloMod]^x01 Zostales mianowany przywodca gildii!");
				}
				case DEPUTY:
				{
					set_user_status(iPlayer, iGuild[id], DEPUTY);
					ColorChat(iPlayer, GREEN, "[DiabloMod]^x01 Zostales zastepca przywodcy gildii!");		
				}
				case MEMBER:
				{
					set_user_status(iPlayer, iGuild[id], MEMBER);
					ColorChat(iPlayer, GREEN, "[DiabloMod]^x01 Zostales zdegradowany do rangi czlonka gildii.");
				}
				case NONE:
				{
					set_user_guild(iPlayer);
					ColorChat(iPlayer, GREEN, "[DiabloMod]^x01 Zostales wyrzucony z gildii.");
				}
			}

			bPlayerOnline = true;
			continue;
		}
		
		switch(status)
		{
			case LEADER: ColorChat(iPlayer, GREEN, "[DiabloMod]^x03 %s^01 zostal nowym przywodca gildii.", szChosenName[id]);
			case DEPUTY: ColorChat(iPlayer, GREEN, "[DiabloMod]^x03 %s^x01 zostal zastepca przywodcy gildii.", szChosenName[id]);
			case MEMBER: ColorChat(iPlayer, GREEN, "[DiabloMod]^x03 %s^x01 zostal zdegradowany do rangi czlonka gildii.", szChosenName[id]);
			case NONE: ColorChat(iPlayer, GREEN, "[DiabloMod]^x03 %s^01 zostal wyrzucony z gildii.", szChosenName[id]);
		}
	}
	
	if(!bPlayerOnline)
	{
		new TempName[64];
		mysql_escape_string(szChosenName[id], TempName, charsmax(TempName));
		
		SaveMember(id, status, TempName);
		
		if(status == NONE)
		{
			new aGuild[GuildInfo];
			ArrayGetArray(gGuilds, iGuild[id], aGuild);
			
			aGuild[MEMBERS]--;
			ArraySetArray(gGuilds, iGuild[id], aGuild);
			
			SaveGuild(iGuild[id]);
		}
	}
	
	GuildMenu(id);
	
	return PLUGIN_HANDLED;
}

public CmdDonate(id)
{
	if(!is_user_connected(id) || !iGuild[id])
		return PLUGIN_HANDLED;
		
	if(!diablo_check_password(id))
	{
		diablo_force_password(id);
		return PLUGIN_HANDLED;
	}
	
	new szArgs[10], aGuild[GuildInfo], iDonated;
	
	ArrayGetArray(gGuilds, iGuild[id], aGuild);
	
	read_args(szArgs, charsmax(szArgs));
	remove_quotes(szArgs);
	iDonated = str_to_num(szArgs);
	
	if(!iDonated)
	{
		ColorChat(id, GREEN, "[DiabloMod]^x01 Probujesz wplacic ujemna lub zerowa ilosc Expa!");
		return PLUGIN_HANDLED;
	}
	
	if(iDonated > (diablo_get_user_exp(id) - diablo_get_level_exp(id)))
	{
		ColorChat(id, GREEN, "[DiabloMod]^x01 Nie masz tyle Expa!");
		return PLUGIN_HANDLED;
	}
	
	diablo_take_xp(id, iDonated);
	
	aGuild[BANK] += iDonated;
	ArraySetArray(gGuilds, iGuild[id], aGuild);
	
	SaveGuild(iGuild[id]);
	SaveMember(id, _, _, _, iDonated);
	
	ColorChat(id, GREEN, "[DiabloMod]^x01 Wplaciles^x03 %i^x01 Expa na rzecz gildii.", iDonated);
	ColorChat(id, GREEN, "[DiabloMod]^x01 Aktualnie twoj gildia ma^x03 %i^x01 Expa w skarbcu.", aGuild[BANK]);
	
	return PLUGIN_HANDLED;
}

public ShowDonations(id)
{
	new szTemp[512], szData[1];
	szData[0] = id;
	
	format(szTemp, charsmax(szTemp), "SELECT name, donated FROM `guild_members` a JOIN `guilds` b ON a.guild = b.guild_name ORDER BY donated DESC");
	SQL_ThreadQuery(hSqlTuple, "ShowDonations_Handle", szTemp, szData, 1);
}

public ShowDonations_Handle(iFailState, Handle:hQuery, szError[], iError, szData[], iDataSize)
{
	if(iFailState) 
	{
		log_to_file("addons/amxmodx/logs/diablo_guilds.log", "SQL Error: %s (%d)", szError, iError);
		return PLUGIN_HANDLED;
	}
	
	new iLen, iPlace = 0, id = szData[0];
	
	iLen = format(szMessage, charsmax(szMessage), "<body bgcolor=#000000><font color=#FFB000><pre>");
	iLen += format(szMessage[iLen], charsmax(szMessage) - iLen, "%1s %-22.22s %8s^n", "#", "Nick", "Wplaty");
	
	while(SQL_MoreResults(hQuery))
	{
		iPlace++;
		
		static szName[32], iDonated;
		
		SQL_ReadResult(hQuery, 0, szName, charsmax(szName));
		replace_all(szName, charsmax(szName), "<", "");
		replace_all(szName,charsmax(szName), ">", "");
		
		iDonated = SQL_ReadResult(hQuery, 1);
		
		if(iPlace >= 10)
			iLen += format(szMessage[iLen], charsmax(szMessage) - iLen, "%1i %22.22s %5d^n", iPlace, szName, iDonated);
		else
			iLen += format(szMessage[iLen], charsmax(szMessage) - iLen, "%1i %22.22s %6d^n", iPlace, szName, iDonated);

		SQL_NextRow(hQuery);
	}
	
	show_motd(id, szMessage, "Wplaty na rzecz Gildii");
	
	GuildMenu(id);
	
	return PLUGIN_HANDLED;
}

public GuildsTop15(id)
{
	new szTemp[512], szData[1];
	szData[0] = id;
	
	format(szTemp, charsmax(szTemp), "SELECT guild_name, members, bank, kills, level, speed, exp, health, damage FROM `guilds` ORDER BY kills DESC LIMIT 15");
	SQL_ThreadQuery(hSqlTuple, "ShowGuildsTop15_Handle", szTemp, szData, 1);
}

public ShowGuildsTop15_Handle(iFailState, Handle:hQuery, szError[], iError, szData[], iDataSize)
{
	if(iFailState) 
	{
		log_to_file("addons/amxmodx/logs/diablo_guilds.log", "SQL Error: %s (%d)", szError, iError);
		return PLUGIN_HANDLED;
	}
	
	new iLen, iPlace = 0, id = szData[0];
	
	iLen = format(szMessage, charsmax(szMessage), "<body bgcolor=#000000><font color=#FFB000><pre>");
	iLen += format(szMessage[iLen], charsmax(szMessage) - iLen, "%1s %-22.22s %4s %8s %9s %8s %9s %12s %8s^n", "#", "Nazwa", "Czlonkowie", "Poziom", "Zabicia", "Bank", "Predkosc", "Doswiadczenie", "Zdrowie", "Obrazenia");
	
	while(SQL_MoreResults(hQuery))
	{
		iPlace++;
		
		static szName[32], iMembers, iLevel, iKills, iBank, iSpeed, iExp, iHealth, iDamage;
		
		SQL_ReadResult(hQuery, 0, szName, charsmax(szName));
		replace_all(szName, charsmax(szName), "<", "");
		replace_all(szName,charsmax(szName), ">", "");
		
		iMembers = SQL_ReadResult(hQuery, 1);
		iBank = SQL_ReadResult(hQuery, 2);
		iKills = SQL_ReadResult(hQuery, 3);
		iLevel = SQL_ReadResult(hQuery, 4);
		iSpeed = SQL_ReadResult(hQuery, 5);
		iExp = SQL_ReadResult(hQuery, 6);
		iHealth = SQL_ReadResult(hQuery, 7);
		iDamage = SQL_ReadResult(hQuery, 8);
		
		if(iPlace >= 10)
			iLen += format(szMessage[iLen], charsmax(szMessage) - iLen, "%1i %22.22s %5d %8d %9d %9d %8d %11d %10d^n", iPlace, szName, iMembers, iLevel, iKills, iBank, iSpeed, iExp, iHealth, iDamage);
		else
			iLen += format(szMessage[iLen], charsmax(szMessage) - iLen, "%1i %22.22s %6d %8d %9d %9d %8d %11d %10d^n", iPlace, szName, iMembers, iLevel, iKills, iBank, iSpeed, iExp, iHealth, iDamage);

		SQL_NextRow(hQuery);
	}
	
	show_motd(id, szMessage, "Top 15 Gildii");
	
	GuildMenu(id);
	
	return PLUGIN_HANDLED;
}

public HandleSayText(msgId, msgDest, msgEnt)
{
	new id = get_msg_arg_int(1);
	
	if(!is_user_connected(id) || !iGuild[id])
		return PLUGIN_CONTINUE;
	
	new szTmp[192], szTmp2[192], szPrefix[20], aGuild[GuildInfo], i = iGuild[id];
	
	get_msg_arg_string(2, szTmp, charsmax(szTmp))

	ArrayGetArray(gGuilds, i, aGuild);
	
	formatex(szPrefix, charsmax(szPrefix), "^x04[%s]", aGuild[NAME]);
	
	if(!equal(szTmp, "#Cstrike_Chat_All"))
	{
		add(szTmp2, charsmax(szTmp2), szPrefix);
		add(szTmp2, charsmax(szTmp2), " ");
		add(szTmp2, charsmax(szTmp2), szTmp);
	}
	else
	{
		add(szTmp2, charsmax(szTmp2), szPrefix);
		add(szTmp2, charsmax(szTmp2), "^x03 %s1^x01 :  %s2");
	}
	
	set_msg_arg_string(2, szTmp2);
	
	return PLUGIN_CONTINUE;
}

set_user_guild(id, iPlayerGuild = 0, iOwner = 0)
{
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE;

	new aGuild[GuildInfo];
	
	if(iPlayerGuild == 0)
	{
		ArrayGetArray(gGuilds, iGuild[id], aGuild);
		aGuild[MEMBERS]--;
		ArraySetArray(gGuilds, iGuild[id], aGuild);
		TrieDeleteKey(aGuild[STATUS], szMemberName[id]);
		
		SaveGuild(iGuild[id]);
		
		SaveMember(id, NONE);
		
		Rem(id, iPassword);
		
		iGuild[id] = 0;
	}
	else
	{
		iGuild[id] = iPlayerGuild;
		
		ArrayGetArray(gGuilds, iGuild[id], aGuild);
		
		new szTempName[64];
		mysql_escape_string(aGuild[NAME], szTempName, charsmax(szTempName));
		
		aGuild[MEMBERS]++;
		ArraySetArray(gGuilds, iGuild[id], aGuild);
		TrieSetCell(aGuild[STATUS], szMemberName[id], iOwner ? LEADER : MEMBER);
		
		SaveMember(id, iOwner ? LEADER : MEMBER, _, szTempName);
		
		SaveGuild(iGuild[id]);
	}
	
	return PLUGIN_CONTINUE;
}

set_user_status(id, iPlayerGuild, iStatus)
{
	if(!is_user_connected(id) || !iPlayerGuild)
		return PLUGIN_CONTINUE;
		
	new aGuild[GuildInfo];
	ArrayGetArray(gGuilds, iPlayerGuild, aGuild);
	TrieSetCell(aGuild[STATUS], szMemberName[id], iStatus);
	
	SaveMember(id, iStatus);
	
	return PLUGIN_CONTINUE;
}

get_user_status(id, iPlayerGuild)
{
	if(!is_user_connected(id) || iPlayerGuild == 0)
		return NONE;
	
	new aGuild[GuildInfo];
	ArrayGetArray(gGuilds, iPlayerGuild, aGuild);
	
	new iStatus;
	TrieGetCell(aGuild[STATUS], szMemberName[id], iStatus);
	
	return iStatus;
}

public SqlInit()
{
	new szData[4][64];
	get_cvar_string("diablo_guilds_host", szData[0], charsmax(szData[])); 
	get_cvar_string("diablo_guilds_user", szData[1], charsmax(szData[])); 
	get_cvar_string("diablo_guilds_pass", szData[2], charsmax(szData[])); 
	get_cvar_string("diablo_guilds_db", szData[3], charsmax(szData[])); 
	
	hSqlTuple = SQL_MakeDbTuple(szData[0], szData[1], szData[2], szData[3]);
	
	formatex(szCache, charsmax(szCache), "CREATE TABLE IF NOT EXISTS `guilds` (`guild_name` varchar(64) NOT NULL, `password` varchar(64) NOT NULL, `members` int(5) NOT NULL DEFAULT '1', `bank` int(5) NOT NULL DEFAULT '0', `kills` int(5) NOT NULL DEFAULT '0', ");
	add(szCache, charsmax(szCache), "`level` int(5) NOT NULL DEFAULT '0', `speed` int(5) NOT NULL DEFAULT '0', `exp` int(5) NOT NULL DEFAULT '0', `damage` int(5) NOT NULL DEFAULT '0', `health` int(5) NOT NULL DEFAULT '0', PRIMARY KEY (`guild_name`));");
	SQL_ThreadQuery(hSqlTuple, "Table_Handle", szCache);
	
	formatex(szCache, charsmax(szCache), "CREATE TABLE IF NOT EXISTS `guild_members` (`name` varchar(64) NOT NULL, `guild` varchar(64) NOT NULL, `flag` int(5) NOT NULL DEFAULT '0', `donated` int(10) NOT NULL DEFAULT '0', PRIMARY KEY (`name`));");
	SQL_ThreadQuery(hSqlTuple, "Table_Handle", szCache);
}

public Table_Handle(iFailState, Handle:hQuery, szError[], iError, szData[], iDataSize)
{
	if(iFailState)
	{
		if(iFailState == TQUERY_CONNECT_FAILED)
			log_to_file("addons/amxmodx/logs/diablo_guilds.log", "Table - Could not connect to SQL database.  [%d] %s", iError, szError);
		else if(iFailState == TQUERY_QUERY_FAILED)
			log_to_file("addons/amxmodx/logs/diablo_guilds.log", "Table Query failed. [%d] %s", iError, szError);

		return;
	}
}

public SaveGuild(iGuild)
{
	new szTempName[64], aGuild[GuildInfo];
	
	ArrayGetArray(gGuilds, iGuild, aGuild);

	mysql_escape_string(aGuild[NAME], szTempName, charsmax(szTempName));
	
	formatex(szCache, charsmax(szCache), "UPDATE `guilds` SET password = '%s', level = '%i', bank = '%i', kills = '%i', members = '%i', speed = '%i', exp = '%i', health = '%i', damage = '%i' WHERE guild_name = '%s'", 
	aGuild[PASSWORD], aGuild[LEVEL], aGuild[BANK], aGuild[KILLS], aGuild[MEMBERS], aGuild[SPEED], aGuild[EXP], aGuild[HEALTH], aGuild[DAMAGE], szTempName);
	SQL_ThreadQuery(hSqlTuple, "Table_Handle", szCache);
}

public LoadMember(id)
{
	if(!is_user_connected(id))
		return;

	get_user_name(id, szMemberName[id], charsmax(szMemberName));
	mysql_escape_string(szMemberName[id], szMemberName[id], charsmax(szMemberName));
	
	new szData[1];
	szData[0] = id;
	
	formatex(szCache, charsmax(szCache), "SELECT * FROM `guild_members` a JOIN `guilds` b ON a.guild = b.guild_name WHERE a.name = '%s'", szMemberName[id]);
	SQL_ThreadQuery(hSqlTuple, "LoadMember_Handle", szCache, szData, 1);
}

SaveMember(id, iStatus = 0, szName[] = "", szGuild[] = "", iDonated = 0)
{
	if(!iGuild[id])
		return;
	
	if(iDonated)
		formatex(szCache, charsmax(szCache), "UPDATE `guild_members` SET donated = donated + %i WHERE name = '%s'", iDonated, szMemberName[id]);
	else if(iStatus)
	{
		if(strlen(szGuild))
			formatex(szCache, charsmax(szCache), "UPDATE `guild_members` SET guild = '%s', flag = '%i' WHERE name = '%s'", szGuild, iStatus, szMemberName[id]);
		else
			formatex(szCache, charsmax(szCache), "UPDATE `guild_members` SET flag = '%i' WHERE name = '%s'", iStatus, !strlen(szName) ? szMemberName[id] : szName);
	}
	else
		formatex(szCache, charsmax(szCache), "UPDATE `guild_members` SET guild = '', flag = '0', donated = '0' WHERE name = '%s'", !strlen(szName) ? szMemberName[id] : szName);

	SQL_ThreadQuery(hSqlTuple, "Table_Handle", szCache);
}

public LoadMember_Handle(iFailState, Handle:hQuery, szError[], iError, szData[], iDataSize)
{
	if(iFailState != TQUERY_SUCCESS)
	{
		log_to_file("addons/amxmodx/logs/diablo_guilds.log", "<Query> Error: %s", szError);
		return;
	}
	
	new id = szData[0];
	
	if(!is_user_connected(id))
		return;
	
	if(SQL_NumResults(hQuery))
	{
		new szGuild[64], szPassword[32], szName[32], aGuild[GuildInfo], iStatus;

		SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "guild_name"), szGuild, charsmax(szGuild));
		if(!GetGuildID(szGuild))
		{
			copy(aGuild[NAME], charsmax(szGuild), szGuild);
			aGuild[STATUS] = _:TrieCreate();
		
			SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "password"), aGuild[PASSWORD], charsmax(aGuild[PASSWORD]));

			aGuild[LEVEL] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "level"));
			aGuild[BANK] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "bank"));
			aGuild[SPEED] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "speed"));
			aGuild[EXP] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "exp"));
			aGuild[HEALTH] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "health"));
			aGuild[DAMAGE] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "damage"));
			aGuild[KILLS] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "kills"));
			aGuild[MEMBERS] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "members"));

			ArrayPushArray(gGuilds, aGuild);
		}
		
		iGuild[id] = GetGuildID(szGuild);
		ArrayGetArray(gGuilds, iGuild[id], aGuild);
		iStatus = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "flag"));
		TrieSetCell(aGuild[STATUS], szMemberName[id], iStatus);
		
		get_user_name(id, szName, charsmax(szName));

		if(get_user_status(id, iGuild[id]) < DEPUTY)
			return;

		cmd_execute(id, "exec gildia.cfg");
		get_user_info(id, "_gildia", szPassword, charsmax(szPassword));

		if(equal(aGuild[PASSWORD], szPassword))
			Set(id, iPassword);
	}
	else
	{
		formatex(szCache, charsmax(szCache), "INSERT IGNORE INTO `guild_members` (`name`) VALUES ('%s');", szMemberName[id]);
		SQL_ThreadQuery(hSqlTuple, "Table_Handle", szCache);
	}
}

public CheckGuildName(const szName[])
{
	new szCache[128], szError[128], iError, bool:bFound;
	
	formatex(szCache, charsmax(szCache), "SELECT * FROM `guilds` WHERE `guild_name` = '%s'", szName);
	
	new Handle:g_Connect = SQL_Connect(hSqlTuple, iError, szError, charsmax(szError));
	
	if(iError)
	{
		log_to_file("addons/amxmodx/logs/diablo_guilds.log", "<Query> Error: %s", szError);
		return true;
	}
	
	new Handle:Query = SQL_PrepareQuery(g_Connect, szCache);
	
	SQL_Execute(Query);
	
	if(SQL_NumResults(Query))
		bFound = true;

	SQL_FreeHandle(Query);
	SQL_FreeHandle(g_Connect);
	
	return bFound;
}

public getGuild(plugin, params)
{
	if(params != 1)
		return 0;
	
	return iGuild[get_param(1)];
}

public getGuildName(guild, szReturn[], iLen)
{
	new aGuild[GuildInfo];
	
	param_convert(2);
	
	ArrayGetArray(gGuilds, guild, aGuild);
	
	copy(szReturn, iLen, aGuild[NAME]);
}

public ConfigLoad() 
{
	new szPath[64];
	
	get_localinfo("amxx_configsdir", szPath, charsmax(szPath));
	format(szPath, charsmax(szPath), "%s/%s", szPath, szFile);
    
	if(!file_exists(szPath)) 
	{
		new szError[100];
		
		formatex(szError, charsmax(szError), "Brak pliku konfiguracyjnego: %s!", szPath);
		set_fail_state(szError);
		
		return;
	}
    
	new szLine[256], szValue[256], szKey[64], iSection, iValue;
	new iFile = fopen(szPath, "rt");
    
	while(iFile && !feof(iFile)) 
	{
		fgets(iFile, szLine, charsmax(szLine));
		replace(szLine, charsmax(szLine), "^n", "");
       
		if(!szLine[0] || szLine[0] == '/') continue;
		if(szLine[0] == '[') { iSection++; continue; }
       
		strtok(szLine, szKey, charsmax(szKey), szValue, charsmax(szValue), '=');
		trim(szKey);
		trim(szValue);
		
		iValue = str_to_num(szValue);
		
		switch (iSection) 
		{ 
			case 1: 
			{
				if(equal(szKey, "CREATE_LEVEL"))
					iCreateLevel = iValue;
				else if(equal(szKey, "MAX_MEMBERS"))
					iMaxMembers = iValue;
				else if(equal(szKey, "LEVEL_MAX"))
					iLevelMax = iValue;
				else if(equal(szKey, "SPEED_MAX"))
					iSpeedMax = iValue;
				else if(equal(szKey, "EXP_MAX"))
					iExpMax = iValue;
				else if(equal(szKey, "DAMAGE_MAX"))
					iDamageMax = iValue;
				else if(equal(szKey, "HEALTH_MAX"))
					iHealthMax = iValue;
			}
			case 2: 
			{
				if(equal(szKey, "LEVEL_COST"))
					iLevelCost = iValue;
				else if(equal(szKey, "SPEED_COST"))
					iSpeedCost = iValue;
				else if(equal(szKey, "EXP_COST"))
					iExpCost = iValue;
				else if(equal(szKey, "DAMAGE_COST"))
					iDamageCost = iValue;
				else if(equal(szKey, "HEALTH_COST"))
					iHealthCost = iValue;
				else if(equal(szKey, "LEVEL_COST_NEXT"))
					iNextLevelCost = iValue;
				else if(equal(szKey, "SPEED_COST_NEXT"))
					iNextSpeedCost = iValue;
				else if(equal(szKey, "EXP_COST_NEXT"))
					iNextExpCost = iValue;
				else if(equal(szKey, "DAMAGE_COST_NEXT"))
					iNextDamageCost = iValue;
				else if(equal(szKey, "HEALTH_COST_NEXT"))
					iNextHealthCost = iValue;
			}
			case 3: 
			{
				if(equal(szKey, "MEMBERS_PER"))
					iMembersPerLevel = iValue;
				else if(equal(szKey, "SPEED_PER"))
					iSpeedPerLevel = iValue;
				else if(equal(szKey, "EXP_PER"))
					iExpPerLevel = iValue;
				else if(equal(szKey, "DAMAGE_PER"))
					iDamagePerLevel = iValue;
				else if(equal(szKey, "HEALTH_PER"))
					iHealthPerLevel = iValue;
			}
		}
	}
	if(iFile) fclose(iFile);
}

stock mysql_escape_string(const szSource[], szDest[], iLen)
{
	copy(szDest, iLen, szSource);
	replace_all(szDest, iLen, "\\", "\\\\");
	replace_all(szDest, iLen, "\0", "\\0");
	replace_all(szDest, iLen, "\n", "\\n");
	replace_all(szDest, iLen, "\r", "\\r");
	replace_all(szDest, iLen, "\x1a", "\Z");
	replace_all(szDest, iLen, "'", "\'");
	replace_all(szDest, iLen, "`", "\`");
	replace_all(szDest, iLen, "^"", "\^"");
}

stock GetGuildID(const szGuild[])
{
	new aGuild[GuildInfo];
	
	for(new i = 1; i < ArraySize(gGuilds); i++)
	{
		ArrayGetArray(gGuilds, i, aGuild);
		
		if(equal(aGuild[NAME], szGuild))
			return i;
	}
	
	return 0;
}

stock cmd_execute(id, const szText[], any:...) 
{
    #pragma unused szText

    if (id == 0 || is_user_connected(id))
	{
    	new szMessage[256];

    	format_args(szMessage, charsmax(szMessage), 1);

        message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id);
        write_byte(strlen(szMessage) + 2);
        write_byte(10);
        write_string(szMessage);
        message_end();
    }
}