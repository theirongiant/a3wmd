/**
 * Charger l'objet déplacé par le joueur dans un transporter
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
	
	_objet = R3F_LOG_player_target_object;
	
	_transporter = nearestObjects [_objet, R3F_LOG_transport_classes, 22];
	// Parce que le transporter peut être un objet transportable
	_transporter = _transporter - [_objet];
	
	if (count _transporter > 0) then
	{
		_transporter = _transporter select 0;
		
		if (alive _transporter && ((velocity _transporter) call BIS_fnc_magnitude < 6) && (getPos _transporter select 2 < 2) && !(_transporter getVariable "R3F_LOG_disabled")) then
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
				// On mémorise sur le réseau le nouveau contenu du véhicule
				_objets_charges = _objets_charges + [_objet];
				_transporter setVariable ["R3F_LOG_objets_charges", _objets_charges, true];
				
				player globalChat STR_R3F_LOG_action_load_in_vehicle_in_progress;
				
				// Faire relacher l'objet au joueur (si il l'a dans "les mains")
				_objet disableCollisionWith _transporter;
				R3F_LOG_player_target_object = objNull;
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
				_objet enableCollisionWith _transporter;
				
				player globalChat format [STR_R3F_LOG_action_load_in_vehicle_confirmation, getText (configFile >> "CfgVehicles" >> (typeOf _transporter) >> "displayName")];
			}
			else
			{
				player globalChat STR_R3F_LOG_action_load_in_vehicle_not_enough_space;
			};
		};
	};
	
	R3F_LOG_mutex_local_lock = false;
};