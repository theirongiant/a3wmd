/**
 * Charger l'objet déplacé par le joueur dans un transporteur
 * GT: Load moved by the player in a carrier object
 * 
 * Copyright (C) 2010 madbull ~R3F~
 * 
 * This program is free software under the terms of the GNU General Public License version 3.
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

//MD- Deal with objects that are player moveable and transportable

//MD- Usual if we're busy, tell the user and exit
if (R3F_LOG_mutex_local_verrou) then
{
	player globalChat STR_R3F_LOG_mutex_action_en_cours;
}
else
{
	//MD- We're now busy
	R3F_LOG_mutex_local_verrou = true;
	
	private ["_objet", "_classes_transporteurs", "_transporteur", "_i"];
	
	//MD- _objet = the object carried by the player
	_objet = R3F_LOG_joueur_deplace_objet;
	
	//MD- Find the nearest transporter class objects within 22m
	_transporteur = nearestObjects [_objet, R3F_LOG_classes_transporteurs, 22];
	// Parce que le transporteur peut être un objet transportable
	//GT: Because the carrier can be a transportable object
	//MD- i.e. quad bike can be both a transporter and a transportable
	//MD- remove our object from the list
	_transporteur = _transporteur - [_objet];
	
	//MD- if we've found at least one
	if (count _transporteur > 0) then
	{
		//MD- Set transporter to be the first (closest?) in the list
		_transporteur = _transporteur select 0;
		//MD- if alive, not moving(much), not off the ground and not disabled
		if (alive _transporteur && ((velocity _transporteur) call BIS_fnc_magnitude < 6) && (getPos _transporteur select 2 < 2) && !(_transporteur getVariable "R3F_LOG_disabled")) then
		{
			private ["_objets_charges", "_chargement_actuel", "_cout_capacite_objet", "_chargement_maxi"];
			
			//MD- google translate give "object loads"
			//MD- probably would be "loaded objects" in English
			_objets_charges = _transporteur getVariable "R3F_LOG_objets_charges";
			
			// Calcul du chargement actuel
			// GT: calculation of current load 
			_chargement_actuel = 0;
			{//MD- loop round loaded objects
				for [{_i = 0}, {_i < count R3F_LOG_CFG_objets_transportables}, {_i = _i + 1}] do
				{
					//MD- if loaded object is kind of transportable (why would we be here if it wasn't)
					if (_x isKindOf (R3F_LOG_CFG_objets_transportables select _i select 0)) exitWith
					{
						//MD- Add the weight of this object to the total
						_chargement_actuel = _chargement_actuel + (R3F_LOG_CFG_objets_transportables select _i select 1);
					};
				};
				//MD- does beg the question, why isn't this stored as a variable on the vehicle rather than being
				//MD- calculated every time someone loads an object?
			} forEach _objets_charges;
			
			// Recherche de la capacité de l'objet
			// GT: Search of the capacity of the object
			//MD- set object weight to a big number
			_cout_capacite_objet = 99999;
			//MD- loop round all the transportables
			for [{_i = 0}, {_i < count R3F_LOG_CFG_objets_transportables}, {_i = _i + 1}] do
			{
				//MD- If we find a match for our object
				if (_objet isKindOf (R3F_LOG_CFG_objets_transportables select _i select 0)) exitWith
				{
					//MD- store the object weight
					_cout_capacite_objet = (R3F_LOG_CFG_objets_transportables select _i select 1);
				};
				//MD- by setting the cout_capacite_objet big it's effectively a defensive measure to stop non-loadables being loaded
				//MD- again can't see why this would be need as how else would we get here if not through interacting with a transportable?
				//MD- is it hacker prevention / are the transportables just the base classes and we treat subclasses as the same thing weight-wise
				//MD- alternatively this might be to do with editing values, if you change the weight of something existing instances of it wouldn't
				//MD- necessarily pick up the changes although that sounds more like a load/save issue.
				//MD- other option is that is could be less expensive than broadcasting
			};
			
			// Recherche de la capacité maximale du transporteur
			// GT: Search for the maximum capacity of the carrier
			//MD- maximum load
			_chargement_maxi = 0;
			for [{_i = 0}, {_i < count R3F_LOG_CFG_transporteurs}, {_i = _i + 1}] do
			{
				//MD- if our trnasporter is a transporter (it must deal with classes rather than exact objects or this is silly)
				if (_transporteur isKindOf (R3F_LOG_CFG_transporteurs select _i select 0)) exitWith
				{
					//MD- Store the max load. Again would this not be better stored on the vehicle
					_chargement_maxi = (R3F_LOG_CFG_transporteurs select _i select 1);
				};
			};
			
			// Si l'objet loge dans le véhicule
			// GT: If the object is housed in the vehicle
			//MD- Again GT seems out, if checks that the capacity isn't being breached
			if (_chargement_actuel + _cout_capacite_objet <= _chargement_maxi) then
			{
				// On mémorise sur le réseau le nouveau contenu du véhicule
				// GT: Is stored on the network the new vehicle content
				//MD- Add object to loaded objects array
				_objets_charges = _objets_charges + [_objet];
				//MD- set the transporters load to the new array and broadcast
				_transporteur setVariable ["R3F_LOG_objets_charges", _objets_charges, true];
				
				//MD- Say: Loading in progress...
				player globalChat STR_R3F_LOG_action_charger_deplace_en_cours;
				
				// Faire relacher l'objet au joueur (si il l'a dans "les mains")
				// GT: To releasing the object to the player (if it has in "hands")

				//MD- disables collision between vehicles
				//MD- is this just for the quadbike?
				_objet disableCollisionWith _transporteur;
				//MD- Set the object being moved by the player to null
				R3F_LOG_joueur_deplace_objet = objNull;
				//MD- nap a bit
				sleep 2;
				
				// Choisir une position dégagée (sphère de 50m de rayon) dans le ciel dans un cube de 9km^3
				// GT: Choose a disengaged position (sphere of radius 50m) in the air in a cube 9km ^ 3
				private ["_nb_tirage_pos", "_position_attache"];
				//MD- set position attache to be somewhere random [0-3000, 0-3000, 10000 + 0-3000] (?)
				_position_attache = [random 3000, random 3000, (10000 + (random 3000))];
				_nb_tirage_pos = 1;
				//MD- Have 25 goes at picking a random position that doesn't have any nearby objects within 50m 
				//MD- https://community.bistudio.com/wiki/nearestObjects
				//MD- is set at 50m 
				while {(!isNull (nearestObject _position_attache)) && (_nb_tirage_pos < 25)} do
				{
					_position_attache = [random 3000, random 3000, (10000 + (random 3000))];
					_nb_tirage_pos = _nb_tirage_pos + 1;
				};
				
				//MD- Okay no idea, the PUBVAR is a helipad placed at 0,0,0
				//MD- only thing i can think of is that it is storing objects
				//MD- in a hidden location rather than having to serialise the object (and contained objects in the case of a weapon cache),
				//MD- delete the object and then having to reserialise it when it's unloaded
				_objet attachTo [R3F_LOG_PUBVAR_point_attache, _position_attache];
				detach _objet;
				sleep 0.25;
				_objet attachTo [R3F_LOG_PUBVAR_point_attache, _position_attache];
				//MD- but no idea why it's attached, detached and then attached again
				//MD- but we re-enble collisions between object and vehicle
				_objet enableCollisionWith _transporteur;
				
				//MD- The object has been loaded in the vehicle <whatever>
				player globalChat format [STR_R3F_LOG_action_charger_deplace_fait, getText (configFile >> "CfgVehicles" >> (typeOf _transporteur) >> "displayName")];
			}
			else  //MD- Not enough space to load object
			{ 
				//MD- Say: There is not enough space in this vehicle.
				player globalChat STR_R3F_LOG_action_charger_deplace_pas_assez_de_place;
			};
		};
	};
	
	//MD- End the operation
	R3F_LOG_mutex_local_verrou = false;
};