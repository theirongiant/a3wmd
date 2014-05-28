//	@file Version: 1.0
//	@file Name: setup.sqf
//	@file Author: AgentRev
//	@file Created: 07/06/2013 22:24

if (!isServer) exitWith {};

if (isNil "ahSetupDone") then
{
	private ["_packetKey", "_assignPacketKey", "_packetKeyArray", "_checksum", "_assignChecksum", "_checksumArray", "_networkCompile"];
	

	//MD- create a random string of characters
	_packetKey = call generateKey;
	
	_assignPacketKey = "";
	//MD- Add up to 49 spaces to assignPacketKey - not sure why?
	for "_x" from 0 to (floor random 50) do { _assignPacketKey = _assignPacketKey + " " };
	
	//MD- add: private "_mpPacketKey"
	_assignPacketKey = _assignPacketKey + 'private "_mpPacketKey";';

	//MD- add another 49-ish spaces to assignPacketKey - who knows?
	for "_x" from 0 to (floor random 50) do { _assignPacketKey = _assignPacketKey + " " };

	//MD- add: call compile toString
	_assignPacketKey = _assignPacketKey + "call compile toString ";


	_packetKeyArray = "_mpPacketKey = ";

	//MD- add each character in packetkey to packetKeyArray so it looks like _mpPacketKey = "a"+"3"+"5"+"g"...
	{
		//MD- https://community.bistudio.com/wiki/forEach - _forEachIndex is the current index, _x is the current item
		if (_forEachIndex > 0) then { _packetKeyArray = _packetKeyArray + "+" };
		_packetKeyArray = _packetKeyArray + format ['"%1"', toString [_x]];
	} forEach toArray _packetKey;

	//MD- ???? Need to test what the fuck this does ???
	//MD- Okay 
	//MD- https://community.bistudio.com/wiki/toArray - converts a string into an array of character codes
	//MD- https://community.bistudio.com/wiki/str - converts variable into a string
	//MD- to clarify, on an array([1,2]) it will return "[1,2]" rather than "12"
	//MD- After some testing _assignPacketKey is: private "_mpPacketKey"; call compile toString [23,54,106,102,104....]
	//MD- When the call line is run the array will toString back to _mpPacketKey = "a"+"3"+"5"+"g"....
	_assignPacketKey = _assignPacketKey + (str toArray _packetKeyArray) + "; ";
	
	//MD- Repeat the above process for _flagChecksum
	_checksum = call generateKey;
	
	_assignChecksum = "";
	for "_x" from 0 to (floor random 50) do { _assignChecksum = _assignChecksum + " " };
	_assignChecksum = _assignChecksum + 'private "_flagChecksum";';
	for "_x" from 0 to (floor random 50) do { _assignChecksum = _assignChecksum + " " };
	_assignChecksum = _assignChecksum + "call compile toString ";
	_checksumArray = "_flagChecksum = ";
	{
		if (_forEachIndex > 0) then { _checksumArray = _checksumArray + "+" };
		_checksumArray = _checksumArray + format ['"%1"', toString [_x]];
	} forEach toArray _checksum;
	_assignChecksum = _assignChecksum + (str toArray _checksumArray) + "; ";

	
	//MD- These two strings are then sent to compileFuncs as parameters
	//MD- when A3W_network_compileFuncs is called.
	A3W_network_compileFuncs = compile ("['" + _assignChecksum + "','" + _assignPacketKey + "'] call compile preprocessFileLineNumbers 'server\antihack\compileFuncs.sqf'");
	//MD- run it now
	_networkCompile = [] spawn A3W_network_compileFuncs;
	//MD- Send it to  all clients (need some testing to see how this works)
	publicVariable "A3W_network_compileFuncs";
	//MD- Wait till completion
	waitUntil {sleep 0.1; scriptDone _networkCompile};

	//MD- This prevents any attempts to change a3W_network_compileFuncs
	//MD- by setting the new value to itself in the EH
	"A3W_network_compileFuncs" addPublicVariableEventHandler { _this set [1, A3W_network_compileFuncs] };
	
	//MD- flagHandler compiled and stored locally
	flagHandler = compileFinal (_assignChecksum + (preprocessFileLineNumbers "server\antihack\flagHandler.sqf"));

	//MD- 
	[] spawn compile (_assignChecksum + (preprocessFileLineNumbers "server\antihack\serverSide.sqf"));
	
	//MD- Take a guess that this kills any hacking scripts that might be broadcast to the server?
	LystoAntiAntiHack = compileFinal "false";
	AntiAntiAntiAntiHack = compileFinal "false";
	
	//MD- Mark antihack as completed and log message
	ahSetupDone = compileFinal "true";
	diag_log "ANTI-HACK 0.8.0: Started.";
};
