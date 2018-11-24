#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fun>
#include <fakemeta>

#include <diablo_nowe.inc>

#define PLUGIN	"Flashlight"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

#define MAX_FLASH 15

native diablo_get_user_render_rope(id);
native diablo_get_user_render_armor(id);
native diablo_get_user_render_coat(id);

new flashlight[33]
new flashbattery[33]
new flashlight_r
new flashlight_g
new flashlight_b

new pCvarCustom,pCvarDrain,pCvarCharge,pCvarRadius,pCvarDecay;

new msgFlashLight,msgFlashBat;

new bool:bHas[ 33 ];

new render[ 33 ];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Latarka" , 250 );
	
	pCvarCustom	=	register_cvar("flashlight_custom","1");
	pCvarDrain	=	register_cvar("flashlight_drain","1.0");
	pCvarCharge	=	register_cvar("flashlight_charge","0.5");
	pCvarRadius	=	register_cvar("flashlight_radius","8");
	pCvarDecay	=	register_cvar("flashlight_decay","90");
	
	msgFlashLight	=	get_user_msgid("Flashlight");
	msgFlashBat		=	get_user_msgid("FlashBat");
	
	register_event("Flashlight","Flashlight","b");
	
	register_forward(FM_PlayerPreThink, "PlayerPreThink");
	
	register_event("HLTV", "NowaRunda", "a", "1=0", "2=0");
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Masz latarke wykrywajaca niewidzialnych graczy");
	
	bHas[ id ] = true;
	
	flashbattery[id] 	=	MAX_FLASH;
	flashlight[id] 		=	0;
	
	message_begin(MSG_ONE,msgFlashBat,{0,0,0},id);
	write_byte(flashbattery[id]);
	message_end();
	
	message_begin(MSG_ONE,msgFlashLight,{0,0,0},id);
	write_byte(flashlight[id]);
	write_byte(flashbattery[id]);
	message_end();
	
	remove_task(id);
}

public diablo_copy_item( iFrom , iTo ){
	bHas[ iTo ] = true;
	
	flashbattery[iTo] 	=	MAX_FLASH;
	flashlight[iTo] 		=	0;
	
	message_begin(MSG_ONE,msgFlashBat,{0,0,0},iTo);
	write_byte(flashbattery[iTo]);
	message_end();
	
	message_begin(MSG_ONE,msgFlashLight,{0,0,0},iTo);
	write_byte(flashlight[iTo]);
	write_byte(flashbattery[iTo]);
	message_end();
	
	remove_task(iTo);
}

public diablo_item_reset( id ){
	bHas[id] = false;
	flashbattery[id] 	=	MAX_FLASH;
	flashlight[id] 		=	0;
	
	message_begin(MSG_ONE,msgFlashBat,{0,0,0},id);
	write_byte(flashbattery[id]);
	message_end();
	
	message_begin(MSG_ONE,msgFlashLight,{0,0,0},id);
	write_byte(flashlight[id]);
	write_byte(flashbattery[id]);
	message_end();
	
	remove_task(id);
}

public diablo_item_set_data( id ){
	bHas[id] = true;
	flashbattery[id] 	=	MAX_FLASH;
	flashlight[id] 		=	0;
	
	message_begin(MSG_ONE,msgFlashBat,{0,0,0},id);
	write_byte(flashbattery[id]);
	message_end();
	
	message_begin(MSG_ONE,msgFlashLight,{0,0,0},id);
	write_byte(flashlight[id]);
	write_byte(flashbattery[id]);
	message_end();
	
	remove_task(id);
}

public diablo_item_spawned(id){
	bHas[id] = true;
	flashbattery[id] 	=	MAX_FLASH;
	flashlight[id] 		=	0;
	
	message_begin(MSG_ONE,msgFlashBat,{0,0,0},id);
	write_byte(flashbattery[id]);
	message_end();
	
	message_begin(MSG_ONE,msgFlashLight,{0,0,0},id);
	write_byte(flashlight[id]);
	write_byte(flashbattery[id]);
	message_end();
	
	remove_task(id);
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Masz latarke wykrywajaca niewidzialnych graczy")
	}
	else{
		formatex( szMessage , iLen , "Masz latarke wykrywajaca niewidzialnych graczy")
	}
}

public Flashlight(id) {
	if(!get_pcvar_num(pCvarCustom) || !is_user_alive(id)) {
		return;
	}
	
	if(flashlight[id]) {
		flashlight[id] = 0;
	}
	else if(flashbattery[id] > 0){
		flashlight[id] = 1;
	}
	
	if(!task_exists(id)) {
		set_task((flashlight[id]) ? get_pcvar_float(pCvarDrain) : get_pcvar_float(pCvarCharge),"charge",id,.flags = "b");
	}
	
	message_begin(MSG_ONE,msgFlashLight,{0,0,0},id);
	write_byte(flashlight[id]);
	write_byte(flashbattery[id]);
	message_end();
	
	entity_set_int(id,EV_INT_effects,entity_get_int(id,EV_INT_effects) & ~EF_DIMLIGHT);
}

