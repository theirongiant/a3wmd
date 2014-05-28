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
//MD- heliporter = lift?
//MD- larguer = drop


_resetConditions = 
{
	R3F_LOG_action_charger_deplace_valide = false;
	R3F_LOG_action_charger_selection_valide = false;
	R3F_LOG_action_contenu_vehicule_valide = false;
	R3F_LOG_action_remorquer_deplace_valide = false;
	R3F_LOG_action_remorquer_selection_valide = false;
	R3F_LOG_action_selectionner_objet_remorque_valide = false;
	R3F_LOG_action_heliporter_valide = false;
	R3F_LOG_action_heliport_larguer_valide = false;
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

			//MD- set _canLock to objects objectLocked property (or false if it's not set)
			Object_canLock = !(_objet_pointe getVariable ['objectLocked', false]);
			
			// Si l'objet est un objet déplaçable
			// GT: If the object is a movable object
			//MD- neat little array count functionality here
			//MD- it rips through the array performing the chunk of code for each object
			//MD- any time the code evaluates to true count is incremented
			//MD- so this if looks through the list of moveable to find a match for our object
			if ({_objet_pointe isKindOf _x} count R3F_LOG_CFG_objets_deplacables > 0) then
			{
				// Condition action deplacer_objet
				//MD- MOVE OBJECT VALID
				R3F_LOG_action_deplacer_objet_valide = (vehicle player == player && //MD- Player isn't in vehicle AND
					(count crew _objet_pointe == 0) &&  //MD- Object doesn't have a crew AND
					(isNull R3F_LOG_joueur_deplace_objet) && //MD- Player isn't already moving an object AND
					(
						isNull (_objet_pointe getVariable "R3F_LOG_est_deplace_par") ||  //MD- player that is moving object is null OR
						(!alive (_objet_pointe getVariable "R3F_LOG_est_deplace_par")) //MD- player that is moving object is dead
					) && //MD- AND
					isNull (_objet_pointe getVariable "R3F_LOG_est_transporte_par") &&  //MD- vehicle transporting object is null AND
					!(_objet_pointe getVariable "R3F_LOG_disabled")); //MD- obhect isn't disabled
			};
			
			// Si l'objet est un objet remorquable
			// GT: If the object is a towable object
			if ({_objet_pointe isKindOf _x} count R3F_LOG_CFG_objets_remorquables > 0) then
			{
				// Et qu'il est déplaçable
				//MD- and it is moveable
				if ({_objet_pointe isKindOf _x} count R3F_LOG_CFG_objets_deplacables > 0) then
				{
					// Condition action remorquer_deplace 
					//MD- TOWER VALID
					R3F_LOG_action_remorquer_deplace_valide = (vehicle player == player && //MD- Player isn't in a vehicle AND
						(alive R3F_LOG_joueur_deplace_objet) && //MD- object being moved is alive AND
						(
							isNull driver _objet_pointe ||  //MD- the object doesn't have a driver OR
							{
								!isPlayer driver _objet_pointe &&  //MD- the player isn't the driver AND
								{
									getText (configFile >> "CfgVehicles" >> typeOf driver _objet_pointe >> "simulation") == "UAVPilot" //MD- object doesn't have a UAV pilot
								}
							}
						) && //MD- And
						(R3F_LOG_joueur_deplace_objet == _objet_pointe) && //MD- Object player is moving is this object AND
						(
							{ //MD- if there is a towable object within 18m
								_x != _objet_pointe && //MD- towable isn't this object
								alive _x && //MD- towable isn't alive
								isNull (_x getVariable "R3F_LOG_remorque") && //MD- object isn't being towaed
								(
									(velocity _x) call BIS_fnc_magnitude < 6 //MD- object isn't moving (much)
								) && 
								(getPos _x select 2 < 2) && //MD- less that 2m away
								!(_x getVariable "R3F_LOG_disabled") //MD- towable isn't disabled
							} count (nearestObjects [_objet_pointe, R3F_LOG_CFG_remorqueurs, 18]) //MD- [object, types,radius]
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
					isNull R3F_LOG_joueur_deplace_objet && //MD- player isn't moving an object already
					isNull (_objet_pointe getVariable "R3F_LOG_est_transporte_par") && //MD- object isn't currently being trnsported
					(
						isNull (_objet_pointe getVariable "R3F_LOG_est_deplace_par") || 
						(!alive (_objet_pointe getVariable "R3F_LOG_est_deplace_par"))) && //MD- Neither is someone else moving it or they are dead
					!(_objet_pointe getVariable "R3F_LOG_disabled")); //MD- object isn't disabled
				
				// Condition action detacher
				//MD- DETACH_VALID
				R3F_LOG_action_detacher_valide = (vehicle player == player && //MD- Player isn't in vehicle
					(isNull R3F_LOG_joueur_deplace_objet) && //MD- Player isn't already moving an object
					!isNull (_objet_pointe getVariable "R3F_LOG_est_transporte_par") && //MD- Object is being transported by something
					!(_objet_pointe getVariable "R3F_LOG_disabled")); //MD- Object isn't disabled
			}; //MD- End of towable 


			
			// Si l'objet est un objet transportable
			// GT: If the object is a transportable object
			if ({_objet_pointe isKindOf _x} count R3F_LOG_classes_objets_transportables > 0) then
			{
				//MD0 And is moveable
				if ({_objet_pointe isKindOf _x} count R3F_LOG_CFG_objets_deplacables > 0) then
				{
					// Condition action charger_deplace
					//MD- ACTION LOAD VALID
					R3F_LOG_action_charger_deplace_valide = (vehicle player == player && //MD- player isn't in vehicle
						(count crew _objet_pointe == 0) &&  //MD- target object doesn't have any crew
						(R3F_LOG_joueur_deplace_objet == _objet_pointe) && // this is object player is moving
						{ //MD- Loop round all transport classes within 18m
							_x != _objet_pointe && //MD- object isn't a transporter
							alive _x && //MD- it's alive
							((velocity _x) call BIS_fnc_magnitude < 6) && //MD- it's velocity is below 6 ?
							(getPos _x select 2 < 2) && //MD- it's less that 2m off the ground
							!(_x getVariable "R3F_LOG_disabled") //MD- it's not disabled
						} count (nearestObjects [_objet_pointe, R3F_LOG_classes_transporteurs, 18]) > 0 &&
						!(_objet_pointe getVariable "R3F_LOG_disabled")); //MD- target object isn't disabled
				};
				
				// Condition action selectionner_objet_charge
				// GT: Action select object loads
				R3F_LOG_action_selectionner_objet_charge_valide = (vehicle player == player && //MD- player isn't in vehicle
					(count crew _objet_pointe == 0) && //MD- target object doesn't have crew
					isNull R3F_LOG_joueur_deplace_objet &&  //MD- player not moving an object
					isNull (_objet_pointe getVariable "R3F_LOG_est_transporte_par") && //MD- target object isn't being transported
					(
						isNull (_objet_pointe getVariable "R3F_LOG_est_deplace_par") || //MD- target object mover is null OR
						(!alive (_objet_pointe getVariable "R3F_LOG_est_deplace_par"))  //MD- target object mover is dead
					) &&
					!(_objet_pointe getVariable "R3F_LOG_disabled")); //MD- target object isn't disabled
			};
			
			// Si l'objet est un véhicule remorqueur
			// GT: If the object is a towing vehicle
			if ({_objet_pointe isKindOf _x} count R3F_LOG_CFG_remorqueurs > 0) then
			{
				// Condition action remorquer_deplace 
				// GT: Condition action tow moves ??
				R3F_LOG_action_remorquer_deplace_valide = (vehicle player == player && //MD- player isn't in vehicle
					(alive _objet_pointe) && //MD- target object is alive
					(!isNull R3F_LOG_joueur_deplace_objet) && //MD- player IS moving an object
					(alive R3F_LOG_joueur_deplace_objet) && //MD- the object the player is moving is alive ?
					!(R3F_LOG_joueur_deplace_objet getVariable "R3F_LOG_disabled") && //MD- players object isn't disabled
					({R3F_LOG_joueur_deplace_objet isKindOf _x} count R3F_LOG_CFG_objets_remorquables > 0) && //MD- players object is a towable
					isNull (_objet_pointe getVariable "R3F_LOG_remorque") && //MD- target object isn't being towed?
					((velocity _objet_pointe) call BIS_fnc_magnitude < 6) && //MD- target object isn't moving much
					(getPos _objet_pointe select 2 < 2) &&  //MD- target objeect is less than 2m off the ground
					!(_objet_pointe getVariable "R3F_LOG_disabled")); //MD- target object isn't disabled
				
				// Condition action remorquer_selection
				// Condition action tow selection valid
				R3F_LOG_action_remorquer_selection_valide = (vehicle player == player && //MD- Player isn't in vehicle
					(alive _objet_pointe) && //MD- target object is alive
					(isNull R3F_LOG_joueur_deplace_objet) && //MD- player isn't already moving an object
					(!isNull R3F_LOG_objet_selectionne) &&  //MD- selected object isn't null
					(R3F_LOG_objet_selectionne != _objet_pointe) && //MD- selected object isn't the target object
					!(R3F_LOG_objet_selectionne getVariable "R3F_LOG_disabled") && //MD- selected object isn't disabled
					({R3F_LOG_objet_selectionne isKindOf _x} count R3F_LOG_CFG_objets_remorquables > 0) && //MD- selected object is a towable
					isNull (_objet_pointe getVariable "R3F_LOG_remorque") &&  //MD- object isn't towing anything ?
					((velocity _objet_pointe) call BIS_fnc_magnitude < 6) && //MD- target object isn't moving faster than 6 
					(getPos _objet_pointe select 2 < 2) &&  //MD- target object is less that 2 off the ground
					!(_objet_pointe getVariable "R3F_LOG_disabled")); //MD- target object isn't disabled.
			};
			
			// Si l'objet est un véhicule transporteur
			// GT: If the object is a transporter
			if ({_objet_pointe isKindOf _x} count R3F_LOG_classes_transporteurs > 0) then
			{
				// Condition action charger_deplace
				// Load Move ? (move loadable perhaps?)
				R3F_LOG_action_charger_deplace_valide = (alive _objet_pointe && //MD- Target object is alive
					(vehicle player == player) &&  //MD- player isn't a vehicle 
					(!isNull R3F_LOG_joueur_deplace_objet) && //MD- player IS carrying an object ?
					!(R3F_LOG_joueur_deplace_objet getVariable "R3F_LOG_disabled") && //MD- the carried object isn't disabled
					({R3F_LOG_joueur_deplace_objet isKindOf _x} count R3F_LOG_classes_objets_transportables > 0) && //MD- carried object is a transportable
					((velocity _objet_pointe) call BIS_fnc_magnitude < 6) && //MD- target object isn't moving faster than 6
					(getPos _objet_pointe select 2 < 2) &&  //MD- target object is less than 2 off the gound
					!(_objet_pointe getVariable "R3F_LOG_disabled")); //MD- target object isn't disabled
				
				// Condition action charger_selection
				// GT: Load Selection
				R3F_LOG_action_charger_selection_valide = (alive _objet_pointe && //MD- target object is alive
					(vehicle player == player) && //MD- player isn't in vehicle
					(isNull R3F_LOG_joueur_deplace_objet) && //MD- player object isn't null
					(!isNull R3F_LOG_objet_selectionne) && //MD- we have an object selection
					(R3F_LOG_objet_selectionne != _objet_pointe) && //MD- selected object not the same as target object
					!(R3F_LOG_objet_selectionne getVariable "R3F_LOG_disabled") && //MD- selected object ain't disabled
					({R3F_LOG_objet_selectionne isKindOf _x} count R3F_LOG_classes_objets_transportables > 0) && //MD- selected object is a transportable
					((velocity _objet_pointe) call BIS_fnc_magnitude < 6) && //MD- target object ain't moving much
					(getPos _objet_pointe select 2 < 2) &&  //MD- target object isn't over 2 off the ground
					!(_objet_pointe getVariable "R3F_LOG_disabled")); //MD- target object isn't disabled
				
				// Condition action contenu_vehicule
				// View Vehicle contents
				R3F_LOG_action_contenu_vehicule_valide = (alive _objet_pointe && //MD- target object is alive
					(vehicle player == player) && //MD- player not in vehicle
					(isNull R3F_LOG_joueur_deplace_objet) && //MD- player object is null
					((velocity _objet_pointe) call BIS_fnc_magnitude < 6) && //MD- target object isn't moving much
					(getPos _objet_pointe select 2 < 2) && //MD- target object ain't far off ground
					!(_objet_pointe getVariable "R3F_LOG_disabled")); //MD- target object isn't disabled
			};
		};

		/*MD A little note
		 * I'm struggling a little to have a clear idea of what some of these flags are, particularly differentiating between tow-ers, towables, loading and moving
		 * I'm going to do a little testing and probably start changing the variable names into English to get a better handle on things
		 * It also appears to me that there is a fair amount of repition in some of the checks being done and I can't see why some of the more
		 * common ones aren't tested early and the results stored in variables rather than testing multiple times (things like is the object alive, 
		 * is the player in a vehicle, etc). In saying that, despite looking to translating all the variables at some point I don't want to start changing code
		 */
	}
	else //MD- if object pointed at is null
	{
		call _resetConditions;
	};
	
	// Pour l'héliportation, l'objet n'est plus pointé, mais on est dedans
	// Si le joueur est dans un héliporteur
	// GT: For héliportation, the object is not pointed, but it is in 
	// GT: if the player is in a Helicarrier
	if ({(vehicle player) isKindOf _x} count R3F_LOG_CFG_heliporteurs > 0) then
	{
		R3F_LOG_objet_addAction = vehicle player;
		
		// On est dans le véhicule, on affiche pas les options de transporteur et remorqueur
		// GT: We are in the vehicle, not display the options carrier and tug
		call _resetConditions;
		
		// Condition action heliporter
		// GT: Action helicopter
		R3F_LOG_action_heliporter_valide = (driver R3F_LOG_objet_addAction == player && //MD- driver of the AddAction object is the player
			(
				{//MD- test all heli-transportable objects within 15 of the addAction object
					_x != R3F_LOG_objet_addAction && //MD- it's not the addAction object 
					!(_x getVariable "R3F_LOG_disabled") //MD- it's not disabled
				} count (nearestObjects [R3F_LOG_objet_addAction, R3F_LOG_CFG_objets_heliportables, 15]) > 0 
			) && //MD- at least one heliportable object nearby
			isNull (R3F_LOG_objet_addAction getVariable "R3F_LOG_heliporte") && //MD- addAction object doesn't have a chopper
			((velocity R3F_LOG_objet_addAction) call BIS_fnc_magnitude < 6) && //MD- addAction object isn't moving much
			(getPos R3F_LOG_objet_addAction select 2 > 1) && //MD- addAction object ain't off the ground much
			!(R3F_LOG_objet_addAction getVariable "R3F_LOG_disabled")); //MD- addAction object ain't disabled
		
		// Condition action heliport_larguer
		// GT: Heli drop
		R3F_LOG_action_heliport_larguer_valide = (driver R3F_LOG_objet_addAction == player && //MD- player is driver of addAction object
			!isNull (R3F_LOG_objet_addAction getVariable "R3F_LOG_heliporte") && //MD- the addAction object's helicopter isn't null
			/*((velocity R3F_LOG_objet_addAction) call BIS_fnc_magnitude < 15) && (getPos R3F_LOG_objet_addAction select 2 < 40) && */ 
			!(R3F_LOG_objet_addAction getVariable "R3F_LOG_disabled")); //MD- addAction object isn't disabled.
	};
	
	//MD- power-nap!
	sleep 0.3;
};
