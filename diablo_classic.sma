#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fun>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <sqlx>
#include <csx>
#include <colorchat>
#include <nvault>

#pragma dynamic 65536

#define DIABLO_STOP 4
#define DIABLO_CONTINUE 3
#define DIABLO_RENDER_DESTROYED -1
#define FLAG_ALL -1

//#define DEBUG
#define DEBUG_LOG "addons/amxmodx/logs/debug.log"

#define PLUGIN	"Diablo Mod Classic"
#define AUTHOR	"DarkGL & O'Zone"
#define VERSION	"1.3"

#define HUD_TEXT				""
#define SQL_TABLE 				"diablomod_classic"
#define MAX_LEN_NAME 			128
#define MAX_LEN_DESC 			256
#define MAX_LEN_NAME_PLAYER		64
#define MAX_LEN_FRACTION		128
#define MAX 					32
#define MAX_LEVEL 				101
#define MAX_SKILL 				50
#define BASE_SPEED 				250.0
#define TASK_DEATH 				100
#define TASK_RENDER 			200
#define THROW_KNIFE_MODEL 		"models/diablomod/w_throwingknife.mdl"
#define THROW_KNIFE_CLASS 		"throwing_knife"
#define CLASS_NAME_CORSPE 		"fakeCorpse"
#define XBOW_ARROW				"xbow_arrow"
#define TIME_HUD 				1.0
#define GAME_DESCRIPTION		"CS-Reload.pl"
#define ADMIN_FLAG_GIVE 		ADMIN_ADMIN
#define HELP_TASK_ID			9132
#define HUD_TASK_ID				8956

#define OFFSET_WPN_LINUX		4
#define OFFSET_WPN_WIN 	 		41

#define PREFIX_SAY				"^x04[DiabloMod]^x01"

/*---------------------SQL---------------------*/
new bool:bSql = false;

new bool:sqlPlayer[MAX+1]

enum sqlCvarsStruct {
	eHost,
	eUser,
	ePass,
	eDb
}

new Handle:gTuple;

new pSqlCvars[sqlCvarsStruct]

/*---------------------PCVARS---------------------*/

new pCvarSaveType,
pCvarNum,
pCvarDamage,
pCvarXPBonus,
pCvarXPBonus2,
pCvarKnifeSpeed,
pCvarKnife,
pCvarPrefixy,
pCvarDurability,
pCvarArrow,
pCvarMulti,
pCvarSpeed,
pCvarExpPrice,
pCvarRandomPrice,
pCvarUpgradePrice,
pCvarPoints,
pCvarStrPower;

/*---------------------EXP---------------------*/

new const LevelXP[MAX_LEVEL] = {
	0,
	50, 215, 516, 982, 1487, 2173, 2895, 3796, 4788, 5836, 
	7049, 8324, 9681, 11330, 13091, 14873, 16843, 18973, 21193, 23452, 
	25855, 28484, 31189, 34014, 36904, 39854, 42975, 46327, 49784, 53326, 
	57013, 60839, 64687, 68733, 72893, 77056, 81318, 85860, 90462, 95088, 
	99731, 104700, 109859, 115097, 120463, 125922, 131424, 137154, 142946, 148830, 
	154830, 160935, 167108, 179541, 192067, 205203, 218767, 232683, 247203, 262083, 
	277368, 292822, 308544, 324927, 341912, 359244, 377179, 395380, 413949, 433043, 
	452354, 472301, 492564, 513558, 534858, 556770, 578996, 601691, 624794, 648084, 
	671838, 696280, 721079, 746140, 771787, 797943, 824316, 850965, 878246, 906023, 
	934418, 963137, 992376, 1021929, 1051851, 1082231, 1112893, 1144191, 1175989, 1200000
}

enum renderStruct {
	renderR = 0,
	renderG,
	renderB,
	renderFx,
	renderNormal,
	renderAmount,
	renderTime
}

/*---------------------HUD---------------------*/
new syncHud,
HudSyncObj,
gmsgStatusText,
gmsgBartimer;

new Array:gClassPlugins,
Array:gClassNames,
Array:gClassHp,
Array:gClassDesc,
Array:gClassFlag,
Array:gItemName,
Array:gItemPlugin,
Array:gItemDur,
Array:gClassFraction,
Array:gFractionNames;

new bool:bFirstRespawn[ MAX + 1 ];

enum DiabloDamageBits{
	diabloDamageKnife 	=	(1<<1), 
	diabloDamageGrenade =	(1<<24),
	diabloDamageShot	=	(1<<12) | (1<<1)
}

enum PlayerStruct {
	currentClass,
	currentLevel,
	currentExp,
	currentStr,
	currentInt,
	currentDex,
	currentAgi,
	currentPoints,
	currentItem,
	extraStr,
	extraInt,
	extraDex,
	extraAgi,
	itemDurability,
	maxHp,
	castTime,
	Float:currentSpeed,
	Float:dmgReduce,
	maxKnife,
	howMuchKnife,
	tossDelay,
	userGrav,
	playerHud,
	playerName[MAX_LEN_NAME_PLAYER]
}

new playerInf[ MAX + 1 ][PlayerStruct],
Array:playerInfClasses[ MAX + 1 ],
Array:playerInfRender[ MAX + 1 ]

new oldItemPlayer[ MAX + 1 ];

new Trie:ClassNames;

new ClassesNumber;
new ItemsNumber;

new bool:bFreezeTime = false,iPlayersNum = 0;
new bool:bWasducking[MAX+1]

new spriteBoom,spriteBloodSpray,spriteBloodDrop;

//trap mode
new bool:g_TrapMode[MAX+1];
new g_GrenadeTrap[MAX+1];
new Float:g_PreThinkDelay[MAX+1];

new cvar_throw_vel = 90 // def: 90
new cvar_activate_dis = 175 // def 190
new cvar_nade_vel = 280 //def 280
new Float: cvar_explode_delay = 0.5 // def 0.50

#define NADE_VELOCITY	EV_INT_iuser1
#define NADE_ACTIVE	EV_INT_iuser2	
#define NADE_TEAM	EV_INT_iuser3	
#define NADE_PAUSE	EV_INT_iuser4

//bow

new Float:bowdelay[MAX+1],bool:bow[MAX+1],bHasBow[MAX+1]

new cbow_VIEW[]  	= "models/diablomod/v_crossbow4.mdl" 
new cvow_PLAYER[]	= "models/diablomod/p_crossbow1.mdl" 
new cbow_bolt[]  	= "models/diablomod/crossbow_bolt.mdl"
new KNIFE_VIEW[] 	= "models/v_knife.mdl"
new KNIFE_PLAYER[] 	= "models/p_knife.mdl"

new pRuneMenu , pModMenu;

new iPlayerFraction[ MAX + 1 ];

new const SkillsValues[] = { 1, 2, 5, 10 };
new SkillsSpeed[33];

new DiabloHUD;

native diablo_get_user_guild(id);
native diablo_get_guild_name(guild, szReturn[], iLen);
native diablo_force_password(id);
native diablo_check_password(id);

public plugin_init(){
	
	register_plugin(PLUGIN, VERSION, AUTHOR);
		
	ClassNames = TrieCreate();
	TrieSetCell(ClassNames,"Brak", ClassesNumber);
	
	for(new i = 1; i < MAX + 1;i++ ){
		playerInfClasses[i] = 	ArrayCreate(7,10);
		playerInfRender[i]	=	ArrayCreate(8,10);
	}
	
	gClassPlugins 		= 	ArrayCreate(1,10)
	gClassNames			=	ArrayCreate(MAX_LEN_NAME,10)
	gClassHp			=	ArrayCreate(1,10)
	gClassDesc			=	ArrayCreate(MAX_LEN_DESC,10);
	gClassFlag			=	ArrayCreate(1,10);
	gItemName			=	ArrayCreate(MAX_LEN_NAME,10);
	gItemPlugin			=	ArrayCreate(1,10);
	gItemDur			=	ArrayCreate(1,10);
	gClassFraction		=	ArrayCreate(1,10);
	gFractionNames		=	ArrayCreate(MAX_LEN_FRACTION,10)
	
	ArrayPushCell(gClassPlugins,0);
	ArrayPushString(gClassNames,"Brak");
	ArrayPushCell(gClassHp,100);
	ArrayPushString(gClassDesc,"Brak");
	ArrayPushCell(gClassFlag,FLAG_ALL);
	ArrayPushString(gItemName,"Brak");
	ArrayPushCell(gItemPlugin,0);
	ArrayPushCell(gItemDur,-1);
	ArrayPushCell(gClassFraction , 0);
	ArrayPushString(gFractionNames , "Brak");
	
	pSqlCvars[eHost] 	= 	register_cvar("diablo_host","sql.pukawka.pl", FCVAR_SPONLY|FCVAR_PROTECTED);
	pSqlCvars[eUser] 	= 	register_cvar("diablo_user","509049", FCVAR_SPONLY|FCVAR_PROTECTED);
	pSqlCvars[ePass] 	= 	register_cvar("diablo_pass","Vd1hRq0EKCe6Mt3", FCVAR_SPONLY|FCVAR_PROTECTED);
	pSqlCvars[eDb] 		= 	register_cvar("diablo_db","509049_diablomod", FCVAR_SPONLY|FCVAR_PROTECTED);
	
	pCvarSaveType 		=	register_cvar("diablo_save_type","1");
	
	pCvarNum			=	register_cvar("diablo_player_num","4");
	
	pCvarPoints			=	register_cvar("diablo_points" , "2" );
	
	pCvarDamage			=	register_cvar("diablo_dmg_exp","30");
	pCvarXPBonus		=	register_cvar("diablo_xpbonus","3");
	pCvarXPBonus2		=	register_cvar("diablo_xpbonus2","30");
	
	pCvarKnifeSpeed		=	register_cvar("diablo_knife_speed","1000");
	pCvarKnife			=	register_cvar("diablo_knife","20.0");
	
	pCvarPrefixy		=	register_cvar("diablo_prefixy","3");
	
	pCvarArrow 			=	register_cvar("diablo_arrow","60.0");
	pCvarMulti			=	register_cvar("diablo_arrow_multi","2.0");
	pCvarSpeed			=	register_cvar("diablo_arrow_speed","1500")
	
	pCvarDurability		=	register_cvar("diablo_durability","10")
	
	pCvarExpPrice		=	register_cvar("diablo_exp_price" , "14500")
	pCvarRandomPrice	=	register_cvar("diablo_random_price" , "5000")
	pCvarUpgradePrice	=	register_cvar("diablo_upgrade_price" , "9000")
	
	pCvarStrPower		=	register_cvar( "diablo_strength_power" , "2" );
	
	register_touch(THROW_KNIFE_CLASS, "player", 			"touchKnife")
	register_touch(THROW_KNIFE_CLASS, "worldspawn",			"touchWorld")
	register_touch(THROW_KNIFE_CLASS, "func_wall",			"touchWorld")
	register_touch(THROW_KNIFE_CLASS, "func_door",			"touchWorld")
	register_touch(THROW_KNIFE_CLASS, "func_door_rotating",	"touchWorld")
	register_touch(THROW_KNIFE_CLASS, "func_wall_toggle",	"touchWorld")
	register_touch(THROW_KNIFE_CLASS, "dbmod_shild",		"touchWorld")
	
	register_touch(THROW_KNIFE_CLASS, "func_breakable",		"touchbreakable")
	register_touch("func_breakable", THROW_KNIFE_CLASS,		"touchbreakable")
	
	register_touch(XBOW_ARROW, "player", 			"toucharrow")
	register_touch(XBOW_ARROW, "worldspawn",		"touchWorld2")
	register_touch(XBOW_ARROW, "func_wall",			"touchWorld2")
	register_touch(XBOW_ARROW, "func_door",			"touchWorld2")
	register_touch(XBOW_ARROW, "func_door_rotating","touchWorld2")
	register_touch(XBOW_ARROW, "func_wall_toggle",	"touchWorld2")
	register_touch(XBOW_ARROW, "dbmod_shild",		"touchWorld2")
	
	register_touch(XBOW_ARROW, "func_breakable",	"touchbreakable")
	register_touch("func_breakable", XBOW_ARROW,	"touchbreakable")
	
	register_event("SendAudio",		"freezeOver","b","2=%!MRAD_GO","2=%!MRAD_MOVEOUT","2=%!MRAD_LETSGO","2=%!MRAD_LOCKNLOAD")
	register_event("SendAudio",		"freezeBegin","a","2=%!MRAD_terwin","2=%!MRAD_ctwin","2=%!MRAD_rounddraw") 
	register_event("StatusValue", 	"showStatus", "be", "1=2", "2!0")
	register_event("StatusText",	"showStatus","be")
	register_event("DeathMsg", 		"DeathMsg", "a")
	register_event("Damage", 		"eventDamage", "b", "2!=0")
	register_event("TextMsg",		"hostKilled","b","2&#Killed_Hostage") 
	register_event("HLTV",			"newRound", 	"a", "1=0", "2=0")
	register_event("SendAudio",		"winTT" , "a", "2&%!MRAD_terwin")
	register_event("SendAudio",		"winCT", "a", "2&%!MRAD_ctwin")
	
	register_logevent("awardHostage",3,"2=Rescued_A_Hostage")
	
	gmsgStatusText	=	get_user_msgid("StatusText");
	gmsgBartimer 	=	get_user_msgid("BarTime");
	
	DiabloHUD = nvault_open("DiabloHUD");
	if(DiabloHUD == INVALID_HANDLE)
		set_fail_state("Nie mozna otworzyc pliku");
	
	syncHud		=	CreateHudSyncObj();
	HudSyncObj	=	CreateHudSyncObj();
	
	if( !equal( GAME_DESCRIPTION , "" ) ){
		register_forward( FM_GetGameDescription, "fwGameDesc" )
	}
	
	new const g_szWpnEntNames[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
		"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
		"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
		"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
		"weapon_ak47", "weapon_knife", "weapon_p90" }
	
	for (new i = 1; i < sizeof g_szWpnEntNames; i++)	if (g_szWpnEntNames[i][0]) RegisterHam(Ham_Item_Deploy, g_szWpnEntNames[i], "fwItemDeployPost", 1)
	
	RegisterHam( get_player_resetmaxspeed_func(), "player", "fwSpeedChange", true );
	RegisterHam(Ham_Spawn,"player","fwSpawned",1);
	RegisterHam(Ham_TakeDamage,"player","fwDamage",0);
	register_forward(FM_PlayerPreThink, "Forward_FM_PlayerPreThink");
	register_forward(FM_AddToFullPack, "fwAddToFullPack", 1);
	
	register_message(get_user_msgid("Health") ,	"msgHealth");
	register_message(get_user_msgid("SayText"),	"handleSayText");
	register_message(get_user_msgid("ClCorpse"), "messageClCorpse");
	register_message(SVC_INTERMISSION, "Message_Intermission");
	
	register_think("grenade", "think_Grenade");
	register_think("think_bot", "think_Bot");
	
	_create_ThinkBot();
	_create_runeMenu();
	_create_modMenu();
	_register_Commands();
	
	return PLUGIN_HANDLED;
}

public plugin_precache(){
	precache_model("models/rpgrocket.mdl")
	precache_model(THROW_KNIFE_MODEL);
	
	precache_model(cbow_VIEW)
	precache_model(cvow_PLAYER)
	precache_model(cbow_bolt)
	
	spriteBoom			=	precache_model("sprites/zerogxplode.spr");
	spriteBloodSpray	=	precache_model("sprites/bloodspray.spr")	
	spriteBloodDrop		=	precache_model("sprites/blood.spr");
}

public plugin_cfg(){
	new szPath[256];
	formatex(szPath[ get_configsdir( szPath,charsmax( szPath ) ) ], charsmax( szPath ),"/diablomod.cfg");
	
	server_cmd("exec %s",szPath);
	server_exec()
	
	sqlStart();
	
	server_cmd("sv_maxspeed 1500");
	server_exec();
	server_cmd("sv_airaccelerate 100");
	server_exec();
	
}

public _register_Commands(){
	register_clcmd("say /klasy",			"showKlasy")
	register_clcmd("say_team /klasy",		"showKlasy")
	register_clcmd("say /klasa",			"wybierzKlase")
	register_clcmd("say_team /klasa",		"wybierzKlase")
	register_clcmd("say /reset",			"resetSkills");
	register_clcmd("say_team /reset",		"resetSkills");
	register_clcmd("say /drop",				"dropItem");
	register_clcmd("say_team /drop",		"dropItem");
	register_clcmd("say /przedmiot",		"itemInfo");
	register_clcmd("say_team /przedmiot",	"itemInfo");
	register_clcmd("say /item",				"itemInfo");
	register_clcmd("say_team /item",		"itemInfo");
	register_clcmd("say /itemy",			"itemsMenu");
	register_clcmd("say_team /itemy",		"itemsMenu");
	register_clcmd("say /gracze",			"playersList");
	register_clcmd("say_team /gracze",		"playersList");
	register_clcmd("say /czary",			"showSkills");
	register_clcmd("say_team /czary",		"showSkills");
	register_clcmd("say /skille",			"showSkills");
	register_clcmd("say_team /skille",		"showSkills");
	register_clcmd("say /rune",				"runeMenu");
	register_clcmd("say_team /rune",		"runeMenu");
	register_clcmd("say /sklep",			"runeMenu");
	register_clcmd("say_team /sklep",		"runeMenu");
	register_clcmd("say /wymiana",			"wymianaItemami");
	register_clcmd("say_team /wymiana",		"wymianaItemami");
	register_clcmd("say /wymien",			"wymianaItemami");
	register_clcmd("say_team /wymien",		"wymianaItemami");
	register_clcmd("say /daj",				"dajItem");
	register_clcmd("say_team /daj",			"dajItem");
	register_clcmd("say /oddaj",			"dajItem");
	register_clcmd("say_team /oddaj",		"dajItem");
	register_clcmd("say /pomoc",			"helpMotd");
	register_clcmd("say_team /pomoc",		"helpMotd");
	register_clcmd("say /help",				"helpMotd");
	register_clcmd("say_team /help",		"helpMotd");
	register_clcmd("say /komendy",			"commandList");
	register_clcmd("say_team /komendy",		"commandList");
	register_clcmd("diablo",				"modMenu");
	register_clcmd("say /diablo",			"modMenu");
	register_clcmd("say_team /diablo",		"modMenu");
	register_clcmd("say /exp",				"expInf");
	register_clcmd("say_team /exp",			"expInf");
	register_clcmd("say /hud",				"ChangeHUD");
	register_clcmd("say_team /hud",			"ChangeHUD");
	
	//short commands
	register_clcmd("say /k",			"wybierzKlase")
	register_clcmd("say_team /k",		"wybierzKlase")
	register_clcmd("say /r",			"resetSkills");
	register_clcmd("say_team /r",		"resetSkills");
	register_clcmd("say /d",				"dropItem") 
	register_clcmd("say_team /d",		"dropItem") 
	register_clcmd("say /p",			"itemInfo")
	register_clcmd("say_team /p",		"itemInfo")
	register_clcmd("say /i",				"itemInfo")
	register_clcmd("say_team /i",		"itemInfo")
	register_clcmd("say /g",			"playersList")
	register_clcmd("say_team /g",		"playersList")
	register_clcmd("say /c",			"showSkills")
	register_clcmd("say_team /c",		"showSkills")
	register_clcmd("say /s",				"runeMenu")
	register_clcmd("say_team /s",		"runeMenu")
	register_clcmd("say /ru",				"runeMenu")
	register_clcmd("say_team /ru",		"runeMenu")
	register_clcmd("say /w",			"wymianaItemami");
	register_clcmd("say_team /w",		"wymianaItemami");
	register_clcmd("say /o",			"dajItem");
	register_clcmd("say_team /o",		"dajItem");
	register_clcmd("say /p",			"helpMotd");
	register_clcmd("say_team /p",		"helpMotd");
	register_clcmd("say /h",				"helpMotd");
	register_clcmd("say_team /h",		"helpMotd");
	register_clcmd("say /ko",			"commandList");
	register_clcmd("say_team /ko",		"commandList");
	register_clcmd("say /m",				"modMenu");
	register_clcmd("say_team /m",		"modMenu");
	register_clcmd("say /h",				"ChangeHUD");
	register_clcmd("say_team /h",			"ChangeHUD");
	
	register_clcmd("amx_giveexp",			"giveExp",		ADMIN_FLAG_GIVE , "Uzycie amx_giveexp <nick> <ile>" );
	register_clcmd("amx_giveitem",  		"giveItem",     ADMIN_FLAG_GIVE , "Uzycie amx_giveitem <nick> <iditemu>" );
}

public fwGameDesc( ){
	forward_return( FMV_STRING, GAME_DESCRIPTION ); 
	return FMRES_SUPERCEDE; 
}

public _create_modMenu(){
	pModMenu	=	menu_create( "\yyMenu \rDiablo" , "modMenuHandle" );
	
	menu_additem( pModMenu , "Informacje o przedmiocie" );
	menu_additem( pModMenu , "Upusc obecny przedmiot" );
	menu_additem( pModMenu , "Pokaz pomoc" );
	menu_additem( pModMenu , "Uzyj mocy przedmiotu" );
	menu_additem( pModMenu , "Kup Rune" );
	menu_additem( pModMenu , "Questy" );
	menu_additem( pModMenu , "Gildie" );
	menu_additem( pModMenu , "Informacje o statystykach" );
	menu_additem( pModMenu , "Informacje o twoim expie" );
	menu_additem( pModMenu , "Lista komend" );
	
	menu_setprop( pModMenu , MPROP_EXITNAME , "Wyjscie" )
	menu_setprop( pModMenu , MPROP_BACKNAME , "Wroc" );
	menu_setprop( pModMenu , MPROP_NEXTNAME , "Dalej" );
}

public modMenuHandle( id , menu , item ){
	if( item	==	MENU_EXIT ){
		return PLUGIN_CONTINUE;
	}
	
	switch( item ){
	case 0:{
			itemInfo( id );
		}
	case 1:{
			dropItem( id );
		}
	case 2:{
			helpMotd( id );
		}
	case 3:{
			if(is_user_alive(id) && playerInf[id][currentClass] != 0 && !bFreezeTime && Float:playerInf[id][castTime] == 0.0 && playerInf[ id ][ currentItem ] != 0) {
				new gFw , iRet;
				
				gFw = CreateOneForward(ArrayGetCell(gItemPlugin,playerInf[id][currentItem]), "diablo_item_skill_used", FP_CELL);
				
				ExecuteForward(gFw, iRet, id);
			}
		}
	case 4:{
			runeMenu( id );
			
			return PLUGIN_HANDLED;
		}
	case 5:{
			client_cmd(id, "say /questy");
			
			return PLUGIN_HANDLED;
		}
	case 6:{
			client_cmd(id, "say /gildia");
			
			return PLUGIN_HANDLED;
		}
	case 7:{
			showSkills( id );
		}
	case 8:{
			expInf( id );
		}
	case 9:{
			commandList( id );
		}
	}
	
	menu_display( id , pModMenu );
	
	return PLUGIN_CONTINUE;
}

public modMenu( id ){
	menu_display( id , pModMenu );
	
	return PLUGIN_HANDLED;
}

public _create_runeMenu(){
	new szTmp[ 256 ];
	
	pRuneMenu	=	menu_create("Sklep z runami","runeMenuHandle");
	
	formatex( szTmp ,charsmax( szTmp ) , "\yUpgrade \d[Ulepszenie Przedmiotu] - \r%d$^n\d Uwaga nie kazdy item sie da ulepszyc ^n Slabe itemy latwo ulepszyc ^n Mocne itemy moga ulec uszkodzeniu" , get_pcvar_num( pCvarUpgradePrice ) )
	menu_additem( pRuneMenu , szTmp )
	
	formatex( szTmp ,charsmax( szTmp ) , "\yLosowanie przedmiotu \d[Dostajesz losowy przedmiot] \r%d$" , get_pcvar_num( pCvarRandomPrice ) )
	menu_additem( pRuneMenu , szTmp )
	
	formatex( szTmp ,charsmax( szTmp ) , "\yExp \d[Dostajesz doswiadczenia] \r%d$" , get_pcvar_num( pCvarExpPrice ) )
	menu_additem( pRuneMenu , szTmp )
	
	menu_setprop( pRuneMenu , MPROP_EXITNAME , "Wyjscie" )
}

