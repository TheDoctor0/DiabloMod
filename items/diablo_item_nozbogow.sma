#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>

#include <diablo_nowe.inc>

#define PLUGIN	"Knife Ruby"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

#define CS_PLAYER_HEIGHT 72.0

new Float:fTime [ 33 ] , bool:bHas [ 33 ];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Rubinowy Sztylet" , 250 );
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Twoj noz pozwala ci teleportowac sie raz na 3 sekundy" )
	
	bHas[ id ]	=	true;
}

public diablo_item_reset( id ){
	fTime[ id ]	=	0.0;
	
	bHas[ id ]	=	false;
}

public diablo_item_set_data( id ){
	fTime[ id ]	=	get_gametime() + 3.0;
	
	bHas[ id ]	=	true;
}

public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Twoj noz pozwala ci teleportowac sie raz na 3 sekundy")
	}
	else{
		formatex( szMessage , iLen , "Twoj noz pozwala ci teleportowac sie raz na 3 sekundy" )
	}
}

public diablo_copy_item( iFrom , iTo ){
	fTime[ iTo ]	=	get_gametime() + 3.0;
	
	bHas[ iTo ]	=	true;
}

public diablo_preThinkItem( id ){
	if( !bHas [ id ] ){
		return PLUGIN_CONTINUE;
	}
	
	if( get_gametime() > fTime[ id ] && get_user_button(id) & IN_ATTACK2 && !(get_user_oldbutton(id) & IN_ATTACK2) && get_user_weapon( id ) == CSW_KNIFE && !diablo_is_freezetime() ){
		fTime[ id ] = get_gametime() + 3.0 ;
		
		UTIL_Teleport(id,300+15*diablo_get_user_int( id ))	
		
	}
	
	return PLUGIN_CONTINUE;
}

public UTIL_Teleport(id,distance)
{	
	Set_Origin_Forward(id,distance)
	
	new origin[3]
	get_user_origin(id,origin)
	
	//Particle burst ie. teleport effect	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY) //message begin
	write_byte(TE_PARTICLEBURST )
	write_coord(origin[0]) // origin
	write_coord(origin[1]) // origin
	write_coord(origin[2]) // origin
	write_short(20) // radius
	write_byte(1) // particle color
	write_byte(4) // duration * 10 will be randomized a bit
	message_end()
	
	
}

stock Set_Origin_Forward(id, distance) 
{
	new Float:origin[3]
	new Float:angles[3]
	new Float:teleport[3]
	new Float:heightplus = 10.0
	new Float:playerheight = 64.0
	new bool:recalculate = false
	new bool:foundheight = false
	pev(id,pev_origin,origin)
	pev(id,pev_angles,angles)
	
	teleport[0] = origin[0] + distance * floatcos(angles[1],degrees) * floatabs(floatcos(angles[0],degrees));
	teleport[1] = origin[1] + distance * floatsin(angles[1],degrees) * floatabs(floatcos(angles[0],degrees));
	teleport[2] = origin[2]+heightplus
	
	while (!Can_Trace_Line_Origin(origin,teleport) || Is_Point_Stuck(teleport,48.0))
	{	
		if (distance < 10)
		break;
		
		//First see if we can raise the height to MAX playerheight, if we can, it's a hill and we can teleport there	
		for (new i=1; i < playerheight+20.0; i++)
		{
			teleport[2]+=i
			if (Can_Trace_Line_Origin(origin,teleport) && !Is_Point_Stuck(teleport,48.0))
			{
				foundheight = true
				heightplus += i
				break
			}
			
			teleport[2]-=i
		}
		
		if (foundheight)
		break
		
		recalculate = true
		distance-=10
		teleport[0] = origin[0] + (distance+32) * floatcos(angles[1],degrees) * floatabs(floatcos(angles[0],degrees));
		teleport[1] = origin[1] + (distance+32) * floatsin(angles[1],degrees) * floatabs(floatcos(angles[0],degrees));
		teleport[2] = origin[2]+heightplus
	}
	
	if (!recalculate)
	{
		set_pev(id,pev_origin,teleport)
		return PLUGIN_CONTINUE
	}
	
	teleport[0] = origin[0] + distance * floatcos(angles[1],degrees) * floatabs(floatcos(angles[0],degrees));
	teleport[1] = origin[1] + distance * floatsin(angles[1],degrees) * floatabs(floatcos(angles[0],degrees));
	teleport[2] = origin[2]+heightplus
	set_pev(id,pev_origin,teleport)
	
	return PLUGIN_CONTINUE
}

stock bool:Can_Trace_Line_Origin(Float:origin1[3], Float:origin2[3])
{	
	new Float:Origin_Return[3]	
	new Float:temp1[3]
	new Float:temp2[3]
	
	temp1[0] = origin1[0]
	temp1[1] = origin1[1]
	temp1[2] = origin1[2]-30
	
	temp2[0] = origin2[0]
	temp2[1] = origin2[1]
	temp2[2] = origin2[2]-30
	
	trace_line(-1, temp1, temp2, Origin_Return) 
	
	if (get_distance_f(Origin_Return,temp2) < 1.0)
	return true
	
	return false
}

stock bool:Is_Point_Stuck(Float:Origin[3], Float:hullsize)
{
	new Float:temp[3]
	new Float:iterator = hullsize/3
	
	temp[2] = Origin[2]
	
	for (new Float:i=Origin[0]-hullsize; i < Origin[0]+hullsize; i+=iterator)
	{
		for (new Float:j=Origin[1]-hullsize; j < Origin[1]+hullsize; j+=iterator)
		{
			//72 mod 6 = 0
			for (new Float:k=Origin[2]-CS_PLAYER_HEIGHT; k < Origin[2]+CS_PLAYER_HEIGHT; k+=6) 
			{
				temp[0] = i
				temp[1] = j
				temp[2] = k
				
				if (point_contents(temp) != -1)
				return true
			}
		}
	}
	
	return false
}
