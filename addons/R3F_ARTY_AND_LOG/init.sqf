/**
 * Script principal qui initialise les systèmes d'artillerie réaliste et de logistique
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

/*
 * Nouveau fil d'exécution pour assurer une compatibilité ascendante (v1.0 à v1.2).
 * Ces versions préconisaient un #include plutôt que execVM pour appeler ce script.
 * A partir de la v1.3 l'exécution par execVM prend l'avantage pour 3 raisons :
 *     - permettre des appels conditionnels optimisés (ex : seulement pour des slots particuliers)
 *     - l'execVM est mieux connu et compris par l'éditeur de mission
 *     - l'init client de l'arty devient bloquant : il attend une PUBVAR du serveur (le point d'attache)
 */


//MD- Google translate version
 /* 
  * New thread execution for backward compatibility (v1.0 to v1.2). 
  * These versions advocated a # include rather than execVM to call this script. 
  * From the v1.3 performance by execVM takes advantage for 3 reasons: 
  * - Allow conditional call optimized (eg only for specific slots) 
  * - The execVM is better known and understood by the mission editor 
  * - The client init arty is blocking: it expects a PUBVAR server (the attachment point) 
  */

	//MD- if tsting R3F on it's own you also need to include:
	//MD- client/icons
	//MD- client/functions/fn_GetMoveParams.sqf
	//MD- client/functions/fn_ParseMove.sqf
	//MD- client/functions/fn_splitString.sqf
	//MD- server/functions/getPos3D.sqf
	//MD- check client/functions/clientCompile.sqf for how they are included.
	//MD- check /globalCompile.sqf for declaration of mf_compile


[] spawn
{
	//MD- Set language (to en)
	#include "config.sqf"
	//MD- set arty (disabled)
	#include "R3F_ARTY_disable_enable.sqf"
	//MD- set logistics (enabled)
	#include "R3F_LOG_disable_enable.sqf"
	
	// Chargement du fichier de langage
	//MD- Google translate (GT): Loading language file
	//MD- loads en_strings_lang.sqf
	//MD- which in turn loads R3F_LOG/en_string_lang.sqf
	call compile preprocessFile format ["addons\R3F_ARTY_AND_LOG\%1_strings_lang.sqf", R3F_ARTY_AND_LOG_CFG_langage];
	

	if (isServer) then
	{
		// Service offert par le serveur : orienter un objet (car setDir est à argument local)
		// GT: Service provided by the server: a direct object (as setDir argument is local)
		//MD- Creates a function and then attached it to the eventhandler of R3F_ARTY_AND_LOG_PUBVAR_setDir
		R3F_ARTY_AND_LOG_FNCT_PUBVAR_setDir =
		{
			private ["_objet", "_direction"];
			_objet = _this select 1 select 0;
			_direction = _this select 1 select 1;
			
			// Orienter l'objet et broadcaster l'effet
			// GT: Direct object and broadcaster effect
			_objet setDir _direction;
			_objet setPos (getPos _objet);
		};
		"R3F_ARTY_AND_LOG_PUBVAR_setDir" addPublicVariableEventHandler R3F_ARTY_AND_LOG_FNCT_PUBVAR_setDir;
	};
	
	//MD- Not in our case
	#ifdef R3F_ARTY_enable
		#include "R3F_ARTY\init.sqf"
		R3F_ARTY_active = true;
	#endif
	
	//MD- yep 
	#ifdef R3F_LOG_enable
		//MD- By this point I have to assume that including a file basically inserts it's contents at this position
		//MD- This init script stores the various init scripts for the different classes of logistics items and
		//MD- starts up the watch_action_menu script
		#include "R3F_LOG\init.sqf"
		//MD- and set a global flag to say that we're logistically active
		R3F_LOG_active = true;
	#else
		// Pour les actions du PC d'arti
		// GT: For the actions of arty PC
		R3F_LOG_joueur_deplace_objet = objNull;
	#endif
	
	// Auto-détection permanente des objets sur le jeu
	if (isDedicated) then
	{
		// Version allégée pour le serveur dédié
		//execVM "addons\R3F_ARTY_AND_LOG\surveiller_nouveaux_objets_dedie.sqf";
	}
	else
	{
		//MD- runs watch_new_objects script
		execVM "addons\R3F_ARTY_AND_LOG\surveiller_nouveaux_objets.sqf";
		
		// Disable R3F on map objects that are not network-synced
		//{
		//	_x setVariable ["R3F_LOG_disabled", true];
		//} forEach ((nearestObjects [[0,0], R3F_LOG_CFG_objets_deplacables, 99999]) - (allMissionObjects "All"));
	};
};
