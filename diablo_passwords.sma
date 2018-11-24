#include <amxmodx>
#include <sqlx>
#include <hamsandwich>
#include <colorchat>
#include <dhudmessage>

#define PLUGIN "Register System"
#define VERSION "1.1"
#define AUTHOR "O'Zone"

#define PREFIX "^x03[SR]^x01"
#define SETINFO "_csrpass"
#define CONFIG "csrpass"

#define TASK_PASSWORD 94328

#define is_user_valid(%1) (1 <= %1 <= gMaxPlayers)

#define Set(%2,%1)	(%1 |= (1<<(%2&31)))
#define Rem(%2,%1)	(%1 &= ~(1 <<(%2&31)))
#define Get(%2,%1)	(%1 & (1<<(%2&31)))

new szPlayerName[33][33], szPlayerSafeName[33][33], szPlayerPassword[33][33], szPlayerTempPassword[33][33], 
szTemp[512], iPasswordFail[33], iStatus[33], iLoaded, gMaxPlayers, Handle:hHookSql;

enum { NOT_REGISTERED, NOT_LOGGED, LOGGED, GUEST };

enum { LOGIN, REGISTER_STEP1, REGISTER_STEP2 }

stock const FIRST_JOIN_MSG[] = "#Team_Select";
stock const FIRST_JOIN_MSG_SPEC[] = "#Team_Select_Spect";
stock const INGAME_JOIN_MSG[] = "#IG_Team_Select";
stock const INGAME_JOIN_MSG_SPEC[] = "#IG_Team_Select_Spect";
const iMaxLen = sizeof(INGAME_JOIN_MSG_SPEC);

stock const VGUI_JOIN_TEAM_NUM = 2;

new const szStatus[][] = { "Niezarejestrowany", "Niezalogowany", "Zalogowany", "Gosc" };

new const szCommandPassword[][] = { "say /haslo", "say_team /haslo", "say /password", "say_team /password", "say /konto", "say_team /konto", "haslo" };

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_cvar("register_system_sql_host", "sql.pukawka.pl", FCVAR_SPONLY|FCVAR_PROTECTED); 
	register_cvar("register_system_sql_user", "509049", FCVAR_SPONLY|FCVAR_PROTECTED); 
	register_cvar("register_system_sql_pass", "Vd1hRq0EKCe6Mt3", FCVAR_SPONLY|FCVAR_PROTECTED); 
	register_cvar("register_system_sql_db", "509049_diablomod", FCVAR_SPONLY|FCVAR_PROTECTED);
	
	for(new i; i < sizeof szCommandPassword; i++)
		register_clcmd(szCommandPassword[i], "ManageMenu");
	
	register_clcmd("WPROWADZ_SWOJE_HASLO", "CheckPassword");
	register_clcmd("WPROWADZ_WYBRANE_HASLO", "RegisterStepOne");
	register_clcmd("POWTORZ_WYBRANE_HASLO", "RegisterStepTwo");
	register_clcmd("WPROWADZ_AKTUALNE_HASLO", "ChangeStepOne");
	register_clcmd("WPROWADZ_NOWE_HASLO", "ChangeStepTwo");
	register_clcmd("POWTORZ_NOWE_HASLO", "ChangeStepThree");
	register_clcmd("WPROWADZ_AKTUALNE_HASLO", "DeletePassword");
	
	register_message(get_user_msgid("ShowMenu"), "MessageShowMenu");
	register_message(get_user_msgid("VGUIMenu"), "MessageVGUIMenu");
	
	gMaxPlayers = get_maxplayers();
	
	SqlInit();
}

public plugin_natives()
	register_native("register_system_check", "nativeCheck");

public plugin_end()
	SQL_FreeHandle(hHookSql);

public client_connect(id)
{
	if(is_user_bot(id) || is_user_hltv(id))
		return;
		
	szPlayerPassword[id] = "";
	
	iPasswordFail[id] = 0;
	
	iStatus[id] = NOT_REGISTERED;

	Rem(id, iLoaded);
	
	LoadPassword(id);
}

public client_disconnect(id)
	remove_task(id + TASK_PASSWORD);
	
