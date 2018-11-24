#define DIABLO_STOP 4
#define DIABLO_CONTINUE 3
#define DIABLO_RENDER_DESTROYED -1
#define FLAG_ALL -1

#define BOTY
//#define DEBUG

#if defined DEBUG
new const DEBUG_LOG[]	=	"addons/amxmodx/logs/debug.log";
#endif

#define PLUGIN	"Diablo Core"
#define AUTHOR	"DarkGL"
#define VERSION	"1.1.1"

new const HUD_TEXT[]			=	"";
new const SQL_TABLE[]			=	"diablo_classic";

new const THROW_KNIFE_MODEL[]	=	"models/diablomod/w_throwingknife.mdl";
new const THROW_KNIFE_CLASS[]	=	"throwing_knife";
new const CLASS_NAME_CORSPE[] 	=	"fakeCorpse";
new const XBOW_ARROW[]			=	"xbow_arrow";

new const GAME_DESCRIPTION[]	=	"Diablo Mod Classic";

new const fileLog[]				=	"diablo.log";


//#define EXP_TABLE

#define MAX_LEN_NAME 			128
#define MAX_LEN_DESC 			256
#define MAX_LEN_NAME_PLAYER		64
#define MAX_LEN_FRACTION		128
#define MAX 					32
#define MAX_LEVEL 				200
#define MAX_SKILL 				100
#define BASE_SPEED 				250.0
#define TASK_DEATH 				100
#define TASK_RENDER 			200

#define TIME_HUD 				1.0
#define ADMIN_FLAG_GIVE 		ADMIN_IMMUNITY
#define DIABLO_EVENT

#define OFFSET_WPN_LINUX		4
#define OFFSET_WPN_WIN 	 		41

new const PREFIX_SAY[]			=	"^x04[ DiabloMod ]^x01 ";


new cbow_VIEW[]  	= "models/diablomod/v_crossbow4.mdl" 
new cvow_PLAYER[]	= "models/diablomod/p_crossbow1.mdl" 
new cbow_bolt[]  	= "models/diablomod/crossbow_bolt.mdl"
new KNIFE_VIEW[] 	= "models/v_knife.mdl"
new KNIFE_PLAYER[] 	= "models/p_knife.mdl"