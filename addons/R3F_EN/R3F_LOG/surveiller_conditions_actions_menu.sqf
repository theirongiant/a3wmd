/**
 * Vérifie régulièrement des conditions portant sur l'objet pointé par l'arme du joueur
 * Permet de diminuer la fréquence des vérifications des conditions normalement faites dans les addAction (~60Hz)
 * La justification de ce système est que les conditions sont très complexes (count, nearestObjects)
 * 
 * Google Traanslate
	* Check regularly conditions on the object pointed to by the player's weapon 
  * Lowers the frequency of audits conditions normally do in addAction (~ 60Hz) 
  * The rationale of this system is that the conditions are very complex (count, nearestObjects)

 * Copyright (C) 2010 madbull ~R3F~
 * 
 * This program is free software under the terms of the GNU General Public License version 3.
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
private ["_objet_pointe", "_resetConditions"];

//MD- charger = load
//MD- deplace = moveable
//MD- contenu = contents
//MD- remorquer = tow
//MD- helicopter = lift?
//MD- drop = drop


_resetConditions = 
{
	R3F_LOG_action_charger_deplace_valide = false;
	R3F_LOG_action_charger_selection_valide = false;
	R3F_LOG_action_contenu_vehicule_valide = false;
	R3F_LOG_action_remorquer_deplace_valide = false;
	R3F_LOG_action_remorquer_selection_valide = false;
	R3F_LOG_action_selectionner_objet_remorque_valide = false;
	R3F_LOG_action_helicopter_valide = false;
	R3F_LOG_action_heliport_drop_valide = false;
};

while {true} do
{
	R3F_LOG_objet_addAction = objNull;
	
	//MD- get what is being pointed at
	_objet_pointe = cursorTarget;
	
	//MD- if it's not null
	if !(isNull _objet_pointe) then
	{
		//if (player distance _objet_pointe < 13) then
		//MD- distance is less than 14m AND ( !multiplayer(what?) OR object isn't local OR netId of object doesn't contain ":-" (eh?)
		if (player distance _objet_pointe < 14 && {!isMultiplayer || {!local _objet_pointe} || {[":-", netId _objet_pointe] call fn_findString == -1}}) then
		{
			//MD- Found an ojbect we can add actions to
			R3F_LOG_objet_addAction = _objet_pointe;
			
			// Note : les expressions de conditions ne sont pas factorisées pour garder de la clarté (déjà que c'est pas vraiment ça) (et le gain serait minime)
			// GT: Note: the terms of conditions are not factored to keep clarity (already it's not really) (and the gain would be minimal)

			//MD- set _canLock to true unless the object is already locked
			Object_canLock = !(_objet_pointe getVariable ['objectLocked', false]);
			
			// Si l'objet est un objet déplaçable
			// GT: If the object is a movable object
			//MD- neat little array count functionality here
			//MD- it rips through the array performing the chunk of code for each object
			//MD- any time the code evaluates to true count is incremented
			//MD- so this if looks through the list of moveable to find a match for our object
			if ({_objet_pointe isKindOf _x} count R3F_LOG_CFG_moveable_objects > 0) then
			{
				// Condition action deplacer_objet
				//MD- MOVE OBJECT VALID
				R3F_LOG_action_deplacer_objet_valide = (vehicle player == player && //MD- Player isn't in vehicle AND
					(count crew _objet_pointe == 0) &&  //MD- Object doesn't have a crew AND
					(isNull R3F_LOG_player_target_object) && //MD- Object player is moving is null AND
					(
						isNull (_objet_pointe getVariable "R3F_LOG_est_deplace_par") ||  //MD- player that is moving object is null OR
						(!alive (_objet_pointe getVariable "R3F_LOG_est_deplace_par")) //MD- player that is moving object is dead
					) && //MD- AND
					isNull (_objet_pointe getVariable "R3F_LOG_est_transporte_par") &&  //MD- vehicle transporting object is null AND
					!(_objet_pointe getVariable "R3F_LOG_disabled")); //MD- obhect isn't disabled
			};
			
			// Si l'objet est un objet remorquable
			// GT: If the object is a towable object
			if ({_objet_pointe isKindOf _x} count R3F_LOG_CFG_towable_objects > 0) then
			{
				// Et qu'il est déplaçable
				//MD- and it is moveable
				if ({_objet_pointe isKindOf _x} count R3F_LOG_CFG_moveable_objects > 0) then
				{
					// Condition action remorquer_deplace 
					//MD- TOWER VALID
					R3F_LOG_action_remorquer_deplace_valide = (vehicle player == player && //MD- Player isn't in a vehicle AND
						(alive R3F_LOG_player_target_object) && //MD- object being moved is alive AND
						(
							isNull driver _objet_pointe ||  //MD- the object doesn't have a driver OR
							{
								!isPlayer driver _objet_pointe &&  //MD- the player isn't the driver AND
								{
									getText (configFile >> "CfgVehicles" >> typeOf driver _objet_pointe >> "simulation") == "UAVPilot" //MD- object doesn't have a UAV pilot
								}
							}
						) && //MD- And
						(R3F_LOG_player_target_object == _objet_pointe) && //MD- Object player is moving is this object AND
						(
							{ //MD- loop over towable objects within 18m
								_x != _objet_pointe && //MD- towable isn't this object
								alive _x && //MD- towable isn't alive
								isNull (_x getVariable "R3F_LOG_remorque") && //MD- object isn't being towaed
								(
									(velocity _x) call BIS_fnc_magnitude < 6 //MD- object isn't moving (much)
								) && 
								(getPos _x select 2 < 2) && //MD- less that 2m away
								!(_x getVariable "R3F_LOG_disabled") //MD- towable isn't disabled
							} count (nearestObjects [_objet_pointe, R3F_LOG_CFG_towers, 18]) //MD- [object, types,radius]
						) > 0 &&
						!(_objet_pointe getVariable "R3F_LOG_disabled")); //MD- our object isn't disabld
				};
				
				// Condition action selectionner_objet_remorque
				//MD- CAN BE TOWED VALID
				R3F_LOG_action_selectionner_objet_remorque_valide = (vehicle player == player && //MD- PLayer not in vehicle
					(alive _objet_pointe) && //MD- object is alive
					(
						isNull driver _objet_pointe || 
						{!isPlayer driver _objet_pointe && {getText (configFile >> "CfgVehicles" >> typeOf driver _objet_pointe >> "simulation") == "UAVPilot"}}
					) && //MD- object doens't have a driver
					isNull R3F_LOG_player_target_object && //MD- player isn't moving an object already
					isNull (_objet_pointe getVariable "R3F_LOG_est_transporte_par") && //MD- object isn't currently being trnsported
					(
						isNull (_objet_pointe getVariable "R3F_LOG_est_deplace_par") || 
						(!alive (_objet_pointe getVariable "R3F_LOG_est_deplace_par"))) && //MD- Neither is someone else moving it or they are dead
					!(_objet_pointe getVariable "R3F_LOG_disabled")); //MD- object isn't disabled
				
				// Condition action detacher
				//MD- DETACH_VALID
				R3F_LOG_action_detacher_valide = (vehicle player == player && //MD- Player isn't in vehicle
					(isNull R3F_LOG_player_target_object) && //MD- Player isn't already moving an object
					!isNull (_objet_pointe getVariable "R3F_LOG_est_transporte_par") && //MD- Object is being transported by something
					!(_objet_pointe getVariable "R3F_LOG_disabled")); //MD- Object isn't disabled
			}; //MD- End of towable 


			
			// Si l'objet est un objet transportable
			// GT: If the object is a transportable object
			if ({_objet_pointe isKindOf _x} count R3F_LOG_transportable_object_classes > 0) then
			{
				//MD0 And is moveable
				if ({_objet_pointe isKindOf _x} count R3F_LOG_CFG_moveable_objects > 0) then
				{
					// Condition action charger_deplace
					//MD- ACTION LOAD VALID
					R3F_LOG_action_charger_deplace_valide = (vehicle player == player && //MD- player isn't in vehicle
						(count crew _objet_pointe == 0) &&  //MD- target object doesn't have any crew
						(R3F_LOG_player_target_object == _objet_pointe) && // this is object playere is moving
						{_x != _objet_pointe && alive _x && ((velocity _x) call BIS_fnc_magnitude < 6) && (getPos _x select 2 < 2) &&
						!(_x getVariable "R3F_LOG_disabled")} count (nearestObjects [_objet_pointe, R3F_LOG_transport_classes, 18]) > 0 &&
						!(_objet_pointe getVariable "R3F_LOG_disabled"));
				};
				
				// Condition action selectionner_objet_charge
				R3F_LOG_action_selectionner_objet_charge_valide = (vehicle player == player && (count crew _objet_pointe == 0) &&
					isNull R3F_LOG_player_target_object && isNull (_objet_pointe getVariable "R3F_LOG_est_transporte_par") &&
					(isNull (_objet_pointe getVariable "R3F_LOG_est_deplace_par") || (!alive (_objet_pointe getVariable "R3F_LOG_est_deplace_par"))) &&
					!(_objet_pointe getVariable "R3F_LOG_disabled"));
			};
			
			// Si l'objet est un véhicule tower
			if ({_objet_pointe isKindOf _x} count R3F_LOG_CFG_towers > 0) then
			{
				// Condition action remorquer_deplace
				R3F_LOG_action_remorquer_deplace_valide = (vehicle player == player && (alive _objet_pointe) && (!isNull R3F_LOG_player_target_object) &&
					(alive R3F_LOG_player_target_object) && !(R3F_LOG_player_target_object getVariable "R3F_LOG_disabled") &&
					({R3F_LOG_player_target_object isKindOf _x} count R3F_LOG_CFG_towable_objects > 0) &&
					isNull (_objet_pointe getVariable "R3F_LOG_remorque") && ((velocity _objet_pointe) call BIS_fnc_magnitude < 6) &&
					(getPos _objet_pointe select 2 < 2) && !(_objet_pointe getVariable "R3F_LOG_disabled"));
				
				// Condition action remorquer_selection
				R3F_LOG_action_remorquer_selection_valide = (vehicle player == player && (alive _objet_pointe) && (isNull R3F_LOG_player_target_object) &&
					(!isNull R3F_LOG_selected_object) && (R3F_LOG_selected_object != _objet_pointe) &&
					!(R3F_LOG_selected_object getVariable "R3F_LOG_disabled") &&
					({R3F_LOG_selected_object isKindOf _x} count R3F_LOG_CFG_towable_objects > 0) &&
					isNull (_objet_pointe getVariable "R3F_LOG_remorque") && ((velocity _objet_pointe) call BIS_fnc_magnitude < 6) &&
					(getPos _objet_pointe select 2 < 2) && !(_objet_pointe getVariable "R3F_LOG_disabled"));
			};
			
			// Si l'objet est un véhicule transporter
			if ({_objet_pointe isKindOf _x} count R3F_LOG_transport_classes > 0) then
			{
				// Condition action charger_deplace
				R3F_LOG_action_charger_deplace_valide = (alive _objet_pointe && (vehicle player == player) && (!isNull R3F_LOG_player_target_object) &&
					!(R3F_LOG_player_target_object getVariable "R3F_LOG_disabled") &&
					({R3F_LOG_player_target_object isKindOf _x} count R3F_LOG_transportable_object_classes > 0) &&
					((velocity _objet_pointe) call BIS_fnc_magnitude < 6) && (getPos _objet_pointe select 2 < 2) && !(_objet_pointe getVariable "R3F_LOG_disabled"));
				
				// Condition action charger_selection
				R3F_LOG_action_charger_selection_valide = (alive _objet_pointe && (vehicle player == player) && (isNull R3F_LOG_player_target_object) &&
					(!isNull R3F_LOG_selected_object) && (R3F_LOG_selected_object != _objet_pointe) &&
					!(R3F_LOG_selected_object getVariable "R3F_LOG_disabled") &&
					({R3F_LOG_selected_object isKindOf _x} count R3F_LOG_transportable_object_classes > 0) &&
					((velocity _objet_pointe) call BIS_fnc_magnitude < 6) && (getPos _objet_pointe select 2 < 2) && !(_objet_pointe getVariable "R3F_LOG_disabled"));
				
				// Condition action contenu_vehicule
				R3F_LOG_action_contenu_vehicule_valide = (alive _objet_pointe && (vehicle player == player) && (isNull R3F_LOG_player_target_object) &&
					((velocity _objet_pointe) call BIS_fnc_magnitude < 6) && (getPos _objet_pointe select 2 < 2) && !(_objet_pointe getVariable "R3F_LOG_disabled"));
			};
		};
	}
	else //MD- if object pointed at is null
	{
		call _resetConditions;
	};
	
	// Pour l'héliportation, l'objet n'est plus pointé, mais on est dedans
	// Si le joueur est dans un héliporteur
	if ({(vehicle player) isKindOf _x} count R3F_LOG_CFG_helicopters > 0) then
	{
		R3F_LOG_objet_addAction = vehicle player;
		
		// On est dans le véhicule, on affiche pas les options de transporter et tower
		call _resetConditions;
		
		// Condition action helicopter
		R3F_LOG_action_helicopter_valide = (driver R3F_LOG_objet_addAction == player &&
			({_x != R3F_LOG_objet_addAction && !(_x getVariable "R3F_LOG_disabled")} count (nearestObjects [R3F_LOG_objet_addAction, R3F_LOG_CFG_liftable_objects, 15]) > 0) &&
			isNull (R3F_LOG_objet_addAction getVariable "R3F_LOG_helicopter") && ((velocity R3F_LOG_objet_addAction) call BIS_fnc_magnitude < 6) && (getPos R3F_LOG_objet_addAction select 2 > 1) &&
			!(R3F_LOG_objet_addAction getVariable "R3F_LOG_disabled"));
		
		// Condition action heliport_drop
		R3F_LOG_action_heliport_drop_valide = (driver R3F_LOG_objet_addAction == player && !isNull (R3F_LOG_objet_addAction getVariable "R3F_LOG_helicopter") &&
			/*((velocity R3F_LOG_objet_addAction) call BIS_fnc_magnitude < 15) && (getPos R3F_LOG_objet_addAction select 2 < 40) && */ !(R3F_LOG_objet_addAction getVariable "R3F_LOG_disabled"));
	};
	
	sleep 0.3;
};
