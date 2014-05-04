//	@file Version: 1.0
//	@file Name: compileFuncs.sqf
//	@file Author: AgentRev
//	@file Created: 04/01/2014 02:51

//MD- Called with 2 parameters from antihack/setup.sqf
//MD- param 0 is code to declare and initialise _flagChecksum with a random string
//MD- param 1 is code to declare and initialise _mpPacketKey with a random string

private ["_assignChecksum", "_assignPacketKey"];

//MD- https://community.bistudio.com/wiki/BIS_fnc_param
//MD- Parameter cleaning, takes [array, index, default, [array of acceptable type examples], required count]
//MD- if array[index] is null or of the wrong type then default is used.
_assignChecksum = [_this, 0, "", [""]] call BIS_fnc_param;
_assignPacketKey = [_this, 1, "", [""]] call BIS_fnc_param;

//MD- Still not getting this - why would be this nil here?
if (call compile (_assignChecksum + "isNil _flagChecksum")) then
{
	TPG_fnc_MPexec = compileFinal (_assignPacketKey + (preprocessFileLineNumbers "server\functions\network\fn_MPexec.sqf"));
	TPG_fnc_MP = compileFinal (_assignPacketKey + (preprocessFileLineNumbers "server\functions\network\fn_MP.sqf"));
	//call compile (_assignPacketKey + (preprocessFileLineNumbers "server\functions\network\fn_initMultiplayer.sqf"));
	
	if (isServer) then
	{
		flagHandler = compileFinal (_assignChecksum + (preprocessFileLineNumbers "server\antihack\flagHandler.sqf"));
		[] spawn compile (_assignChecksum + (preprocessFileLineNumbers "server\antihack\serverSide.sqf"));
	};
	
	if (!isDedicated) then	
	{
		clientFlagHandler = compileFinal (_assignChecksum + (preprocessFileLineNumbers "server\antihack\clientFlagHandler.sqf"));
		chatBroadcast = compileFinal (_assignChecksum + (preprocessFileLineNumbers "server\antihack\chatBroadcast.sqf"));
		notifyAdminMenu = compileFinal (_assignChecksum + (preprocessFileLineNumbers "server\antihack\notifyAdminMenu.sqf"));
		[] spawn compile (_assignChecksum + (preprocessFileLineNumbers "server\antihack\payload.sqf"));
	};
	
	call compile (_assignChecksum + "call compile format ['%1 = compileFinal str true', _flagChecksum]");
};

call compile (_assignPacketKey + "_mpPacketKey addPublicVariableEventHandler compileFinal '_this call TPG_fnc_MPexec'");
