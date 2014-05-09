/**
 * Sélectionne un objet à charger dans un transporter
 * 
 * @param 0 l'objet à sélectionner
 */

if (R3F_LOG_mutex_local_lock) then
{
	player globalChat STR_R3F_LOG_action_isnt_completed;
}
else
{
	_tempVar = false;
	if(!isNil {(_this select 0) getVariable "R3F_Side"}) then {
		if(playerSide != ((_this select 0) getVariable "R3F_Side")) then {
			{if(side _x ==  ((_this select 0) getVariable "R3F_Side") && alive _x && _x distance (_this select 0) < 150) exitwith {_tempVar = true;};} foreach AllUnits;
		};
	};
	if(_tempVar) exitwith {hint format["This object belongs to %1 and they're nearby you cannot take this.", (_this select 0) getVariable "R3F_Side"]; R3F_LOG_mutex_local_lock = false;};

	R3F_LOG_mutex_local_lock = true;
	
	R3F_LOG_selected_object = _this select 0;
	player globalChat format [STR_R3F_LOG_action_select_load_in_target, getText (configFile >> "CfgVehicles" >> (typeOf R3F_LOG_selected_object) >> "displayName")];
	
	R3F_LOG_mutex_local_lock = false;
};