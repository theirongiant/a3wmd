//	@file Version: 1.0
//	@file Name: detachTowedObject.sqf
//	@file Author: AgentRev
//	@file Created: 014/07/2013 14:54

private ["_object", "_tower", "_airdrop", "_pos", "_altitude", "_vel"];

if (typeName _this != "OBJECT") exitWith {};

_object = _this;

//MD- if the object isn't null and is local
if (!isNull _object && {local _object}) then
{
	//MD- set _tower to the attached object
	_tower = attachedTo _object;
	_airdrop = [_this, 1, false, [false]] call BIS_fnc_param; //MD- Set _airdrop, if it's not declared set to falsee
	
	//MD- enable simulation on object and tow-er
	//MD- only locally, need to read up on locaility
	_object enableSimulation true; // FPS fix safeguard
	_tower enableSimulation true;
	
	//MD- if it's an airdrop
	if (_airdrop) then
	{
		//MD- i'm guessing detached objects start at rest
		//MD- and this retains preserves their pre-detach velocity
		_vel = velocity _object;
		detach _object;
		_object setVelocity _vel;
	}
	else
	{
		//MD- Set object flat on ground
		//MD- seems balance out a difference in pos and posATL
		//MD- placing it slightly above.
		//MD- need to test what the differences are
		_pos = getPos _object;
		_altitude = (getPosATL _object) select 2;
		detach _object;
		if (_tower isKindOf "Helicopter") then { _object setVectorUp [0,0,1] };
		_object setPosATL [_pos select 0, _pos select 1, (_altitude - (_pos select 2)) + 0.01];	
		_object setVelocity [0,0,0.01];
	};
	
	//MD- reset vehicle status 
	_object lockDriver false;
	_object enableCopilot true;
};
