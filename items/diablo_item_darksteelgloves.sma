#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>

#include <diablo_nowe.inc>

#define PLUGIN	"Darksteel Glove"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

new iDamage[ 33 ] = 0

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	diablo_register_item( "Darksteel Glove" , 250 );
	
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage");
}

public diablo_item_give( id , szRet[] , iLen ){
	formatex( szRet , iLen , "Dodatkowe uszkodzenia, gdy trafisz kogos od tylu" )
}

public diablo_item_set_data( id ){
	iDamage[ id ]	=	random_num( 1 , 5 );
}

public diablo_copy_item( iFrom , iTo ){
	iDamage[ iTo ]	=	iDamage[ iFrom ];
	iDamage[ iFrom ]	=	0;
}

public diablo_item_reset( id ){
	iDamage[ id ] = 0;
}

public diablo_upgrade_item( id ){
	iDamage[ id ] += random_num( 0 , 2 )
}


public diablo_item_info( id , szMessage[] , iLen , bool:bList ){
	if( bList ){
		formatex( szMessage , iLen , "Dodatkowe uszkodzenia, gdy trafisz kogos od tylu")
	}
	else{
		formatex( szMessage , iLen , "Dodatkowe uszkodzenia, gdy trafisz kogos od tylu" )
	}
}

public TakeDamage(this, idinflictor, idattacker, Float:damage, damagebits)
{
	if(!is_user_connected(idattacker))
		return HAM_IGNORED;
	
	if(!iDamage[idattacker])
		return HAM_IGNORED;
		
	if(UTIL_In_FOV(idattacker, this) && !UTIL_In_FOV(this, idattacker)){
		new bonus = floatround(15+diablo_get_user_str(idattacker)*2*iDamage[idattacker]/10.0)
		SetHamParamFloat(4, damage + bonus);
	}
		
	return HAM_IGNORED;
}

stock bool:UTIL_In_FOV(id,target)
{
	if (Find_Angle(id,target,9999.9) > 0.0)
		return true;
	
	return false;
}

stock Float:Find_Angle(Core,Target,Float:dist)
{
	new Float:vec2LOS[2];
	new Float:flDot;
	new Float:CoreOrigin[3];
	new Float:TargetOrigin[3];
	new Float:CoreAngles[3];
	
	pev(Core,pev_origin,CoreOrigin);
	pev(Target,pev_origin,TargetOrigin);
	
	if (get_distance_f(CoreOrigin,TargetOrigin) > dist)
		return 0.0;
	
	pev(Core,pev_angles, CoreAngles);
	
	for ( new i = 0; i < 2; i++ )
		vec2LOS[i] = TargetOrigin[i] - CoreOrigin[i];
	
	new Float:veclength = Vec2DLength(vec2LOS);
	
	//Normalize V2LOS
	if (veclength <= 0.0)
	{
		vec2LOS[0] = 0.0;
		vec2LOS[1] = 0.0;
	}
	else
	{
		new Float:flLen = 1.0 / veclength;
		vec2LOS[0] = vec2LOS[0]*flLen;
		vec2LOS[1] = vec2LOS[1]*flLen;
	}
	
	//Do a makevector to make v_forward right
	engfunc(EngFunc_MakeVectors,CoreAngles);
	
	new Float:v_forward[3];
	new Float:v_forward2D[2];
	get_global_vector(GL_v_forward, v_forward);
	
	v_forward2D[0] = v_forward[0];
	v_forward2D[1] = v_forward[1];
	
	flDot = vec2LOS[0]*v_forward2D[0]+vec2LOS[1]*v_forward2D[1];
	
	if ( flDot > 0.5 )
	{
		return flDot;
	}
	
	return 0.0;
}

stock Float:Vec2DLength( Float:Vec[2] )  
{ 
	return floatsqroot(Vec[0]*Vec[0] + Vec[1]*Vec[1] );
}