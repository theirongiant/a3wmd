/**
 * Initialise un véhicule héliporteur
 * 
 * @param 0 l'héliporteur
 */

private ["_helicopter", "_est_desactive", "_helicopter"];

_helicopter = _this select 0;

_est_desactive = _helicopter getVariable "R3F_LOG_disabled";
if (isNil "_est_desactive") then
{
	_helicopter setVariable ["R3F_LOG_disabled", false];
};

// Définition locale de la variable si elle n'est pas définie sur le réseau
_helicopter = _helicopter getVariable "R3F_LOG_helicopter";
if (isNil "_helicopter") then
{
	_helicopter setVariable ["R3F_LOG_helicopter", objNull, false];
};

_helicopter addAction [("<img image='client\icons\r3f_tow.paa' color='#ffff00'/> <t color='#ffff00'>" + STR_R3F_LOG_action_helicopter + "</t>"), "addons\R3F_ARTY_AND_LOG\R3F_LOG\helicopter\helicopter.sqf", nil, 6, true, true, "", "R3F_LOG_objet_addAction == _target && R3F_LOG_action_helicopter_valide"];

_helicopter addAction [("<img image='client\icons\r3f_release.paa' color='#06ef00'/> <t color='#06ef00'>" + STR_R3F_LOG_action_heliport_drop + "</t>"), "addons\R3F_ARTY_AND_LOG\R3F_LOG\helicopter\drop.sqf", nil, 6, true, true, "", "R3F_LOG_objet_addAction == _target && R3F_LOG_action_heliport_drop_valide"];