public runeMenu ( id ){
	if(!diablo_check_password(id))
	{
		diablo_force_password(id);
		return PLUGIN_HANDLED;
	}
	
	menu_display( id , pRuneMenu );
	
	return PLUGIN_HANDLED;
}

public runeMenuHandle ( id , menu , item ){
	if( item == MENU_EXIT ){
		return PLUGIN_HANDLED;
	}
	
	switch( item ){
	case 0:{
			if( playerInf[ id ][ currentItem ] == 0 ){
				ColorChat( id , GREEN , "%s Nie posiadasz zadnego itemu." , PREFIX_SAY);
			}
			else{
				if( cs_get_user_money( id ) < get_pcvar_num( pCvarUpgradePrice ) ){
					ColorChat( id ,  GREEN ,"%s Masz za malo kasy potrzebujesz^x03 %d$^x01." , PREFIX_SAY , get_pcvar_num( pCvarUpgradePrice ) );
				}
				else{
					playerInf[ id ][ itemDurability ]  += random_num(-50,50);
					
					if(! checkItemDurability( id ) )
					return PLUGIN_HANDLED;
					
					new gFw , iRet;
					
					gFw = CreateOneForward( ArrayGetCell( gItemPlugin , playerInf[ id ][ currentItem ] ) , "diablo_upgrade_item" , FP_CELL )
					
					ExecuteForward( gFw , iRet , id );
					cs_set_user_money( id , cs_get_user_money( id ) - get_pcvar_num( pCvarUpgradePrice ) );
				}
			}
		}
	case 1:{
			if( playerInf[ id ][ currentItem ] != 0 ){
				ColorChat( id , GREEN , "%s Juz posiadasz item.",PREFIX_SAY);
			}
			else{
				if( cs_get_user_money( id ) < get_pcvar_num( pCvarRandomPrice ) ){
					ColorChat( id , GREEN , "%s Masz za malo kasy potrzebujesz^x03 %d$^x01." , PREFIX_SAY, get_pcvar_num( pCvarRandomPrice ) );
				}
				else{
					giveUserItem( id );
					cs_set_user_money( id , cs_get_user_money( id ) - get_pcvar_num( pCvarRandomPrice ) );
				}
			}
		}
	case 2:{
			if( cs_get_user_money( id ) < get_pcvar_num( pCvarExpPrice ) ){
				ColorChat( id ,  GREEN ,"%s Masz za malo kasy potrzebujesz^x03 %d$^x01." , PREFIX_SAY , get_pcvar_num( pCvarExpPrice ) );
			}
			else{
				new iExp = get_pcvar_num( pCvarXPBonus ) * random_num( 3,10 ) + playerInf[ id ][ currentLevel ] * get_pcvar_num( pCvarXPBonus )/20
				giveXp( id , iExp, 0);
				ColorChat( id ,  GREEN ,"%s Otrzymales^x03 %d^x01 EXP'a.", PREFIX_SAY , iExp )
				cs_set_user_money( id , cs_get_user_money( id ) - get_pcvar_num( pCvarExpPrice ) );
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

public dajItem( id ){
	if( playerInf[ id ][ currentItem ] == 0 ){
		ColorChat( id ,  GREEN ,"%s Nie posiadasz zadnego itemu." , PREFIX_SAY);
		
		return PLUGIN_HANDLED;
	}
	
	new szName[ 64 ], szTmp [ 128 ] , szID [ 16 ];
	
	new pMenu = menu_create( "Oddaj \rItem" , "dajItemHandle" );
	
	for( new i = 1 ; i <= MAX ; i++ ){
		if(  !is_user_connected( i ) || playerInf[ i ][ currentItem ] != 0 || i == id )
		continue;
		
		get_user_name( i , szName , charsmax( szName ) );
		
		formatex( szTmp , charsmax( szTmp ) , "%s" , szName);
		
		num_to_str( i , szID , charsmax( szID ) );
		
		menu_additem( pMenu , szTmp , szID );
	}
	
	menu_setprop( pMenu , MPROP_BACKNAME , "Wroc" );
	menu_setprop( pMenu , MPROP_EXITNAME , "Wyjscie" );
	menu_setprop( pMenu , MPROP_NEXTNAME , "Dalej");
	
	menu_display( id , pMenu );
	
	return PLUGIN_HANDLED;
}

public dajItemHandle( id , menu , item ){
	if( item	==	MENU_EXIT || !is_user_connected( id ) ){
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	new data[6], iName[64]
	new acces, callback
	menu_item_getinfo(menu, item, acces, data,5, iName, 63, callback)
	
	new idTarget = str_to_num( data );
	
	if( !is_user_connected( idTarget ) ){
		ColorChat( id ,  GREEN ,"%s Tego gracza juz nie ma na serwerze." , PREFIX_SAY);
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	if( playerInf[ idTarget ][ currentItem ] != 0 ){
		ColorChat( id ,  GREEN ,"%s Ten gracz ma juz item. Mozesz sprobowac sie wymienic korzystajac z /wymien.", PREFIX_SAY);
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	if( playerInf[ id ][ currentItem ] == 0 ){
		ColorChat( id , GREEN , "%s Nie posiadasz zadnego itemu." , PREFIX_SAY);
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	if( oldItemPlayer[ id ] == idTarget ){
		ColorChat( id ,  GREEN ,"%s Ten gracz oddal ci swoj item. Przerzucanie jest zabronione.", PREFIX_SAY);
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	new szTitle [ MAX_LEN_NAME + 128 ] , szItem [ MAX_LEN_NAME ] , szName [ 64 ] , szID [ 16 ];
	
	get_user_name( id , szName , charsmax( szName ) );
	
	ArrayGetString( gItemName , playerInf[ id ][ currentItem ] , szItem , charsmax( szItem ) );
	
	formatex( szTitle , charsmax( szTitle ) , "\w%s chce oddac ci swoj item:\r %s ^n\w Zgadasz sie?", szName , szItem );
	
	num_to_str( id , szID , charsmax( szID ) );
	
	new pMenu = menu_create( szTitle , "dajItemPotwierdzenie" );
	
	menu_additem( pMenu , "Tak" , szID)
	menu_additem( pMenu , "Nie" , szID)
	
	menu_setprop( pMenu , MPROP_EXIT , MEXIT_NEVER );
	
	#if defined BOTY
	if( is_user_bot( idTarget ) ){
		menu_destroy( menu );
		dajItemPotwierdzenie(idTarget , pMenu,  random_num( 0 , 1 ) )
		
		return PLUGIN_HANDLED;
	}
	#endif
	
	menu_display( idTarget , pMenu );
	
	menu_destroy( menu );
	return PLUGIN_HANDLED;
}

public dajItemPotwierdzenie( id , menu , item ){
	if( item	==	MENU_EXIT || !is_user_connected( id ) ){
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	new data[6], iName[64]
	new acces, callback
	menu_item_getinfo(menu, item, acces, data,5, iName, 63, callback)
	
	new idTarget = str_to_num( data );
	
	if( item == 1 ){
		ColorChat( idTarget ,  GREEN ,"%s Gracz nie przyjal twojego itemu." , PREFIX_SAY );
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	if( !is_user_connected( idTarget ) ){
		ColorChat( id , GREEN , "%s Tego gracza juz nie ma na serwerze." , PREFIX_SAY);
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	if( !is_user_connected( id ) ){
		ColorChat( idTarget , GREEN , "%s Tego gracza juz nie ma na serwerze." , PREFIX_SAY);
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	if( playerInf[ idTarget ][ currentItem ] == 0 ){
		ColorChat( id ,  GREEN ,"%s Ten gracz nie ma juz itemu." , PREFIX_SAY);
		ColorChat( idTarget ,  GREEN ,"%s Nie posiadasz zadnego itemu." , PREFIX_SAY);
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	if( playerInf[ id ][ currentItem ] != 0 ){
		ColorChat( id , GREEN ,"%s Masz juz item. Mozesz sprobowac sie wymienic korzystajac z /wymien." , PREFIX_SAY );
		ColorChat( idTarget , GREEN ,"%s Ten gracz ma juz item." , PREFIX_SAY );
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	new szItem[ MAX_LEN_NAME ];
	
	ArrayGetString( gItemName , playerInf[ idTarget ][ currentItem ] , szItem ,charsmax( szItem ) )
	
	new gFw , iRet;
	
	gFw	=	CreateOneForward( ArrayGetCell( gItemPlugin , playerInf[ idTarget ][ currentItem ] ) , "diablo_copy_item" , FP_CELL , FP_CELL );
	
	ExecuteForward( gFw , iRet , idTarget , id );
	
	new iTmpItem = playerInf[ idTarget ][ currentItem ], iTmpDur = playerInf[ idTarget ][ itemDurability ];
	
	gFw	=	CreateOneForward( ArrayGetCell(gItemPlugin , playerInf[ idTarget ][ currentItem ] ) , "diablo_item_reset" , FP_CELL );
	
	ExecuteForward( gFw , iRet , idTarget );
	
	playerInf[ idTarget ][ currentItem ]			=	0;
	playerInf[ idTarget ][ itemDurability ]		=	0;
	
	playerInf[ id ][ currentItem ]	=	iTmpItem;
	playerInf[ id ][ itemDurability ]	=	iTmpDur;
	oldItemPlayer[ id ]  =	idTarget;
	
	ColorChat( idTarget , GREEN , "%s Oddales^x03 %s^x01." , PREFIX_SAY , szItem );
	ColorChat( id ,  GREEN ,"%s Otrzymales^x03 %s^x01." , PREFIX_SAY , szItem );
	
	menu_destroy( menu );
	return PLUGIN_HANDLED;
}

public expInf( id ){
	if( playerInf[ id ][ currentClass ] == 0 ){ 
		ColorChat( id , GREEN , "%s Nie masz zadnej klasy" , PREFIX_SAY);
	}
	else{
		ColorChat( id , GREEN ,"%s Obecnie posiadasz %i expa potrzebujesz %i czyli brakuje ci %i ( %0.2f%s )." , PREFIX_SAY ,  playerInf[ id ][ currentExp ] ,  LevelXP[playerInf[id][currentLevel]], LevelXP[playerInf[id][currentLevel] ]  - playerInf[ id ][ currentExp ] , ((float(playerInf[id][currentExp])-float( LevelXP[playerInf[id][currentLevel]-1]))*100.0)/(float(LevelXP[playerInf[id][currentLevel]])-float(LevelXP[playerInf[id][currentLevel]-1])) , "%" );
	}
	return PLUGIN_HANDLED;
}

public messageClCorpse(){
	return PLUGIN_HANDLED;
}

public autoHelp(id)
{
	id -= HELP_TASK_ID;
	
	set_hudmessage(0, 180, 0, -1.0, 0.70, 0, 10.0, 5.0, 0.1, 0.5, 11);
	
	switch ( random_num( 1 , 7 ) ){
	case 1: {
			show_hudmessage(id, "Mozesz wyrzucic przedmiot komenda /drop | Informacje o przedmiocie uzyskasz za pomoca komendy /item")
		}
	case 2: {
			show_hudmessage(id, "Mozesz uzyc przedmiotu wciskajac klawisz E")
		}
	case 3: {
			show_hudmessage(id, "Chcesz dowiedziec sie wiecej? Wpisz /pomoc | Aby sprawdzic wszystkie komendy wpisz /komendy")
		}
	case 4: {
			show_hudmessage(id, "Nie chcesz za kazdym razem wpisywac /menu? Zbinduj sobie klawisz wpisujac w konsoli: bind klawisz say /menu")
		}
	case 5: {
			show_hudmessage(id, "Niektore przedmioty moga byc ulepszone przez Runy. Wpisz /rune zeby otworzyc sklep z runami")
		}
	case 6: {
			show_hudmessage(id, "Mozesz zmieniac wyglad HUD miedzy starymodnym a nowoczesnym wpisujac komende /hud")
		}
	case 7: {
			show_hudmessage(id, "Sposobem na zdobywanie wiekszej ilosci doswiadczenia sa Questy. Wpisz /questy")
		}
	case 8: {
			show_hudmessage(id, "Od 25 poziomu mozesz zalozyc gildie i zapraszac do niej innych graczy. Wpisz /gildia")
		}
	}
}

public giveExp( id , level , cid ){
	if(!cmd_access(id,level, cid, 3)) 
		return PLUGIN_HANDLED; 
	
	new szName[ 64 ];
	read_argv( 1 , szName , charsmax( szName ) );
	
	remove_quotes( szName );
	
	new idTarget	=	find_player( "bjlh" , szName );
	
	if( !is_user_connected( idTarget ) ){
		client_print( id , print_console , "Nie znaleziono gracza" );
		return PLUGIN_HANDLED;
	}
	
	new szExp[ 64 ] , iExp ;
	read_argv( 2 , szExp , charsmax( szExp ) );
	
	remove_quotes( szExp );
	
	iExp	=	str_to_num( szExp );
	
	if( iExp < 0 )
		takeXp( idTarget , -iExp, 1);
	else
		giveXp( idTarget , iExp, 1);
	
	client_print( id , print_console , "Gracz %s dostal %i expa" , szName , iExp );	
	
	return PLUGIN_HANDLED;
}

public giveItem( id , level , cid ){
	if(!cmd_access(id,level, cid, 3)) 
	return PLUGIN_HANDLED; 
	
	new szName[ 64 ];
	read_argv( 1 , szName , charsmax( szName ) );
	
	remove_quotes( szName );
	
	new idTarget	=	find_player( "bjlh" , szName );
	
	if( !is_user_connected( idTarget ) ){
		client_print( id , print_console , "Nie znaleziono gracza" );
		return PLUGIN_HANDLED;
	}
	
	new szItem[ 64 ] , iItem ;
	read_argv( 2 , szItem , charsmax( szItem ) );
	
	remove_quotes( szItem );
	
	iItem	=	str_to_num( szItem );
	
	if ( 0 < iItem < ArraySize( gItemName ) && playerInf[ idTarget ][ currentItem ] == 0 ){
		giveUserItem( idTarget , iItem );
		client_print( id , print_console , "Gracz %s dostal item" , szName );	
	}
	
	return PLUGIN_HANDLED;
}

public commandList( id ){
	new szMessage[ 1650 ] , iLen = 0;
	
	iLen	+=	formatex( szMessage [ iLen ] , charsmax( szMessage ) - iLen , "<ul>\
	<li>/klasy 				- 	otwiera liste klas</li>\
	<li>/klasa 				- 	otwiera menu klas do wyboru</li>\
	<li>/reset 				- 	resetuje rozdane punkty umiejetnosci</li>\
	<li>/drop  				- 	wyrzuca aktualnie posiadany przedmiot</li>\
	<li>/item  				- 	opis akutalnie posiadanego przedmiotu</li>\
	<li>/przedmiot  		- 	takie samo dzialanie jak /item</li>");
	
	iLen	+=	formatex( szMessage [ iLen ] , charsmax( szMessage ) - iLen , "<li>/gracze  			-  	lista graczy wraz z ich levelami i klasami</li>\
	<li>/czary				-  	twoje statystyki</li>\
	<li>/skille				-  	tak jak /czary </li>\
	<li>/rune 				-  	menu gdzie mozna kupic rozne rzeczy</li>\
	<li>/wymiana  			-  	wymiana itemami</li>\
	<li>/wymien				-	tak jak /wymiana</li>\
	<li>/daj				-	oddaj item za kase</li>" );
	
	iLen	+=	formatex( szMessage [ iLen ] , charsmax( szMessage ) - iLen , "<li>/questy  				- 	menu wybory questow</li>\
	<li>/gildia  			- 	menu gildii</li>\
	<li>/pomoc  			-  	krotka notatka o modzie</li>\
	<li>/komendy  			-	ta lista</li>\
	<li>/exp				-	informacje o stanie twojego expa</li>\
	<li>/menu				-	menu serwera</li>\
	</ul>");
	
	showMotd( id , "" , "" , -1 , -1 , "" , szMessage);
}

public helpMotd( id ){
	showMotd( id , "" , "" , -1 , -1 , "" , "Dostajesz przedmioty i doswiadczenie za zabijanie innych. Item mozesz dostac tylko wtedy, gdy nie masz na sobie innego<br>\
	Aby dowiedziec sie wiecej o swoim przedmiocie napisz /przedmiot lub /item, a jesli chcesz wyrzucic item wpisz /drop<br>\
	Niektore przedmoty da sie uzyc za pomoca klawisza E<br>\
	Napisz /czary zeby zobaczyc jakie masz staty<br>\
	Gildie znajdziesz pod komenda /gildia<br>\
	Sposobem na zdobywanie wiekszej ilosci doswiadczenia sa Questy: /questy" );
	
	return PLUGIN_HANDLED;
}

public wymianaItemami( id ){
	if( playerInf[ id ][ currentItem ] == 0 ){
		ColorChat( id ,  GREEN ,"%s Nie posiadasz zadnego itemu." , PREFIX_SAY);
		
		return PLUGIN_HANDLED;
	}
	
	new szName[ 64 ] , szItem[ MAX_LEN_NAME ] , szTmp [ MAX_LEN_NAME + 128 ] , szID [ 16 ];
	
	new pMenu = menu_create( "Wymiana itemami" , "wymianaItemamiHandle" );
	
	for( new i = 1 ; i <= MAX ; i++ ){
		if(  !is_user_connected( i ) || playerInf[ i ][ currentItem ] == 0 || i == id )
		continue;
		
		get_user_name( i , szName , charsmax( szName ) );
		
		ArrayGetString( gItemName , playerInf[ i ][ currentItem ] , szItem , charsmax( szItem ) );
		
		formatex( szTmp , charsmax( szTmp ) , "%s \r %s" , szName , szItem );
		
		num_to_str( i , szID , charsmax( szID ) );
		
		menu_additem( pMenu , szTmp , szID );
	}
	
	menu_setprop( pMenu , MPROP_BACKNAME , "Wroc" );
	menu_setprop( pMenu , MPROP_EXITNAME , "Wyjscie" );
	menu_setprop( pMenu , MPROP_NEXTNAME , "Dalej");
	
	menu_display( id , pMenu );
	
	return PLUGIN_HANDLED;
}

public wymianaItemamiHandle( id , menu , item ){
	if( item	==	MENU_EXIT || !is_user_connected( id ) ){
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	new data[6], iName[64]
	new acces, callback
	menu_item_getinfo(menu, item, acces, data,5, iName, 63, callback)
	
	new idTarget = str_to_num( data );
	
	if( !is_user_connected( idTarget ) ){
		ColorChat( id ,  GREEN ,"%s Tego gracza juz nie ma na serwerze." , PREFIX_SAY);
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	if( oldItemPlayer[ id ] == idTarget ){
		ColorChat( id ,  GREEN ,"%s Zamieniles sie poprzednio z tym graczem. Przerzucanie jest zabronione.", PREFIX_SAY);
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	if( playerInf[ idTarget ][ currentItem ] == 0 ){
		ColorChat( id ,  GREEN ,"%s Ten gracz juz nie ma itemu.", PREFIX_SAY);
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	if( playerInf[ id ][ currentItem ] == 0 ){
		ColorChat( id , GREEN , "%s Nie posiadasz zadnego itemu." , PREFIX_SAY);
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	new szTitle [ MAX_LEN_NAME + 128 ] , szItem [ MAX_LEN_NAME ] , szName [ 64 ] , szID [ 16 ];
	
	get_user_name( id , szName , charsmax( szName ) );
	
	ArrayGetString( gItemName , playerInf[ id ][ currentItem ] , szItem , charsmax( szItem ) );
	
	formatex( szTitle , charsmax( szTitle ) , "\w%s chce wymienic sie z toba itemami i oferuje ci:\r %s ^n\w Zgadasz sie?", szName , szItem );
	
	num_to_str( id , szID , charsmax( szID ) );
	
	new pMenu = menu_create( szTitle , "wymianaItemamiPotwierdzenie" );
	
	menu_additem( pMenu , "Tak" , szID)
	menu_additem( pMenu , "Nie" , szID)
	
	menu_setprop( pMenu , MPROP_EXIT , MEXIT_NEVER );
	
	#if defined BOTY
	if( is_user_bot( idTarget ) ){
		menu_destroy( menu );
		wymianaItemamiPotwierdzenie(idTarget , pMenu,  random_num( 0 , 1 ) )
		
		return PLUGIN_HANDLED;
	}
	#endif
	
	menu_display( idTarget , pMenu );
	
	menu_destroy( menu );
	return PLUGIN_HANDLED;
}

public wymianaItemamiPotwierdzenie( id , menu , item ){
	if( item	==	MENU_EXIT || !is_user_connected( id ) ){
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	new data[6], iName[64]
	new acces, callback
	menu_item_getinfo(menu, item, acces, data,5, iName, 63, callback)
	
	new idTarget = str_to_num( data );
	
	if( item == 1 ){
		ColorChat( idTarget ,  GREEN ,"%s Gracz nie zgodzil sie na wymiane." , PREFIX_SAY );
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	if( !is_user_connected( idTarget ) ){
		ColorChat( id , GREEN , "%s Tego gracza juz nie ma na serwerze." , PREFIX_SAY);
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	if( is_user_connected( idTarget ) && playerInf[ idTarget ][ currentItem ] == 0 ){
		ColorChat( id ,  GREEN ,"%s Ten gracz juz nie ma itemu." , PREFIX_SAY);
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	if( is_user_connected( id ) && playerInf[ id ][ currentItem ] == 0 ){
		ColorChat( id ,  GREEN ,"%s Nie posiadasz zadnego itemu." , PREFIX_SAY );
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	new szItem[ MAX_LEN_NAME ] , szItem2[ MAX_LEN_NAME ];
	
	ArrayGetString( gItemName , playerInf[ id ][ currentItem ] , szItem ,charsmax( szItem ) )
	ArrayGetString( gItemName , playerInf[ idTarget ][ currentItem ] , szItem2 ,charsmax( szItem2 ) )
	
	new gFw , iRet;
	
	gFw	=	CreateOneForward( ArrayGetCell( gItemPlugin , playerInf[ id ][ currentItem ] ) , "diablo_copy_item" , FP_CELL , FP_CELL );
	
	ExecuteForward( gFw , iRet , id , idTarget );
	
	gFw	=	CreateOneForward( ArrayGetCell( gItemPlugin , playerInf[ idTarget ][ currentItem ] ) , "diablo_copy_item" , FP_CELL , FP_CELL );
	
	ExecuteForward( gFw , iRet , idTarget , id );
	
	new iTmpItem = playerInf[ id ][ currentItem ], iTmpDur = playerInf[ id ][ itemDurability ];
	
	gFw	=	CreateOneForward( ArrayGetCell(gItemPlugin , playerInf[ id ][ currentItem ] ) , "diablo_item_reset" , FP_CELL );
	
	ExecuteForward( gFw , iRet , id );
	
	gFw	=	CreateOneForward( ArrayGetCell(gItemPlugin , playerInf[ idTarget ][ currentItem ] ) , "diablo_item_reset" , FP_CELL );
	
	ExecuteForward( gFw , iRet , idTarget );
	
	playerInf[ id ][ currentItem ]			=	playerInf[ idTarget ][ currentItem ]
	playerInf[ id ][ itemDurability ]		=	playerInf[ idTarget ][ itemDurability ]
	
	playerInf[ idTarget ][ currentItem ]	=	iTmpItem;
	playerInf[ idTarget ][ itemDurability ]	=	iTmpDur;
	
	oldItemPlayer[ id ] = idTarget;
	oldItemPlayer[ idTarget ] = id;
	
	ColorChat( id , GREEN , "%s Otrzymales^x03 %s^x01." , PREFIX_SAY , szItem2 );
	ColorChat( idTarget ,  GREEN ,"%s Otrzymales^x03 %s^x01." , PREFIX_SAY , szItem );
	
	menu_destroy( menu );
	return PLUGIN_HANDLED;
}

public playersList(id)
{
	static motd[1000],header[100],szName[64],szClass[ MAX_LEN_NAME ] ,len = 0,i
	new team[32]
	new players[32], numplayers
	new playerid
	
	get_players(players, numplayers, "a")
	
	len += formatex(motd[len],sizeof motd - 1 - len,"<body bgcolor=#000000 text=#FFB000>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<center><table width=700 border=1 cellpadding=4 cellspacing=4>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<tr><td>Name</td><td>Klasa</td><td>Level</td><td>Team</td></tr>")
	
	formatex(header,sizeof header - 1,"Diablo Mod Statystyki")
	
	for (i = 0; i< numplayers; i++)
	{
		playerid = players[i]
		if ( get_user_team(playerid) == 1 ) team = "Terrorist"
		else if ( get_user_team(playerid) == 2 ) team = "CT"
		else team = "Spectator"
		get_user_name( playerid, szName, charsmax( szName ) )
		
		ArrayGetString( gClassNames , playerInf[playerid][currentClass] , szClass , charsmax( szClass ) )
		
		len += formatex(motd[len],sizeof motd - 1 - len,"<tr><td>%s</td><td>%s</td><td>%d</td><td>%s</td></tr>",szName,szClass, playerInf[playerid][currentLevel],team)
	}
	len += formatex(motd[len],sizeof motd - 1 - len,"</table></center>")
	
	show_motd(id,motd,header)     
}

public showSkills( id ){
	new SkillsInfo[768]
	formatex( SkillsInfo, charsmax( SkillsInfo ) ,"Masz %i sily - co daje ci %i zycia<br>Masz %i zwinnosci - co daje ci szybsze bieganie o %i punkow i redukuje sile atakow magia %i%%<br>Masz %i zrecznosci - Redukuje obrazenia z normalnych atakow o %i%%<br>Masz %i inteligencji - to daje im wieksza moc przedmiotom ktorych da sie uzyc",
	getUserStr( id ),
	getUserStr( id ) * get_pcvar_num( pCvarStrPower ),
	getUserDex( id ),
	floatround(getUserDex( id ) * 1.3),
	getUserDex( id ),
	getUserAgi( id ),
	floatround(playerInf[id][dmgReduce]*100),
	getUserInt( id ));
	
	showMotd( id , "Skille" , "" , -1 , -1 , "" , SkillsInfo )
}

public itemsMenu( id ){
	new pMenu = menu_create("Lista itemow","itemsMenuHandle");
	new szTmp[ MAX_LEN_NAME ]
	
	for( new i = 1 ; i < ArraySize( gItemName ) ; i++ ){
		ArrayGetString( gItemName , i , szTmp , charsmax( szTmp ) );
		
		menu_additem( pMenu , szTmp );
	}
	
	menu_setprop( pMenu , MPROP_NUMBER_COLOR , "\r" );
	menu_setprop( pMenu , MPROP_BACKNAME , "Wroc" );
	menu_setprop( pMenu , MPROP_NEXTNAME , "Dalej" );
	menu_setprop( pMenu , MPROP_EXITNAME , "Wyjscie");
	
	menu_display( id , pMenu );
}

public itemsMenuHandle ( id , menu , item ){
	if( item == MENU_EXIT ){
		menu_destroy( menu );
		
		return PLUGIN_HANDLED;
	}
	
	new szMessage[ 256 ];
	
	ArrayGetString( gItemName , item + 1 , szMessage , charsmax( szMessage ) );
	
	ColorChat( id ,  GREEN ,"%s Item :^x03 %s^x01." , PREFIX_SAY , szMessage );
	
	new gFW,iRet;
	
	new iArrayPass = PrepareArray(szMessage,256,1)
	
	gFW = CreateOneForward (ArrayGetCell(gItemPlugin , item + 1 ) , "diablo_item_info" , FP_CELL,FP_ARRAY,FP_CELL,FP_CELL);
	
	ExecuteForward(gFW, iRet, id , iArrayPass,charsmax( szMessage ) , true);
	
	ColorChat( id , GREEN , "%s Opis :^x03 %s^x01.",PREFIX_SAY , szMessage )
	
	menu_display( id , menu , item / 7 );
	
	return PLUGIN_CONTINUE;
}

public itemInfo( id ){
	if( playerInf[id][currentItem] == 0){
		showMotd( id , "Zabij kogos, aby dostac item albo kup (/rune)" , "Zabij kogos, aby dostac item albo kup (/rune)" );
	}
	else{
		new gFW,iRet , szMessage[ 256 ];
		
		new iArrayPass = PrepareArray(szMessage,256,1)
		
		gFW = CreateOneForward (ArrayGetCell(gItemPlugin , playerInf[id][currentItem] ) , "diablo_item_info" , FP_CELL,FP_ARRAY,FP_CELL,FP_CELL);
		
		ExecuteForward(gFW, iRet, id , iArrayPass,charsmax( szMessage ) , false);
		
		new szItem[ MAX_LEN_NAME ];
		
		ArrayGetString( gItemName , playerInf[id][currentItem] , szItem , MAX_LEN_NAME - 1 );
		
		showMotd( id , szItem , szItem , -1 , playerInf[id][itemDurability] , "" , szMessage );
	}
	
	return PLUGIN_HANDLED;
}

public dropItem( id ){
	if( playerInf[id][currentItem] == 0){
		set_hudmessage ( 255, 0, 0, -1.0, 0.4, 0, 1.0,2.0, 0.1, 0.2, -1 ) 	
		show_hudmessage(id, "Nie masz przedmiotu do wyrzucenia!")
	}
	else{
		set_hudmessage(100, 200, 55, -1.0, 0.40, 0, 3.0, 2.0, 0.2, 0.3, 5)
		show_hudmessage(id, "Przedmiot wyrzucony")
		
		new gFw , iRet;
		
		gFw	=	CreateOneForward( ArrayGetCell(gItemPlugin , playerInf[ id ][ currentItem ] ) , "diablo_item_reset" , FP_CELL );
		
		ExecuteForward( gFw , iRet , id );
		
		gFw	=	CreateOneForward( ArrayGetCell(gItemPlugin , playerInf[ id ][ currentItem ] ) , "diablo_item_drop" , FP_CELL );
		
		ExecuteForward( gFw , iRet , id );
		
		playerInf[ id ][ currentItem ]		=	0;
		playerInf[ id ][ itemDurability ]	=	0;
		oldItemPlayer[ id ] = 0;
	}
	
	return PLUGIN_HANDLED;
}

public handleSayText(msgId,msgDest,msgEnt){
	new id = get_msg_arg_int(1);
	
	if(!is_user_connected(id) || !get_pcvar_num(pCvarPrefixy) || ( get_user_team( id ) != 1 && get_user_team( id ) != 2 ))      return PLUGIN_CONTINUE;
	
	new szTmp[ 192 ],szTmp2[ 192 ],szTmp3[ 192 ];
	get_msg_arg_string(2,szTmp, charsmax( szTmp ) )
	
	new szPrefix[64]
	
	switch(get_pcvar_num(pCvarPrefixy)){
	case 1:{
			ArrayGetString(gClassNames,playerInf[id][currentClass],szTmp3,charsmax( szTmp3 ) )
			formatex(szPrefix,charsmax( szPrefix ),"^x04[%s]",szTmp3);
		}
	case 2:{
			formatex(szPrefix,charsmax( szPrefix ),"^x04[%d]",playerInf[id][currentLevel]);
		}
	case 3:{
			ArrayGetString(gClassNames,playerInf[id][currentClass],szTmp3,charsmax( szTmp3 ) )
			formatex(szPrefix,charsmax( szPrefix ),"^x04[%s - %d]",szTmp3,playerInf[id][currentLevel]);
		}
	}
	
	if(!equal(szTmp,"#Cstrike_Chat_All")){
		add(szTmp2,charsmax(szTmp2),szPrefix);
		add(szTmp2,charsmax(szTmp2)," ");
		add(szTmp2,charsmax(szTmp2),szTmp);
	}
	else{
		add(szTmp2,charsmax(szTmp2),szPrefix);
		add(szTmp2,charsmax(szTmp2),"^x03 %s1^x01 :  %s2");
	}
	
	set_msg_arg_string(2,szTmp2);
	
	return PLUGIN_CONTINUE;
}

public msgHealth(iMsgtype, iMsgid, id){
	if(get_msg_arg_int(1) >= 0xFF){
		
		set_hudmessage(255, 212, 0, 0.01, 0.88, 0, 6.0, 5.0)
		show_hudmessage(id, "Zycie: %d", get_msg_arg_int(1))
		
		set_msg_arg_int(1, get_msg_argtype(1), 0xFF);
	}
}

public newRound()
{
	remove_entity_name(CLASS_NAME_CORSPE);
	remove_entity_name(THROW_KNIFE_CLASS);
	
	new entArrow = find_ent_by_class(0, XBOW_ARROW);
	while(entArrow > 0)
	{
		remove_entity(entArrow);
		entArrow = find_ent_by_class(entArrow, XBOW_ARROW);
	}
	
	new gFW,iRet;
	
	for(new i = 1; i <= MAX ; i++){
		if(!is_user_connected(i) || playerInf[i][currentClass] == 0)	continue;
		
		gFW = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[i][currentClass]),"diablo_clean_data",FP_CELL);
		
		ExecuteForward(gFW,iRet,i);
	}
	
	gFW	=	CreateMultiForward( "diablo_new_round" , ET_IGNORE );
	
	ExecuteForward( gFW , iRet );
}

public showKlasy(id){
	showKlasy2(id);
}

showKlasy2(id,page = 0){
	new pMenu,szTmp[MAX_LEN_NAME];
	
	pMenu = menu_create("Lista \yKlas","showKlasyHandle");
	
	for(new i = 1; i < ArraySize( gClassNames ) ; i++){
		ArrayGetString(gClassNames,i,szTmp,charsmax( szTmp ));
		menu_additem(pMenu,szTmp);
	}
	
	menu_addtext(pMenu,"");
	menu_additem(pMenu,"Wyjscie");
	menu_setprop(pMenu,MPROP_PERPAGE,0)
	menu_setprop(pMenu,MPROP_NUMBER_COLOR,"\r");
	menu_setprop(pMenu,MPROP_BACKNAME,"Wroc");
	menu_setprop(pMenu,MPROP_NEXTNAME,"Dalej");
	
	menu_display(id,pMenu,page)
}

public showKlasyHandle(id,menu,item){
	if(item == MENU_EXIT){
		menu_destroy(menu);
		
		return PLUGIN_CONTINUE;
	}
	new szTitle[128],szClass[MAX_LEN_NAME],szDesc[MAX_LEN_DESC];
	
	ArrayGetString(gClassNames,item + 1 , szClass , charsmax( szClass ));
	ArrayGetString(gClassDesc, item + 1 , szDesc  , charsmax( szDesc ));
	
	formatex( szTitle, charsmax( szTitle ),"Informacje o klasie %s",szClass);
	
	showMotd(id,szTitle,.szDesc = szDesc );
	
	menu_destroy(menu);
	showKlasy2(id,item/7);
	
	return PLUGIN_CONTINUE;
}

public winCT(){
	new iBonus = get_pcvar_num(pCvarXPBonus2);
	for( new i = 1; i < MAX + 1; i++ ){
		if(!is_user_alive(i) || get_user_team(i) != 2)	continue;
		
		ColorChat(i, GREEN ,"%s Dostales^x03 %i^x01 doswiadczenia za wygranie rundy przez twoj team.", PREFIX_SAY, iBonus/2)
		giveXp(i,iBonus/2, 0)
	}
}

public winTT(){
	new iBonus = get_pcvar_num(pCvarXPBonus2);
	for( new i = 1; i < MAX + 1; i++ ){
		if(!is_user_alive(i) || get_user_team(i) != 1)	continue;
		
		ColorChat(i, GREEN ,"%s Dostales^x03 %i^x01 doswiadczenia za wygranie rundy przez twoj team.", PREFIX_SAY, iBonus/2)
		giveXp(i,iBonus/2, 0)
	}
}

public bomb_planted(iPlanter){
	new iBonus = get_pcvar_num(pCvarXPBonus2);
	for( new i = 1; i < MAX + 1; i++ ){
		if(!is_user_alive(i) || get_user_team(i) != 1 || i == iPlanter)	continue;
		
		ColorChat(i, GREEN ,"%s Dostales^x03 %i^x01 doswiadczenia za polozenie bomby przez twoj team.", PREFIX_SAY, iBonus/2)
		giveXp(i,iBonus/2, 0)
	}
	giveXp(iPlanter,iBonus, 0)
	ColorChat(iPlanter, GREEN ,"%s Dostales^x03 %i^x01 doswiadczenia za polozenie bomby.", PREFIX_SAY, iBonus)
}

public bomb_defused(iDefuse){
	new iBonus = get_pcvar_num(pCvarXPBonus2);
	for( new i = 1; i < MAX + 1; i++ ){
		if(!is_user_alive(i) || get_user_team(i) != 2 || i == iDefuse)	continue;
		
		ColorChat(i, GREEN , "%s Dostales^x03 %i^x01 doswiadczenia za rozbrojenie bomby przez twoj team.", PREFIX_SAY, iBonus/2)
		giveXp(i,iBonus/2, 0)
	}
	ColorChat(iDefuse, GREEN , "%s Dostales^x03 %i^x01 doswiadczenia za rozbrojenie bomby.", PREFIX_SAY, iBonus)
	giveXp(iDefuse,iBonus, 0)
}

public awardHostage()
{
	new id = get_loguser_index()
	
	new iBonus = get_pcvar_num(pCvarXPBonus2);
	for( new i = 1; i < MAX + 1; i++ ){
		if(!is_user_alive(i) || get_user_team(i) != 2 || i == id)	continue;
		
		ColorChat(i, GREEN , "%s Dostales^x03 %i^x01 doswiadczenia za uratowanie hostow przez twoj team.", PREFIX_SAY, iBonus/2)
		giveXp(i,iBonus/2, 0)
	}
	if (is_user_connected(id)){
		ColorChat(id, GREEN , "%s Dostales^x03 %i^x01 doswiadczenia za uratowanie hostow.", PREFIX_SAY, iBonus)
		giveXp(id,iBonus, 0)
	}	
}

stock get_loguser_index()
{
	new loguser[80], szName[64]
	read_logargv(0, loguser, charsmax( loguser ))
	parse_loguser(loguser, szName, charsmax( szName ))
	
	return get_user_index(szName)
}

public hostKilled(id)
{
	set_hudmessage ( 255, 0, 0, -1.0, 0.4, 0, 1.0,2.0, 0.1, 0.2, -1 ) 	
	show_hudmessage(id, "Straciles doswiadczenie za zabicie zakladnika")
	
	takeXp(id,get_pcvar_num(pCvarXPBonus2)/3, 0)
}

public eventDamage(id){
	static playerDamage[33];
	
	new iKiller = get_user_attacker(id);
	
	if(!is_user_alive(iKiller) || !is_user_alive(id) || iKiller == id || get_user_team(iKiller) == get_user_team(id))	return PLUGIN_CONTINUE;
	
	new iDamage	=	read_data(2);
	
	playerDamage[iKiller]	+=	iDamage;
	
	new iExp = 0,expDamage = get_pcvar_num(pCvarDamage);
	
	while(playerDamage[iKiller] >= expDamage)
	{
		playerDamage[iKiller] -= expDamage;
		iExp++
	}
	
	static gFW,iRet;
	
	if(iExp > 0){
		
		gFW = CreateMultiForward ("diablo_exp_damage",ET_CONTINUE,FP_CELL,FP_CELL);
		
		ExecuteForward(gFW, iRet, iKiller ,iExp);
		
		if(iRet != 0)	iExp	=	iRet;
		
		if(iRet >= 0){
			giveXp(iKiller,iExp, 0)
		}
		else{
			takeXp(iKiller,iExp, 0)
		}
	}
	
	gFW = CreateMultiForward ("diablo_damage_taken_post",ET_IGNORE,FP_CELL,FP_CELL,FP_CELL);
	
	ExecuteForward(gFW, iRet, iKiller,id,iDamage);
	
	return PLUGIN_CONTINUE;
}

public fwDamage(iVictim, idinflictor, iAttacker, Float:fDamage, damagebits)
{
	if(!is_user_connected(iAttacker) || !is_user_connected(iVictim) || get_user_team(iVictim) == get_user_team(iAttacker))	
		return HAM_IGNORED;
	
	#if defined DEBUG
	log_to_file( DEBUG_LOG , "fwDamage Started" )
	#endif
	
	new pFunc;
	
	if(playerInf[iVictim][currentClass] != 0){
		if(!is_user_ninja(iAttacker))
			fDamage = fDamage - (fDamage * playerInf[iVictim][dmgReduce] );
		
		pFunc = get_func_id("diablo_damage_class_taken",ArrayGetCell(gClassPlugins,playerInf[iVictim][currentClass]));
		
		if(pFunc != -1){
			callfunc_begin_i(pFunc,ArrayGetCell(gClassPlugins,playerInf[iVictim][currentClass]))
			callfunc_push_int(iVictim);
			callfunc_push_int(iAttacker);
			callfunc_push_floatrf(fDamage);
			callfunc_push_int(damagebits);
			callfunc_end();
		}
	}
	
	if(playerInf[iAttacker][currentClass] != 0){
		pFunc = get_func_id("diablo_damage_class_do",ArrayGetCell(gClassPlugins,playerInf[iAttacker][currentClass]));
		
		if(pFunc != -1){
			callfunc_begin_i(pFunc,ArrayGetCell(gClassPlugins,playerInf[iAttacker][currentClass]))
			callfunc_push_int(iVictim);
			callfunc_push_int(iAttacker);
			callfunc_push_floatrf(fDamage);
			callfunc_push_int(damagebits);
			callfunc_end();
		}
	}
	
	if(playerInf[iVictim][currentItem] != 0 ){
		pFunc = get_func_id("diablo_damage_item_taken",ArrayGetCell(gItemPlugin,playerInf[iVictim][currentItem]));
		
		if(pFunc != -1){
			callfunc_begin_i(pFunc,ArrayGetCell(gItemPlugin,playerInf[iVictim][currentItem]))
			callfunc_push_int(iVictim);
			callfunc_push_int(iAttacker);
			callfunc_push_floatrf(fDamage);
			callfunc_push_int(damagebits);
			callfunc_end();
		}
	}
			
	if(playerInf[iAttacker][currentItem] != 0){
		new szItem[ MAX_LEN_NAME ];
		if(playerInf[iVictim][currentItem] != 0 )
			ArrayGetString( gItemName , playerInf[ iVictim ][ currentItem ] , szItem , charsmax( szItem ) );
		
		if(!equal(szItem, "Ognista Tarcza")){
			pFunc = get_func_id("diablo_damage_item_do",ArrayGetCell(gItemPlugin,playerInf[iAttacker][currentItem]));
		
			if(pFunc != -1){
				callfunc_begin_i(pFunc,ArrayGetCell(gItemPlugin,playerInf[iAttacker][currentItem]))
				callfunc_push_int(iVictim);
				callfunc_push_int(iAttacker);
				callfunc_push_floatrf(fDamage);
				callfunc_push_int(damagebits);
				callfunc_end();
			}
		}
	}
	
	new tempArray[ 1 ] , gFW , iRet;
	tempArray[ 0 ]	=	_:fDamage;
	
	new pArray	=	PrepareArray( tempArray , 1 , 1);
	
	gFW = CreateMultiForward ("diablo_damage_taken_pre",ET_IGNORE,FP_CELL,FP_CELL,FP_ARRAY);
	
	ExecuteForward(gFW, iRet, iAttacker,iVictim,pArray);
	
	if(fDamage < 0.0)	fDamage = 0.0;
	
	SetHamParamFloat(4, fDamage );
	
	#if defined DEBUG
	log_to_file( DEBUG_LOG , "fwDamage End" )
	#endif
	
	return HAM_HANDLED;
}

public client_PostThink(id){
	if(playerInf[id][currentClass] == 0 || is_user_bot(id) || !is_user_alive(id))	return ;
	
	new gFw,iRet;
	
	gFw = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_postThink",FP_CELL);
	
	ExecuteForward(gFw,iRet,id);
}

public client_PreThink(id){
	if(playerInf[id][currentClass] == 0 || is_user_bot(id))	return PLUGIN_CONTINUE;
	
	if( Float:playerInf[id][castTime] <= get_gametime() && Float:playerInf[id][castTime] != 0.0 && is_user_alive(id)){
		
		playerInf[id][castTime]		=	_:0.0;
		
		message_begin( MSG_ONE, gmsgBartimer, {0,0,0}, id ) 
		write_byte( 0 ) 
		write_byte( 0 )
		message_end()
		
		set_hudmessage(60, 200, 25, -1.0, 0.25, 0, 1.0, 2.0, 0.1, 0.2, 2)
		
		new gFw,iRet;
		
		gFw = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_call_cast",FP_CELL);
		
		ExecuteForward(gFw,iRet,id);
	}
	
	else if( Float:playerInf[id][castTime] > 0.0 && (!is_user_alive(id) || get_user_button(id) & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT) || get_user_weapon(id) != CSW_KNIFE || !(get_entity_flags(id) & FL_ONGROUND) || bFreezeTime) || bow[id]){
		new gFw,iRet;
		
		gFw = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_cast_stop",FP_CELL);
		
		ExecuteForward(gFw,iRet,id);
		
		if(iRet != DIABLO_STOP){
			playerInf[id][castTime]		=	_:0.0;
			
			message_begin( MSG_ONE, gmsgBartimer, {0,0,0}, id ) 
			write_byte( 0 ) 
			write_byte( 0 )
			message_end()
		}
	}
	
	else if(Float:playerInf[id][castTime] == 0.0 && is_user_alive(id) && get_user_weapon(id) == CSW_KNIFE && get_entity_flags(id) & FL_ONGROUND && !bFreezeTime && !bow[id]){
		new gFw,iRet,bool:bBreak = false;
		
		if(get_user_button(id) & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT)){
			
			gFw = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_cast_move",FP_CELL);
			
			ExecuteForward(gFw,iRet,id);
			
			if(iRet == DIABLO_STOP || iRet == 0){
				bBreak = true;
			}
		}
		
		if(!bBreak){
			iRet	=	_:0.0;
			
			gFw = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_cast_time",FP_CELL,FP_FLOAT);
			
			ExecuteForward(gFw,iRet,id,5.0-(float(getUserInt( id ))/25.0));
			
			if(Float:iRet != 0.0){

				message_begin( MSG_ONE, gmsgBartimer, {0,0,0}, id ) 
				write_byte( floatround(Float:iRet,floatround_ceil) ) 
				write_byte( 0 ) 
				message_end() 
				
				playerInf[id][castTime]	= _:(get_gametime() + floatround(Float:iRet,floatround_ceil));
			}
		}
	}
	
	if(g_GrenadeTrap[id] && get_user_button(id) & IN_ATTACK2)
	{
		switch(get_user_weapon(id))
		{
		case CSW_HEGRENADE, CSW_FLASHBANG, CSW_SMOKEGRENADE:
			{
				if((g_PreThinkDelay[id] + 0.28) < get_gametime())
				{
					switch(g_TrapMode[id])
					{
					case 0: g_TrapMode[id] = true;
					case 1: g_TrapMode[id] = false;
					}
					client_print(id, print_center, "Grenade Trap %s", g_TrapMode[id] ? "[ON]" : "[OFF]")
					g_PreThinkDelay[id] = get_gametime()
				}
			}
		default: g_TrapMode[id] = false
		}
	}
	
	if(bHasBow[id]){
		new button2 = get_user_button(id);
		
		if (get_user_button(id) & IN_RELOAD && !(get_user_oldbutton(id) & IN_RELOAD) && get_user_weapon(id) == CSW_KNIFE && !bow[id]){
			bow[id] = true;
			commandBow(id)
		}
		else if (get_user_button(id) & IN_RELOAD && !(get_user_oldbutton(id) & IN_RELOAD) && get_user_weapon(id) == CSW_KNIFE && bow[id]){
			bow[id] = false;
			entity_set_string(id, EV_SZ_viewmodel, KNIFE_VIEW)  
			entity_set_string(id, EV_SZ_weaponmodel, KNIFE_PLAYER)  
		}
		
		if(bow[id]){
			if( bowdelay[id] < get_gametime() && button2 & IN_ATTACK)
			{
				bowdelay[id] = get_gametime() + 4.25 - ( float( getUserInt( id ) ) / 25.0 );
				
				command_arrow(id) 
			}
			entity_set_int(id, EV_INT_button, (button2 & ~IN_ATTACK) & ~IN_ATTACK2)
		}
	}
	
	if( pev(id,pev_button) & IN_RELOAD && is_user_alive(id) && !bFreezeTime && playerInf[id][maxKnife] > 0 && (is_user_ninja(id) || get_user_weapon(id) == CSW_KNIFE))	commandKnife(id);

	if(is_user_alive(id)){
		new gFw,iRet;
		
		if( playerInf[id][currentClass] != 0 ){
			gFw = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_preThink",FP_CELL);
			
			ExecuteForward(gFw,iRet,id);
		}
		
		if(playerInf[id][currentItem] != 0 ){
			gFw = CreateOneForward(ArrayGetCell(gItemPlugin,playerInf[id][currentItem]),"diablo_preThinkItem",FP_CELL);
			
			ExecuteForward(gFw,iRet,id);
		}
		
		if(  playerInf[id][currentClass] != 0 && !bFreezeTime && Float:playerInf[id][castTime] == 0.0 && pev(id,pev_button) & IN_USE && !( pev( id , pev_oldbuttons ) & IN_USE ) ){
			
			new Float:origin[3]
			pev(id, pev_origin, origin)
			
			//Func door and func door rotating
			new aimid, body
			get_user_aiming ( id, aimid, body ) 
			
			if (aimid > 0)
			{
				new classname[32]
				pev(aimid,pev_classname,classname,31)
				
				if (equal(classname,"func_door_rotating") || equal(classname,"func_door") || equal(classname,"func_button"))
				{
					new Float:doororigin[3]
					pev(aimid, pev_origin, doororigin)
					
					if (get_distance_f(origin, doororigin) < 70 && UTIL_In_FOV(id,aimid))
						return PLUGIN_CONTINUE
				}
				
			}
			
			//Bomb condition
			new bomb
			if ((bomb = find_ent_by_model(-1, "grenade", "models/w_c4.mdl"))) 
			{
				new Float:bombpos[3]
				pev(bomb, pev_origin, bombpos)
				
				//We are near the bomb and have it in FOV.
				if (get_distance_f(origin, bombpos) < 100 && UTIL_In_FOV(id,bomb))
					return PLUGIN_CONTINUE
			}
			
			
			//Hostage
			new hostage = engfunc(EngFunc_FindEntityByString, -1,"classname", "hostage_entity")
			
			while (hostage)
			{
				new Float:hospos[3]
				pev(hostage, pev_origin, hospos)
				if (get_distance_f(origin, hospos) < 70 && UTIL_In_FOV(id,hostage))
				return PLUGIN_CONTINUE
				
				hostage = engfunc(EngFunc_FindEntityByString, hostage,"classname", "hostage_entity")
			}
			
			new gFw , iRet;
			
			gFw = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]), "diablo_class_skill_used", FP_CELL);
			
			ExecuteForward(gFw, iRet, id);
			
			if( playerInf[ id ][ currentItem ] != 0){
				gFw = CreateOneForward(ArrayGetCell(gItemPlugin,playerInf[id][currentItem]), "diablo_item_skill_used", FP_CELL);
				
				ExecuteForward(gFw, iRet, id);
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public command_arrow(id) 
{
	if(!is_user_alive(id)) return PLUGIN_HANDLED
	
	new Float: Origin[3], Float: Velocity[3], Float: vAngle[3], Ent
	
	entity_get_vector(id, EV_VEC_origin , Origin)
	entity_get_vector(id, EV_VEC_v_angle, vAngle)
	
	Ent = create_entity("info_target")
	
	if (!Ent) return PLUGIN_HANDLED
	
	entity_set_string(Ent, EV_SZ_classname, "xbow_arrow")
	entity_set_model(Ent, cbow_bolt)
	
	new Float:MinBox[3] = {-2.8, -2.8, -0.8}
	new Float:MaxBox[3] = {2.8, 2.8, 2.0}
	entity_set_vector(Ent, EV_VEC_mins, MinBox)
	entity_set_vector(Ent, EV_VEC_maxs, MaxBox)
	
	vAngle[0]*= -1
	Origin[2]+=10
	
	entity_set_origin(Ent, Origin)
	entity_set_vector(Ent, EV_VEC_angles, vAngle)
	
	entity_set_int(Ent, EV_INT_effects, 2)
	entity_set_int(Ent, EV_INT_solid, 1)
	entity_set_int(Ent, EV_INT_movetype, 5)
	entity_set_edict(Ent, EV_ENT_owner, id)
	new Float:dmg = (get_pcvar_float(pCvarArrow) + getUserInt( id ) * get_pcvar_float(pCvarMulti))
	entity_set_float(Ent, EV_FL_dmg, dmg)
	
	VelocityByAim(id, get_pcvar_num(pCvarSpeed) , Velocity)
	set_rendering (Ent,kRenderFxGlowShell, 255,0,0, kRenderNormal,56)
	entity_set_vector(Ent, EV_VEC_velocity ,Velocity)
	
	return PLUGIN_HANDLED
}

public commandBow(id) 
{
	if(!is_user_alive(id)) return PLUGIN_HANDLED
	
	if(bow[id]){
		entity_set_string(id,EV_SZ_viewmodel,cbow_VIEW)
		entity_set_string(id,EV_SZ_weaponmodel,cvow_PLAYER)
	}
	
	return PLUGIN_CONTINUE
}

public toucharrow(arrow, id)
{	
	new kid = entity_get_edict(arrow, EV_ENT_owner)
	new lid = entity_get_edict(arrow, EV_ENT_enemy)
	
	if(is_user_alive(id)) 
	{
		if(kid == id || lid == id) return
		
		entity_set_edict(arrow, EV_ENT_enemy,id)
		
		new Float:dmg = entity_get_float(arrow,EV_FL_dmg)
		
		dmg -= getUserDex( id );
		
		if(get_cvar_num("mp_friendlyfire") == 0 && get_user_team(id) == get_user_team(kid)) return
		
		bloodEffect(id,248)
		
		if(is_user_alive( id ) ){
			doDamage(id,kid,dmg,diabloDamageKnife);
		}
		
		screenShake( id , 7<<14 , 1<<13 , 1<<14 )	
		
		emit_sound(id, CHAN_ITEM, "weapons/knife_hit4.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		remove_entity(arrow)
	}
}

public touchWorld2(arrow, world)
{
	remove_entity(arrow)
}

public think_Bot(bot)
{
	new ent = -1
	while((ent = find_ent_by_class(ent, "grenade")))
	{
		new entModel[33]
		entity_get_string(ent, EV_SZ_model, entModel, 32)
		
		if(equal(entModel, "models/w_c4.mdl"))
		continue

		if(!entity_get_int(ent, NADE_ACTIVE))
		continue
		
		new Players[32], iNum
		get_players(Players, iNum, "a")
		
		for(new i = 0; i < iNum; ++i)
		{
			new id = Players[i];
			
			if(entity_get_int(ent, NADE_TEAM) == get_user_team(id)) 
				continue
			
			if(get_entity_distance(id, ent) > cvar_activate_dis || player_speed(id) <200.0) 
			continue
			
			if(entity_get_int(ent, NADE_VELOCITY)) continue
			
			new Float:fOrigin[3]
			entity_get_vector(ent, EV_VEC_origin, fOrigin)
			while(PointContents(fOrigin) == CONTENTS_SOLID)
			fOrigin[2] += 100.0
			
			entity_set_vector(ent, EV_VEC_origin, fOrigin)
			drop_to_floor(ent)
			
			new Float:fVelocity[3]
			entity_get_vector(ent, EV_VEC_velocity, fVelocity)
			fVelocity[2] += float(cvar_nade_vel)
			entity_set_vector(ent, EV_VEC_velocity, fVelocity)
			entity_set_int(ent, NADE_VELOCITY, 1)
			
			new param[1]
			param[0] = ent 
			//set_task(cvar_explode_delay, "task_ExplodeNade", 0, param, 1)
			entity_set_float(param[0], EV_FL_nextthink, halflife_time() + cvar_explode_delay)
			entity_set_int(param[0], NADE_PAUSE, 0)
		}
	}
	
	entity_set_float(bot, EV_FL_nextthink, halflife_time() + 0.1)
}

stock Float:player_speed(index) 
{
	new Float:vec[3]
	
	pev(index,pev_velocity,vec)
	vec[2]=0.0
	
	return floatsqroot ( vec[0]*vec[0]+vec[1]*vec[1] )
}

public _create_ThinkBot()
{
	new think_bot = create_entity("info_target")
	if(is_valid_ent(think_bot)){
		entity_set_string(think_bot, EV_SZ_classname, "think_bot")
		entity_set_float(think_bot, EV_FL_nextthink, halflife_time() + 1.0)
	}
}

public grenade_throw(id, ent, wID)
{	
	if(!g_TrapMode[id] || !is_valid_ent(ent))
		return PLUGIN_CONTINUE
	
	new Float:fVelocity[3]
	VelocityByAim(id, cvar_throw_vel, fVelocity)
	entity_set_vector(ent, EV_VEC_velocity, fVelocity)
	
	new Float: angle[3]
	entity_get_vector(ent,EV_VEC_angles,angle)
	angle[0]=0.00
	entity_set_vector(ent,EV_VEC_angles,angle)
	
	entity_set_float(ent,EV_FL_dmgtime,get_gametime()+3.5)
	
	entity_set_int(ent, NADE_PAUSE, 0)
	entity_set_int(ent, NADE_ACTIVE, 0)
	entity_set_int(ent, NADE_VELOCITY, 0)
	entity_set_int(ent, NADE_TEAM, get_user_team(id))
	
	new param[1]
	param[0] = ent
	set_task(3.0, "task_ActivateTrap", 0, param, 1)
	
	return PLUGIN_CONTINUE
}

public task_ActivateTrap(param[])
{
	new ent = param[0]
	if(!is_valid_ent(ent)) 
	return PLUGIN_CONTINUE
	
	entity_set_int(ent, NADE_PAUSE, 1)
	entity_set_int(ent, NADE_ACTIVE, 1)
	
	new Float:fOrigin[3]
	entity_get_vector(ent, EV_VEC_origin, fOrigin)
	//fOrigin[2] -= 8.1*(1.0-floatpower( 2.7182, -0.06798*float(getUserAgi( entity_get_edict(ent,EV_ENT_owner) ))))
	entity_set_vector(ent, EV_VEC_origin, fOrigin)
	
	return PLUGIN_CONTINUE
}

public think_Grenade(ent)
{
	new entModel[33]
	entity_get_string(ent, EV_SZ_model, entModel, 32)
	
	if(!is_valid_ent(ent) || equal(entModel, "models/w_c4.mdl"))
	return PLUGIN_CONTINUE
	
	if(entity_get_int(ent, NADE_PAUSE))
	return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public sqlStart(){
	
	new szHost[64],szUser[64],szPass[64],szDb[64];
	
	get_pcvar_string(pSqlCvars[eHost],szHost,charsmax( szHost ) );
	get_pcvar_string(pSqlCvars[eUser],szUser,charsmax( szUser ) );
	get_pcvar_string(pSqlCvars[ePass],szPass,charsmax( szPass ) );
	get_pcvar_string(pSqlCvars[eDb],szDb,charsmax( szDb ) );
	
	gTuple = SQL_MakeDbTuple(szHost,szUser,szPass,szDb);
	
	new szCommand[1024],iLen = 0;
	
	iLen += formatex(szCommand,charsmax( szCommand ),"CREATE TABLE IF NOT EXISTS %s (`ip` VARCHAR ( 64 ) , `sid` VARCHAR (64) , `nick` VARCHAR( 64 ) , `klasa` VARCHAR(64) , PRIMARY KEY(nick, klasa), `lvl` INT(10) NOT NULL DEFAULT  '1', `exp` INT(10) NOT NULL DEFAULT  '0' ,`str` INT(10) NOT NULL DEFAULT  '0',",SQL_TABLE)
	iLen += formatex(szCommand[ iLen ],charsmax( szCommand ) - iLen,"`int` INT(10) NOT NULL DEFAULT  '0' , `dex` INT(10) NOT NULL DEFAULT  '0' , `agi` INT(10) NOT NULL DEFAULT  '0' , `points` INT(10) NOT NULL DEFAULT  '0')" );
	
	SQL_ThreadQuery(gTuple,"sqlStartHandle",szCommand)
}

public sqlStartHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	if(Errcode)
	{
		log_to_file("addons/amxmodx/logs/diablo.log","sqlStartHandle: Error on Table query: %s",Error)
	}
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		log_to_file("addons/amxmodx/logs/diablo.log","sqlStartHandle: Could not connect to SQL database.")
		
		return PLUGIN_CONTINUE
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		log_to_file("addons/amxmodx/logs/diablo.log","sqlStartHandle: Table Query failed.")
		
		return PLUGIN_CONTINUE
	}
	bSql = true;
	
	return PLUGIN_CONTINUE
}

public client_putinserver(id)
{
	if(is_user_bot(id) || is_user_hltv(id))
		return;
		
	cmdExecute(id, "bind v menu");
	cmdExecute(id, "hud_centerid 0");
		
	iPlayersNum++;
	
	ArrayClear(playerInfClasses[id]);
	ArrayClear(playerInfRender[id]);
	
	new iInput[7] = {0,0,0,0,0,0,0}
	
	for(new i = 0 ; i < ArraySize(gClassNames) ; i++){
		ArrayPushArray(playerInfClasses[id],iInput)
	}
	
	playerInf[id][currentClass] 	= 	0;
	playerInf[id][currentLevel] 	= 	1;
	playerInf[id][currentExp]		=	0;
	playerInf[id][currentStr]		=	0;
	playerInf[id][currentInt]		=	0;
	playerInf[id][currentDex]		=	0;
	playerInf[id][currentAgi]		=	0;
	playerInf[id][currentPoints] 	=	0;
	playerInf[id][currentItem]		=	0;
	playerInf[id][extraStr]		=	0;
	playerInf[id][extraInt]		=	0;
	playerInf[id][extraDex]		=	0;
	playerInf[id][extraAgi]		=	0;
	playerInf[id][itemDurability]	=	0;
	playerInf[id][maxHp]			=	100;
	playerInf[id][castTime]			=	_:0.0;
	playerInf[id][currentSpeed]		=	_:BASE_SPEED;
	playerInf[id][dmgReduce]		=	_:0.0;
	playerInf[id][maxKnife]			=	0;
	playerInf[id][howMuchKnife]		=	0;
	playerInf[id][tossDelay]		=	_:0.0;
	playerInf[id][userGrav]			=	_:1.0;
	playerInf[id][playerHud]			=	0;
	get_user_name(id, playerInf[id][playerName], MAX_LEN_NAME_PLAYER-1);

	replace_all(playerInf[id][playerName], 63, "'", "\'" );
	replace_all(playerInf[id][playerName], 63, "`", "\`" );  
	replace_all(playerInf[id][playerName], 63, "\\", "\\\\" );
	replace_all(playerInf[id][playerName], 63, "^0", "\0");
	replace_all(playerInf[id][playerName], 63, "^n", "\n");
	replace_all(playerInf[id][playerName], 63, "^r", "\r");
	replace_all(playerInf[id][playerName], 63, "^x1a", "\Z"); 
	
	new iInputRedner[8];
	
	iInputRedner[0]	=	255;
	iInputRedner[1]	=	255
	iInputRedner[2]	=	255
	iInputRedner[3]	=	kRenderFxNone;
	iInputRedner[4]	=	kRenderNormal;
	iInputRedner[5]	=	16;
	iInputRedner[6]	=	_:0.0;
	iInputRedner[7]	=	0;
	
	ArrayPushArray(playerInfRender[id],iInputRedner);
	
	sqlPlayer[id] = false;
	
	set_task(0.1, "LoadInfo", id);
	
	bFirstRespawn[id] = true;
	
	LoadHUD(id);
	
	set_task(TIME_HUD,"writeHud", id + HUD_TASK_ID, .flags = "b");
}

public client_disconnect(id)
{
	new entArrow = find_ent_by_class(0, XBOW_ARROW);
	while(entArrow > 0)
	{
		if(entity_get_edict(entArrow, EV_ENT_owner) == id)
			remove_entity(entArrow);
		entArrow = find_ent_by_class(entArrow, XBOW_ARROW);
	}
	
	SaveInfo(id, 2);
	
	iPlayersNum--;
	
	remove_task(id + HUD_TASK_ID);
	
	if(playerInf[id][currentClass] != 0)
	{
		new gFW,iRet;
		
		gFW = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_class_disabled",FP_CELL);
		
		ExecuteForward(gFW, iRet, id);
		
		gFW = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_clean_data",FP_CELL);
		
		ExecuteForward(gFW,iRet,id);
		
		if( playerInf[id][currentItem] != 0 )
		{
			new gFw , iRet;
			
			gFw	=	CreateOneForward( ArrayGetCell(gItemPlugin , playerInf[ id ][ currentItem ] ) , "diablo_item_reset" , FP_CELL );
			
			ExecuteForward( gFw , iRet , id );
			
			playerInf[id][currentItem]		=	0;
			playerInf[id][itemDurability]	=	0;
		}
	}
	
	ArrayClear(playerInfClasses[id]);
	ArrayClear(playerInfRender[id]);
}

public getUserStr( id ){
	return playerInf[id][currentStr] + playerInf[id][extraStr];
}

public getUserInt( id ){
	return playerInf[id][currentInt] + playerInf[id][extraInt];
}

public getUserDex( id ){
	return playerInf[id][currentDex] + playerInf[id][extraDex];
}

public getUserAgi( id ){
	return playerInf[id][currentAgi] + playerInf[id][extraAgi];
}

public plugin_end(){
	nvault_close(DiabloHUD)
	
	SQL_FreeHandle(gTuple);
	
	ArrayDestroy(gClassPlugins);
	ArrayDestroy(gClassNames);
	ArrayDestroy(gClassHp);
	ArrayDestroy(gClassDesc);
	ArrayDestroy(gClassFlag);
	ArrayDestroy(gItemName);
	ArrayDestroy(gItemPlugin);
	ArrayDestroy(gItemDur);
	ArrayDestroy(gFractionNames);
	ArrayDestroy(gClassFraction);
	
	for(new i = 1;i < MAX + 1; i++ ){
		ArrayDestroy(playerInfClasses[i])
		ArrayDestroy(playerInfRender[i]);
	}
}

playerPointsMenu(id,page = 0){
	if(playerInf[id][currentClass] == 0 || playerInf[id][currentPoints] <= 0)	return PLUGIN_CONTINUE;
	
	new pMenu,szTmp[128];
	
	formatex(szTmp,charsmax( szTmp ),"Wybierz Staty - \rPunkty: %i",playerInf[id][currentPoints]);
	pMenu = menu_create(szTmp,"playerPointsMenuHandle")
	
	formatex(szTmp,charsmax( szTmp ),"Inteligencja \r[%i] \y[Wieksze obrazenia czarami]", getUserInt( id ));
	menu_additem(pMenu,szTmp , "0" );
	
	formatex(szTmp,charsmax( szTmp ),"Sila \r[%i] \y[Wiecej zycia]", getUserStr( id ));
	menu_additem(pMenu,szTmp , "1" );
	
	formatex(szTmp,charsmax( szTmp ),"Zrecznosc \r[%i] \y[Bronie zadaja ci mniejsze obrazenia]", getUserAgi( id ));
	menu_additem(pMenu,szTmp , "2" );
	
	formatex(szTmp,charsmax( szTmp ),"Zwinnosc \r[%i] \y[Szybciej biegasz i magia zadaje ci mniejsze obrazenia]^n", getUserDex( id ));
	menu_additem(pMenu,szTmp, "3");
	
	formatex(szTmp,charsmax( szTmp ),"Szybkosc Rozdawania \r[%i] \y[Ilosc rozdawanych jednorazowo punktow]", SkillsValues[ SkillsSpeed[ id ] ]);
	menu_additem(pMenu,szTmp, "4");
	
	menu_setprop(pMenu,MPROP_NUMBER_COLOR,"\r");
	menu_setprop(pMenu,MPROP_BACKNAME,"Wroc");
	menu_setprop(pMenu,MPROP_EXITNAME,"Wyjscie");
	menu_setprop(pMenu,MPROP_NEXTNAME,"Dalej");
	
	#if defined BOTY
	if( is_user_bot( id ) ){
		playerPointsMenuHandle(id , pMenu,  random_num( 0 , 3 ) )
		
		return PLUGIN_HANDLED;
	}
	#endif
	
	menu_display(id,pMenu,page)
	
	return PLUGIN_CONTINUE;
}

public playerPointsMenuHandle(id,menu,item){
	if(item == MENU_EXIT || playerInf[id][currentClass] == 0 || playerInf[id][currentPoints] <= 0){
		menu_destroy(menu);
		
		return PLUGIN_CONTINUE;
	}
	
	new data[6], iName[64]
	new acces, callback
	menu_item_getinfo(menu, item, acces, data,5, iName, 63, callback)
	
	new iPage	=	item / 7;
	
	new item	=	str_to_num( data );
	
	new value = (SkillsValues[SkillsSpeed[id]] > playerInf[id][currentPoints] ? playerInf[id][currentPoints] : SkillsValues[SkillsSpeed[id]])
	
	switch(item){
	case 0:{
			if(playerInf[id][currentInt] + value <= MAX_SKILL){
				playerInf[id][currentInt] += value;
				playerInf[id][currentPoints] -= value;
			}
			else if(playerInf[id][currentInt] != MAX_SKILL){
				playerInf[id][currentPoints] -= (MAX_SKILL-playerInf[id][currentInt]);
				playerInf[id][currentInt] = MAX_SKILL;
			}
			else 
				ColorChat(id,GREEN,"%s Maksymalny poziom inteligencji osiagniety.", PREFIX_SAY)
		}
	case 1:{
			if(playerInf[id][currentStr] + value <= MAX_SKILL){
				playerInf[id][currentStr] += value;
				playerInf[id][currentPoints] -= value;
			}
			else if(playerInf[id][currentStr] != MAX_SKILL){
				playerInf[id][currentPoints] -= (MAX_SKILL-playerInf[id][currentStr]);
				playerInf[id][currentStr] = MAX_SKILL;
			}
			else 
				ColorChat(id,GREEN,"%s Maksymalny poziom sily osiagniety.", PREFIX_SAY)
		}
	case 2:{
			if(playerInf[id][currentAgi] + value <= MAX_SKILL){
				playerInf[id][currentAgi] += value;
				playerInf[id][currentPoints] -= value;
				
				//playerInf[id][dmgReduce]		=	_:(36.3057*(1.0-floatpower( 2.7182, -0.03398*float(getUserAgi( id ))))/100);
				playerInf[id][dmgReduce]		=	_:damage_reduction(getUserAgi( id ))
			}
			else if(playerInf[id][currentAgi] != MAX_SKILL){
				playerInf[id][currentPoints] -= (MAX_SKILL-playerInf[id][currentAgi]);
				playerInf[id][currentAgi] = MAX_SKILL;
				
				//playerInf[id][dmgReduce]		=	_:(36.3057*(1.0-floatpower( 2.7182, -0.03398*float(getUserAgi( id ))))/100);
				playerInf[id][dmgReduce]		=	_:damage_reduction(getUserAgi( id ))
			}
			else 
				ColorChat(id,GREEN,"%s Maksymalny poziom zrecznosci osiagniety.", PREFIX_SAY)
		}
	case 3:{
			if(playerInf[id][currentDex] + value <= MAX_SKILL){
				playerInf[id][currentDex] += value;
				playerInf[id][currentPoints] -= value;
			}
			else if(playerInf[id][currentDex] != MAX_SKILL){
				playerInf[id][currentPoints] -= (MAX_SKILL-playerInf[id][currentDex]);
				playerInf[id][currentDex] = MAX_SKILL;
			}
			else 
				ColorChat(id,GREEN,"%s Maksymalny poziom zwinnosci osiagniety.", PREFIX_SAY)
		}
	case 4: {
		if(SkillsSpeed[id] < charsmax(SkillsValues)) 
			SkillsSpeed[id]++;
		else 
			SkillsSpeed[id] = 0;
		}
	}
	
	if(playerInf[id][currentClass] != 0 && playerInf[id][currentPoints] > 0)	playerPointsMenu(id,iPage);
	
	return PLUGIN_CONTINUE;
}

public clearRender(id){
	if(ArraySize(playerInfRender[id]) != 1){	
		new Array:arrayTmp = ArrayCreate(8,1);
		new iOutput[8] , bool:bPush = true;
		
		for(new i = ArraySize(playerInfRender[id]) - 1 ; i >= 0 ; i-- ){
			ArrayGetArray(playerInfRender[id],i,iOutput);
			
			if( ( Float:iOutput[6] == 0.0 || Float:iOutput[6] > get_gametime() ) && iOutput[7] != DIABLO_RENDER_DESTROYED){			
				if(bPush){
					bPush	=	false;
					ArrayPushArray(arrayTmp,iOutput);
				}
				else{
					if(Float:iOutput[6] != 0.0){
						new iTmpOutput[8];
						ArrayGetArray(arrayTmp,0,iTmpOutput);
						if(Float:iTmpOutput[6] < Float:iOutput[6])
						ArrayInsertArrayBefore(arrayTmp,0,iOutput);
					}
					else
					ArrayInsertArrayBefore(arrayTmp,0,iOutput);
				}
			}
			if(Float:iOutput[6] == 0.0 && iOutput[7] != DIABLO_RENDER_DESTROYED )	break;
		}
		
		ArrayClear(playerInfRender[id]);
		
		for( new i = 0; i < ArraySize(arrayTmp) ; i++ ){
			ArrayGetArray(arrayTmp,i,iOutput);
			ArrayPushArray(playerInfRender[id],iOutput)
		}
		
		ArrayDestroy(arrayTmp);
	}
	else {
		new iOutput[8];
		ArrayGetArray( playerInfRender[id] , 0 , iOutput );
		
		if( iOutput[ 7 ] == DIABLO_RENDER_DESTROYED ){
			ArrayClear(playerInfRender[id]);
			
			new iInputRedner[8];
			
			iInputRedner[0]	=	255;
			iInputRedner[1]	=	255
			iInputRedner[2]	=	255
			iInputRedner[3]	=	kRenderFxNone;
			iInputRedner[4]	=	kRenderNormal;
			iInputRedner[5]	=	16;
			iInputRedner[6]	=	_:0.0;
			iInputRedner[7]	=	0;
			
			ArrayPushArray(playerInfRender[id],iInputRedner);
		}
	}
}

/*---------------------NATIVES---------------------*/

public plugin_natives(){
	register_native("diablo_register_class","registerClass");
	
	register_native("diablo_get_user_class","getClass");
	register_native("diablo_set_user_class","setClass");
	register_native("diablo_get_class_name","getClassName" , 1);
	register_native("diablo_get_classes_num","getClassesNum");
	register_native("diablo_get_user_level","getLevel");
	register_native("diablo_get_user_exp","getExp");
	register_native("diablo_get_level_exp","getLevelExp");
	register_native("diablo_set_user_exp","setExp");
	register_native("diablo_get_user_points","getPoints")
	register_native("diablo_get_user_str","getStr");
	register_native("diablo_get_user_int","getInt");
	register_native("diablo_get_user_dex","getDex");
	register_native("diablo_get_user_agi","getAgi");
	
	register_native("diablo_is_class_from","isFrom");
	
	register_native("diablo_is_this_class","isThisClass");
	register_native("diablo_is_this_item","isThisItem");
	
	register_native("diablo_set_speed","setSpeed");
	register_native("diablo_add_speed","addSpeed");
	register_native("diablo_reset_speed","resetSpeed");
	
	register_native("diablo_get_speed","getSpeed")
	register_native("diablo_get_speed_extra","getSpeedExtra")
	
	register_native("diablo_damage","doDamage" , 1);
	register_native("diablo_create_explode","createExplode")
	
	register_native("diablo_add_hp","addHP");
	register_native("diablo_add_force_hp","addForceHP");
	register_native("diablo_add_max_hp","addMaxHp");
	register_native("diablo_set_max_hp","setMaxHp");
	register_native("diablo_get_max_hp","getMaxHp");
	
	register_native("diablo_is_freezetime","isFreeze");
	
	register_native("diablo_write_hud_native","writeHudNative");
	register_native("diablo_show_hudmsg","showHudMsg");
	register_native("diablo_player_hud","checkHUD");
	
	register_native("diablo_get_xpbonus","xpBonus");
	register_native("diablo_get_xpbonus2","xpBonus2");
	
	register_native("diablo_add_xp","addNativeXp");
	register_native("diablo_take_xp","takeNativeXp");
	
	register_native("diablo_add_knife","knifeAdd");
	register_native("diablo_set_knife","knifeSet");
	
	register_native("diablo_set_user_grav","setGrav");
	register_native("diablo_add_user_grav","addGrav");
	register_native("diablo_get_user_grav","getGrav");
	
	register_native("diablo_kill","killPlayer");
	
	register_native("diablo_give_user_trap","userTrap")
	register_native("diablo_give_user_bow","userBow")
	
	register_native("diablo_set_user_render","setUserRender");
	register_native("diablo_render_cancel","cancelRender");
	
	register_native("diablo_display_icon","displayIcon");
	register_native("diablo_display_fade","displayFade");
	register_native("diablo_screen_shake","screenShake" , 1);
	
	register_native("diablo_register_item","registerItem");
	register_native("diablo_get_user_item","getItem");
	register_native("diablo_get_item_name","getItemName", 1);
	register_native("diablo_get_items_num","getItemsNum");
	
	register_native("diablo_add_extra_str" , "addExtraStr");
	register_native("diablo_add_extra_int" , "addExtraInt");
	register_native("diablo_add_extra_agi" , "addExtraAgi");
	register_native("diablo_add_extra_dex" , "addExtraDex");
	
	register_native("diablo_set_extra_str" , "setExtraStr");
	register_native("diablo_set_extra_int" , "setExtraInt");
	register_native("diablo_set_extra_agi" , "setExtraAgi");
	register_native("diablo_set_extra_dex" , "setExtraDex");
	
	register_native("diablo_reset_grav" , "resetGrav" );
	
	set_native_filter("native_filter");
}

public native_filter(const name[], index, trap)
{
    if (!trap)
        return PLUGIN_HANDLED;
        
    return PLUGIN_CONTINUE;
}

public resetGrav( plugin , params ){
	if( params != 1 )
	return PLUGIN_CONTINUE;
	
	playerInf[get_param( 1 )][userGrav]			=	_:1.0;
	
	gravChange( get_param( 1 ) );
	
	return PLUGIN_CONTINUE;
}

public addExtraStr( plugin , params ){
	if( params != 2 )
	return -1;
	
	playerInf[ get_param( 1 ) ][ extraStr ]	+=	get_param( 2 );
	
	return playerInf[ get_param( 1 ) ][ extraStr ];
}

public addExtraInt( plugin , params ){
	if( params != 2 )
	return -1;
	
	playerInf[ get_param( 1 ) ][ extraInt ]	+=	get_param( 2 );
	
	return playerInf[ get_param( 1 ) ][ extraInt ];
}

public addExtraDex( plugin , params ){
	if( params != 2 )
	return -1;
	
	playerInf[ get_param( 1 ) ][ extraDex ]	+=	get_param( 2 );
	
	return playerInf[ get_param( 1 ) ][ extraDex ];
}

public addExtraAgi( plugin , params ){
	if( params != 2 )
	return -1;
	
	playerInf[ get_param( 1 ) ][ extraAgi ]	+=	get_param( 2 );
	
	return playerInf[ get_param( 1 ) ][ extraAgi ];
}

public setExtraStr( plugin , params ){
	if( params != 2 ){
		return -1;
	}
	
	playerInf[ get_param( 1 ) ][ extraStr ]	=	get_param( 2 );
	
	return playerInf[ get_param( 1 ) ][ extraStr ];
}

public setExtraInt( plugin , params ){
	if( params != 2 ){
		return -1;
	}
	
	playerInf[ get_param( 1 ) ][ extraInt ]	=	get_param( 2 );
	
	return playerInf[ get_param( 1 ) ][ extraInt ];
}

public setExtraDex( plugin , params ){
	if( params != 2 ){
		return -1;
	}
	
	playerInf[ get_param( 1 ) ][ extraDex ]	=	get_param( 2 );
	
	return playerInf[ get_param( 1 ) ][ extraDex ];
}

public setExtraAgi( plugin , params ){
	if( params != 2 ){
		return -1;
	}
	
	playerInf[ get_param( 1 ) ][ extraAgi ]	=	get_param( 2 );
	
	return playerInf[ get_param( 1 ) ][ extraAgi ];
}

public getMaxHp( plugin , params ){
	if( params != 1 )
	return -1;
	
	return playerInf[ get_param( 1 ) ][ maxHp ];
}

public setMaxHp( plugin , params ){
	if( params != 2 )
	return PLUGIN_CONTINUE;
	
	new id	=	get_param( 1 );
	
	playerInf[ id ][ maxHp ]	=	get_param( 2 );
	
	if( playerInf[ id ][ maxHp ]	>	get_user_health( id ) ){
		set_user_health( id , playerInf[ id ][ maxHp ] )
	}
	
	return PLUGIN_CONTINUE;
}

public registerItem( plugin , params ){
	if( params != 2 )
	return PLUGIN_CONTINUE;
	
	ItemsNumber++;
	
	new szName[ MAX_LEN_NAME + 1];
	get_string( 1 , szName , charsmax( szName ) );

	ArrayPushString( gItemName , szName );
	ArrayPushCell( gItemDur , get_param( 2 ) );
	ArrayPushCell( gItemPlugin , plugin );
	
	return PLUGIN_CONTINUE;
}

public getItemsNum()
	return ItemsNumber;

public addMaxHp( plugin , params ){
	if( params != 2 )
	return PLUGIN_CONTINUE;
	
	new id	=	get_param( 1 ) , iHp	=	get_param( 2 );
	
	if(playerInf[ id ][ currentClass ] != 0){
		playerInf[ id ][ maxHp ] += iHp;
		
		//set_user_health(id,get_user_health(id) + iHp > playerInf[id][maxHp] ? playerInf[id][maxHp] : get_user_health(id) + iHp );
	}
	
	return PLUGIN_CONTINUE;
}

public screenShake( id , amplitude , duration , frequency ){
	if (!pev_valid(id) || is_user_bot(id) || !is_user_alive(id)){
		return PLUGIN_HANDLED
	}
	
	static gmsgScreenShake;
	
	if( !gmsgScreenShake )	gmsgScreenShake	=	get_user_msgid( "ScreenShake" );
	
	message_begin(MSG_ONE , gmsgScreenShake , {0,0,0} ,id)
	write_short( amplitude );
	write_short( duration );
	write_short( frequency );
	message_end();
	
	return PLUGIN_CONTINUE;
}

public displayIcon( plugin , params ){
	if( params != 6 )
	return PLUGIN_CONTINUE;
	
	new id = get_param( 1 );
	
	if (!pev_valid(id) || is_user_bot(id)  || !is_user_alive(id))
		return PLUGIN_HANDLED
	
	static gmsgStatusIcon;
	
	if( !gmsgStatusIcon )	gmsgStatusIcon	=	get_user_msgid( "StatusIcon" );
	
	new szNameIcon[ 64 ];
	
	get_string( 3 , szNameIcon , charsmax( szNameIcon ) );
	
	message_begin( MSG_ONE, gmsgStatusIcon, {0,0,0}, id ) 
	write_byte( get_param( 2 ) ) 	
	write_string( szNameIcon ) 
	write_byte( get_param( 4 ) ) // red 
	write_byte( get_param( 5 ) ) // green 
	write_byte( get_param( 6 ) ) // blue 
	message_end()
	
	return PLUGIN_CONTINUE;
}

public displayFade( plugin , params ){
	if( params != 8 )
		return PLUGIN_CONTINUE;
	
	new id = get_param( 1 );
	
	if (!pev_valid(id) || is_user_bot(id) || !is_user_alive(id))
		return PLUGIN_HANDLED
	
	static gmsgScreenFade;
	
	if( !gmsgScreenFade )	gmsgScreenFade	=	get_user_msgid( "ScreenFade" );
	
	message_begin( MSG_ONE, gmsgScreenFade,{0,0,0}, id )
	write_short( get_param( 2 ) )
	write_short( get_param( 3 ) )
	write_short( get_param( 4 ) )
	write_byte ( get_param( 5 ) )
	write_byte ( get_param( 6 ) )
	write_byte ( get_param( 7 ) )
	write_byte ( get_param( 8 ) )
	message_end()
	
	return PLUGIN_CONTINUE;
}

public cancelRender(plugin,params){
	if( params != 1 )
	return PLUGIN_CONTINUE;
	
	new iOutput[8],
	id = get_param(1);
	
	for( new i = ArraySize( playerInfRender[id] ) - 1 ; i >= 0 ; i-- ){
		ArrayGetArray(playerInfRender[id],i,iOutput)
		
		if( iOutput[ 7 ] == plugin ){
			
			iOutput[ 7 ]	=	DIABLO_RENDER_DESTROYED;
			ArraySetArray( playerInfRender[ id ] , i , iOutput );
		}
	}
	
	clearRender( id );
	renderChange(id);
	
	return PLUGIN_CONTINUE;
}

public setUserRender(plugin,params){
	if( params != 8)
		return PLUGIN_CONTINUE;
	
	new iInput[8] , id = get_param(1);
	
	iInput[0]	=	get_param(3);
	iInput[1]	=	get_param(4);
	iInput[2]	=	get_param(5);
	iInput[3]	=	get_param(2);
	iInput[4]	=	get_param(6);
	iInput[5]	=	get_param(7);
	iInput[6]	=	get_param_f(8) == 0.0 ?  (_:0.0) : (_:(get_gametime() + get_param_f(8)));
	iInput[7]	=	plugin;
	
	ArrayPushArray(playerInfRender[id],iInput);
	
	clearRender(id);
	renderChange(id);
	
	return PLUGIN_CONTINUE;
}

public userBow(plugin,params){
	if( params != 2)
	return PLUGIN_CONTINUE;
	
	new id	=	get_param( 1 );
	
	bowdelay[ id ]	=	get_gametime();
	bHasBow[ id ]	=	bool:get_param( 2 );
	
	return PLUGIN_CONTINUE;
}

stock ham_strip_weapon(id, weapon[])
{
	if(!equal(weapon, "weapon_", 7) ) return 0
	new wId = get_weaponid(weapon)
	if(!wId) return 0
	new wEnt
	while( (wEnt = engfunc(EngFunc_FindEntityByString,wEnt,"classname", weapon) ) && pev(wEnt, pev_owner) != id) {}
	if(!wEnt) return 0

	if(get_user_weapon(id) == wId) ExecuteHamB(Ham_Weapon_RetireWeapon, wEnt)

	if(!ExecuteHamB(Ham_RemovePlayerItem, id, wEnt)) return 0
	ExecuteHamB(Ham_Item_Kill ,wEnt)

	set_pev(id, pev_weapons, pev(id, pev_weapons) & ~(1<<wId) )
	return 1
}


public userTrap(plugin,params){
	if( params != 2)
	return PLUGIN_CONTINUE;
	
	g_GrenadeTrap[get_param(1)]	=	bool:get_param(2);
	g_TrapMode[get_param(1)]	=	bool:get_param(2);
	
	return PLUGIN_CONTINUE;
}

public Float:getGrav(plugin,params){
	if( params != 1)
	return 0.0;

	return Float:playerInf[get_param(1)][userGrav];
}

public setGrav(plugin,params){
	if( params != 2)
	return PLUGIN_CONTINUE;
	
	playerInf[get_param(1)][userGrav]	=	_:get_param_f(2);
	
	gravChange(get_param(1));
	
	return PLUGIN_CONTINUE;
}

public addGrav(plugin,params){
	if( params != 2)
	return PLUGIN_CONTINUE;
	
	playerInf[get_param(1)][userGrav]	=	_:(Float:playerInf[get_param(1)][userGrav] + get_param_f(2));
	
	if(Float:playerInf[get_param(1)][userGrav] < 0.0)	playerInf[get_param(1)][userGrav]	=	_:0.1;
	
	gravChange(get_param(1));
	
	return PLUGIN_CONTINUE;
}

public knifeAdd(plugin,params){
	if( params != 2)
	return PLUGIN_CONTINUE;
	
	playerInf[get_param(1)][maxKnife] += get_param(2);
	
	return PLUGIN_CONTINUE;
}

public knifeSet(plugin,params){
	if( params != 2)
	return PLUGIN_CONTINUE;
	
	playerInf[get_param(1)][maxKnife] = get_param(2);
	
	return PLUGIN_CONTINUE;
}

public addNativeXp(plugin,params){
	if( params != 2)
	return PLUGIN_CONTINUE;
	
	giveXp(get_param(1),get_param(2), 0);
	
	return PLUGIN_CONTINUE;
}

public takeNativeXp(plugin,params){
	if( params != 2)
	return PLUGIN_CONTINUE;
	
	takeXp(get_param(1),get_param(2), 0);
	
	return PLUGIN_CONTINUE;
}

public xpBonus(plugin,params){
	if( params != 0)
	return PLUGIN_CONTINUE;
	
	return get_pcvar_num(pCvarXPBonus);
}

public xpBonus2(plugin,params){
	if( params != 0)
	return PLUGIN_CONTINUE;
	
	return get_pcvar_num(pCvarXPBonus);
}


public writeHudNative(plugin,params){
	if( params != 1)
	return PLUGIN_CONTINUE;
	
	writeHud(get_param(1));
	
	return PLUGIN_CONTINUE;
}

public showHudMsg(plugin,params){
	if( params < 3 )
	return PLUGIN_CONTINUE;
	
	new szMessage[ 256 ];
	
	vdformat( szMessage , charsmax( szMessage ) , 3 , 4 );
	
	set_hudmessage ( 255, 0, 0, -1.0, 0.4, 0, get_param_f( 2 ) / 2, get_param_f( 2 ) , 0.1, 0.2, -1 ) 	
	ShowSyncHudMsg( get_param( 1 ) , HudSyncObj , szMessage )
	
	return PLUGIN_CONTINUE;
}

public checkHUD(plugin, params){
	if( params != 1 )
	return PLUGIN_CONTINUE;
	
	return playerInf[ get_param(1) ][ playerHud ];
}

public bool:isFreeze(plugin,params){
	return bFreezeTime;
}

public addHP(plugin,params){
	if( params != 2 || !is_user_alive(get_param(1)))
	return PLUGIN_CONTINUE;
	
	new id = get_param(1),iHp = get_param(2);
	
	set_user_health(id,get_user_health(id) + iHp > playerInf[id][maxHp] ? playerInf[id][maxHp] : get_user_health(id) + iHp );
	
	return PLUGIN_CONTINUE;
}

public addForceHP(plugin,params){
	if( params != 2 || !is_user_alive(get_param(1)))
	return PLUGIN_CONTINUE;
	
	new id = get_param(1),iHp = get_param(2);
	
	set_user_health(id, get_user_health(id) + iHp);
	
	return PLUGIN_CONTINUE;
}

public createExplode(plugin,params){
	if( params != 4)
	return PLUGIN_CONTINUE;
	
	new Float:fOrigin[3];
	
	get_array_f(2,fOrigin,3);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(3)
	engfunc(EngFunc_WriteCoord,fOrigin[0]);
	engfunc(EngFunc_WriteCoord,fOrigin[1]);
	engfunc(EngFunc_WriteCoord,fOrigin[2]);
	write_short(spriteBoom)
	write_byte(50)
	write_byte(15)
	write_byte(0)
	message_end()
	
	new Players[32], playerCount, iEnemy;
	get_players(Players, playerCount, "ah") 
	
	new id = get_param(1),Float:fDist = get_param_f(4),Float:fDamage = get_param_f(3);
	
	for (new i=0; i<playerCount; i++) 
	{
		iEnemy = Players[i] 
		
		new Float:aOrigin[3]
		pev(iEnemy,pev_origin,aOrigin)
		
		if ( iEnemy != id && get_user_team(id) != get_user_team(iEnemy) && get_distance_f(aOrigin,fOrigin) < fDist && is_user_alive( iEnemy ))
		{
			new Float:fDamageSec = fDamage - (getUserDex( iEnemy ) * 2)
			
			if (fDamageSec > 0.0 && is_user_alive( iEnemy) ){
				doDamageExplode(iEnemy,id,fDamageSec,diabloDamageGrenade);
				
				bloodEffect(iEnemy,248)
			}
		}
		
	}
	
	return PLUGIN_CONTINUE;
}

public killPlayer(plugin,params){
	if( params != 3)
	return PLUGIN_CONTINUE;
	
	new iKiller = get_param(2);
	new iVictim = get_param(1);
	new iArmor,CsArmorType:iArmorType;
	
	iArmor = cs_get_user_armor(iVictim,iArmorType);
	
	if( is_user_alive( iVictim ) ){
		cs_set_user_armor(iVictim, 0, CS_ARMOR_NONE);
		doDamage(iVictim,iKiller,float(get_user_health(iVictim) + iArmor),DiabloDamageBits:get_param(3));
	}
	
	return PLUGIN_CONTINUE;
}

public doDamage(iVictim,iKiller,Float:fDamage,DiabloDamageBits:damageBits){
	#if defined DEBUG
	log_to_file( DEBUG_LOG , "doDamage iVictim %d | iKiller %d | fDamage %f", iVictim , iKiller , fDamage );
	#endif
		
	if(is_user_alive( iVictim ) ){
		ExecuteHam(Ham_TakeDamage,iVictim,iKiller,iKiller,fDamage,_:damageBits);
	}
	
	return PLUGIN_CONTINUE;
}

public doDamageExplode(iVictim,iKiller,Float:fDamage,DiabloDamageBits:damageBits){
	#if defined DEBUG
	log_to_file( DEBUG_LOG , "doDamage iVictim %d | iKiller %d | fDamage %f", iVictim , iKiller , fDamage );
	#endif
		
	if(is_user_alive( iVictim ) ){
		new szItem[ MAX_LEN_NAME ];
		if(playerInf[iVictim][currentItem] != 0 )
			ArrayGetString( gItemName , playerInf[ iVictim ][ currentItem ] , szItem , charsmax( szItem ) );
		
		if(!equal(szItem, "Fireshield"))
			ExecuteHam(Ham_TakeDamage,iVictim,iKiller,iKiller,fDamage,_:damageBits);
	}
	
	return PLUGIN_CONTINUE;
}

public registerClass(plugin,params){
	if( params != 5)
	return PLUGIN_CONTINUE;
	
	new szName[MAX_LEN_NAME],szDesc[MAX_LEN_DESC]
	
	get_string(1,szName,MAX_LEN_NAME - 1);
	
	if( equal(szName , "" ) )
	return PLUGIN_CONTINUE;
	
	ClassesNumber++;
	
	TrieSetCell(ClassNames, szName, ClassesNumber);
	
	get_string(3,szDesc,MAX_LEN_DESC - 1);
	
	ArrayPushCell(gClassPlugins,plugin);
	ArrayPushString(gClassNames,szName);
	ArrayPushCell(gClassHp,get_param(2));
	ArrayPushString(gClassDesc,szDesc)
	ArrayPushCell(gClassFlag,get_param( 4 ) );
	
	new szFraction[ MAX_LEN_FRACTION ];
	
	get_string( 5 , szFraction , MAX_LEN_FRACTION - 1 );
	
	if( !equal( szFraction , "" ) ){
		ArrayPushCell( gClassFraction , checkFraction( szFraction ) );
	}
	else{
		ArrayPushCell( gClassFraction , 0 );
	}
	
	return PLUGIN_CONTINUE;
}

public getClassesNum()
	return ClassesNumber;

public checkFraction( szFract[] ){
	new szName[ MAX_LEN_FRACTION ];
	
	for( new i = 1 ; i < ArraySize( gFractionNames ) ; i++ ){
		ArrayGetString( gFractionNames , i , szName , MAX_LEN_FRACTION - 1 );
		
		if( equal( szName , szFract ) ){
			return i;
		}
	}
	
	new iRet	=	ArraySize( gFractionNames );
	
	ArrayPushString( gFractionNames , szFract );
	
	return iRet;
}

public setSpeed(plugin,params){
	if( params != 2)
	return 0;
	
	playerInf[get_param(1)][currentSpeed]	=	_:get_param_f(2);
	
	speedChange(get_param(1))
	
	return 1;
}

public resetSpeed( plugin , params ){
	if( params != 1 )
	return 0;
	
	new id	=	get_param( 1 );
	
	playerInf[id][currentSpeed]		=	_:(BASE_SPEED + (float( getUserDex( id ) ) * 1.25))
	
	speedChange(id);
	
	return 1;
}

public addSpeed(plugin,params){
	if( params != 2)
	return 0;
	
	playerInf[get_param(1)][currentSpeed]	=	_:(playerInf[get_param(1)][currentSpeed] + get_param_f(2))
	
	speedChange(get_param( 1 ))
	
	return 1;
}

public Float:getSpeed(plugin,params){
	if( params != 1)
	return 0.0;
	
	return playerInf[get_param(1)][currentSpeed];
}

public Float:getSpeedExtra(plugin,params){
	if( params != 1)
	return 0.0;
	
	return playerInf[get_param(1)][currentSpeed] - (BASE_SPEED + (float( getUserDex( get_param( 1 ) ) ) * 1.3));
}

public isThisClass(plugin,params){
	if( params != 2)
	return 0;
	
	new szClass[MAX_LEN_NAME],szParam[MAX_LEN_NAME]
	
	ArrayGetString(gClassNames, playerInf[get_param(1)][currentClass], szClass, charsmax( szClass )); 
	
	get_string(2,szParam, MAX_LEN_NAME - 1);
	
	if(equali(szClass, szParam))
	return 1;
	
	return 0;
}

public isThisItem(plugin,params){
	if( params != 2)
	return 0;

	new szItem[MAX_LEN_NAME],szParam[MAX_LEN_NAME]
	
	ArrayGetString(gItemName, playerInf[get_param(1)][currentItem], szItem, charsmax( szItem )); 
	
	get_string(2,szParam, MAX_LEN_NAME - 1);
	
	if(equali(szItem,szParam))
	return 1;
	
	return 0;
}

public getLevel(plugin,params){
	if( params != 1)
	return PLUGIN_CONTINUE;
	
	return playerInf[get_param(1)][currentLevel];
}

public getExp(plugin,params){
	if( params != 1)
	return PLUGIN_CONTINUE;
	
	return playerInf[get_param(1)][currentExp];
}

public getLevelExp(plugin,params){
	if( params != 1)
	return PLUGIN_CONTINUE;
	
	return LevelXP[playerInf[get_param(1)][currentLevel] - 1];
}

public setExp(plugin,params){
	if( params != 2)
	return PLUGIN_CONTINUE;
	
	new id = get_param(1);
	
	playerInf[id][currentExp] = get_param(2);
	playerInf[id][currentLevel] = 1;
	playerInf[id][currentPoints] = 0;
	
	while(playerInf[id][currentExp] >= LevelXP[playerInf[id][currentLevel]] && playerInf[id][currentLevel] < MAX_LEVEL)
	{
		playerInf[id][currentLevel]++;
		playerInf[id][currentPoints] += get_pcvar_num( pCvarPoints );
	}
	
	resetSkills(id);
	
	SaveInfo(id, 1, 1);
	
	return PLUGIN_CONTINUE;
}

public getPoints(plugin,params){
	if( params != 1)
	return PLUGIN_CONTINUE;
	
	return playerInf[get_param(1)][currentPoints];
}

public getClass(plugin,params){
	if( params != 1)
		return 0;
	
	return playerInf[get_param(1)][currentClass];
}

public setClass(plugin,params){
	if( params != 2)
		return 0;
		
	SaveInfo(get_param(1), 1);
	
	playerInf[get_param(1)][currentClass] = get_param(2);
	LoadClass(get_param(1), playerInf[get_param(1)][currentClass]);
	
	return 0;
}

public getClassName( class , Return[] , len){
	new szClass[MAX_LEN_NAME];
	
	param_convert( 2 )
	
	ArrayGetString(gClassNames,class,szClass,charsmax( szClass )); 
	
	copy( Return , len , szClass)
}

public getItem(plugin,params){
	if( params != 1)
		return 0;
	
	return playerInf[get_param(1)][currentItem];
}

public getItemName( item , Return[] , len){
	new szItem[MAX_LEN_NAME];
	
	param_convert( 2 )
	
	ArrayGetString(gItemName, item, szItem, charsmax( szItem ));
	
	copy( Return , len , szItem)
}

public getStr(plugin,params){
	if( params != 1)
	return PLUGIN_CONTINUE;
	
	return playerInf[get_param(1)][currentStr];
}

public getInt(plugin,params){
	if( params != 1)
	return PLUGIN_CONTINUE;
	
	return playerInf[get_param(1)][currentInt];
}
public getDex(plugin,params){
	if( params != 1)
	return PLUGIN_CONTINUE;
	
	return playerInf[get_param(1)][currentDex];
}
public getAgi(plugin,params){
	if( params != 1)
	return PLUGIN_CONTINUE;
	
	return playerInf[get_param(1)][currentAgi];
}

public isFrom(plugin,params){
	if( params != 1)
	return PLUGIN_CONTINUE;
	
	return bool:(ArrayGetCell(gClassPlugins,playerInf[get_param(1)][currentClass]) == plugin);
}

/*---------------------NATIVES---------------------*/

public wybierzKlase(id){
	if(!sqlPlayer[id]){
		ColorChat(id, GREEN, "%s Trwa wczytywanie twoich klas...", PREFIX_SAY)
		return PLUGIN_HANDLED;
	}
	
	if(!diablo_check_password(id))
	{
		diablo_force_password(id);
		return PLUGIN_HANDLED;
	}
	
	if(!bFreezeTime && playerInf[id][currentClass] != 0) set_user_health(id,0);
	
	if( ArraySize( gFractionNames )	==	1 )
		wybierzKlase2(id)
	else
		wybierzKlaseFrakcje( id );
	
	return PLUGIN_HANDLED;
}

wybierzKlaseFrakcje( id , page = 0 ){
	new pMenu = menu_create("Wybierz Frakcje","wybierzFrakcjeHandle");
	
	new szFraction[MAX_LEN_FRACTION],szTmp[MAX_LEN_NAME + 128],iOutput[9] , szNum[ 64 ] , szClass[ MAX_LEN_NAME ] ;
	
	for(new i = 1; i < ArraySize( gFractionNames ) ; i++ ){
		ArrayGetString( gFractionNames , i , szFraction , MAX_LEN_FRACTION - 1 );
		
		formatex(szTmp,charsmax( szTmp ),"%s",szFraction);
		
		num_to_str( i , szNum , charsmax( szNum ) )
		
		add( szNum , charsmax( szNum ) , "frakcja" );
		
		menu_additem(pMenu,szTmp , szNum);
	}
	
	for(new i = 1;i < ArraySize(gClassNames) ; i++){
		if( ArrayGetCell( gClassFraction  , i) == 0 ){
			LoadClass(id, i);
			ArrayGetString(gClassNames,i,szClass,charsmax( szClass ) );
			ArrayGetArray(playerInfClasses[id],i,iOutput);
			
			formatex(szTmp,charsmax( szTmp ),"\r%s \yLevel: %d",szClass,iOutput[0]);
			
			num_to_str( i , szNum , charsmax( szNum ) )
			
			menu_additem( pMenu , szTmp , szNum );
		}
	}
	
	menu_setprop(pMenu,MPROP_EXITNAME,"Wyjscie")
	menu_setprop(pMenu,MPROP_BACKNAME,"Wroc")
	menu_setprop(pMenu,MPROP_NEXTNAME,"Dalej")
	menu_setprop(pMenu,MPROP_NUMBER_COLOR,"\w")
	
	#if defined BOTY
	if( is_user_bot( id ) ){
		wybierzFrakcjeHandle(id , pMenu,  random_num( 0 , ArraySize( gFractionNames ) - 1 ) )
		
		return PLUGIN_HANDLED;
	}
	#endif
	
	menu_display(id,pMenu,page)
	
	return PLUGIN_HANDLED;
}

public wybierzKlaseHandle2 ( id , menu , item ){
	if( item == MENU_EXIT ){
		menu_destroy( menu );
		
		wybierzKlaseFrakcje( id );
		
		return PLUGIN_HANDLED;
	}
	
	new data[64], iName[64]
	new acces, callback
	menu_item_getinfo(menu, item, acces, data,63, iName, 63, callback)
	
	item	=	str_to_num( data );
	
	new oldItem	=	item;
	item	=	str_to_num( data );
	
	if(item == playerInf[id][currentClass]){
		ColorChat(id,GREEN,"%s Masz juz ta klase!",PREFIX_SAY)
		
		wybierzKlaseFrakcje(id,oldItem/7)
		
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	if( ArrayGetCell( gClassFlag , item ) != FLAG_ALL && !(get_user_flags( id ) & ArrayGetCell( gClassFlag , item )) ){
		ColorChat(id,GREEN,"%s Nie masz uprawnien do korzystania z tej klasy!",PREFIX_SAY)
		
		createMenuFromFraction(id,oldItem/7)
		
		menu_destroy(menu);
		
		return PLUGIN_CONTINUE;
	}
	
	new gFW,iRet;
	
	if(playerInf[id][currentClass] != 0 ){
		
		gFW = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_class_disabled",FP_CELL);
		
		ExecuteForward(gFW, iRet, id);
		
		
		gFW = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_clean_data",FP_CELL);
		
		ExecuteForward(gFW,iRet,id);
		
		SaveInfo(id, 1);
	}
	else {
		ColorChat(id,GREEN,"%s Wszystkie skille klasy zostana zaladowane przy ponownym odrodzeniu.",PREFIX_SAY)
		
		new gFw , iRet;
		
		gFw = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_class_spawned",FP_CELL);
		
		ExecuteForward(gFw,iRet,id);
	}
	
	playerInf[id][currentClass] = item;
	
	if( playerInf[id][currentItem] != 0 ){
		new gFw , iRet;
		
		gFw	=	CreateOneForward( ArrayGetCell(gItemPlugin , playerInf[ id ][ currentItem ] ) , "diablo_item_reset" , FP_CELL );
		
		ExecuteForward( gFw , iRet , id );
		
		playerInf[id][currentItem]		=	0;
		playerInf[id][itemDurability]	=	0;
	}
	
	LoadClass(id, playerInf[id][currentClass]);
	ResetClass(id);
	
	gFW = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_class_enabled",FP_CELL);
	
	ExecuteForward(gFW, iRet, id);
	
	gFW = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_set_data",FP_CELL);
	
	ExecuteForward(gFW,iRet,id);
	
	gFW = CreateMultiForward("diablo_user_change_class",ET_IGNORE,FP_CELL,FP_CELL);
	
	ExecuteForward(gFW,iRet,id , playerInf[id][currentClass]);
	
	menu_destroy(menu);
	
	return PLUGIN_CONTINUE;
}

createMenuFromFraction ( id , page	= 0 ){

	new pMenu = menu_create("Wybierz Klase","wybierzKlaseHandle2");
	
	new szClass[MAX_LEN_NAME],szTmp[MAX_LEN_NAME + 128],iOutput[9] , szNum[ 16 ] , iNum	=	0;
	
	for(new i = 1;i < ArraySize(gClassNames) ; i++){
		if( iPlayerFraction[ id ]	==	ArrayGetCell( gClassFraction , i ) ){
			iNum++;
			LoadClass(id, i);
			ArrayGetString(gClassNames,i,szClass,charsmax( szClass ) );
			ArrayGetArray(playerInfClasses[id],i,iOutput);
			
			formatex(szTmp,charsmax( szTmp ),"\r%s \yLevel: %d",szClass,iOutput[0]);
			
			num_to_str( i , szNum , charsmax( szNum ) )
			
			menu_additem(pMenu,szTmp , szNum);
		}
	}
	menu_setprop(pMenu,MPROP_EXITNAME,"Do frakcji")
	menu_setprop(pMenu,MPROP_BACKNAME,"Wroc")
	menu_setprop(pMenu,MPROP_NEXTNAME,"Dalej")
	menu_setprop(pMenu,MPROP_NUMBER_COLOR,"\w")
	
	#if defined BOTY
	if( is_user_bot( id ) ){
		wybierzKlaseHandle2(id , pMenu,  random_num( 0 , iNum - 1 ) )
		
		return PLUGIN_HANDLED;
	}
	#endif
	
	menu_display( id , pMenu , page);
	
	return PLUGIN_HANDLED;
}

public wybierzFrakcjeHandle( id , menu , item ){
	if( item	==	MENU_EXIT ){
		menu_destroy( menu );
		
		return PLUGIN_HANDLED;
	}
	
	new data[64], iName[64]
	new acces, callback
	menu_item_getinfo(menu, item, acces, data,63, iName, 63, callback)
	
	if( contain( data , "frakcja" ) != -1 ){
		replace_all( data , charsmax( data ) , "frakcja" , "" );
		
		iPlayerFraction[ id ]	=	str_to_num( data );
		
		createMenuFromFraction ( id );
		
	}
	else{
		new oldItem	=	item;
		item	=	str_to_num( data );
		
		if(item == playerInf[id][currentClass]){
			ColorChat(id,GREEN,"%s Masz juz ta klase!",PREFIX_SAY)
			
			wybierzKlaseFrakcje(id,oldItem/7)
			
			menu_destroy(menu);
			return PLUGIN_CONTINUE;
		}
		
		if( ArrayGetCell( gClassFlag , item ) != FLAG_ALL && !(get_user_flags( id ) & ArrayGetCell( gClassFlag , item )) ){
			ColorChat(id,GREEN,"%s Nie masz uprawnien do korzystania z tej klasy!",PREFIX_SAY)
			
			wybierzKlaseFrakcje(id,oldItem/7)
			
			menu_destroy(menu);
			
			return PLUGIN_CONTINUE;
		}
		
		new gFW,iRet;
		
		if(playerInf[id][currentClass] != 0 ){
			
			gFW = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_class_disabled",FP_CELL);
			
			ExecuteForward(gFW, iRet, id);
			
			
			gFW = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_clean_data",FP_CELL);
			
			ExecuteForward(gFW,iRet,id);
			
			SaveInfo(id, 1);
		}
		else {
			ColorChat(id,GREEN,"%s Wszystkie skille klasy zostana zaladowane przy ponownym odrodzeniu.",PREFIX_SAY)
			
			new gFw , iRet;
			
			gFw = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_class_spawned",FP_CELL);
			
			ExecuteForward(gFw,iRet,id);
		}
		
		playerInf[id][currentClass] = item;
		
		if( playerInf[id][currentItem] != 0 ){
			new gFw , iRet;
			
			gFw	=	CreateOneForward( ArrayGetCell(gItemPlugin , playerInf[ id ][ currentItem ] ) , "diablo_item_reset" , FP_CELL );
			
			ExecuteForward( gFw , iRet , id );
			
			playerInf[id][currentItem]		=	0;
			playerInf[id][itemDurability]	=	0;
		}
		
		LoadClass(id, playerInf[id][currentClass]);
		ResetClass(id);
		
		gFW = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_class_enabled",FP_CELL);
		
		ExecuteForward(gFW, iRet, id);
		
		gFW = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_set_data",FP_CELL);
		
		ExecuteForward(gFW,iRet,id);
		
		gFW = CreateMultiForward("diablo_user_change_class",ET_IGNORE,FP_CELL,FP_CELL);
		
		ExecuteForward(gFW,iRet,id , playerInf[id][currentClass]);
		
		menu_destroy(menu);
		
		return PLUGIN_CONTINUE;
	}
	
	menu_destroy( menu );
	return PLUGIN_HANDLED;
	
}

wybierzKlase2(id,page = 0){
	new pMenu = menu_create("Wybierz Klase","wybierzKlaseHandle");
	
	new szClass[MAX_LEN_NAME],szTmp[MAX_LEN_NAME + 128],iOutput[9],OldClass = 0;
	OldClass = playerInf[id][currentClass];
		
	for(new i = 1;i < ArraySize(gClassNames) ; i++){
		LoadClass(id, i);
		ArrayGetString(gClassNames,i,szClass,charsmax(szClass));
		ArrayGetArray(playerInfClasses[id],i,iOutput);
		
		formatex(szTmp,charsmax( szTmp ),"\r%s \yLevel: %d",szClass,iOutput[0]);
		
		menu_additem(pMenu,szTmp);
	}
	menu_addtext(pMenu,"");
	menu_additem(pMenu,"Wyjscie");
	menu_setprop(pMenu,MPROP_PERPAGE,0)
	menu_setprop(pMenu,MPROP_NUMBER_COLOR,"\w")
	
	LoadClass(id, OldClass);
	
	#if defined BOTY
	if( is_user_bot( id ) ){
		wybierzKlaseHandle(id , pMenu,  random_num( 0 , ArraySize(gClassNames) - 1 ) )
		
		return PLUGIN_HANDLED;
	}
	#endif
	
	menu_display(id,pMenu,page)
	
	return PLUGIN_HANDLED;
}

public wybierzKlaseHandle(id,menu,item){
	if(item == MENU_EXIT || !is_user_connected( id ) ){
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	if(item+1 == playerInf[id][currentClass]){
		ColorChat(id,GREEN,"%s Masz juz ta klase!",PREFIX_SAY)
		
		wybierzKlase2(id,item/7)
		
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	if( ArrayGetCell( gClassFlag , item + 1 ) != FLAG_ALL && !(get_user_flags( id ) & ArrayGetCell( gClassFlag , item + 1 )) ){
		ColorChat(id,GREEN,"%s Nie masz uprawnien do korzystania z tej klasy!",PREFIX_SAY)
		
		wybierzKlase2(id,item/7)
		
		menu_destroy(menu);
		
		return PLUGIN_CONTINUE;
	}
	
	new gFW,iRet;
	
	if(playerInf[id][currentClass] != 0 ){
		
		gFW = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_class_disabled",FP_CELL);
		
		ExecuteForward(gFW, iRet, id);
		
		
		gFW = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_clean_data",FP_CELL);
		
		ExecuteForward(gFW,iRet,id);
		
		SaveInfo(id, 1);
	}
	else {
		ColorChat(id,GREEN,"%s Wszystkie skille klasy zostana zaladowane przy ponownym odrodzeniu.",PREFIX_SAY)
		
		new gFw , iRet;
		
		gFw = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_class_spawned",FP_CELL);
		
		ExecuteForward(gFw,iRet,id);
	}
	
	playerInf[id][currentClass] = item+1;
	
	if( playerInf[id][currentItem] != 0 ){
		new gFw , iRet;
		
		gFw	=	CreateOneForward( ArrayGetCell(gItemPlugin , playerInf[ id ][ currentItem ] ) , "diablo_item_reset" , FP_CELL );
		
		ExecuteForward( gFw , iRet , id );
		
		playerInf[id][currentItem]		=	0;
		playerInf[id][itemDurability]	=	0;
	}
	
	LoadClass(id, playerInf[id][currentClass]);
	ResetClass(id);

	new bool:bSpadek = false;
	
	while(playerInf[id][currentExp] < LevelXP[playerInf[id][currentLevel] - 1] && playerInf[id][currentLevel] > 1){
		
		playerInf[id][currentLevel]--;
		
		bSpadek = true;
	}
	
	if(bSpadek){	
		resetSkills(id);
		SaveInfo(id, 1);
	}
	else
		SaveInfo(id, 0);
	
	gFW = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_class_enabled",FP_CELL);
	
	ExecuteForward(gFW, iRet, id);
	
	gFW = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_set_data",FP_CELL);
	
	ExecuteForward(gFW,iRet,id);
	
	gFW = CreateMultiForward("diablo_user_change_class",ET_IGNORE,FP_CELL,FP_CELL);
	
	ExecuteForward(gFW,iRet,id , playerInf[id][currentClass]);
	
	menu_destroy(menu);
	
	return PLUGIN_CONTINUE;
}
/*---------------------EXP---------------------*/

public showStatus(id){
	writeHud(id);
}

public sprawdzPoziomUp(id){
	new bool:bAwans = false;
	
	while(playerInf[id][currentExp] >= LevelXP[playerInf[id][currentLevel]] && playerInf[id][currentLevel] < MAX_LEVEL){
		
		playerInf[id][currentLevel]++;
		playerInf[id][currentPoints] += get_pcvar_num( pCvarPoints );
		
		bAwans = true;
	}
	
	if(bAwans){
		set_hudmessage(60, 200, 25, -1.0, 0.25, 0, 1.0, 2.0, 0.1, 0.2, 2)
		ShowSyncHudMsg(id,syncHud,"Awansowales do poziomu %i", playerInf[id][currentLevel]) 
		SaveInfo(id, 1);
	}
	else
		SaveInfo(id, 0);
}

public sprawdzPoziomLose(id){
	new bool:bSpadek = false;
	
	while(playerInf[id][currentExp] < LevelXP[playerInf[id][currentLevel] - 1] && playerInf[id][currentLevel] > 1){
		
		playerInf[id][currentLevel]--;
		
		bSpadek = true;
	}
	
	if(bSpadek){	
		set_hudmessage(60, 200, 25, -1.0, 0.25, 0, 1.0, 2.0, 0.1, 0.2, 2)
		ShowSyncHudMsg(id,syncHud,"Spadles do poziomu %i", playerInf[id][currentLevel]) 
		resetSkills(id);
	}
	
	SaveInfo(id, 1);
}

public giveXp(id,ile, dodaj){
	if(playerInf[id][currentClass] != 0 ){
		if(iPlayersNum >= get_pcvar_num(pCvarNum) || dodaj){
			playerInf[id][currentExp] += ile;
			sprawdzPoziomUp(id);
		}
	}
}

public takeXp(id,ile,odejmij){
	if(playerInf[id][currentClass] != 0){
		if(iPlayersNum >= get_pcvar_num(pCvarNum) || odejmij){
			playerInf[id][currentExp] -= ile;
		
			if(playerInf[id][currentExp] < 0)	playerInf[id][currentExp] = 0;
		
			sprawdzPoziomLose(id);
		}
	}
}

public killXP(iKiller,iVictim)
{
	if (!is_user_connected(iKiller) || !is_user_connected(iVictim) || get_user_team(iKiller) == get_user_team(iVictim))
	return PLUGIN_CONTINUE
	
	new iXpAward = get_pcvar_num(pCvarXPBonus),xpBonus = get_pcvar_num(pCvarXPBonus);
	
	if (playerInf[iKiller][currentExp] < playerInf[iVictim][currentExp])	 iXpAward	+=	xpBonus /4
	
	new moreLvl = playerInf[iVictim][currentLevel] - playerInf[iKiller][currentLevel]
	
	if(moreLvl>0) 		iXpAward += floatround((xpBonus/7)*(moreLvl*((2.0-moreLvl/101.0)/3.0)))
	else if(moreLvl<-50)	iXpAward -= xpBonus*(2/3)
	else if(moreLvl<-40)	iXpAward -= xpBonus/2
	else if(moreLvl<-30)	iXpAward -= xpBonus/3
	else if(moreLvl<-20)	iXpAward -= xpBonus/4
	else if(moreLvl<-10)	iXpAward -= xpBonus/7
	
	if(iXpAward < 0)	iXpAward = 0;
	
	new gFW,iRet;
	
	gFW = CreateMultiForward ("diablo_kill_xp",ET_CONTINUE,FP_CELL,FP_CELL,FP_CELL);
	
	ExecuteForward(gFW, iRet, iKiller,iVictim ,iXpAward);
	
	if(iRet != 0)	iXpAward = iRet;
	
	if(iRet >= 0){
		giveXp(iKiller,iXpAward, 0)
	}
	else{
		takeXp(iKiller,iXpAward, 0)
	}
	
	return PLUGIN_CONTINUE
	
}

public resetSkills(id){
	if(!diablo_check_password(id))
	{
		diablo_force_password(id);
		return PLUGIN_HANDLED;
	}
	
	if(playerInf[id][currentClass] != 0){
		playerInf[id][currentPoints] = ( playerInf[id][currentLevel] * get_pcvar_num( pCvarPoints ) ) - get_pcvar_num( pCvarPoints )
		
		playerInf[id][currentAgi] = 0;
		playerInf[id][currentDex] = 0;
		playerInf[id][currentInt] = 0;
		playerInf[id][currentStr] = 0;
		
		playerPointsMenu(id)
		
		ColorChat(id, GREEN , "%s Twoje statystyki zostaly zresetowane." , PREFIX_SAY)
	}
	
	return PLUGIN_HANDLED;
}

public writeHud(id){
	id -= HUD_TASK_ID;
	
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE;
		
	if(!is_user_alive(id)){
		static iSpec ;
		
		iSpec	=	pev( id , pev_iuser2 );
		
		if( !is_user_alive( iSpec ) ){
			return PLUGIN_CONTINUE;
		}
		
		static szName[ 64 ] , szGuild[ 64 ] , szClass[ 128 ] , szItem[ 128 ];
		
		get_user_name( iSpec , szName , charsmax( szName ) );
		
		ArrayGetString( gClassNames , playerInf[ iSpec ][ currentClass ] , szClass , charsmax( szClass ) );
		ArrayGetString( gItemName , playerInf[ iSpec ][ currentItem ] , szItem , charsmax( szItem ) );
		
		diablo_get_guild_name(diablo_get_user_guild(iSpec), szGuild, charsmax(szGuild));
		
		set_hudmessage( 255, 255, 255, 0.65, 0.53, 0, 6.0, 3.0 );
		show_hudmessage( id , "Nick: %s^nPoziom: %i^nKlasa: %s^nPrzedmiot: %s^nGildia: %s^nInteligencja: %i^nSila: %i^nZwinnosc: %i^nZrecznosc: %i", szName , playerInf[ iSpec ][ currentLevel ] , szClass , szItem , szGuild, getUserInt(iSpec) , getUserStr(iSpec) , getUserDex(iSpec) , getUserAgi(iSpec) );
	}
	else {
		static szMessage[512],
		szClass[ MAX_LEN_NAME ],
		szItem[ MAX_LEN_NAME ],
		szGuild[ MAX_LEN_NAME ];
		
		ArrayGetString(gClassNames,playerInf[id][currentClass],szClass,charsmax( szClass ));
		ArrayGetString(gItemName , playerInf[ id ][ currentItem ] , szItem , charsmax( szItem ) );
		
		diablo_get_guild_name(diablo_get_user_guild(id), szGuild, charsmax(szGuild));
		
		switch( playerInf[ id ][ playerHud ] ){
			case 0:{
				if( playerInf[ id ][ currentLevel ] >= MAX_LEVEL ){ 
					formatex(szMessage,charsmax( szMessage ),"Klasa: %s Level: %i Item: %s Gildia: %s",szClass,playerInf[id][currentLevel],szItem,szGuild)
				}
				else{
					formatex(szMessage,charsmax( szMessage ),"Klasa: %s Level: %i ( %0.1f%s ) Item: %s Gildia: %s",szClass,playerInf[id][currentLevel],((float(playerInf[id][currentExp])-float( LevelXP[playerInf[id][currentLevel]-1]))*100.0)/(float(LevelXP[playerInf[id][currentLevel]])-float(LevelXP[playerInf[id][currentLevel]-1])),"%%",szItem,szGuild)
				}
			}
			case 1:{
				if( playerInf[ id ][ currentLevel ] >= MAX_LEVEL ){ 
					formatex(szMessage, charsmax(szMessage), "%s[Klasa: %s]^n[Level: %i]^n[Item: %s]^n[Gildia: %s]", HUD_TEXT , szClass,playerInf[id][currentLevel],szItem,szGuild)
				}
				else{
					formatex(szMessage, charsmax(szMessage), "%s[Klasa: %s]^n[Level: %i] [ %0.1f%s ]^n[Item: %s]^n[Gildia: %s]", HUD_TEXT , szClass,playerInf[id][currentLevel],((float(playerInf[id][currentExp])-float( LevelXP[playerInf[id][currentLevel]-1]))*100.0)/(float(LevelXP[playerInf[id][currentLevel]])-float(LevelXP[playerInf[id][currentLevel]-1])),"%%", szItem,szGuild)
				}
			}
		}
		
		if( get_user_health( id ) > 255 ){
			set_hudmessage(255, 212, 0, 0.01, 0.88, 0, 6.0, 5.0)
			show_hudmessage(id, "Zycie: %d", get_user_health( id ))
		}
		
		static gFW,iRet;
		
		static iArrayPass;
		
		iArrayPass = PrepareArray(szMessage,256,1);
		
		gFW = CreateMultiForward ("diablo_hud_write",ET_IGNORE,FP_CELL,FP_ARRAY,FP_CELL);
		
		ExecuteForward(gFW, iRet, id , iArrayPass,charsmax( szMessage ));
		
		switch( playerInf[ id ][ playerHud ] ){
			case 0:{
				message_begin(MSG_ONE,gmsgStatusText,{0,0,0}, id) 
				write_byte(0) 
				write_string(szMessage) 
				message_end() 
			}
			case 1:{
				set_hudmessage(16, 186, 16, 0.02, 0.21, 0, 6.0, 2.0)
				show_hudmessage(id, szMessage)
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

/*---------------------FREEZETIME---------------------*/

public freezeOver(){
	bFreezeTime = false;
	
	for( new i = 1 ; i <= MAX ; i++ ){
		if( !is_user_alive( i ) || playerInf[ i ][ currentClass ] == 0 ){
			continue;
		}
		
		speedChange( i );
	}
}

public freezeBegin(){
	bFreezeTime = true;
}

/*---------------------SAVE & LOAD---------------------*/

SaveInfo(id, sql, force = 0){
	if(!sqlPlayer[id] || playerInf[id][currentClass] == 0)	
		return PLUGIN_CONTINUE;
	
	if(sql){
		new szClass[MAX_LEN_NAME], szAuth[64],szIp[64],szName[64],szTmp[128];
	
		get_user_authid(id,szAuth,charsmax( szAuth ) );
		get_user_ip(id,szIp,charsmax( szIp ) );
	
		switch(get_pcvar_num(pCvarSaveType)){
		case 1:{
				formatex(szTmp,charsmax( szTmp ),"`nick` = '%s'", playerInf[id][playerName]);
			}
		case 2:{			
				formatex(szTmp,charsmax( szTmp ),"`sid` = '%s'",szAuth);
			}
		case 3:{
				if(is_steam(id)){
					formatex(szTmp,charsmax( szTmp ),"`sid` = '%s'",szAuth);
				}
				else{
					formatex(szTmp,charsmax( szTmp ),"`nick` = '%s' AND `sid` = '%s'",playerInf[id][playerName],szAuth);
				}
			}
		}
	
		new szCommand[512];
		
		ArrayGetString(gClassNames,playerInf[id][currentClass],szClass,charsmax(szClass));

		if( get_pcvar_num(pCvarSaveType) == 1 ){
			if(force) {
				formatex(szCommand,charsmax( szCommand ),"UPDATE %s SET `ip` = '%s' , `sid` = '%s' , `lvl` = '%d' , `exp` = '%d', `str` = '%d',`int` = '%d',`dex` = '%d',`agi` = '%d', `points` = '%d' WHERE `klasa` = '%s' AND ",
				SQL_TABLE,szIp,szAuth,playerInf[id][currentLevel],playerInf[id][currentExp],playerInf[id][currentStr],playerInf[id][currentInt],playerInf[id][currentDex],playerInf[id][currentAgi],playerInf[id][currentPoints],szClass);
			}
			else {
				formatex(szCommand,charsmax( szCommand ),"UPDATE %s SET `ip` = '%s' , `sid` = '%s' , `lvl` = '%d' , `exp` = '%d', `str` = '%d',`int` = '%d',`dex` = '%d',`agi` = '%d', `points` = '%d' WHERE `klasa` = '%s' AND exp <= '%d' AND ",
				SQL_TABLE,szIp,szAuth,playerInf[id][currentLevel],playerInf[id][currentExp],playerInf[id][currentStr],playerInf[id][currentInt],playerInf[id][currentDex],playerInf[id][currentAgi],playerInf[id][currentPoints],szClass, playerInf[id][currentExp]);
			}
		}
		else if( get_pcvar_num(pCvarSaveType) == 3 && !is_steam( id ) ){
			if(force) {
				formatex(szCommand,charsmax( szCommand ),"UPDATE %s SET `ip` = '%s' , `lvl` = '%d' , `exp` = '%d', `str` = '%d',`int` = '%d',`dex` = '%d',`agi` = '%d', `points` = '%d' WHERE `klasa` = '%s' AND ",
				SQL_TABLE,szIp,playerInf[id][currentLevel],playerInf[id][currentExp],playerInf[id][currentStr],playerInf[id][currentInt],playerInf[id][currentDex],playerInf[id][currentAgi],playerInf[id][currentPoints],szClass);
			}
			else {
				formatex(szCommand,charsmax( szCommand ),"UPDATE %s SET `ip` = '%s' , `lvl` = '%d' , `exp` = '%d', `str` = '%d',`int` = '%d',`dex` = '%d',`agi` = '%d', `points` = '%d' WHERE `klasa` = '%s' AND exp <= '%d'  AND ",
				SQL_TABLE,szIp,playerInf[id][currentLevel],playerInf[id][currentExp],playerInf[id][currentStr],playerInf[id][currentInt],playerInf[id][currentDex],playerInf[id][currentAgi],playerInf[id][currentPoints],szClass, playerInf[id][currentExp]);
			}
		}
		else{
			if(force) {
				formatex(szCommand,charsmax( szCommand ),"UPDATE %s SET `ip` = '%s' , `nick` = '%s' , `lvl` = '%d' , `exp` = '%d', `str` = '%d',`int` = '%d',`dex` = '%d',`agi` = '%d', , `points` = '%d' WHERE `klasa` = '%s' AND ",
				SQL_TABLE,szIp,szName,playerInf[id][currentLevel],playerInf[id][currentExp],playerInf[id][currentStr],playerInf[id][currentInt],playerInf[id][currentDex],playerInf[id][currentAgi],playerInf[id][currentPoints],szClass);
			}
			else {
				formatex(szCommand,charsmax( szCommand ),"UPDATE %s SET `ip` = '%s' , `nick` = '%s' , `lvl` = '%d' , `exp` = '%d', `str` = '%d',`int` = '%d',`dex` = '%d',`agi` = '%d', , `points` = '%d' WHERE `klasa` = '%s' AND exp <= '%d' AND ",
				SQL_TABLE,szIp,szName,playerInf[id][currentLevel],playerInf[id][currentExp],playerInf[id][currentStr],playerInf[id][currentInt],playerInf[id][currentDex],playerInf[id][currentAgi],playerInf[id][currentPoints],szClass, playerInf[id][currentExp]);
			}
		}
		
		add(szCommand,charsmax( szCommand ), szTmp);
		
		#if defined DEBUG
		log_to_file( DEBUG_LOG , "SaveInfo id %d | class %s | Query %s", id, szClass, szCommand )
		#endif
		
		if(sql == 3)
		{
			new ErrCode, Error[128], Handle:SqlConnection, Handle:Query;
			SqlConnection = SQL_Connect(gTuple, ErrCode, Error, charsmax(Error));

			if (!SqlConnection)
			{
				log_to_file( DEBUG_LOG , "Save - Could not connect to SQL database.  [%d] %s", ErrCode, Error);
				SQL_FreeHandle(SqlConnection);
				return PLUGIN_CONTINUE;
			}
			
			Query = SQL_PrepareQuery(SqlConnection, szCommand);
			if (!SQL_Execute(Query))
			{
				ErrCode = SQL_QueryError(Query, Error, charsmax(Error));
				log_to_file( DEBUG_LOG , "Save Query Nonthreaded failed. [%d] %s", ErrCode, Error);
				SQL_FreeHandle(Query);
				SQL_FreeHandle(SqlConnection);
				return PLUGIN_CONTINUE;
			}
	
			SQL_FreeHandle(Query);
			SQL_FreeHandle(SqlConnection);
		}
		else
			SQL_ThreadQuery(gTuple,"SaveInfoHandle",szCommand);
	}
	
	if(sql != 2){
		static iOutput[7];
	
		iOutput[0]	=	playerInf[id][currentLevel] 
		iOutput[1]	=	playerInf[id][currentExp]
		iOutput[2]	=	playerInf[id][currentStr]
		iOutput[3]	=	playerInf[id][currentInt]
		iOutput[4]	=	playerInf[id][currentDex]
		iOutput[5]	=	playerInf[id][currentAgi] 
		iOutput[6]	=	playerInf[id][currentPoints]
	
		ArraySetArray(playerInfClasses[id],playerInf[id][currentClass],iOutput);
	}
	
	return PLUGIN_CONTINUE;
}

public SaveInfoHandle(FailState,Handle:Query,Error[],ErrCode,Data[],DataSize)
{
	if(ErrCode)
	{
		log_to_file("addons/amxmodx/logs/diablo.log","SaveInfoHandle: Error on Table query: %s",Error)
	}
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		log_to_file("addons/amxmodx/logs/diablo.log","SaveInfoHandle: Could not connect to SQL database.")
		
		return PLUGIN_CONTINUE
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		log_to_file("addons/amxmodx/logs/diablo.log","SaveInfoHandle: Table Query failed.")
		
		return PLUGIN_CONTINUE
	}
	
	return PLUGIN_CONTINUE
}

public LoadInfo(id){
	if(!bSql || sqlPlayer[id] || !is_user_connected(id)){
		return PLUGIN_CONTINUE;
	}
	
	new szCommand[256],szTmp[64],iLen = 0;
	
	iLen += formatex(szCommand,charsmax( szCommand ),"SELECT * FROM %s WHERE ",SQL_TABLE);
	
	get_user_authid(id,szTmp,charsmax(szTmp));
	
	switch(get_pcvar_num(pCvarSaveType)){
	case 1: formatex(szCommand[iLen],charsmax( szCommand ) - iLen,"`nick` = '%s'",playerInf[id][playerName]);
	case 2: formatex(szCommand[iLen],charsmax( szCommand ) - iLen,"`sid` = '%s'",szTmp);
	case 3:{
			if(is_steam(id))	
				formatex(szCommand[iLen],charsmax( szCommand ) - iLen,"`sid` = '%s'",szTmp);
			else	
				formatex(szCommand[iLen],charsmax( szCommand ) - iLen,"`nick` = '%s' AND `sid` = '%s'",playerInf[id][playerName],szTmp);
		}
	}
	add(szCommand,charsmax( szCommand )," ORDER BY `exp` DESC");
	
	new Data[1];
	Data[0] = id;
	
	SQL_ThreadQuery(gTuple,"LoadInfoHandle",szCommand,Data,1);
	
	#if defined DEBUG
	log_to_file( DEBUG_LOG , "LoadInfo id %d | Query %s", id , szCommand )
	#endif
		
	return PLUGIN_CONTINUE;
}

public LoadInfoHandle(FailState,Handle:Query,Error[],ErrCode,Data[],DataSize)
{
	if(ErrCode)
	{
		log_to_file("addons/amxmodx/logs/diablo.log","LoadInfoHandle: Error on Table query: %s",Error)
	}
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		log_to_file("addons/amxmodx/logs/diablo.log","LoadInfoHandle: Could not connect to SQL database.")
		
		return PLUGIN_CONTINUE
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		log_to_file("addons/amxmodx/logs/diablo.log","LoadInfoHandle: Table Query failed.")
		
		return PLUGIN_CONTINUE
	}
	
	new id = Data[0];
	
	static szClass[MAX_LEN_NAME], iInput[7], int;
	while(SQL_MoreResults(Query)){
		if(!is_user_connected(id))
			break;

		SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"klasa"),szClass,charsmax(szClass));
		iInput[0] 	= 	SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"lvl"))
		iInput[1] 	= 	SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"exp"))
		iInput[2] 	= 	SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"str"))
		iInput[3] 	= 	SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"int"))
		iInput[4] 	= 	SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"dex"))
		iInput[5] 	= 	SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"agi"))
		iInput[6]	=	SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"points"))

		TrieGetCell(ClassNames, szClass, int);
		ArraySetArray(playerInfClasses[id], int, iInput);

		SQL_NextRow(Query);
	}
	
	sqlPlayer[id] = true;
	
	if((get_user_team(id) == 1 || get_user_team(id) == 2) && is_user_alive(id))
		wybierzKlase(id);
	
	return PLUGIN_CONTINUE;
}

public LoadClass(id, class){
	if(!sqlPlayer[id])
		return;
		
	static iOutput[7];
	
	ArrayGetArray(playerInfClasses[id],class,iOutput);
	
	playerInf[id][currentLevel] 	= 	iOutput[0]
	playerInf[id][currentExp] 		= 	iOutput[1]
	playerInf[id][currentStr] 		= 	iOutput[2]
	playerInf[id][currentInt] 		= 	iOutput[3]
	playerInf[id][currentDex] 		= 	iOutput[4]
	playerInf[id][currentAgi] 		= 	iOutput[5]
	playerInf[id][currentPoints]	=	iOutput[6]
		
	if(!playerInf[id][currentLevel])
	{
		iOutput[0] = 1;
		playerInf[id][currentLevel] = 1;
		ArraySetArray(playerInfClasses[id],class,iOutput);
		if(class){
			new szTemp[256],szAuth[64],szIp[64],szClass[64];
			get_user_authid(id,szAuth,charsmax(szAuth));
			get_user_ip(id,szIp,charsmax(szIp));
			ArrayGetString(gClassNames,class,szClass,charsmax(szClass));
			formatex(szTemp, 255, "INSERT INTO %s  (`ip`, `sid`, `nick`, `klasa`) VALUES ('%s','%s','%s','%s') ON DUPLICATE KEY UPDATE klasa=klasa",SQL_TABLE,szIp,szAuth,playerInf[id][playerName],szClass);
			SQL_ThreadQuery(gTuple, "LoadClassHandleIgnore", szTemp);
		}
	}
}

public LoadClassHandleIgnore(FailState,Handle:Query,Error[],ErrCode,Data[],DataSize)
{
	if(ErrCode)
	{
		log_to_file("addons/amxmodx/logs/diablo.log","LoadClassHandleIgnore: Error on Table query: %s",Error)
	}
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		log_to_file("addons/amxmodx/logs/diablo.log","LoadClassHandleIgnore: Could not connect to SQL database.")
		
		return PLUGIN_CONTINUE
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		log_to_file("addons/amxmodx/logs/diablo.log","LoadClassHandleIgnore: Table Query failed.")
		
		return PLUGIN_CONTINUE
	}
	
	return PLUGIN_CONTINUE
}

public ResetClass(id)
{
	playerInf[id][extraStr]		=	0;
	playerInf[id][extraInt]		=	0;
	playerInf[id][extraDex]		=	0;
	playerInf[id][extraAgi]		=	0;
	playerInf[id][maxHp]			=	ArrayGetCell(gClassHp,playerInf[id][currentClass]) + (getUserStr( id ) * get_pcvar_num( pCvarStrPower ))
	playerInf[id][castTime]			=	_:0.0;
	playerInf[id][currentSpeed]		=	_:(BASE_SPEED + (float( getUserDex( id ) ) * 1.3));
	//playerInf[id][dmgReduce]		=	_:(36.3057*(1.0-floatpower( 2.7182, -0.03398*float(getUserAgi( id ))))/100);
	playerInf[id][dmgReduce]		=	_:damage_reduction(getUserAgi( id ))
	playerInf[id][maxKnife]			=	0;
	playerInf[id][howMuchKnife]		=	0;
	playerInf[id][tossDelay]		=	_:0.0;
	playerInf[id][userGrav]			=	_:1.0;
	
	ArrayClear(playerInfRender[id]);
	new iInputRedner[8];
	
	iInputRedner[0]	=	255;
	iInputRedner[1]	=	255
	iInputRedner[2]	=	255
	iInputRedner[3]	=	kRenderFxNone;
	iInputRedner[4]	=	kRenderNormal;
	iInputRedner[5]	=	16;
	iInputRedner[6]	=	_:0.0;
	iInputRedner[7]	=	0;
	
	ArrayPushArray(playerInfRender[id],iInputRedner);
	
	renderChange(id);
	speedChange(id);
	gravChange(id);
}

/*---------------------Jakies takie---------------------*/

public fwItemDeployPost(weaponEnt)
{
	new iOwner = get_pdata_cbase(weaponEnt, OFFSET_WPN_WIN, OFFSET_WPN_LINUX);	
	new iWpnID = cs_get_weapon_id(weaponEnt)
	
	if(!is_user_alive(iOwner))	return HAM_IGNORED;
	
	new gFw,iRet;
	
	gFw = CreateMultiForward("diablo_weapon_deploy",ET_IGNORE,FP_CELL,FP_CELL,FP_CELL);
	
	ExecuteForward(gFw,iRet,iOwner,iWpnID , weaponEnt );
	
	if(bow[iOwner])
	{
		bow[iOwner] = false;
		
		if(iWpnID == CSW_KNIFE)
		{
			entity_set_string(iOwner, EV_SZ_viewmodel, 	KNIFE_VIEW );  
			entity_set_string(iOwner, EV_SZ_weaponmodel, 	KNIFE_PLAYER );  
		}
	}
	
	return HAM_IGNORED;
}

public fwSpeedChange( id ){
	if( !is_user_alive( id ) ){
		return HAM_IGNORED;
	}
	
	if(!bFreezeTime)	speedChange(id);
	
	return HAM_IGNORED;
}

public renderChange(id){
	if(!is_user_alive(id))	return PLUGIN_CONTINUE;
	
	new gFw,iRet;
	
	gFw = CreateMultiForward("diablo_render_change",ET_IGNORE,FP_CELL);
	
	ExecuteForward(gFw,iRet,id);
	
	new iPos = ArraySize(playerInfRender[id]) - 1,iOutput[8];
	
	if( iPos < 0 ){
		return PLUGIN_CONTINUE;
	}
	
	ArrayGetArray(playerInfRender[id],iPos,iOutput);
	
	set_user_rendering(id,iOutput[renderFx],iOutput[renderR],iOutput[renderG],iOutput[renderB],iOutput[renderNormal],iOutput[renderAmount]);
	
	remove_task( id + TASK_RENDER );
	
	if(Float:iOutput[6] != 0.0){
		
		set_task(Float:iOutput[6] - get_gametime(),"renderEnded",id + TASK_RENDER);
	}
	
	return PLUGIN_CONTINUE;
}	

public renderEnded(id){
	id	-=	TASK_RENDER;
	
	clearRender(id);
	renderChange(id);
}

public gravChange(id){
	if(!is_user_alive(id))	return PLUGIN_CONTINUE;
	
	new gFw,iRet;
	
	gFw = CreateMultiForward("diablo_grav_change",ET_IGNORE,FP_CELL);
	
	ExecuteForward(gFw,iRet,id);
	
	set_user_gravity(id,Float:playerInf[id][userGrav]);
	
	return PLUGIN_CONTINUE;
}

public speedChange(id){
	if(!is_user_alive(id) || bFreezeTime)	return PLUGIN_CONTINUE;
	
	set_user_maxspeed(id, playerInf[id][currentSpeed]);
	
	engfunc( EngFunc_SetClientMaxspeed , id , playerInf[id][currentSpeed] )
	
	return PLUGIN_CONTINUE;
}

public fwSpawned(id){
	if(!is_user_alive(id))	return HAM_IGNORED;
	
	if(bFirstRespawn[id]){
		
		bFirstRespawn[id] = false;
		
		new szName[64]
		get_user_name(id,szName,charsmax( szName ));
		
		ColorChat(id, GREEN ,"%s %s witaj na serwerze Diablo Mod Classic.", PREFIX_SAY , szName)
	}
	
	if(!task_exists(id + HELP_TASK_ID))
		set_task( 180.0 , "autoHelp" , id + HELP_TASK_ID , .flags = "b" );
	
	playerInf[id][maxHp]			=	ArrayGetCell(gClassHp,playerInf[id][currentClass]) + (getUserStr( id ) * get_pcvar_num( pCvarStrPower ))
	playerInf[id][castTime]			=	_:0.0;
	playerInf[id][currentSpeed]		=	_:(BASE_SPEED + ( float( getUserDex( id ) ) * 1.3));
	playerInf[id][maxKnife]			=	0;
	playerInf[id][howMuchKnife]		=	0;
	playerInf[id][tossDelay]			=	_:0.0;
	playerInf[id][userGrav]			=	_:1.0;
	
	g_GrenadeTrap[id]				=	false;
	bHasBow[id]						=	0;
	bowdelay[id]					=	get_gametime();
	
	ArrayClear(playerInfRender[id]);
	new iInputRedner[8];
	
	iInputRedner[0]	=	255;
	iInputRedner[1]	=	255
	iInputRedner[2]	=	255
	iInputRedner[3]	=	kRenderFxNone;
	iInputRedner[4]	=	kRenderNormal;
	iInputRedner[5]	=	16;
	iInputRedner[6]	=	_:0.0;
	iInputRedner[7]	=	0;
	
	ArrayPushArray(playerInfRender[id],iInputRedner);
	
	bWasducking[id]	=	false;
	
	new gFw,iRet;
	
	if( playerInf[id][currentClass] != 0 ){
		if( playerInf[id][currentPoints] > 0 )
		playerPointsMenu(id);
		
		gFw = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_class_spawned",FP_CELL);
		
		ExecuteForward(gFw,iRet,id);
		
		gFw = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[id][currentClass]),"diablo_set_data",FP_CELL);
		
		ExecuteForward(gFw,iRet,id);
	}
	else
		wybierzKlase(id);
	
	if( playerInf[ id ][ currentItem ] != 0 ){
		gFw	=	CreateOneForward( ArrayGetCell(gItemPlugin , playerInf[ id ][ currentItem ] ) , "diablo_item_player_spawned" , FP_CELL );
		
		ExecuteForward( gFw , iRet , id );
	}
	
	gFw = CreateMultiForward("diablo_player_spawned",ET_IGNORE,FP_CELL);
	
	ExecuteForward(gFw,iRet,id);
	
	playerInf[id][howMuchKnife]		=	playerInf[id][maxKnife];
	
	new iEnt	=	-1;
	
	while( ( iEnt = find_ent_by_owner( iEnt , CLASS_NAME_CORSPE , id ) ) != 0 ) if( pev_valid( iEnt ) )	remove_entity( iEnt );
	
	clearRender(id);
	renderChange(id);
	gravChange(id);
	
	set_user_health( id , playerInf[id][maxHp] );
	
	return HAM_IGNORED;
}

public DeathMsg(){
	new iVictim = read_data(2);
	new iKiller = read_data(1);
	
	if(!is_user_connected( iVictim ) || !is_user_connected( iKiller ) || iKiller == iVictim || get_user_team( iVictim ) == get_user_team( iKiller ) || is_user_alive( iVictim ) )	return PLUGIN_CONTINUE;
	
	static gFw,iRet;
	
	if(playerInf[iVictim][currentClass] != 0){
		
		gFw = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[iVictim][currentClass]),"diablo_clean_data",FP_CELL);
		
		ExecuteForward(gFw,iRet,iVictim);
		
		gFw = CreateOneForward(ArrayGetCell(gClassPlugins,playerInf[iVictim][currentClass]),"diablo_class_killed",FP_CELL);
		
		ExecuteForward(gFw,iRet,iVictim);
	}
	
	gFw	=	CreateMultiForward("diablo_death",ET_IGNORE,FP_CELL,FP_CELL,FP_CELL,FP_CELL);
	
	ExecuteForward(gFw,iRet,iKiller , playerInf[iKiller][currentClass] , iVictim , playerInf[iVictim][currentClass]);
	
	killXP(iKiller,iVictim);
	
	remove_task(iVictim + TASK_DEATH);
	
	set_task(0.5, "checkDeathFlag", iVictim + TASK_DEATH , .flags = "b")
	
	new Float:fSize[3]
	pev(iVictim, pev_mins, fSize)
	
	if(fSize[2] == -18.0)	bWasducking[iVictim] = true
	else					bWasducking[iVictim] = false
	
	if(playerInf[iKiller][currentClass] != 0 && playerInf[iKiller][currentItem]	== 0)
		giveUserItem(iKiller);
	
	if( playerInf[iVictim][currentItem] != 0 ){
		playerInf[iVictim][itemDurability] -=	get_pcvar_num( pCvarDurability )
		checkItemDurability(iVictim)
	}
	
	if(get_player_alive() == 2 && get_ninjas_alive() == 2)
		set_ninjas_visible()
	
	return PLUGIN_CONTINUE;
}

public bool:checkItemDurability( id ){
	if( playerInf[id][itemDurability] <= 0 && playerInf[id][currentItem] != 0 ){
		set_hudmessage ( 255, 0, 0, -1.0, 0.4, 0, 1.0,2.0, 0.1, 0.2, -1 ) 	
		show_hudmessage(id, "Przedmiot stracil swoja wytrzymalosc!")
		
		new gFw , iRet;
		
		gFw	=	CreateOneForward( ArrayGetCell(gItemPlugin , playerInf[ id ][ currentItem ] ) , "diablo_item_reset" , FP_CELL );
		
		ExecuteForward( gFw , iRet , id );
		
		playerInf[id][currentItem]		=	0;
		playerInf[id][itemDurability]	=	0;
		
		return false;
	}
	
	return true;
}

giveUserItem( id , iItem = 0){
	new iRandom
	if( !iItem ){
		iRandom = random_num( 1 , ArraySize( gItemName ) - 1 );
	}
	else{
		iRandom	=	iItem;
	}
	
	playerInf[ id ][ currentItem ] 		= iRandom;
	playerInf[ id ][ itemDurability ] 	= ArrayGetCell( gItemDur , iRandom );
	
	new gFw , iRet , szRet[ 256 ];
	
	gFw	=	CreateOneForward( ArrayGetCell(gItemPlugin , playerInf[ id ][ currentItem ] ) , "diablo_item_set_data" , FP_CELL );
	
	ExecuteForward( gFw , iRet , id );
	
	new iArrayPass = PrepareArray(szRet, 256, 1)
	
	gFw	=	CreateOneForward( ArrayGetCell( gItemPlugin , iRandom ) , "diablo_item_give" , FP_CELL , FP_ARRAY , FP_CELL);
	
	ExecuteForward( gFw , iRet , id , iArrayPass , charsmax( szRet ) );
	
	new QuestsPlugin = find_plugin_byfile("diablo_quests.amxx");
	
	if(QuestsPlugin != -1)
	{
		gFw	=	CreateOneForward( QuestsPlugin , "diablo_item_get" , FP_CELL , FP_CELL);
		ExecuteForward( gFw , iRet , id, playerInf[ id ][ currentItem ] );
	}
	
	new szName[ MAX_LEN_NAME ];
	
	ArrayGetString( gItemName , iRandom , szName , charsmax( szName ) );
	
	set_hudmessage(220, 115, 70, -1.0, 0.40, 0, 3.0, 4.0, 0.2, 0.3, 5)
	show_hudmessage(id, "Znalazles przedmiot: %s :: %s", szName , szRet )
}

public checkDeathFlag(id)
{
	id -= TASK_DEATH;
	
	if(!is_user_connected(id)){
		remove_task(id + TASK_DEATH);
		return ;
	}
	
	if(pev(id, pev_deadflag) == DEAD_DEAD){
		
		remove_task(id + TASK_DEATH);
		
		createFakeCorpse(id)
	}
}	

public createFakeCorpse(id)
{
	set_pev(id, pev_effects, EF_NODRAW)
	
	static szModel[32]
	cs_get_user_model(id,szModel, charsmax( szModel ))
	
	static player_model[64]
	formatex(player_model, charsmax( player_model ), "models/player/%s/%s.mdl", szModel, szModel)
	
	static Float: player_origin[3]
	pev(id, pev_origin, player_origin)
	
	static Float:mins[3]
	mins[0] = -16.0
	mins[1] = -16.0
	mins[2] = -34.0
	
	static Float:maxs[3]
	maxs[0] = 16.0
	maxs[1] = 16.0
	maxs[2] = 34.0
	
	if(bWasducking[id])
	{
		mins[2] /= 2
		maxs[2] /= 2
	}
	
	static Float:player_angles[3]
	pev(id, pev_angles, player_angles)
	player_angles[2] = 0.0
	
	new sequence = pev(id, pev_sequence)
	
	new ent = fm_create_entity("info_target")
	if(ent)
	{
		set_pev(ent, pev_classname, CLASS_NAME_CORSPE)
		engfunc(EngFunc_SetModel, ent, player_model)
		engfunc(EngFunc_SetOrigin, ent, player_origin)
		engfunc(EngFunc_SetSize, ent, mins, maxs)
		set_pev(ent, pev_solid, SOLID_TRIGGER)
		set_pev(ent, pev_movetype, MOVETYPE_TOSS)
		set_pev(ent, pev_owner, id)
		set_pev(ent, pev_angles, player_angles)
		set_pev(ent, pev_sequence, sequence)
		set_pev(ent, pev_frame, 9999.9)
	}	
}

showMotd(id,szTitle[] = "",szItemName[] = "",szValue = -1 ,szDur = -1,szEffect[] = "",szDesc[] = "")
{
	
	new szData[1024],iLen = 0;
	
	iLen += formatex(szData[iLen],charsmax( szData ) - iLen,"<html><head><title>%s</title></head>",szTitle)
	
	iLen += formatex(szData[iLen],charsmax( szData ) - iLen,"<body text=^"#FFFF00^" bgcolor=^"#000000^">")
	
	iLen += formatex(szData[iLen],charsmax( szData ) - iLen,"<center><table border=^"0^" cellpadding=^"0^" cellspacing=^"0^" style=^"border-collapse: collapse^" width=^"100%s^"><tr>","^%")
	
	if( !equal(szItemName,"") )	iLen += formatex(szData[iLen],charsmax( szData ) - iLen,"<td width=^"0^"><p align=^"center^"><font face=^"Arial^"><font color=^"#FFCC00^"><b>Przedmiot: </b>%s</font><br>",szItemName)
	
	if( szValue != -1 )		iLen += formatex(szData[iLen],charsmax( szData ) - iLen,"<font color=^"#FFCC00^"><b><br>Wartosc: </b>%d</font><br>",szValue)
	
	if( szDur != -1 )		iLen += formatex(szData[iLen],charsmax( szData ) - iLen,"<font color=^"#FFCC00^"><b><br>Wytrzymalosc: </b>%d</font><br><br>",szDur)
	
	if( !equal(szEffect,"") )	iLen += formatex(szData[iLen],charsmax( szData ) - iLen,"<font color=^"#FFCC00^"><b><br>Efekt:</b> %s</font></td>",szEffect)
	
	if( !equal(szDesc,"") )		iLen += formatex(szData[iLen],charsmax( szData ) - iLen,"<font color=^"#FFCC00^"><b><br>Opis:</b> %s</font></td>",szDesc)
	
	iLen += formatex(szData[iLen],charsmax( szData ) - iLen,"</font></tr></table></center></body></html>")
	
	show_motd(id,szData, szTitle)	
}

/*---------------------Rzucanie nozami---------------------*/

public commandKnife(id) 
{

	if(!is_user_alive(id)) return PLUGIN_HANDLED

	if(!playerInf[id][howMuchKnife])
	{
		client_print(id,print_center,"Nie masz juz nozy do rzucania")
		return PLUGIN_HANDLED
	}

	if(Float:playerInf[id][tossDelay] > get_gametime() - 0.9) return PLUGIN_HANDLED
	else playerInf[id][tossDelay] = _:get_gametime()

	playerInf[id][howMuchKnife]--

	if (playerInf[id][howMuchKnife] == 1) {
		client_print(id,print_center,"Zostal ci tylko 1 noz!")
	}
	else {
		client_print(id,print_center,"Zostalo ci tylko %d nozy !",playerInf[id][howMuchKnife])
	}

	new Float: Origin[3], Float: Velocity[3], Float: vAngle[3], Ent

	entity_get_vector(id, EV_VEC_origin , Origin)
	entity_get_vector(id, EV_VEC_v_angle, vAngle)

	Ent = create_entity("info_target")

	if (!Ent) return PLUGIN_HANDLED

	entity_set_string(Ent, EV_SZ_classname, THROW_KNIFE_CLASS)
	entity_set_model(Ent, THROW_KNIFE_MODEL)

	new Float:MinBox[3] = {-1.0, -7.0, -1.0}
	new Float:MaxBox[3] = {1.0, 7.0, 1.0}
	entity_set_vector(Ent, EV_VEC_mins, MinBox)
	entity_set_vector(Ent, EV_VEC_maxs, MaxBox)

	vAngle[0] -= 90

	entity_set_origin(Ent, Origin)
	entity_set_vector(Ent, EV_VEC_angles, vAngle)

	entity_set_int(Ent, EV_INT_effects, 2)
	entity_set_int(Ent, EV_INT_solid, 1)
	entity_set_int(Ent, EV_INT_movetype, 6)
	entity_set_edict(Ent, EV_ENT_owner, id)

	VelocityByAim(id, get_pcvar_num(pCvarKnifeSpeed) , Velocity)
	entity_set_vector(Ent, EV_VEC_velocity ,Velocity)
	
	return PLUGIN_HANDLED
}

public touchKnife(knife, id)
{	
	new kid = entity_get_edict(knife, EV_ENT_owner)
	
	if(is_user_alive(id)) 
	{
		new movetype = entity_get_int(knife, EV_INT_movetype)
		
		if(movetype == 0) 
		{
			if( playerInf[id][howMuchKnife] < playerInf[id][maxKnife] )
			{
				playerInf[id][howMuchKnife] += 1
				client_print(id,print_center,"Obecna liczba nozy: %i",playerInf[id][howMuchKnife])
			}
			emit_sound(knife, CHAN_ITEM, "weapons/knife_deploy1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			remove_entity(knife)
		}
		else if (movetype != 0) 
		{
			if(kid == id) return

			remove_entity(knife)

			if(get_cvar_num("mp_friendlyfire") == 0 && get_user_team(id) == get_user_team(kid)) return

			if(is_user_alive( id ) ){
				doDamage(id,kid,get_pcvar_float(pCvarKnife),diabloDamageKnife);
			}
			
			screenShake( id , 7<<14 , 1<<13 , 1<<14 )	
			
			emit_sound(id, CHAN_ITEM, "weapons/knife_hit4.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

		}
	}
}

public touchWorld(knife, world)
{
	entity_set_int(knife, EV_INT_movetype, 0)
	emit_sound(knife, CHAN_ITEM, "weapons/knife_hitwall1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public touchbreakable(ent1, ent2){
	new szClass[64],iBreakable,iEnt;
	
	entity_get_string( ent1,EV_SZ_classname,szClass,charsmax( szClass ) );
	
	if(equali(szClass,"func_breakable"))
	{
		iBreakable	=	ent1;
		iEnt		=	ent2;
	}
	else
	{
		iBreakable	=	ent2;
		iEnt		=	ent1;
	}
	
	if(pev_valid( iEnt ) && pev(iBreakable,pev_takedamage) && pev(iBreakable, pev_health)){
		entity_get_string(iEnt,EV_SZ_classname,szClass,charsmax( szClass ))
		
		new Float: b_hp = entity_get_float(iBreakable,EV_FL_health)
		if(equali(szClass,THROW_KNIFE_CLASS)){
			if(b_hp > get_pcvar_float(pCvarKnife)) entity_set_float(iBreakable,EV_FL_health,b_hp - get_pcvar_float(pCvarKnife))
			else dllfunc(DLLFunc_Use,iBreakable,iEnt)
		}
		else if(equali(szClass,XBOW_ARROW)){
			if(b_hp > entity_get_float(iEnt , EV_FL_dmg )) entity_set_float(iBreakable,EV_FL_health,b_hp - entity_get_float(iEnt , EV_FL_dmg ))
			else dllfunc(DLLFunc_Use,iBreakable,iEnt)
		}
		
	}
	
	if( pev_valid( iEnt ) )
	{
		entity_get_string(iEnt,EV_SZ_classname,szClass,charsmax( szClass ))
	
		if(equali(szClass,THROW_KNIFE_CLASS))
		{
			emit_sound(iEnt, CHAN_ITEM, "weapons/knife_hitwall1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
		else remove_entity(iEnt)
	}
}

public Forward_FM_PlayerPreThink(id) 
{
	if(is_user_alive(id)) 
	{
		new Float:fVector[3];
		pev(id, pev_velocity, fVector)
		new Float: fSpeed = floatsqroot(fVector[0]*fVector[0]+fVector[1]*fVector[1]+fVector[2]*fVector[2])
		if((fm_get_user_maxspeed(id) * 5) > (fSpeed*9))
		set_pev(id, pev_flTimeStepSound, 300)
	}
}

public fwAddToFullPack(es, e, ent, host, hostflags, player, set){
	if(!player) 
		return FMRES_IGNORED;
	
	if(!is_user_alive(host) || !is_user_alive(ent))
		return FMRES_IGNORED;
		
	if(get_user_team(host) != get_user_team(ent))
		return FMRES_IGNORED;
    
	if(is_user_ninja(ent)){
		set_es(es, ES_RenderMode, kRenderNormal);
		set_es(es, ES_RenderAmt, 200);
		set_es(es, ES_RenderFx, kRenderFxGlowShell);
		set_es(es, ES_RenderColor, 0, 0, 255);
		set_es(es, ES_RenderAmt, 25);
		
		return FMRES_HANDLED;
    }
	
	return FMRES_IGNORED;
}

public ChangeHUD(id) 
{
	if(!diablo_check_password(id))
	{
		diablo_force_password(id);
		return PLUGIN_HANDLED;
	}
	
	playerInf[id][playerHud] = playerInf[id][playerHud] ? 0 : 1;
	if(playerInf[id][playerHud])
	{
		ColorChat(id, TEAM_COLOR, "%s Przelaczyles wyglad HUD na nowoczesny!", PREFIX_SAY);
		message_begin(MSG_ONE_UNRELIABLE, gmsgStatusText, _, id);
		write_byte(0);
		write_short(0);
		message_end();
	}
	else
		ColorChat(id, TEAM_COLOR, "%s Przelaczyles wyglad HUD na staromodny!", PREFIX_SAY);
		
	new key[64], data[8];
	format(key, 63, "%s-hud", playerInf[id][playerName]);
	format(data, 7, "%i", playerInf[id][playerHud]);
	nvault_set(DiabloHUD, key, data);
	
	return PLUGIN_HANDLED;
}

public LoadHUD(id) 
{
	new key[64], data[8], HUD[8];
	format(key, 63, "%s-hud", playerInf[id][playerName]);
	format(data, 7, "%i", playerInf[id][playerHud]);
	nvault_get(DiabloHUD, key, data, 7);
	parse(data, HUD, 7);
	
	playerInf[id][playerHud] = str_to_num(HUD);
}

public Message_Intermission()
{
	new players[32], num;
	get_players(players, num);
	
	if(num < 4)
		return;
	
	new tempfrags, id;
	
	new swapfrags, swapid;
	
	new starfrags[3];
	new starid[3];
	
	for (new i = 0; i < num; i++)
	{
		id = players[i];
		
		if(!is_user_connected(id))
			continue;
			
		tempfrags = get_user_frags(id);
		if ( tempfrags > starfrags[0] )
		{
			starfrags[0] = tempfrags;
			starid[0] = id;
			if ( tempfrags > starfrags[1] )
			{
				swapfrags = starfrags[1];
				swapid = starid[1];
				starfrags[1] = tempfrags;
				starid[1] = id;
				starfrags[0] = swapfrags;
				starid[0] = swapid;
				
				if ( tempfrags > starfrags[2] )
				{
					swapfrags = starfrags[2];
					swapid = starid[2];
					starfrags[2] = tempfrags;
					starid[2] = id;
					starfrags[1] = swapfrags;
					starid[1] = swapid;
				}
			}
		}
	}
	
	if(get_user_frags(starid[2]) == get_user_frags(starid[1]) && get_user_deaths(starid[2]) > get_user_deaths(starid[1]))
	{
		new tempid = starid[2];
		starid[2] = starid[1];
		starid[1] = tempid;
	}
	
	if(get_user_frags(starid[1]) == get_user_frags(starid[0]) && get_user_deaths(starid[1]) > get_user_deaths(starid[0]))
	{
		new tempid = starid[1];
		starid[1] = starid[0];
		starid[0] = tempid;
	}
	
	new winner = starid[2];
	
	if ( !winner )
		return;
	
	new winner_name[32];
	get_user_name(starid[2], winner_name, charsmax(winner_name));
	new second_name[32];
	get_user_name(starid[1], second_name, charsmax(second_name));
	new third_name[32];
	get_user_name(starid[0], third_name, charsmax(third_name));
	
	ColorChat(0,GREEN,"%s Gratulacje dla^x03 Zwyciezcow^x01!", PREFIX_SAY);
	ColorChat(0,GREEN,"%s^x03 %s^x01 -^x04 +300^x01 EXP'a -^x03 %i^x01 Zabojstw.", PREFIX_SAY, winner_name, starfrags[2]);
	giveXp(starid[2], 300, 0);
	ColorChat(0,GREEN,"%s^x03 %s^x01 -^x04 +200^x01 EXP'a -^x03 %i^x01 Zabojstw.", PREFIX_SAY, second_name, starfrags[1]);
	giveXp(starid[1], 200, 0);
	ColorChat(0,GREEN,"%s^x03 %s^x01 -^x04 +100^x01 EXP'a -^x03 %i^x01 Zabojstw.", PREFIX_SAY, third_name, starfrags[0]);
	giveXp(starid[0], 100, 0);
	
	for (new i = 0; i < num; i++)
	{
		id = players[i];
		
		if(!is_user_connected(id) || is_user_bot(id) || is_user_hltv(id))
			continue;
			
		SaveInfo(id, 3);
	}
}

/*---------------------STOCKS---------------------*/

stock bool:is_steam(id) 
{
	new szAuth[64];
	
	get_user_authid(id,szAuth,charsmax( szAuth ) );
	
	if(contain(szAuth, "STEAM_0:0:") != -1 || contain(szAuth, "STEAM_0:1:") != -1)
		return true;
	
	return false;
}

stock bloodEffect(id,iColor){
	new Float:fOrigin[3]
	pev(id,pev_origin,fOrigin)
	
	new Float:dx, Float:dy, Float:dz
	
	for(new i = 0; i < 3; i++) 
	{
		dx = random_float(-15.0,15.0)
		dy = random_float(-15.0,15.0)
		dz = random_float(-20.0,25.0)
		
		for(new j = 0; j < 2; j++) 
		{
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_BLOODSPRITE)
			engfunc(EngFunc_WriteCoord , fOrigin[0] + ( dx*j ) )
			engfunc(EngFunc_WriteCoord , fOrigin[1] + ( dy*j ) )
			engfunc(EngFunc_WriteCoord , fOrigin[2] + ( dz*j ) )
			write_short(spriteBloodSpray)
			write_short(spriteBloodDrop)
			write_byte(iColor) // color index
			write_byte(8) // size
			message_end()
		}
	}
}

stock bool:UTIL_In_FOV(id,target)
{
	if (Find_Angle(id,target,9999.9) > 0.0)
		return true
	
	return false
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

stock cmdExecute(id, const szText[], any:...) 
{
    #pragma unused szText

    if (id == 0 || is_user_connected(id))
	{
    	new szMessage[256]

    	format_args( szMessage ,charsmax(szMessage), 1)

        message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id)
        write_byte(strlen(szMessage) + 2)
        write_byte(10)
        write_string(szMessage)
        message_end()
    }
}

public get_player_alive() 
{
	new iAlive
	for (new id = 1; id <= get_maxplayers(); id++) 
		if (is_user_alive(id) && !is_user_bot(id)) 
			iAlive++
	return iAlive
}

public get_ninjas_alive() 
{
	new iAlive
	for (new id = 1; id <= get_maxplayers(); id++) 
		if (is_user_alive(id) && !is_user_bot(id) && is_user_ninja(id)) 
			iAlive++
	return iAlive
}

public set_ninjas_visible()
{
	for (new id = 1; id <= get_maxplayers(); id++) 
		if (is_user_alive(id) && !is_user_bot(id) && is_user_ninja(id))
			set_user_rendering(id, kRenderFxNone, 0,0,0, kRenderTransAlpha, 255)
}

public is_user_ninja(id)
{
	new szClass[MAX_LEN_NAME]
	
	ArrayGetString(gClassNames,playerInf[id][currentClass],szClass,charsmax( szClass )); 
	
	if(equali(szClass, "Ninja"))
		return 1;
	
	return 0;
}

Ham:get_player_resetmaxspeed_func()
{
	#if defined Ham_CS_Player_ResetMaxSpeed
		return IsHamValid(Ham_CS_Player_ResetMaxSpeed)?Ham_CS_Player_ResetMaxSpeed:Ham_Item_PreFrame;
	#else
		return Ham_Item_PreFrame;
	#endif
}

stock Float:damage_reduction(skill) {
	if(skill > 0) {
		new Float:qwe = float(skill)/50;
		new Float:bonus = (2.0-floatpower(2.0, qwe))/(2.8*4);
		if(bonus < 0.0) bonus = 0.0;
		return bonus+qwe/2.8;
	}

	return 0.0;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
