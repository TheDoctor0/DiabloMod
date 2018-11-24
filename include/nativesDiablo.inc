public plugin_natives(){
	register_native("diablo_register_class","registerClass");
	
	register_native("diablo_get_user_class","getClass");
	register_native("diablo_get_class_name","getClassName" , 1);
	register_native("diablo_get_user_level","getLevel");
	register_native("diablo_get_user_exp","getExp");
	register_native("diablo_get_user_points","getPoints")
	register_native("diablo_get_user_str","getStr");
	register_native("diablo_get_user_int","getInt");
	register_native("diablo_get_user_dex","getDex");
	register_native("diablo_get_user_agi","getAgi");
	
	register_native("diablo_is_class_from","isFrom")
	
	register_native("diablo_is_this_class","isThisClass")
	
	register_native("diablo_set_speed","setSpeed")
	register_native("diablo_add_speed","addSpeed")
	register_native("diablo_reset_speed","resetSpeed");
	
	register_native("diablo_get_speed","getSpeed")
	register_native("diablo_get_speed_extra","getSpeedExtra")
	
	register_native("diablo_damage","doDamage" , 1);
	register_native("diablo_create_explode","createExplode")
	
	register_native("diablo_add_hp","addHP");
	
	register_native("diablo_is_freezetime","isFreeze");
	register_native("diablo_write_hud_native","writeHudNative");
	
	register_native("diablo_get_xpbonus","xpBonus");
	register_native("diablo_get_xpbonus2","xpBonus2");
	
	register_native("diablo_add_xp","addNativeXp");
	register_native("diablo_take_xp","takeNativeXp");
	
	register_native("diablo_add_knife","knifeAdd");
	
	register_native("diablo_set_user_grav","setGrav");
	register_native("diablo_add_user_grav","addGrav");
	register_native("diablo_get_user_grav","getGrav");
	
	register_native("diablo_kill","killPlayer");
	
	register_native("diablo_give_user_trap","userTrap")
	register_native("diablo_give_user_bow","userBow")
	
	register_native("diablo_set_user_render","setUserRender");
	register_native("diablo_render_cancel","cancelRender");
	
	register_native("diablo_show_hudmsg","showHudMsg")
	
	register_native("diablo_display_icon","displayIcon");
	register_native("diablo_display_fade","displayFade");
	register_native("diablo_screen_shake","screenShake" , 1);
	
	register_native("diablo_add_max_hp","addMaxHp");
	
	register_native("diablo_register_item","registerItem");
	
	register_native( "diablo_get_items_amount" , "getItemsAmount" );
	
	register_native( "diablo_get_user_item" , "getUserItem" );
	register_native( "diablo_set_user_item" , "setUserItem" );
	
	register_native("diablo_set_max_hp","setMaxHp");
	register_native("diablo_get_max_hp","getMaxHp");
	
	register_native("diablo_add_extra_str" , "addExtraStr");
	register_native("diablo_add_extra_int" , "addExtraInt");
	register_native("diablo_add_extra_agi" , "addExtraAgi");
	register_native("diablo_add_extra_dex" , "addExtraDex");

	register_native("diablo_set_extra_str" , "setExtraStr");
	register_native("diablo_set_extra_int" , "setExtraInt");
	register_native("diablo_set_extra_agi" , "setExtraAgi");
	register_native("diablo_set_extra_dex" , "setExtraDex");
	
	register_native("diablo_reset_grav" , "resetGrav" );
	
	register_native( "diablo_print_chat" , "printChatColor" , 1 );
	
	register_native( "diablo_is_player_class_none" , "isClassNone" , 1 );
	
	register_native( "diablo_blood_effect" , "makeBloodEffect" ,1 );
	
	register_native( "diablo_bar_timer" , "makeBarTimerNative" , 1 );
	
	register_native( "diablo_get_item_from" , "getItemFrom" , 1 );
	register_native( "diablo_get_item_to" , "getItemTo" , 1 );
	
}

public getItemFrom( idItem ){
	return ArrayGetCell( gItemFrom , idItem );
}

public getItemTo( idItem ){
	return ArrayGetCell( gItemTo , idItem );
}

public makeBarTimerNative( id , iTime ){
	makeBarTimer( id , iTime );
}

public makeBloodEffect( id , color ){
	bloodEffect( id , color );
}

public resetGrav( plugin , params ){
	if( params != 1 ){
		return PLUGIN_CONTINUE;
	}
	
	playerInf[get_param( 1 )][userGrav]			=	_:1.0;
	
	gravChange( get_param( 1 ) );
	
	return PLUGIN_CONTINUE;
}

