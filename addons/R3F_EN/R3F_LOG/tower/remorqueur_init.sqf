/**
 * Initialise un véhicule tower
 * 
 * @param 0 le tower
 */

private ["_tower", "_est_desactive", "_remorque"];

_tower = _this select 0;

_est_desactive = _tower getVariable "R3F_LOG_disabled";
if (isNil "_est_desactive") then
{
	_tower setVariable ["R3F_LOG_disabled", false];
};

// Définition locale de la variable si elle n'est pas définie sur le réseau
_remorque = _tower getVariable "R3F_LOG_remorque";
if (isNil "_remorque") then
{
	_tower setVariable ["R3F_LOG_remorque", objNull, false];
};

_tower addAction [("<img image='client\icons\r3f_tow.paa' color='#ffff00'/> <t color='#ffff00'>" + STR_R3F_LOG_action_tow_the_object + "</t>"), "addons\R3F_ARTY_AND_LOG\R3F_LOG\tower\remorquer_deplace.sqf", nil, 6, true, true, "", "R3F_LOG_objet_addAction == _target && R3F_LOG_action_remorquer_deplace_valide"];

_tower addAction [("<img image='client\icons\r3f_tow.paa' color='#ffff00'/> <t color='#ffff00'>" + STR_R3F_LOG_action_tow_select_tower + "</t>"), "addons\R3F_ARTY_AND_LOG\R3F_LOG\tower\remorquer_selection.sqf", nil, 6, true, true, "", "R3F_LOG_objet_addAction == _target && R3F_LOG_action_remorquer_selection_valide"];

_tower addAction [("<img image='client\icons\r3f_tow.paa' color='#ffff00'/> <t color='#ffff00'>" + STR_R3F_LOG_action_tow_cancel_towing + "</t>"), "addons\R3F_ARTY_AND_LOG\R3F_LOG\tower\cancel_remorquer.sqf", nil, 6, true, true, "", "R3F_LOG_objet_addAction == _target && R3F_LOG_action_remorquer_selection_valide"];