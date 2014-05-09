/**
 * drop un objet en train d'être héliporté
 * 
 * @param 0 l'héliporteur
 * 
 * Copyright (C) 2010 madbull ~R3F~
 * 
 * This program is free software under the terms of the GNU General Public License version 3.
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

if (R3F_LOG_mutex_local_lock) then
{
	player globalChat STR_R3F_LOG_action_isnt_completed;
}
else
{
	R3F_LOG_mutex_local_lock = true;
	
	private ["_helicopter", "_objet", "_velocity", "_airdrop"];
	
	_helicopter = _this select 0;
	_objet = _helicopter getVariable "R3F_LOG_helicopter";
	
	// On mémorise sur le réseau que le véhicule n'héliporte plus rien
	_helicopter setVariable ["R3F_LOG_helicopter", objNull, true];
	// On mémorise aussi sur le réseau que l'objet n'est plus attaché
	_objet setVariable ["R3F_LOG_est_transporte_par", objNull, true];
	
	if ((velocity _helicopter) call BIS_fnc_magnitude < 15 && getPos _helicopter select 2 < 40) then
	{
		_airdrop = false;
	}
	else
	{
		_airdrop = true;
	};
	
	if (local _objet) then
	{
		_objet call detachTowedObject;
	}
	else
	{
		[_objet, {_this call detachTowedObject}, false, false, _objet] call fn_vehicleInit;
	};
	
	player globalChat format [STR_R3F_LOG_action_helicopter_drop_confirmation, getText (configFile >> "CfgVehicles" >> (typeOf _objet) >> "displayName")];
	
	R3F_LOG_mutex_local_lock = false;
};
