/**
 * Charger l'objet sélectionné (R3F_LOG_selected_object) dans un transporter
 * 
 * @param 0 le transporter
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
	
	private ["_objet", "_classes_transporters", "_transporter", "_i"];
	
	_objet = R3F_LOG_selected_object;
	_transporter = _this select 0;
	
	if (!(isNull _objet) && !(_objet getVariable "R3F_LOG_disabled")) then
	{
		if (isNull (_objet getVariable "R3F_LOG_est_transporte_par") && (isNull (_objet getVariable "R3F_LOG_est_deplace_par") || (!alive (_objet getVariable "R3F_LOG_est_deplace_par")))) then
		{
			private ["_objets_charges", "_chargement_actuel", "_cout_capacite_objet", "_chargement_maxi"];
			
			_objets_charges = _transporter getVariable "R3F_LOG_objets_charges";
			
			// Calcul du chargement actuel
			_chargement_actuel = 0;
			{
				for [{_i = 0}, {_i < count R3F_LOG_CFG_transportable_objects}, {_i = _i + 1}] do
				{
					if (_x isKindOf (R3F_LOG_CFG_transportable_objects select _i select 0)) exitWith
					{
						_chargement_actuel = _chargement_actuel + (R3F_LOG_CFG_transportable_objects select _i select 1);
					};
				};
			} forEach _objets_charges;
			
			// Recherche de la capacité de l'objet
			_cout_capacite_objet = 99999;
			for [{_i = 0}, {_i < count R3F_LOG_CFG_transportable_objects}, {_i = _i + 1}] do
			{
				if (_objet isKindOf (R3F_LOG_CFG_transportable_objects select _i select 0)) exitWith
				{
					_cout_capacite_objet = (R3F_LOG_CFG_transportable_objects select _i select 1);
				};
			};
			
			// Recherche de la capacité maximale du transporter
			_chargement_maxi = 0;
			for [{_i = 0}, {_i < count R3F_LOG_CFG_transporters}, {_i = _i + 1}] do
			{
				if (_transporter isKindOf (R3F_LOG_CFG_transporters select _i select 0)) exitWith
				{
					_chargement_maxi = (R3F_LOG_CFG_transporters select _i select 1);
				};
			};
			
			// Si l'objet loge dans le véhicule
			if (_chargement_actuel + _cout_capacite_objet <= _chargement_maxi) then
			{
				if (_objet distance _transporter <= 30) then
				{
					// On mémorise sur le réseau le nouveau contenu du véhicule
					_objets_charges = _objets_charges + [_objet];
					_transporter setVariable ["R3F_LOG_objets_charges", _objets_charges, true];
					
					player globalChat STR_R3F_LOG_action_loading_in_progress;
					
					sleep 2;
					
					// Choisir une position dégagée (sphère de 50m de rayon) dans le ciel dans un cube de 9km^3
					private ["_nb_tirage_pos", "_position_attache"];
					_position_attache = [random 3000, random 3000, (10000 + (random 3000))];
					_nb_tirage_pos = 1;
					while {(!isNull (nearestObject _position_attache)) && (_nb_tirage_pos < 25)} do
					{
						_position_attache = [random 3000, random 3000, (10000 + (random 3000))];
						_nb_tirage_pos = _nb_tirage_pos + 1;
					};
					
					_objet attachTo [R3F_LOG_PUBVAR_attach_point, _position_attache];
					detach _objet;
					sleep 0.25;
					_objet attachTo [R3F_LOG_PUBVAR_attach_point, _position_attache];
					
					R3F_LOG_selected_object = objNull;
					
					player globalChat format [STR_R3F_LOG_action_load_confirmation, getText (configFile >> "CfgVehicles" >> (typeOf _objet) >> "displayName")];
				}
				else
				{
					player globalChat format [STR_R3F_LOG_action_load_too_far_away, getText (configFile >> "CfgVehicles" >> (typeOf _objet) >> "displayName")];
				};
			}
			else
			{
				player globalChat format [STR_R3F_LOG_action_load_not_enough_space, (_chargement_maxi - _chargement_actuel), _cout_capacite_objet];
			};
		}
		else
		{
			player globalChat format [STR_R3F_LOG_action_load_object_in_transit, getText (configFile >> "CfgVehicles" >> (typeOf _objet) >> "displayName")];
		};
	};
	
	R3F_LOG_mutex_local_lock = false;
};