/**
 * Script principal qui initialise le système de logistique
 * 
 * Copyright (C) 2010 madbull ~R3F~
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

//MD- Sets up lists of what is towable, what can tow towables, what can be loaded and into what and that sort of stuff
#include "config.sqf"

if (isServer) then
{
	// On crée le point d'attache qui servira aux attachTo pour les objets à charger virtuellement dans les véhicules
	// GT: It creates the point of attachment to serve the AttachTo for loading objects virtually in vehicles
	//MD- https://community.bistudio.com/wiki/createVehicle
	//MD- create a (invisible) helipoint at 0,0,0
	R3F_LOG_PUBVAR_attach_point = "Land_HelipadEmpty_F" createVehicle [0,0,0];
	//MD- Broadcast that shit all over the shop like a boss
	publicVariable "R3F_LOG_PUBVAR_attach_point";
};

// Un serveur dédié n'en a pas besoin
// GT: A dedicated server does not need
if !(isServer && isDedicated) then
{
	// Le client attend que le serveur ai créé et publié la référence de l'objet servant de point d'attache
	// GT: The client waits for the server I created and published the reference object serving as anchor
	//MD- So th client waits for the point_attache is created and broadcast (like a boss)
	waitUntil {!isNil "R3F_LOG_PUBVAR_attach_point"};
	
	/** Indique quel objet le joueur est en train de déplacer, objNull si aucun */
	// GT: Indicates which object the player is trying to move, if no objNull
	//MD- joueur_deplace_objet = player_move_object (learning french and sqf!)
	R3F_LOG_player_target_object = objNull;
	
	/** Pseudo-mutex permettant de n'exécuter qu'un script de manipulation d'objet à la fois (true : vérouillé) */
	// GT: Pseudo-mutex to run only script object manipulation both (true: locked)
	//MD- verrou = lock
	R3F_LOG_mutex_local_lock = false;
	
	/** Objet actuellement sélectionner pour être chargé/remorqué */
	// GT: Currently selected object to be loaded / towed (GT knocks it out the park)
	R3F_LOG_selected_object = objNull;
	
	// On construit la liste des classes des transporters dans les quantités associés (pour les nearestObjects, count isKindOf, ...)
	// GT: We construct the list of classes of carriers in the associated quantities (for nearestObjects, count isKindOf, ...)
	R3F_LOG_transport_classes = [];
	
	//MD- forEach transporter in the cfg file
	{
		// Add them to the transports list
		// Eh? where else is this being filled from?
		R3F_LOG_transport_classes = R3F_LOG_transport_classes + [_x select 0];
	} forEach R3F_LOG_CFG_transporters;
	
	// On construit la liste des classes des transportables dans les quantités associés (pour les nearestObjects, count isKindOf, ...)
	// GT: We construct the list of classes in the associated transportable quantities (for nearestObjects, count isKindOf ...)
	R3F_LOG_transportable_object_classes = [];
	
	//MD- forEach transportable in the cfg file
	{
		//MD- See above
		R3F_LOG_transportable_object_classes = R3F_LOG_transportable_object_classes + [_x select 0];
	} forEach R3F_LOG_CFG_transportable_objects;
	
	//MD- Store the init functions as public vars
	R3F_LOG_FNC_object_init = compile preprocessFile "addons\R3F_ARTY_AND_LOG\R3F_LOG\objet_init.sqf";
	R3F_LOG_FNC_helicopter_init = compile preprocessFile "addons\R3F_ARTY_AND_LOG\R3F_LOG\helicopter\helicopter_init.sqf";
	R3F_LOG_FNCT_tower_init = compile preprocessFile "addons\R3F_ARTY_AND_LOG\R3F_LOG\tower\tower_init.sqf";
	R3F_LOG_CFG_transporter_init = compile preprocessFile "addons\R3F_ARTY_AND_LOG\R3F_LOG\transporter\transporter_init.sqf";
	
	/** Indique quel est l'objet concerné par les variables d'actions des addAction */
	// GT: Indicates which is the object affected by variables actions addAction
	R3F_LOG_objet_addAction = objNull;
	
	// Liste des variables activant ou non les actions de menu
	// GT: List of variables enabling or not the actions menu
	//MD- charger = load
	//MD- deplace = moveable
	//MD- contenu = contents
	//MD- remorquer = tow
	//MD- helicopter = lift?
	//MD- drop = drop
	R3F_LOG_action_charger_deplace_valide = false;
	R3F_LOG_action_charger_selection_valide = false;
	R3F_LOG_action_contenu_vehicule_valide = false;
	
	R3F_LOG_action_remorquer_deplace_valide = false;
	R3F_LOG_action_remorquer_selection_valide = false;
	
	R3F_LOG_action_helicopter_valide = false;
	R3F_LOG_action_heliport_drop_valide = false;
	
	R3F_LOG_action_deplacer_objet_valide = false;
	R3F_LOG_action_selectionner_objet_remorque_valide = false;
	R3F_LOG_action_detacher_valide = false;
	R3F_LOG_action_selectionner_objet_charge_valide = false;
	
	/** Ce fil d'exécution permet de diminuer la fréquence des vérifications des conditions normalement faites dans les addAction (~60Hz) */
	// GT: This thread of execution can reduce the frequency of audits conditions normally do in addAction (~ 60Hz)
	execVM "addons\R3F_ARTY_AND_LOG\R3F_LOG\surveiller_conditions_actions_menu.sqf";
};
