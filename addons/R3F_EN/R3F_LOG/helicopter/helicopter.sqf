/**
 * Héliporte un objet avec un héliporteur
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
	
	private ["_helicopter", "_objet"];
	
	_helicopter = _this select 0;
	_objet = nearestObjects [_helicopter, R3F_LOG_CFG_liftable_objects, 20];
	// Parce que l'héliporteur peut être un objet héliportable
	_objet = _objet - [_helicopter];
	
	if (count _objet > 0) then
	{
		_objet = _objet select 0;
		
		if !(_objet getVariable "R3F_LOG_disabled") then
		{
			if (isNull (_objet getVariable "R3F_LOG_est_transporte_par")) then
			{
				if (count crew _objet == 0) then
				{
					// Si l'objet n'est pas en train d'être déplacé par un joueur
					if (isNull (_objet getVariable "R3F_LOG_est_deplace_par") || (!alive (_objet getVariable "R3F_LOG_est_deplace_par"))) then
					{
						private ["_ne_remorque_pas", "_remorque"];
						// Ne pas héliporter quelque chose qui remorque autre chose
						_ne_remorque_pas = true;
						_remorque = _objet getVariable "R3F_LOG_remorque";
						if !(isNil "_remorque") then
						{
							if !(isNull _remorque) then
							{
								_ne_remorque_pas = false;
							};
						};
						
						if (_ne_remorque_pas) then
						{
							// On mémorise sur le réseau que l'héliporteur remorque quelque chose
							_helicopter setVariable ["R3F_LOG_helicopter", _objet, true];
							// On mémorise aussi sur le réseau que l'objet est attaché à un véhicule
							_objet setVariable ["R3F_LOG_est_transporte_par", _helicopter, true];
							
							_heliBB = _helicopter call fn_boundingBoxReal;
							_heliMinBB = _heliBB select 0;
							_heliMaxBB = _heliBB select 1;
							
							_objectBB = _objet call fn_boundingBoxReal;
							_objectMinBB = _objectBB select 0;
							_objectMaxBB = _objectBB select 1;
							
							_objectCenterX = (_objectMinBB select 0) + (((_objectMaxBB select 0) - (_objectMinBB select 0)) / 2);
							_objectCenterY = (_objectMinBB select 1) + (((_objectMaxBB select 1) - (_objectMinBB select 1)) / 2);
							
							_heliPos = _helicopter modelToWorld [0,0,0];
							_objectPos = _objet modelToWorld [0,0,0];
							
							_minZ = (_heliMinBB select 2) - (_objectMaxBB select 2) - 0.5;
							
							// Attacher sous l'héliporteur au ras du sol
							_objet attachTo [_helicopter,
							[
								0 - _objectCenterX,
								0 - _objectCenterY,
								((_objectPos select 2) - (_heliPos select 2) + 2) min _minZ
							]];
							
							player globalChat format [STR_R3F_LOG_action_helicopter_confirmation, getText (configFile >> "CfgVehicles" >> (typeOf _objet) >> "displayName")];
						}
						else
						{
							player globalChat format [STR_R3F_LOG_action_helicopter_object_is_towing, getText (configFile >> "CfgVehicles" >> (typeOf _objet) >> "displayName")];
						};
					}
					else
					{
						player globalChat format [STR_R3F_LOG_action_helicopter_moved_by_player, getText (configFile >> "CfgVehicles" >> (typeOf _objet) >> "displayName")];
					};
				}
				else
				{
					player globalChat format [STR_R3F_LOG_action_helicopter_player_in_object, getText (configFile >> "CfgVehicles" >> (typeOf _objet) >> "displayName")];
				};
			}
			else
			{
				player globalChat format [STR_R3F_LOG_action_helicopter_already_carrying, getText (configFile >> "CfgVehicles" >> (typeOf _objet) >> "displayName")];
			};
		};
	};
	
	R3F_LOG_mutex_local_lock = false;
};