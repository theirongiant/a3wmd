//	@file Version: 1.2
//	@file Name: init.sqf
//	@file Author: [404] Deadbeat, [GoT] JoSchaap
//	@file Description: The main init.

#define DEBUG false

enableSaving [false, false]; //MD- no saving, don't create autosave: https://community.bistudio.com/wiki/enableSaving

//MD- not 100% sure about str call part but seems to read in descriptionExt
//MD- https://community.bistudio.com/wiki/missionConfigFile
currMissionDir = compileFinal str call 
{
	private "_arr";
	_arr = toArray str missionConfigFile;
	_arr resize (count _arr - 15);
	toString _arr
};

//MD- Define some globals
X_Server = false; 
X_Client = false;
X_JIP = false;

// versionName = ""; // Set in STR_WL_WelcomeToWasteland in stringtable.xml


//MD- And set them here
if (isServer) then { X_Server = true };
if (!isDedicated) then { X_Client = true };
if (isNull player) then { X_JIP = true };


//MD- Guess this is only run in debug - nope is passing value of DEBUG to the script
//MD- call passes [DEBUG] in globalCompile.sqf - https://community.bistudio.com/wiki/call
//MD- compile - https://community.bistudio.com/wiki/compile
//MD- preprocessFileLineNumbers - https://community.bistudio.com/wiki/preprocessFileLineNumbers
[DEBUG] call compile preprocessFileLineNumbers "globalCompile.sqf";

//init Wasteland Core

//MD- Inits globals for towns, spawns and territories
[] execVM "config.sqf";
//MD- Inits globals for shop contents
[] execVM "storeConfig.sqf"; // Separated as its now v large
//MD- Inits map menu contents
[] execVM "briefing.sqf";


//MD- If it's a player: spawn them, removeWeapons (why?), add respawn event handler to do the same
//MD- reset group side (why?) and init the client
if (!isDedicated) then
{
	//MD- Fired as soon as spawn starts, doesn't wait for completion
	[] spawn
	{
		//MD- Layer cutText["Message", Effect, FadeTime] - https://community.bistudio.com/wiki/Title_Effect_Type
		9999 cutText ["Welcome to A3Wasteland, please wait for your client to initialize", "BLACK", 0.01];
		
		//MD- wait till player has spawned
		waitUntil {!isNull player};
		//MD- Does exactly what it says on the tin
		removeAllWeapons player;
		//MD- removeWeapons on respawn - https://community.bistudio.com/wiki/Arma_3:_Event_Handlers
		client_initEH = player addEventHandler ["Respawn", { removeAllWeapons (_this select 0) }];

		//MD- Reset group & side
		//MD- https://community.bistudio.com/wiki/joinSilent
		//MD- https://community.bistudio.com/wiki/createGroup
		//MD- https://community.bistudio.com/wiki/playerSide
		[player] joinSilent createGroup playerSide;

		//MD- Run the client init
		//MD- Looks at server first as that will run before a client joins
		[] execVM "client\init.sqf";
	};
};

//MD- If it's a server then init the server
if (isServer) then
{
	//MD- https://community.bistudio.com/wiki/diag_log
	//MD- https://community.bistudio.com/wiki/format
	diag_log format ["############################# %1 #############################", missionName];
	diag_log "WASTELAND SERVER - Initializing Server";
	[] execVM "server\init.sqf";
};

//init 3rd Party Scripts
[] execVM "addons\R3F_ARTY_AND_LOG\init.sqf";
[] execVM "addons\proving_Ground\init.sqf";
[] execVM "addons\scripts\DynamicWeatherEffects.sqf";
[] execVM "addons\JumpMF\init.sqf";