public charge(id){
	if(!get_pcvar_num(pCvarCustom) || !is_user_alive(id)) {
		remove_task(id);
		
		return;
	}
	
	if(flashlight[id]) {
		flashbattery[id] -= 1;
	}
	else {
		flashbattery[id] += 1;
	}
	
	message_begin(MSG_ONE,msgFlashBat,{0,0,0},id);
	write_byte(flashbattery[id]);
	message_end();
	
	if(flashbattery[id] <= 0) {
		remove_task(id);
		
		flashbattery[id] = 0;
		flashlight[id] = 0;
		
		message_begin(MSG_ONE,msgFlashLight,{0,0,0},id);
		write_byte(flashlight[id]);
		write_byte(flashbattery[id]);
		message_end();
	}
	else if(flashbattery[id] >= MAX_FLASH) {
		
		flashbattery[id] = MAX_FLASH
		
		remove_task(id);
	}
}

public PlayerPreThink(id){
	if(!is_user_alive(id) || !bHas[id]){
		return PLUGIN_CONTINUE;
	}
	
	if (flashlight[id] && flashbattery[id] && get_pcvar_num(pCvarCustom)) {
		new num1, num2, num3
		num1=random_num(0,2)
		num2=random_num(-1,1)
		num3=random_num(-1,1)
		flashlight_r+=1+num1
		if (flashlight_r>250) flashlight_r-=245
		flashlight_g+=1+num2
		if (flashlight_g>250) flashlight_g-=245
		flashlight_b+=-1+num3
		if (flashlight_b<5) flashlight_b+=240		
		new origin[3];
		get_user_origin(id,origin,3);
		
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
		write_byte(27); // TE_DLIGHT
		write_coord(origin[0]); // X
		write_coord(origin[1]); // Y
		write_coord(origin[2]); // Z
		write_byte(get_pcvar_num(pCvarRadius)); // radius
		write_byte(flashlight_r); // R
		write_byte(flashlight_g); // G
		write_byte(flashlight_b); // B
		write_byte(1); // life
		write_byte(get_pcvar_num(pCvarDecay)); // decay rate
		message_end();
		
		new index1, bodypart1
		get_user_aiming(id,index1,bodypart1) 
		
		if (is_user_alive(index1) && get_user_team(id)!=get_user_team(index1) )
		{
			if(diablo_is_this_item(index1, "Swietlna Tarcza"))
				return PLUGIN_CONTINUE;
				
			diablo_set_user_render(index1,kRenderFxGlowShell,flashlight_r,flashlight_g,flashlight_b,kRenderNormal,4,7.5);
				
			if(diablo_is_this_item(index1, "Pierscien Przesladowcy")) {
				render[index1] = 5
				diablo_display_icon( index1 , 2 , "dmg_bio" , 255 , 0 , 0 )
				remove_task( index1 + 4635 )
				set_task( 7.5 , "offIcon" , index1 + 4635 )
			}
			else if(diablo_is_this_item(index1, "Naszyjnik Niewidzialnosci")){
				render[index1] = diablo_get_user_render_rope( index1 )
				diablo_display_icon( index1 , 2 , "dmg_bio" , 255 , 0 , 0 )
				remove_task( index1 + 4635 )
				set_task( 7.5 , "offIcon" , index1 + 4635 )
			}
			else if(diablo_is_this_item(index1, "Zbroja Niewidzialnosci")){
				render[index1] = diablo_get_user_render_armor( index1 )
				diablo_display_icon( index1 , 2 , "dmg_bio" , 255 , 0 , 0 )
				remove_task( index1 + 4635 )
				set_task( 7.5 , "offIcon" , index1 + 4635 )
			}
			else if(diablo_is_this_item(index1, "Plaszcz Niewidzialnosci")){
				render[index1] = diablo_get_user_render_coat( index1 )
				diablo_display_icon( index1 , 2 , "dmg_bio" , 255 , 0 , 0 )
				remove_task( index1 + 4635 )
				set_task( 7.5 , "offIcon" , index1 + 4635 )
			}
			else if(diablo_is_this_class(index1,"Ninja")){
				diablo_display_icon( index1 , 2 , "dmg_bio" , 255 , 0 , 0 )
				remove_task( index1 + 4635 )
				set_task( 7.5 , "offIcon" , index1 + 4635 )
				render[index1] = 10
			}
			else if(diablo_is_this_class(index1,"Zabojca")){
				diablo_display_icon( index1 , 2 , "dmg_bio" , 255 , 0 , 0 )
				remove_task( index1 + 4635 )
				set_task( 7.5 , "offIcon" , index1 + 4635 )
				render[index1] = 255
			}
			else {
				render[index1] = 255
			}
			remove_task( index1 + 4636 )
			set_task( 7.5 , "Render" , index1 + 4636 )
		}
	}
	
	return PLUGIN_CONTINUE;
}

public offIcon( id ){
	id	-=	4635;
	
	if( is_user_connected( id ) ){
		diablo_display_icon( id , 0 , "dmg_bio" , 255 , 0 , 0 )
	}
}

public Render( id ){
	id	-=	4636;
	
	if( is_user_connected( id ) ){
		diablo_set_user_render( id, .render = kRenderTransAlpha , .amount = render[id] )
	}
}

public NowaRunda(){
	new maxplayers = get_maxplayers();
	for(new i=1; i<=maxplayers; i++){
		if(!is_user_connected(i) || is_user_hltv(i) || is_user_bot(i))
			return;
		
		remove_task( i + 4637 )
		remove_task( i + 4638 )
	}
}