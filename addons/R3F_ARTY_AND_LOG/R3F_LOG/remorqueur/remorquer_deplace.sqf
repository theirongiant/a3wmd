/**
 * Remorque l'objet déplacé par le joueur avec un remorqueur
 * GT: The trailer moved by the player with a tug object
 * 
 * Copyright (C) 2010 madbull ~R3F~
 * 
 * This program is free software under the terms of the GNU General Public License version 3.
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

//MD- Tow a player moveable object - there are none currently in the game but AA guns from A2 wasteland would be an exmmple
//MD- Player has to be moving the object and near a tow-er

//MD- Make sure no othere operation is underway
if (R3F_LOG_mutex_local_verrou) then
{
	//MD- Say: The current operation isn't finished.
	player globalChat STR_R3F_LOG_mutex_action_en_cours;
}
else
{
	//MD- Start the operation
	R3F_LOG_mutex_local_verrou = true;
	
	private ["_objet", "_remorqueur"];
	
	//MD- Set _objet to be the object currently being moved
	_objet = R3F_LOG_joueur_deplace_objet;
	
	//MD- Grab all the tow-ers within 22m
	_remorqueur = nearestObjects [_objet, R3F_LOG_CFG_remorqueurs, 22];
	// Parce que le remorqueur peut être un objet remorquable
	// GT: Because the tug can be a towable object
	//MD- remove the current object from the list (it might be classed as a towable)
	_remorqueur = _remorqueur - [_objet];
	
	//MD- If we found at least 1 towable
	if (count _remorqueur > 0) then
	{
		_remorqueur = _remorqueur select 0; //MD- Set closest tow-er to be our target
		
		if (alive _remorqueur && //MD- if it's alive
			isNull (_remorqueur getVariable "R3F_LOG_remorque") && //MD- it's not already towing something
			((velocity _remorqueur) call BIS_fnc_magnitude < 6) && //MD- it's not moving (much)
			(getPos _remorqueur select 2 < 2) && //MD- it's not off the ground (much)
			!(_remorqueur getVariable "R3F_LOG_disabled")) then //MD- and it's not disabled
		{
			// On mémorise sur le réseau que le véhicule remorque quelque chose
			// GT: Is stored on the network that the vehicle towing something
			//MD- note the true param stating that variable is broadcast
			_remorqueur setVariable ["R3F_LOG_remorque", _objet, true];
			// On mémorise aussi sur le réseau que le canon est attaché en remorque
			// GT: It also stores on the network that the barrel is attached to the trailer
			//MD- conversely record the tow-ers relationship with the towable on the network
			_objet setVariable ["R3F_LOG_est_transporte_par", _remorqueur, true];
			
			//MD- https://community.bistudio.com/wiki/Locality_in_Multiplayer
			//MD- lockDriver only works on local objects
			//MD- A vehicle is always local to the client of its driver
			//MD- Empty vehicles/objects placed in the mission editor are local to the server
			//MD- Empty vehicles/objects created after mission start via scripting (with createVehicle for example) are local to the machine that issued the command
			//MD- In our case vehicles will be local to the server unless the player is the driver
			//MD- Need to test this, from the description: Lock the driver position of the vehicle
			//MD- not sure what the effect is if someone else is in the driver seat
			//MD- also for static weapons, is the user considered the driver? (would make sense)
			if (local _objet) then
			{
				_objet lockDriver true;
			}
			else //MD- Hooking it to a tow-er that isn't local
			{
				//MD- this sets the lock code to be the vehicle init code
				[_objet, {_this lockDriver true}, false, false, _objet] call fn_vehicleInit;
			};
			
			//MD- Get real bounding box for tow-er (same as bounding box but more precise)
			_towerBB = _remorqueur call fn_boundingBoxReal;
			_towerMinBB = _towerBB select 0;
			_towerMaxBB = _towerBB select 1;
			
			//MD- get bounding box for object
			_objectBB = _objet call fn_boundingBoxReal;
			_objectMinBB = _objectBB select 0;
			_objectMaxBB = _objectBB select 1;
			
			// minx + maxx - (0.5 * minx) for tow-er
			_towerCenterX = (_towerMinBB select 0) + (((_towerMaxBB select 0) - (_towerMinBB select 0)) / 2);
			// minx + maxx - (0.5 * minx) for object
			_objectCenterX = (_objectMinBB select 0) + (((_objectMaxBB select 0) - (_objectMinBB select 0)) / 2);
			
			//MD- from biki: Converts position from world space to object model space.
			//MD- fn_getPos3D gets the lower between getPosATL and getTerrainHeightASL
			_towerGroundPos = _remorqueur worldToModel (_remorqueur call fn_getPos3D);
			
			//MD- if we're above sealevel
			if ((getPosASL player) select 2 > 0) then
			{
				// On place le joueur sur le côté du véhicule, ce qui permet d'éviter les blessure et rend l'animation plus réaliste
				// GT: Placing the player on the side of the vehicle, which helps prevent injury and makes it more realistic animation
				//MD- Attach player to vehicle side
				player attachTo [_remorqueur,
				[
					(_towerMinBB select 0) - 0.25,
					(_towerMinBB select 1) - 0.25,
					_towerMinBB select 2
				]];
				
				//MD- Set direciton and reset position then detach player
				//MD- note on biki for setDir only works locally but 
				//MD- setPos'ing afterwards broadcasts on network
				player setDir 90;
				player setPos (getPos player);
				sleep 0.05;
				detach player;
			};
			
			// Faire relacher l'objet au joueur (si il l'a dans "les mains")
			// GT: To releasing the object to the player (if it has in "hands")
			//MD- set object player is moving to null
			R3F_LOG_joueur_deplace_objet = objNull;
			//MD- Play the medic anim
			player playMove "AinvPknlMstpSlayWrflDnon_medic";
			//MD- power nap
			sleep 2;
			
			// Attacher à l'arrière du véhicule au ras du sol
			// GT: Attached to the rear of the vehicle to the ground
			_objet attachTo [_remorqueur,
			[
				_towerCenterX - _objectCenterX,
				(_towerMinBB select 1) - (_objectMaxBB select 1) - 0.5,
				(_towerGroundPos select 2) - (_objectMinBB select 2) + 0.1
			]];
			
			//MD- detach player from whatever it's attached to (why is this here)
			//MD- the only place we attached the player we detached him afterwards in the same block?
			detach player;
			
			// Si l'objet est une arme statique, on corrige l'orientation en fonction de la direction du canon
			// GT: If the object is a static weapon, it corrects the orientation according to the direction of the barrel
			if (_objet isKindOf "StaticWeapon") then
			{
				private ["_azimut_canon"];
				
				_azimut_canon = ((_objet weaponDirection (weapons _objet select 0)) select 0) atan2 ((_objet weaponDirection (weapons _objet select 0)) select 1);
				
				// Seul le D30 a le canon pointant vers le véhicule
				// GT: Only the D30 has the gun pointing towards the vehicle
				//MD- Dunno what a D30 is but if it is one then spin that shit 180 degrees
				if !(_objet isKindOf "D30_Base") then
				{
					_azimut_canon = _azimut_canon + 180;
				};
				
				// On est obligé de demander au serveur de tourner l'objet pour nous
				// GT: One is obliged to ask the server to rotate the object for us
				//MD- Get the server to rotate the barrel
				R3F_ARTY_AND_LOG_PUBVAR_setDir = [_objet, (getDir _objet)-_azimut_canon];
				if (isServer) then
				{
					["R3F_ARTY_AND_LOG_PUBVAR_setDir", R3F_ARTY_AND_LOG_PUBVAR_setDir] spawn R3F_ARTY_AND_LOG_FNCT_PUBVAR_setDir;
				}
				else
				{
					publicVariable "R3F_ARTY_AND_LOG_PUBVAR_setDir";
				};
			};

			//MD- power nap
			sleep 5;
		};
	};
	//MD- End the operation
	R3F_LOG_mutex_local_verrou = false;
};