public addExtraStr( plugin , params ){
	if( params != 2 ){
		return -1;
	}
	
	playerInf[ get_param( 1 ) ][ extraStr ]	+=	get_param( 2 );
	
	return playerInf[ get_param( 1 ) ][ extraStr ];
}

public addExtraInt( plugin , params ){
	if( params != 2 ){
		return -1;
	}
	
	playerInf[ get_param( 1 ) ][ extraInt ]	+=	get_param( 2 );
	
	return playerInf[ get_param( 1 ) ][ extraInt ];
}

public addExtraDex( plugin , params ){
	if( params != 2 ){
		return -1;
	}
	
	playerInf[ get_param( 1 ) ][ extraDex ]	+=	get_param( 2 );
	
	return playerInf[ get_param( 1 ) ][ extraDex ];
}

public addExtraAgi( plugin , params ){
	if( params != 2 ){
		return -1;
	}
	
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
	if( params != 1 ){
		return -1;
	}
	
	return playerInf[ get_param( 1 ) ][ maxHp ];
}

public setMaxHp( plugin , params ){
	if( params != 2 ){
		return PLUGIN_CONTINUE;
	}
	
	new id	=	get_param( 1 );
	
	playerInf[ id ][ maxHp ]	=	get_param( 2 );
	
	if( playerInf[ id ][ maxHp ]	>	get_user_health( id ) ){
		set_user_health( id , playerInf[ id ][ maxHp ] )
	}
	
	return PLUGIN_CONTINUE;
}

public registerItem( plugin , params ){
	if( params != 4 ){
		return PLUGIN_CONTINUE;
	}
	
	new szName[ MAX_LEN_NAME + 1];
	get_string( 1 , szName , charsmax( szName ) );
	
	ArrayPushString( gItemName , szName );
	ArrayPushCell( gItemDur , get_param( 2 ) );
	ArrayPushCell( gItemPlugin , plugin );
	ArrayPushCell( gItemFrom , get_param( 3 ) );
	ArrayPushCell( gItemTo , get_param( 4 ) );
	
	new tmpForwardsItem[ forwardsStructureItem ];
	
	tmpForwardsItem[ ITEM_SKILL_USED ]		=	CreateOneForward( plugin ,"diablo_item_skill_used",FP_CELL );
	tmpForwardsItem[ ITEM_UPGRADE_ITEM ]	=	CreateOneForward( plugin ,"diablo_upgrade_item",FP_CELL );
	tmpForwardsItem[ ITEM_INFO ]			= 	CreateOneForward ( plugin  , "diablo_item_info" , FP_CELL,FP_ARRAY,FP_CELL,FP_CELL);
	tmpForwardsItem[ ITEM_RESET ]			=	CreateOneForward( plugin ,"diablo_item_reset",FP_CELL );
	tmpForwardsItem[ ITEM_DROP ]			=	CreateOneForward( plugin ,"diablo_item_drop",FP_CELL );
	tmpForwardsItem[ ITEM_PRE_THINK ]		=	CreateOneForward( plugin ,"diablo_preThinkItem",FP_CELL );
	tmpForwardsItem[ ITEM_PLAYER_SPAWNED ]	=	CreateOneForward( plugin ,"diablo_item_player_spawned",FP_CELL );
	tmpForwardsItem[ ITEM_SET_DATA ]		=	CreateOneForward( plugin ,"diablo_item_set_data",FP_CELL );
	tmpForwardsItem[ ITEM_GIVE ]			=	CreateOneForward( plugin , "diablo_item_give" , FP_CELL , FP_ARRAY , FP_CELL);
	tmpForwardsItem[ ITEM_COPY ]			=	CreateOneForward( plugin , "diablo_copy_item" , FP_CELL , FP_CELL );
	tmpForwardsItem[ ITEM_DAMAGE_TAKEN ]	=	get_func_id( "diablo_damage_item_taken", plugin );
	tmpForwardsItem[ ITEM_DAMAGE_DO ]		=	get_func_id( "diablo_damage_item_do", plugin );
	
	ArrayPushArray( gForwardsItem , tmpForwardsItem );
	
	return PLUGIN_CONTINUE;
}

public getItemsAmount( plugin , params ){
	return ArraySize( gItemName );
}

public setUserItem( plugin , params ){
	if( params != 2 ){
		return ;
	}
	
	new id = get_param( 1 ),
		itemId = get_param( 2 );
	
	setPlayerItem( id , itemId );
	
	return ;
}

