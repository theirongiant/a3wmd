//	@file Version: 1.0
//	@file Name: getMoveParams.sqf
//	@file Author: AgentRev
//	@file Created: 25/02/2013 18:41

private ["_player", "_params", "_currentMove", "_result"];

_player = _this select 0;
_params = _this select 1;

_currentMove = ([animationState _player, "_"] call fn_splitString) select 0; // get just the first part
// MD- split animation string into [x, xxxx] chunked array
_currentMove = _currentMove call parseMove;

_result = "";

{
	//MD- From deplacer.sqf _params will be ["A"]
	//MD- got no documentation for BIS_fnc_getFromPairs
	//MD- need to write a test for this
	_result = _result + _x + ([_currentMove, _x, ""] call BIS_fnc_getFromPairs);
} forEach _params;


_result
