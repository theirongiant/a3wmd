//	@file Version: 1.0
//	@file Name: serverSide.sqf
//	@file Author: AgentRev
//	@file Created: 29/06/2013 18:01

//MD- Preceeded with _flagChecksum initialisation when called from antihack/compileFuncs

//MD- No clients here
if (!isServer) exitWith {};

private ["_serverID", "_cheatFlag", "_unit"];

//MD- the fuck is this?
//MD- well it's not in the biki
//MD- http://forums.bistudio.com/showthread.php?160694-BIS_fnc_MP-isPersistent-param-is-broken/page3&highlight=bis_functions_mainscope
//MD- check internal functions (fn_initMultiplayer)
waitUntil {!isNil "bis_functions_mainscope"};
_serverID = owner bis_functions_mainscope;

//MD- Adds an event handler when a variable is broadcast using publicVariable or it's cousins, only runs on clients
//MD- https://community.bistudio.com/wiki/addPublicVariableEventHandler
"BIS_fnc_MP_packet" addPublicVariableEventHandler compileFinal "_this execVM 'server\antihack\filterExecAttempt.sqf'";

// diag_log "ANTI-HACK 0.8.0: Starting loop!";

// diag_log "ANTI-HACK 0.8.0: Detection of hacked units!";


//MD- Run constantly (isn't there a 10,000 iteration limit on while loops?)
//MD- See notes/scriptcalls 10,000 limit is only for unscheduled environment
while { true } do
{			
	//MD- https://community.bistudio.com/wiki/time
	//MD- Time since server started.
	waitUntil {time > 0.1};
	
	//MD- while cheat flag is nil
	if (isNil "_cheatFlag") then 
	{
		//MD- start of forEach(allUnits - playableUnits)
		//MD- so basically every non playable unit.
		//MD- allUnits: https://community.bistudio.com/wiki/allUnits
		//MD- playableUnits: https://community.bistudio.com/wiki/playableUnits (only MP)
		{
			//MD- Assign _unit to be current unit
			_unit = _x;
			
			//MD- if the owner isn't server
			//MD- nb: would != work as well or is there some significance to it being greater than
			if (owner _unit > _serverID) then
			{
				//MD- if it's alive, not a player and not a UAV
				//MD- could dead units, player units or uav's have ownerid's lower that the server?
				if (alive _unit && {!isPlayer _unit} && {["_UAV_AI", typeOf _unit] call fn_findString == -1}) then
				{
					//MD- create cheat flag array if it doesn't already exist
					if (isNil "_cheatFlag") then
					{
						_cheatFlag = [];
					};
					
					//MD- https://community.bistudio.com/wiki/set
					//MD- https://community.bistudio.com/wiki/count
					//MD- [0, ["hacked unit", "<type of unit>", client]]
					//MD- findClientPlayer server/functions/findClientPlayer.sqf
					//MD- scans playableunits for matching player object for owner of hacked unit
					_cheatFlag set [count _cheatFlag, ["hacked unit", typeOf _unit, [owner _unit] call findClientPlayer]];
					
					//MD- Force unit out of vehicle if it's in there, gives 0.1 seconds to happen.
					//MD- https://community.bistudio.com/wiki/moveOut
					//MD- would suggest that it happens instantly, not sure why the delay here
					for [{_i = 0}, {_i < 10 && vehicle _unit != _unit}, {_i = _i + 1}] do
					{
						moveOut _unit;
						sleep 0.01;
					};
					
					//MD- deletes the if it's a vehicle
					//MD- https://community.bistudio.com/wiki/deleteVehicle
					//MD- states that deleting a vehicle still being accessed by script can
					//MD- cause a crash to desktop (CTD), could account for the test above?
					deleteVehicle _unit;
				};
			};
		} forEach (allUnits - playableUnits);
	};
	
	//MD- take action on detected cheaters
	if (!isNil "_cheatFlag") then
	{
		//MD- loop-da-loop round the filthy cheat array
		{
			private "_player";
			_player = _x select 2;
			
			if (isPlayer _player) then
			{
				//MD- Okay, here is our first call to the mysterious TPG_fnc_MP
				//MD- params: [ [UID, _flagChecksum], "clientFlagHandler", player object, false] ]
				//MD- nb. passes over the _flagChecksum value that originally came from antihack/setup.sqf via anithack/compileFuncs.sqf
				[[getPlayerUID _player, _flagChecksum], "clientFlagHandler", _player, false] call TPG_fnc_MP;
				
				[name _player, getPlayerUID _player, _x select 0, _x select 1, _flagChecksum] call flagHandler;
			};
		} forEach _cheatFlag;
		
		_cheatFlag = nil;
	};
	
	sleep 5;
};
