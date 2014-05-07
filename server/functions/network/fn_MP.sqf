//MD- Preceeded by _mpPacketKey declaraton and initialisation
//MD- when compileFinal'd via antihack/compileFuncs.sqf

/*
	Author: Karel Moricky, modified by AgentRev

	Description:
	Send function for remote execution (and executes locally if conditions are met)

	Parameter(s):
		0: ANY - function params
		1: STRING - function name
		2 (Optional):
			BOOL - true to execute on every client, false to execute it on server only
			OBJECT - the function will be executed only where unit is local [default: everyone]
			GROUP - the function will be executed only on client who is member of the group
			SIDE - the function will be executed on all players of the given side
			NUMBER - the function will be executed only on client with the given ID
			ARRAY - array of previous data types
		3 (Optional): BOOL - true for persistent call (will be called now and for every JIP client) [default: false]
	
	Returns:
	Nothing (Previously ARRAY - sent packet)
*/

//MD- Ignore for now until I've got an example of a call.
//MD- Okay, first call is from antihack/serverSide.sqf when it detects a filty cheat
//MD- passing in: [ [UID, _flagChecksum], "clientFlagHandler", player object, false] ]

//MD- https://community.bistudio.com/wiki/missionNamespace
//MD- also http://killzonekid.com/arma-scripting-tutorials-variables-part-2/
with missionnamespace do {
	private ["_params","_functionName","_target","_isPersistent","_isCall","_packet"];

	_params = 	[_this,0,[]] call bis_fnc_param; //MD- [UID, _flagChecksum] in our example, defaults to 0
	_functionName =	[_this,1,"",[""]] call bis_fnc_param; //MD- clientFlagHandler, defaults to ""
	_target =	[_this,2,true,[objnull,true,0,[],sideUnknown,grpnull]] call bis_fnc_param; //MD- a player, defaults to true
	_isPersistent =	[_this,3,false,[false]] call bis_fnc_param; //MD- false, defaults to false
	_isCall =	[_this,4,false,[false]] call bis_fnc_param; //MD- not given, defaults to false
	
	//MD= [0, [UID, _flagChecksum], "clientFlagHandler", false, false]
	_packet = [0,_params,_functionName,_target,_isPersistent,_isCall];

	//--- Local execution
	//MD- need to check up definition of isMultiplayer here
	//MD- from memory (biki is down for maintentance) isServer is true even if playing a single player mission
	//MD- need to wait on biki coming back up to check.
	//MD- and we're back
	//MD- https://community.bistudio.com/wiki/isServer
	//MD- Returns true if the machine is either a server in a multiplayer game or if it is running a singleplayer game.
	//MD- https://community.bistudio.com/wiki/isMultiplayer
	//MD- Return true if multiPlayer. (does this include servers or is it clients only)
	//MD- Okay that's as clear as mud, one of these statements seem superfluous 
	//MD- http://www.kylania.com/ex/?p=26 to  the rescue.
	//MD- isServer is true for:
	//MD- 	EDITOR PREVIEW / SINGLEPLAYER
	//MD-		MULTIPLAYER (NON-DEDICATED) HOST SERVER
	//MD-		MULTIPLAYER DEDICATED SERVER
	//MD- !isMultiplayer is true for
	//MD-		EDITOR PREVIEW / SINGLEPLAYER
	if (isServer || !isMultiplayer) then
	{
		//MD- If it's anything other than a multiplayer client

		//MD- Call TPG_fnc_MPexec for the first time
		//MD- passing in mpPacketKey and the packet above
		[_mpPacketKey, _packet] spawn TPG_fnc_MPexec;
	}
	else //--- Send to server
	{
		//MD- only MULTIPLAYER CLIENT should be here
		//MD- although isServer alone performed the same split.
		missionNamespace setVariable [_mpPacketKey, _packet];
		publicVariableServer _mpPacketKey;
	}

	// call compile _mpPacketKey
};
