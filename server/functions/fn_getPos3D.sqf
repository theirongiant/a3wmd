//	@file Name: fn_getPos3D.sqf
//	@file Author: AgentRev

// This function is to counter the fact that "getPos" is relative to the floor under the object,
// while most functions require positions to be from ground or sea level, whichever is highest

//MD- gets passed in the player

private "_pos";
_pos = getPosATL _this;

//MD- get teriain height above sea level at this position
if (getTerrainHeightASL _pos < 0) then
{
	_pos = getPosASL _this;
};

_pos