public getUserItem( plugin , params ){
	if( params != 1 ){
		return 0;
	}
	
	return getPlayerItem( get_param( 1 ) );
}

public addMaxHp( plugin , params ){
	if( params != 2 )
	return PLUGIN_CONTINUE;
	
	new id	=	get_param( 1 ) , iHp	=	get_param( 2 );
	
	if( !isPlayerClassNone( id ) ){
		playerInf[ id ][ maxHp ] += iHp;
	}
	
	return PLUGIN_CONTINUE;
}

public screenShake( id , amplitude , duration , frequency ){
	if (!pev_valid(id) || is_user_bot(id)){
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
	
	if (!pev_valid(id) || is_user_bot(id)){
		return PLUGIN_HANDLED
	}
	
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
	
	if (!pev_valid(id) || is_user_bot(id)){
		return PLUGIN_HANDLED
	}
	
	static gmsgScreenFade;
	
	if( !gmsgScreenFade )	gmsgScreenFade	=	get_user_msgid( "ScreenFade" );
	
	message_begin( MSG_ONE, gmsgScreenFade,{0,0,0}, id )
	write_short( (1<<12) * get_param( 2 ) )
	write_short( (1<<12) * get_param( 3 ) )
	write_short( get_param( 4 )  )
	write_byte ( get_param( 5 )  )
	write_byte ( get_param( 6 )  )
	write_byte ( get_param( 7 )  )
	write_byte ( get_param( 8 )  )
	message_end()
	
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
	if( params != 8 )
		return PLUGIN_CONTINUE;
	
	new iInput[8] , id = get_param(1);
	
	new iRet = PLUGIN_CONTINUE
	
	ExecuteForward( getForwardMulti( MULTI_SET_RENDER ) , iRet );
	
	if( iRet == PLUGIN_HANDLED ){
		return PLUGIN_CONTINUE;
	}
	
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

public addNativeXp(plugin,params){
	if( params != 2)
		return PLUGIN_CONTINUE;
	
	giveXp(get_param(1),get_param(2));
	
	return PLUGIN_CONTINUE;
}

public takeNativeXp(plugin,params){
	if( params != 2)
	return PLUGIN_CONTINUE;
	
	takeXp(get_param(1),get_param(2));
	
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

public bool:isFreeze(plugin,params){
	return bFreezeTime;
}

public bool: isClassNone( id ){
	if( !is_user_connected( id ) ){
		return false;
	}
	
	return isPlayerClassNone( id );
}

public addHP(plugin,params){
	if( params != 2 || !is_user_alive(get_param(1)))
	return PLUGIN_CONTINUE;
	
	new id = get_param(1),iHp = get_param(2);
	
	set_user_health(id,get_user_health(id) + iHp > playerInf[id][maxHp] ? playerInf[id][maxHp] : get_user_health(id) + iHp );
	
	return PLUGIN_CONTINUE;
}


public createExplode(plugin,params){
	if( params != 6)
		return PLUGIN_CONTINUE;
	
	new Float:fOrigin[3];
	
	get_array_f(2,fOrigin,3);
	
	if(get_param(5)){	
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
	}
	
	if( get_param( 6 ) ){
		return PLUGIN_CONTINUE;
	}
	
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
				doDamage(iEnemy,id,fDamageSec,diabloDamageGrenade);
				
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

public registerClass(plugin,params){
	if( params != 5)
	return PLUGIN_CONTINUE;
	
	new szName[MAX_LEN_NAME],szDesc[MAX_LEN_DESC]
	
	get_string(1,szName,MAX_LEN_NAME - 1);
	
	if( equal(szName , "" ) )
	return PLUGIN_CONTINUE;
	
	get_string(3,szDesc,MAX_LEN_DESC - 1);
	
	ArrayPushCell(gClassPlugins,plugin);
	ArrayPushString(gClassNames,szName);
	ArrayPushCell(gClassAvg,1);
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
	
	new tmpForwardsClass[ forwardsStructureClass ];
	
	tmpForwardsClass[ CLASS_CLEAN_DATA ]	=	CreateOneForward( plugin ,"diablo_clean_data",FP_CELL );
	tmpForwardsClass[ CLASS_SET_DATA ]		=	CreateOneForward( plugin ,"diablo_set_data",FP_CELL );
	tmpForwardsClass[ CLASS_ENABLED ]		=	CreateOneForward( plugin ,"diablo_class_enabled",FP_CELL );
	tmpForwardsClass[ CLASS_DISABLED ]		=	CreateOneForward( plugin ,"diablo_class_disabled",FP_CELL );
	tmpForwardsClass[ CLASS_SPAWNED ]		=	CreateOneForward( plugin ,"diablo_class_spawned",FP_CELL );
	tmpForwardsClass[ CLASS_POST_THINK ]	=	CreateOneForward( plugin ,"diablo_postThinkClass",FP_CELL );
	tmpForwardsClass[ CLASS_PRE_THINK ]		=	CreateOneForward( plugin ,"diablo_preThinkClass",FP_CELL );
	tmpForwardsClass[ CLASS_CALL_CAST ]		=	CreateOneForward( plugin ,"diablo_call_cast" ,FP_CELL );
	tmpForwardsClass[ CLASS_CAST_STOP ]		=	CreateOneForward( plugin ,"diablo_cast_stop" ,FP_CELL );
	tmpForwardsClass[ CLASS_CAST_MOVE ]		=	CreateOneForward( plugin ,"diablo_cast_move" ,FP_CELL );
	tmpForwardsClass[ CLASS_CAST_TIME ]		=	CreateOneForward( plugin ,"diablo_cast_time", FP_CELL,FP_FLOAT );
	tmpForwardsClass[ CLASS_SKILL_USED ]	=	CreateOneForward( plugin ,"diablo_class_skill_used", FP_CELL );
	tmpForwardsClass[ CLASS_KILLED ]		=	CreateOneForward( plugin ,"diablo_class_killed", FP_CELL );
	tmpForwardsClass[ CLASS_DAMAGE_TAKEN ]	= 	get_func_id( "diablo_damage_class_taken", plugin );
	tmpForwardsClass[ CLASS_DAMAGE_DO ]		= 	get_func_id( "diablo_damage_class_do", plugin );
	
	
	ArrayPushArray( gForwardsClass , tmpForwardsClass );
	
	return PLUGIN_CONTINUE;
}

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
	
	playerInf[id][currentSpeed]		=	_:(BASE_SPEED + (float( getUserDex( id ) ) * 1.3))
	
	speedChange(id);
	
	return 1;
}

public addSpeed(plugin,params){
	if( params != 2)
	return 0;
	
	playerInf[get_param(1)][currentSpeed]	=	_:(Float:playerInf[get_param(1)][currentSpeed] + get_param_f(2))
	
	speedChange(get_param( 1 ))
	
	return 1;
}

public Float:getSpeed(plugin,params){
	if( params != 1)
	return 0.0;
	
	return Float:playerInf[get_param(1)][currentSpeed];
}

public Float:getSpeedExtra(plugin,params){
	if( params != 1)
	return 0.0;
	
	return Float:playerInf[get_param(1)][currentSpeed] - (BASE_SPEED + (float( getUserDex( get_param( 1 ) ) ) * 1.3));
}

public isThisClass(plugin,params){
	if( params != 2)
	return 0;
	
	new szClass[MAX_LEN_NAME],szParam[MAX_LEN_NAME]
	
	ArrayGetString(gClassNames, getPlayerClass( get_param( 1 ) ) , szClass,charsmax( szClass )); 
	
	get_string(2,szParam,MAX_LEN_NAME - 1);
	
	if(equali(szClass,szParam))
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

public getPoints(plugin,params){
	if( params != 1)
	return PLUGIN_CONTINUE;
	
	return playerInf[get_param(1)][currentPoints];
}

public getClass(plugin,params){
	if( params != 1)
	return 0;
	
	return getPlayerClass( get_param( 1 ) );
}

public getClassName( class , Return[] , len){
	new szClass[MAX_LEN_NAME];
	
	param_convert( 2 )
	
	ArrayGetString(gClassNames,class,szClass,charsmax( szClass )); 
	
	copy( Return , len , szClass)
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
	
	return bool:(ArrayGetCell( gClassPlugins , getPlayerClass( get_param( 1 ) ) ) == plugin);
}

public printChatColor( id , Color:color , const msg[] , {Float,Sql,Result,_}:... ){
	new szMessage[ 256 ] ,
		szMessageFull[ 256 ];
	
	vformat( szMessage , charsmax( szMessage ) , msg , 4 );
	
	formatex( szMessageFull , charsmax( szMessageFull ) , PREFIX_SAY );
	
	copy( szMessageFull[ strlen( szMessageFull ) ] , charsmax( szMessageFull ) - strlen( szMessageFull ) , szMessage );
	
	ColorChat( id , color , szMessageFull );
}