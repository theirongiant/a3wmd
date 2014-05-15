// ARMA3 function fn_vehicleInit v0.5 - by SPUn / lostvar & AgentRev
// Function to set custom init commands for units & vehicles
// Call this from another scripts with syntax:
// [_vehicle, _customInit, _persistence, _thisCheck] call fn_vehicleInit;
//
// IMPORTANT : Set "_persistence" to FALSE if you used to call "clearVehicleInit" right after "processInitCommands"
// 
// Make sure _customInit is in format (same format as setVehicleInit):
// "init command '1'; init command '2'"
// - Every init command MUST be ended in semicolon! (except the last one)
// - Keep it inside quotes, and if you need quotes in init commands, you MUST use ' or "" instead of "

//MD- Called from remorquer_deplace and passed [_objet, {_this lockDriver true}, false, false, _objet] (_objet is the object being hitched)

//MD- Also called from detacher and passed [_objet, {_this call detachTowedObject}, false, false, _objet] (_objet is the object being unhitched)

private ["_vehicle", "_customInit", "_persistence", "_thisCheck", "_target"];

//MD- set un-init'ed vars to their defaults
_vehicle = [_this, 0, objNull, [objNull]] call BIS_fnc_param;
_customInit = [_this, 1, "", ["",{}]] call BIS_fnc_param; // string or code
_persistence = [_this, 2, true, [true]] call BIS_fnc_param; // same as BIS_fnc_MP "isPersistent" - see http://community.bistudio.com/wiki/BIS_fnc_MP
_thisCheck = [_this, 3, true, [true]] call BIS_fnc_param; // convert all "this" keywords to "_this"
_target = [_this, 4, true, [objNull,[],true,0,sideUnknown]] call BIS_fnc_param; // same as BIS_fnc_MP "target"

//MD- exit if we have no vehicle
if (isNull _vehicle) exitWith {};

//MD- guessing that this is the method of testing if _customInit is blank - exit if it is
if ([_customInit, ""] call BIS_fnc_areEqual) exitWith {};

//MD- if customInit is a string (don't think it ever is in this mod)
if (typeName _customInit == "STRING") then
{
	//MD- see var init comment for details but it's false in our example
	//MD- and as far as I can see nowhere calls this with thisCheck set to true
	//MD- but let have a look anyway
	if (_thisCheck) then
	{
		private ["_initChars", "_strLen", "_command", "_varNameChars", "_inlineStr1Quote", "_inlineStr2Quote", "_vehicleChars"];
		
		_initChars = toArray _customInit; //MD- turn the code string into an array of char codes 
		_strLen = count _initChars; //MD- store the count
		_command = [];

		_varNameChars = toArray "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_"; //MD- create alphanum & _ array

		_inlineStr1Quote = false;
		_inlineStr2Quote = false;

		for "_i" from 0 to (_strLen - 1) do
		{
			// Single-quote (')
			if (!_inlineStr2Quote && {_initChars select _i == 39}) then {
				_inlineStr1Quote = !_inlineStr1Quote; // Invert bool
			};
			
			// Double-quote (")
			if (!_inlineStr1Quote && {_initChars select _i == 34}) then {
				_inlineStr2Quote = !_inlineStr2Quote; // Invert bool
			};
			
			if (!_inlineStr1Quote && {!_inlineStr2Quote} // verifies that we're not in an inline string
				&& {_i+3 < _strLen} && {toLower toString [_initChars select _i, _initChars select (_i+1), _initChars select (_i+2), _initChars select (_i+3)] == "this"} // verifies if current and next chars make up the word "this"
				&& {_i-1 < 0 || {!((_initChars select (_i-1)) in _varNameChars)}} // verifies that previous char is not part of a variable name
				&& {_i+4 >= _strLen || {!((_initChars select (_i+4)) in _varNameChars)}}) // verifies that next char is not part of a variable name	
			then
			{		
				_vehicleChars = toArray "_this";
				
				{
					_command set [count _command, _x];
				} forEach _vehicleChars;
				
				_i = _i + 3;
			}
			else {
				_command set [count _command, _initChars select _i];
			};
		};
		
		_customInit = toString _command;
	};
	
	_customInit = compile _customInit;
};

//MD- customInit has been passed as code (it has) or passed as string (it hasn't) and been compiled in the if above
//MD- aaaand were back to the mysteries of TPG_fnc_MP
//MD- but lets assume that it locks/detaches the vehicle
[[[netId _vehicle, _customInit], {(objectFromNetId (_this select 0)) call (_this select 1)}], "BIS_fnc_spawn", _target, _persistence] call TPG_fnc_MP;