public MessageShowMenu(iMsgid, iDest, id)
{
	static sMenuCode[iMaxLen];
	get_msg_arg_string(4, sMenuCode, sizeof(sMenuCode) - 1);
	
	if(iStatus[id] < LOGGED && (equal(sMenuCode, FIRST_JOIN_MSG) || equal(sMenuCode, FIRST_JOIN_MSG_SPEC) || equal(sMenuCode, INGAME_JOIN_MSG) || equal(sMenuCode, INGAME_JOIN_MSG_SPEC)))
	{
		if(iStatus[id] == NOT_LOGGED)
			set_task(60.0, "KickPlayer", id + TASK_PASSWORD);
		
		ManageMenu(id);
		
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public MessageVGUIMenu(iMsgid, iDest, id)
{
	if(get_msg_arg_int(1) != VGUI_JOIN_TEAM_NUM || iStatus[id] >= LOGGED)
		return PLUGIN_CONTINUE;

	if(iStatus[id] == NOT_LOGGED)
		set_task(60.0, "KickPlayer", id + TASK_PASSWORD);
		
	ManageMenu(id);
	
	return PLUGIN_HANDLED;
}

public KickPlayer(id)
{
	id -= TASK_PASSWORD;
	
	server_cmd("kick #%d ^"Nie zalogowales sie w ciagu 60s!^"", get_user_userid(id));
}

public ManageMenu(id)
{
	if(!Get(id, iLoaded))
		return PLUGIN_HANDLED;
	
	new szMenu[128];
	
	formatex(szMenu, charsmax(szMenu), "\rSystem Rejestracji:^n^n\rNick: \w[\y%s\w]^n\rStatus: \w[\y%s\w]^n\wAby haslo bylo ladowane automatycznie wpisz w konsoli komende \ysetinfo ^"%s^" ^"twojehaslo^"", szPlayerName[id], szStatus[iStatus[id]], SETINFO);

	new menu = menu_create(szMenu, "ManageMenu_Handle"), callback = menu_makecallback("ManageMenu_Callback");
	
	menu_additem(menu, "\yLogowanie", _, _, callback);
	menu_additem(menu, "\rRejestracja", _, _, callback);
	menu_additem(menu, "\yZmien \wHaslo", _, _, callback);
	menu_additem(menu, "\ySkasuj \wKonto", _, _, callback);
	menu_additem(menu, "\yZaloguj jako \wGosc \r(NIEZALECANE)^n", _, _, callback);
 
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_BACKNAME, "Wstecz");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public ManageMenu_Callback(id, menu, item)
{
	switch(item)
	{
		case 0: return iStatus[id] == NOT_LOGGED ? ITEM_ENABLED : ITEM_DISABLED;
		case 1: return (iStatus[id] == NOT_REGISTERED || iStatus[id] == GUEST) ? ITEM_ENABLED : ITEM_DISABLED;
		case 2, 3: return iStatus[id] == LOGGED ? ITEM_ENABLED : ITEM_DISABLED;
		case 4: return iStatus[id] == NOT_REGISTERED ? ITEM_ENABLED : ITEM_DISABLED;
	}
	return ITEM_ENABLED;
}

public ManageMenu_Handle(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_CONTINUE;
	}
	
	switch(item)
	{
		case 0:
		{
			ColorChat(id, GREEN, "%s Wprowadz swoje^x04 haslo^x01, aby sie^x04 zalogowac.", PREFIX);

			set_dhudmessage(0, 128, 255, 0.07, 0.12, 0, 0.0, 2.0, 0.0, 0.0);
			show_dhudmessage(id, "Wprowadz swoje haslo.");

			client_cmd(id, "messagemode WPROWADZ_SWOJE_HASLO");
		}
		case 1: 
		{
			ColorChat(id, GREEN, "%s Rozpoczales proces^x04 rejestracji^x01. Wprowadz wybrane^x04 haslo^x01.", PREFIX);
	
			set_dhudmessage(0, 128, 255, 0.07, 0.12, 0, 0.0, 2.0, 0.0, 0.0);
			show_dhudmessage(id, "Wprowadz wybrane haslo.");
	
			client_cmd(id, "messagemode WPROWADZ_WYBRANE_HASLO");
		}
		case 2:
		{
			ColorChat(id, GREEN, "%s Wprowadz swoje^x04 aktualne haslo^x01 w celu potwierdzenia tozsamosci.", PREFIX);
			
			set_dhudmessage(0, 128, 255, 0.07, 0.12, 0, 0.0, 2.0, 0.0, 0.0);
			show_dhudmessage(id, "Wprowadz swoje aktualne haslo.");
			
			client_cmd(id, "messagemode WPROWADZ_AKTUALNE_HASLO");
		}
		case 3: 
		{
			ColorChat(id, GREEN, "%s Wprowadz swoje^x04 aktualne haslo^x01 w celu potwierdzenia tozsamosci.", PREFIX);
			
			set_dhudmessage(0, 128, 255, 0.07, 0.12, 0, 0.0, 2.0, 0.0, 0.0);
			show_dhudmessage(id, "Wprowadz swoje aktualne haslo.");
			
			client_cmd(id, "messagemode WPROWADZ_SWOJE_AKTUALNE_HASLO");
		}
		case 4: 
		{
			ColorChat(id, GREEN, "%s Zalogowales sie jako^x04 Gosc^x01. By zabezpieczyc swoj nick^x04 zarejestruj sie^x01.", PREFIX);
			
			set_dhudmessage(0, 255, 0, 0.07, 0.12, 0, 0.0, 2.0, 0.0, 0.0);
			show_dhudmessage(id, "Zostales pomyslnie zalogowany jako Gosc.");
			
			remove_task(id + TASK_PASSWORD);
			
			iStatus[id] = GUEST;
		}
	}

	return PLUGIN_CONTINUE;
}

public CheckPassword(id)
{
	if(iStatus[id] != NOT_LOGGED || !Get(id, iLoaded))
		return PLUGIN_HANDLED;
	
	new szPassword[33];
	read_args(szPassword, charsmax(szPassword));
	
	remove_quotes(szPassword);

	if(!equal(szPlayerPassword[id], szPassword))
	{
		if(++iPasswordFail[id] >= 3)
			server_cmd("kick #%d ^"Nieprawidlowe haslo!^"", get_user_userid(id));
		
		ColorChat(id, GREEN, "%s Podane haslo jest^x04 nieprawidlowe^x01. (Bledne haslo^x04 %i/3^x01)", PREFIX, iPasswordFail[id]);
		
		set_dhudmessage(255, 0, 0, 0.07, 0.12, 0, 0.0, 2.0, 0.0, 0.0);
		show_dhudmessage(id, "Podane haslo jest nieprawidlowe.");
		
		ManageMenu(id);
		
		return PLUGIN_HANDLED;
	}
	
	ColorChat(id, GREEN, "%s Zostales pomyslnie^x04 zalogowany^x01. Zyczymy milej gry.", PREFIX);
	
	set_dhudmessage(0, 255, 0, 0.07, 0.12, 0, 0.0, 2.0, 0.0, 0.0);
	show_dhudmessage(id, "Zostales pomyslnie zalogowany.");
	
	engclient_cmd(id, "chooseteam");
	
	remove_task(id + TASK_PASSWORD);
	
	iPasswordFail[id] = 0;
	
	iStatus[id] = LOGGED;
	
	return PLUGIN_HANDLED;
}

public RegisterStepOne(id)
{
	if(iStatus[id] != NOT_REGISTERED || iStatus[id] != GUEST || !Get(id, iLoaded))
		return PLUGIN_HANDLED;

	new szPassword[33];
	
	read_args(szPassword, charsmax(szPassword));
	remove_quotes(szPassword);
	
	if(strlen(szPassword) < 5)
	{
		ColorChat(id, GREEN, "%s Haslo musi miec co najmniej^x04 5 znakow^x01.", PREFIX);

		set_dhudmessage(255, 0, 0, 0.07, 0.12, 0, 0.0, 2.0, 0.0, 0.0);
		show_dhudmessage(id, "Haslo musi miec co najmniej 5 znakow.");
		
		return PLUGIN_HANDLED;
	}
	
	copy(szPlayerTempPassword[id], charsmax(szPlayerTempPassword), szPassword);
	
	ColorChat(id, GREEN, "%s Powtorz wybrane^x04 haslo^x01.", PREFIX);
	
	set_dhudmessage(0, 128, 255, 0.07, 0.12, 0, 0.0, 2.0, 0.0, 0.0);
	show_dhudmessage(id, "Powtorz wybrane haslo.");
	
	client_cmd(id, "messagemode POWTORZ_WYBRANE_HASLO");
	
	return PLUGIN_HANDLED;
}
	
public RegisterStepTwo(id)
{
	if(iStatus[id] != NOT_REGISTERED || iStatus[id] != GUEST || !Get(id, iLoaded))
		return PLUGIN_HANDLED;
	
	new szPassword[33];
	
	read_args(szPassword, charsmax(szPassword));
	remove_quotes(szPassword);
	
	if(!equal(szPassword, szPlayerTempPassword[id]))
	{
		ColorChat(id, GREEN, "%s Podane hasla^x04 roznia sie^x01 od siebie.", PREFIX);
		
		set_dhudmessage(255, 0, 0, 0.07, 0.12, 0, 0.0, 2.0, 0.0, 0.0);
		show_dhudmessage(id, "Podane hasla roznia sie od siebie.");
		
		ManageMenu(id);
		
		return PLUGIN_HANDLED;
	}
	
	copy(szPlayerPassword[id], charsmax(szPlayerPassword), szPassword);
	mysql_escape_string(szPassword, szPassword, charsmax(szPassword));
	
	formatex(szTemp, charsmax(szTemp), "UPDATE `register_system` SET pass = '%s' WHERE name = '%s'", szPassword, szPlayerName[id]);
	
	SQL_ThreadQuery(hHookSql, "Ignore_Handle", szTemp);
	
	set_dhudmessage(0, 255, 0, 0.07, 0.12, 0, 0.0, 2.0, 0.0, 0.0);
	show_dhudmessage(id, "Zostales pomyslnie zarejestrowany i zalogowany.");
	
	ColorChat(id, GREEN, "%s Twoj nick zostal pomyslnie^x04 zarejestrowany^x01.", PREFIX);
	ColorChat(id, GREEN, "%s Wpisz w konsoli komende^x04 setinfo ^"%s^" ^"%s^"^x01, aby twoje haslo bylo ladowane automatycznie.", PREFIX, SETINFO, szPlayerPassword[id]);
	
	iStatus[id] = LOGGED;
	
	cmd_execute(id, "setinfo %s %s", SETINFO, szPlayerPassword[id]);
	cmd_execute(id, "writecfg %s", CONFIG);
	
	return PLUGIN_HANDLED;
}

public ChangeStepOne(id)
{
	if(iStatus[id] != LOGGED || !Get(id, iLoaded))
		return PLUGIN_HANDLED;

	new szPassword[33];
	
	read_args(szPassword, charsmax(szPassword));
	remove_quotes(szPassword);
	
	if(!equal(szPlayerPassword[id], szPassword))
	{
		if(++iPasswordFail[id] >= 3)
			server_cmd("kick #%d ^"Nieprawidlowe haslo!^"", get_user_userid(id));
		
		ColorChat(id, GREEN, "%s Podane haslo jest^x04 nieprawidlowe^x01. (Bledne haslo^x04 %i/3^x01)", PREFIX, iPasswordFail[id]);
		
		set_dhudmessage(255, 0, 0, 0.07, 0.12, 0, 0.0, 2.0, 0.0, 0.0);
		show_dhudmessage(id, "Podane haslo jest nieprawidlowe.");
		
		ManageMenu(id);
		
		return PLUGIN_HANDLED;
	}
	
	ColorChat(id, GREEN, "%s Wprowadz swoje^x04 nowe haslo^x01.", PREFIX);

	set_dhudmessage(0, 128, 255, 0.07, 0.12, 0, 0.0, 2.0, 0.0, 0.0);
	show_dhudmessage(id, "Wprowadz swoje nowe haslo.");

	client_cmd(id, "messagemode WPROWADZ_NOWE_HASLO");
	
	return PLUGIN_HANDLED;
}

public ChangeStepTwo(id)
{
	if(iStatus[id] != LOGGED || !Get(id, iLoaded))
		return PLUGIN_HANDLED;

	new szPassword[33];
	
	read_args(szPassword, charsmax(szPassword));
	remove_quotes(szPassword);
	
	if(strlen(szPassword) < 5)
	{
		ColorChat(id, GREEN, "%s Nowe haslo musi miec co najmniej^x04 5 znakow^x01.", PREFIX);

		set_dhudmessage(255, 0, 0, 0.07, 0.12, 0, 0.0, 2.0, 0.0, 0.0);
		show_dhudmessage(id, "Nowe haslo musi miec co najmniej 5 znakow.");
		
		return PLUGIN_HANDLED;
	}
	
	copy(szPlayerTempPassword[id], charsmax(szPlayerTempPassword), szPassword);
	
	ColorChat(id, GREEN, "%s Powtorz swoje nowe^x04 haslo^x01.", PREFIX);
	
	set_dhudmessage(0, 128, 255, 0.07, 0.12, 0, 0.0, 2.0, 0.0, 0.0);
	show_dhudmessage(id, "Powtorz swoje nowe haslo.");
	
	client_cmd(id, "messagemode POWTORZ_NOWE_HASLO");
	
	return PLUGIN_HANDLED;
}

public ChangeStepThree(id)
{
	if(iStatus[id] != LOGGED || !Get(id, iLoaded))
		return PLUGIN_HANDLED;
	
	new szPassword[33];
	
	read_args(szPassword, charsmax(szPassword));
	remove_quotes(szPassword);
	
	if(!equal(szPassword, szPlayerTempPassword[id]))
	{
		ColorChat(id, GREEN, "%s Podane hasla^x04 roznia sie^x01 od siebie.", PREFIX);
		
		set_dhudmessage(255, 0, 0, 0.07, 0.12, 0, 0.0, 2.0, 0.0, 0.0);
		show_dhudmessage(id, "Podane hasla roznia sie od siebie.");
		
		ManageMenu(id);
		
		return PLUGIN_HANDLED;
	}
	
	copy(szPlayerPassword[id], charsmax(szPlayerPassword), szPassword);
	mysql_escape_string(szPassword, szPassword, charsmax(szPassword));
	
	formatex(szTemp, charsmax(szTemp), "UPDATE `register_system` SET pass = '%s' WHERE name = '%s'", szPassword, szPlayerSafeName[id]);
	
	SQL_ThreadQuery(hHookSql, "Ignore_Handle", szTemp);
	
	set_dhudmessage(0, 255, 0, 0.07, 0.12, 0, 0.0, 2.0, 0.0, 0.0);
	show_dhudmessage(id, "Twoje haslo zostalo pomyslnie zmienione.");
	
	ColorChat(id, GREEN, "%s Twoje haslo zostalo pomyslnie^x04 zmienione^x01.", PREFIX);
	ColorChat(id, GREEN, "%s Wpisz w konsoli komende^x04 setinfo ^"%s^" ^"%s^"^x01, aby twoje haslo bylo ladowane automatycznie.", PREFIX, SETINFO, szPlayerPassword[id]);
	
	cmd_execute(id, "setinfo %s %s", SETINFO, szPlayerPassword[id]);
	cmd_execute(id, "writecfg %s", CONFIG);
	
	return PLUGIN_HANDLED;
}

public DeletePassword(id)
{
	if(iStatus[id] != LOGGED || !Get(id, iLoaded))
		return PLUGIN_HANDLED;
		
	new szPassword[33];
	
	read_args(szPassword, charsmax(szPassword));
	remove_quotes(szPassword);
	
	if(!equal(szPlayerPassword[id], szPassword))
	{
		if(++iPasswordFail[id] >= 3)
			server_cmd("kick #%d ^"Nieprawidlowe haslo!^"", get_user_userid(id));
		
		ColorChat(id, GREEN, "%s Podane haslo jest^x04 nieprawidlowe^x01. (Bledne haslo^x04 %i/3^x01)", PREFIX, iPasswordFail[id]);
		
		set_dhudmessage(255, 0, 0, 0.07, 0.12, 0, 0.0, 2.0, 0.0, 0.0);
		show_dhudmessage(id, "Podane haslo jest nieprawidlowe.");
		
		ManageMenu(id);
		
		return PLUGIN_HANDLED;
	}
	
	new szMenu[128];
	
	formatex(szMenu, charsmax(szMenu), "\wCzy na pewno chcesz \rusunac \wswoje konto?");

	new menu = menu_create(szMenu, "DeletePassword_Handle");
	
	menu_additem(menu, "\rTak");
	menu_additem(menu, "\yNie");

	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public DeletePassword_Handle(id, menu, item)
{
	if(item == 0)
	{
		formatex(szTemp, charsmax(szTemp), "DELETE FROM `register_system` WHERE name = '%s'", szPlayerSafeName[id]);
		
		SQL_ThreadQuery(hHookSql, "Ignore_Handle", szTemp);
		
		console_print(id, "==========================================");
		console_print(id, "-------------REGISTER SYSTEM--------------");
		console_print(id, "------------------------------------------");
		console_print(id, "   Skasowales konto o nicku: %s", szPlayerName[id]);
		console_print(id, "------------------------------------------");
		console_print(id, "==========================================");
		
		server_cmd("kick #%d ^"Konto zostalo usuniete!^"", get_user_userid(id));
	}
	
	menu_destroy(menu)
	return PLUGIN_CONTINUE;
}

public SqlInit()
{
	new szData[4][64];
	get_cvar_string("register_system_sql_host", szData[0], charsmax(szData[])); 
	get_cvar_string("register_system_sql_user", szData[1], charsmax(szData[])); 
	get_cvar_string("register_system_sql_pass", szData[2], charsmax(szData[])); 
	get_cvar_string("register_system_sql_db", szData[3], charsmax(szData[])); 
	
	hHookSql = SQL_MakeDbTuple(szData[0], szData[1], szData[2], szData[3]);

	new iError, szError[128], Handle:hConn = SQL_Connect(hHookSql, iError, szError, charsmax(szError));
	
	if(iError)
	{
		log_to_file("addons/amxmodx/logs/register_system.log", "Error: %s", szError);
		return;
	}
	
	new szTemp[1024];
	formatex(szTemp, charsmax(szTemp), "CREATE TABLE IF NOT EXISTS `register_system` (name VARCHAR(35), pass VARCHAR(35), PRIMARY KEY(name));");

	new Handle:hQuery = SQL_PrepareQuery(hConn, szTemp);
	
	SQL_Execute(hQuery);
	SQL_FreeHandle(hQuery);
	SQL_FreeHandle(hConn);
}

public LoadPassword(id)
{
	if(!is_user_connected(id))
		return;

	get_user_name(id, szPlayerName[id], charsmax(szPlayerName));
	mysql_escape_string(szPlayerName[id], szPlayerSafeName[id], charsmax(szPlayerSafeName));
	
	new szData[1];
	szData[0] = id;
	
	formatex(szTemp, charsmax(szTemp), "SELECT * FROM `register_system` WHERE name = '%s'", szPlayerSafeName[id]);
	SQL_ThreadQuery(hHookSql, "LoadPassword_Handle", szTemp, szData, 1);
}

public LoadPassword_Handle(iFailState, Handle:hQuery, szError[], iError, szData[], iDataSize)
{
	if(iFailState != TQUERY_SUCCESS)
	{
		log_to_file("addons/amxmodx/logs/register_system.log", "<Query> Error: %s", szError);
		return;
	}
	
	new id = szData[0];
	
	if(!is_user_connected(id))
		return;
	
	if(SQL_MoreResults(hQuery))
	{
		SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "pass"), szPlayerPassword[id], charsmax(szPlayerPassword));
		
		new szPassword[33];
		cmd_execute(id, "exec %s.cfg", CONFIG);
		get_user_info(id, SETINFO, szPassword, charsmax(szPassword));
		
		if(equal(szPlayerPassword[id], szPassword))
			iStatus[id] = LOGGED;
	}
	else
	{
		formatex(szTemp, charsmax(szTemp), "INSERT INTO `register_system` VALUES ('%s', '')", szPlayerSafeName[id]);
		SQL_ThreadQuery(hHookSql, "Ignore_Handle", szTemp);
	}
	
	Set(id, iLoaded);
}

public Ignore_Handle(iFailState, Handle:hQuery, szError[], iError, szData[], iDataSize)
{
	if(iFailState != TQUERY_SUCCESS)
	{
		log_to_file("addons/amxmodx/logs/register_system.log", "<Ignore Query> Error: %s", szError);
		return;
	}
}

public nativeCheck(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[Register System] Invalid Player (%d)", id);
		return PLUGIN_HANDLED;
	}
	
	if(iStatus[id] < LOGGED)
	{
		ColorChat(id, GREEN, "%s Musisz sie^x04 zalogowac^x01, aby miec dostep do glownych funkcji!", PREFIX);
		ManageMenu(id);
	}
	
	return PLUGIN_HANDLED;
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