/**
 * Fait déplacer un objet par le joueur. Il garde l'objet tant qu'il ne le relâche pas ou ne meurt pas.
 * L'objet est relaché quand la variable R3F_LOG_joueur_deplace_objet passe à objNull ce qui terminera le script
 * 
 * GT:
 * Made to move an object by the player. It keeps the subject as he does not or does not die hard. 
 * The object is released when the variable passes R3F_LOG_joueur_deplace_objet objNull the end the script
 *
 * @param 0 l'objet à déplacer
 * 
 * Copyright (C) 2010 madbull ~R3F~
 * 
 * This program is free software under the terms of the GNU General Public License version 3.
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

 //MD- Check player isn't on a ladder
_currentAnim =	animationState player;
_config = configFile >> "CfgMovesMaleSdr" >> "States" >> _currentAnim;
_onLadder =	(getNumber (_config >> "onLadder"));
if(_onLadder == 1) exitWith{player globalChat "You can't move this object while on a ladder";};

// if local mutex is locked (an action is currently underway)
if (R3F_LOG_mutex_local_verrou) then
{
	//MD- Say: The current operation isn't finished.
	player globalChat STR_R3F_LOG_mutex_action_en_cours;
}
else
{
	//MD- lock mutex (prevent other actions)
	R3F_LOG_mutex_local_verrou = true;
	
	//MD- set selected object to null
	R3F_LOG_objet_selectionne = objNull;
	
	private ["_objet", "_est_calculateur", "_arme_principale", "_arme_principale_accessoires", "_arme_principale_magasines", "_action_menu_release_relative", "_action_menu_release_horizontal" , "_action_menu_45", "_action_menu_90", "_action_menu_180", "_azimut_canon", "_muzzles", "_magazine", "_ammo", "_adjustPOS"];
	
	// set _objet to be the object this move action is being performed on
	_objet = _this select 0;
	// set a variable on an object to link it to players side
	if(isNil {_objet getVariable "R3F_Side"}) then 
	{
		_objet setVariable ["R3F_Side", (playerSide), true];
	};

	//MD- If the object has a side but it's not the players side then
	//MD- scan 150m around looking for a player of the same side as the object
	//MD- prevent moving if there is, set object to players side if there isn't
	_tempVar = false;
	if(!isNil {_objet getVariable "R3F_Side"}) then 
	{
		if(playerSide != (_objet getVariable "R3F_Side")) then 
		{
			{if(side _x ==  (_objet getVariable "R3F_Side") && alive _x && _x distance _objet < 150) exitwith {_tempVar = true;};} foreach AllUnits;
		};
	};
	if(_tempVar) exitwith {
		hint format["This object belongs to %1 and they're nearby you cannot take this.", _objet getVariable "R3F_Side"]; R3F_LOG_mutex_local_verrou = false;
	};
	_objet setVariable ["R3F_Side", (playerSide), true];

	
	// Si l'objet est un calculateur d'artillerie, on laisse le script spécialisé gérer
	// GT: If the object is a computer, artillery specialist script is allowed to run
	//MD- Arty not included, so I'd imagine nothing is est calculateur (I wonder what they call calculators in France)

	_est_calculateur = _objet getVariable "R3F_ARTY_est_calculateur";
	if !(isNil "_est_calculateur") then
	{
		R3F_LOG_mutex_local_verrou = false;
		[_objet] execVM "addons\R3F_ARTY_AND_LOG\R3F_ARTY\poste_commandement\deplacer_calculateur.sqf";
	}
	else
	{
		//MD- set is being moved by var on the object to player
		_objet setVariable ["R3F_LOG_est_deplace_par", player, true];
		
		//MD- set object being moved to be the object 
		R3F_LOG_joueur_deplace_objet = _objet;
		
		// Sauvegarde et retrait de l'arme primaire
		// GT: Backup and removing the primary weapon
		//MD- when you move an item it switches to pistol
		//MD- not tested what happens if you don't have a pistol

		//MD- Store the primary weapons and set up variable storage for accessories and magazines
		_arme_principale = primaryWeapon player;
		_arme_principale_accessoires = [];
		_arme_principale_magasines = [];
		
		//MD- if they have a primary weapon
		if (_arme_principale != "") then
		{
			//MD- store accessory list
			_arme_principale_accessoires = primaryWeaponItems player;
			
			//MD- Select the primary weapon (why?)
			player selectWeapon _arme_principale;
			//MD- add entry to mag array [magazine name, ammo count]
			_arme_principale_magasines set [count _arme_principale_magasines, [currentMagazine player, player ammo _arme_principale]];
			
			//MD- Loops round each muzzle adding magazine magazine and ammo count
			//MD- the _x != "this" if puzzles me. I'll speculate that the main muzzle is returned as this
			//MD- which would necessitate the bit above being separate so that it can store the magazine type
			//MD- needs to have a look at what the configFile array returns, the biki page is a little light on info
			{ // add one mag for each muzzle
				if (_x != "this") then 
				{
					player selectWeapon _x;
					_arme_principale_magasines set [count _arme_principale_magasines, [currentMagazine player, player ammo _x]];
				};
			} forEach getArray(configFile>>"CfgWeapons">>_arme_principale>>"muzzles");
			
			//MD- Detect whether player is swimming
			_currAction = [player, ["A"]] call getMoveParams;
			_isSwimming = {_currAction == _x} count ["Aswm","Assw","Absw","Adve","Asdv","Abdv"] > 0;
			
			//MD- if they are then sleep for a bit
			if (_isSwimming) then
			{
				sleep 0.5;
			}
			else
			{
				//MD- otherwise play an animation based on whether player has a handgun.
				if (handgunWeapon player == "") then
				{
					player playMove "AmovPercMstpSnonWnonDnon";
				}
				else
				{
					player playMove "AmovPercMstpSrasWpstDnon";
				};
				//MD- sleep (to let it play out I guess)
				sleep 1;
			};
			
			//MD- Remove players primary
			player removeWeapon _arme_principale;
			
			//MD- not the foggiest what this does but apparently doesn't tween the animations
			if (_isSwimming) then
			{
				player switchMove "";
			};
		}
		else // If they DON'T have a primary
		{
			//MD- Don't know why
			sleep 0.5;
		};
		
		// Si le joueur est mort pendant le sleep, on remet tout comme avant
		// GT: If the player died during sleep, it puts everything as before
		if (!alive player) then
		{
			//MD- set the current moving object to null
			R3F_LOG_joueur_deplace_objet = objNull;
			//MD- set the objects mover to null
			_objet setVariable ["R3F_LOG_est_deplace_par", objNull, true];
			// Car attachTo de "charger" positionne l'objet en altitude :
			// GT: AttachTo because of "load" position the object altitude:
			//MD- Drop the object back onto the ground
			_objet setPos [getPos _objet select 0, getPos _objet select 1, 0];
			_objet setVelocity [0,0,0];
			
			//MD- Although what happens to the primary weapon now?
			//MD- guess you don't shot fellas moving stuff if you want their weapon

			//MD- mutex is false (action is finished)
			R3F_LOG_mutex_local_verrou = false;
		}
		else // player is still alive 
		{
			//MD- Attach object to player
			//MD- boundingBox returns [ [minx, miny, minz], [maxx, maxy,maxz] ]
			//MD- max return the highest of two given numbers
			//MD- AtachTo takes [player, position array, mempoint]
			//MD- I've no idea what mempoint is
			_objet attachTo [player, [
				0, // x=0
				(
					( (boundingBox _objet select 1 select 1) max (-(boundingBox _objet select 0 select 1)) )  //MD- Find max between maxy and -miny
					max 
					( (boundingBox _objet select 1 select 0) max (-(boundingBox _objet select 0 select 0)) ) //MD- Find max between maxx and -maxx
				) + 1, // Find the max between those and add 1. Ensures that it has enough room to rotate without hitting the player
				1] //MD- seems mempoints are preset positions on object that might be used as axis for swinging doors open etc. 
			]; //MD- No idea what 1 is though although it must apply to all objects so it might be the common centre point.
			

			//MD- weapons lists weapons on vehicle (and since arma in vehicle inventory)
			if (count (weapons _objet) > 0) then
			{
				// Le canon doit pointer devant nous (sinon on a l'impression de se faire empaler)
				// GT: The barrel must point to us (if we have the feeling of being impaled)
				//MD- No earthly idea, might be arty stuff

				//MD- weapons direction gets turrent dirction
				//MD- atan returns the angle of the vector x atan2 y
				_azimut_canon = ((_objet weaponDirection (weapons _objet select 0)) select 0) 
					atan2 ((_objet weaponDirection (weapons _objet select 0)) select 1);
				
				// On est obligé de demander au serveur de tourner le canon pour nous
				// GT: One is obliged to ask the server to turn the barrel for us
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
			
			R3F_LOG_mutex_local_verrou = false;
			R3F_LOG_force_horizontally = false;
			
			_action_menu_release_relative = player addAction [ //MD- Release the object
				("<img image='client\icons\r3f_release.paa' color='#06ef00'/> <t color='#06ef00'>" + STR_R3F_LOG_action_relacher_objet + "</t>"), 
				"addons\R3F_ARTY_AND_LOG\R3F_LOG\objet_deplacable\relacher.sqf", false, 5, true, true];

			_action_menu_release_horizontal = player addAction [ //MD- release horizontal (never have been able to figure out what this does in game)
				("<img image='client\icons\r3f_releaseh.paa' color='#06ef00'/> <t color='#06ef00'>" + STR_RELEASE_HORIZONTAL + "</t>"), 
				"addons\R3F_ARTY_AND_LOG\R3F_LOG\objet_deplacable\relacher.sqf", true, 5, true, true];

			_action_menu_45 = player addAction [ //MD- rotate object 45 deg
			("<img image='client\icons\r3f_rotate.paa' color='#06ef00'/> <t color='#06ef00'>Rotate object 45°</t>"), 
			"addons\R3F_ARTY_AND_LOG\R3F_LOG\objet_deplacable\rotate.sqf", 45, 5, true, false];
			//MD- wonder why theses were removed?
			//_action_menu_90 = player addAction [("<img image='client\ui\ui_arrow_combo_ca.paa'/> <t color='#dddd00'>Rotate object 90°</t>"), "addons\R3F_ARTY_AND_LOG\R3F_LOG\objet_deplacable\rotate.sqf", 90, 5, true, false];
			//_action_menu_180 = player addAction [("<img image='client\ui\ui_arrow_combo_ca.paa'/> <t color='#dddd00'>Rotate object 180°</t>"), "addons\R3F_ARTY_AND_LOG\R3F_LOG\objet_deplacable\rotate.sqf", 180, 5, true, false];
			
			// On limite la vitesse de marche et on interdit de monter dans un véhicule tant que l'objet est porté
			// Walking speed is limited and it is forbidden to ride in a vehicle as the object is brought(carried)
			//MD- while the player is alive and is carrying an object
			//MD- Stay in this loop until the conditions change
			while {!isNull R3F_LOG_joueur_deplace_objet && alive player} do
			{
				if (vehicle player != player) then //MD- player ain't in vehicle 
				{
					player globalChat STR_R3F_LOG_ne_pas_monter_dans_vehicule; // Say: You can't get in a vehicle while you're carrying this object !
					player action ["eject", vehicle player]; //MD- Kick his ass out
					sleep 1; //MD- Wait for anim to complete
				};
				
				if ([(velocity player) select 0,(velocity player) select 1,0] call BIS_fnc_magnitude > 3.5) then
				{
					player globalChat STR_R3F_LOG_courir_trop_vite; //MD- Say: Moving too fast! (Press C to slow down)
					player playMove "AmovPpneMstpSrasWpstDnon"; //MD- [] call BIS_animViewer to see anim viewer in mission editor
					sleep 1;
				};
	
				sleep 0.25;
			};
			
			// L'objet n'est plus porté, on le repose
			// GT: The object is no longer worn, based on the
			//MD- not the cleanest translate but we're dropping the object or we're dead 
			//MD- so first step is to detach the object from our player 
			detach _objet;

			// this addition comes from Sa-Matra (fixes the heigt of some of the objects) - all credits for this fix go to him!

			//MD- Get the object type
			_class = typeOf _objet;

			//MD- some objects must not naturally sit at the correct height
			_zOffset = switch (true) do
			{
				//case (_class == "Land_Scaffolding_F"):         { 3 }; 
				case (_class == "Land_Canal_WallSmall_10m_F"): { 2 };
				case (_class == "Land_Canal_Wall_Stairs_F"):   { 2 };
				default { 0 };
			};

			//MD- Need to wait till I get throught the release script to unlock the mysteries of
			//MD- what the hell release horizontallly actually does
			if (R3F_LOG_force_horizontally) then
			{
				//MD- reset it to false
				R3F_LOG_force_horizontally = false;
				
				//MD- getPosATL (At Terrain Level) returns a positionATL array (x (north/south), y (east/west, z (height above terrain))
				_objectATL = getPosATL _objet;

				//MD- correct for objects that don't sit on ground correctly
				if ((_objectATL select 2) - _zOffset < 0) then
				{
					_objectATL set [2, 0 + _zOffset];
					_objet setPosATL _objectATL;
				}
				else //MD- Not sure why the players z is getting involved here or why the switch to ASL
				{
					_objectASL = getPosASL _objet; //MD- get object's position relative to terrain
					_objectASL set [2, ((getPosASL player) select 2) + _zOffset]; //MD- set the z to be the players z + offset if any
					_objet setPosASL _objectASL; //MD- set the object's new position
				}; //MD- Okay I think release horizontal retains the object at it's z position as opposed to dropping it to the ground (need to test)
				//MD- Would make sense, would allow you to partially embed walls in the ground rather than have some of the haphazard placements you get
				//MD- when it tries to lay flat on bumpy ground. Neat, that always bugged the life out me.
				
				//MD- http://forums.bistudio.com/showthread.php?50914-SetVectorUp-SetVectorDir-and-3D-coords
				//MD- https://community.bistudio.com/wiki/setVectorUp
				//MD- make sure the object points up
				_objet setVectorUp [0,0,1];
			}
			else
			{
				_objectPos = getPos _objet;
				//MD- fn_getPos3D is in server/fn_getPos3D.sqf
				//MD- for ease I've copied the notes from fn_getPos3D as that covers the explanation
				// This function is to counter the fact that "getPos" is relative to the floor under the object,
				// while most functions require positions to be from ground or sea level, whichever is highest
				_objectPos set [2, ((player call fn_getPos3D) select 2) + _zOffset];
				_objet setPos _objectPos;
			};
			
			//MD- woah boy!
			_objet setVelocity [0,0,0];
			
			//MD- clean up the action menu
			player removeAction _action_menu_release_relative;
			player removeAction _action_menu_release_horizontal;
			player removeAction _action_menu_45;
			//player removeAction _action_menu_90;
			//player removeAction _action_menu_180;

			//MD- set the player carried object to null
			R3F_LOG_joueur_deplace_objet = objNull;
			
			//MD- and conversely set the objects carried by variable to null also
			_objet setVariable ["R3F_LOG_est_deplace_par", objNull, true];
			
			// Restauration de l'arme primaire
			//MD- restore the primary weapon.
			if (alive player && _arme_principale != "") then
			{
				if(primaryWeapon player != "") then {
					_o = createVehicle ["WeaponHolder", player modelToWorld [0,0,0], [], 0, "NONE"];
					_o addWeaponCargoGlobal [_arme_principale, 1];
				}
				else {
					{
						_magazine = _x select 0;
						_ammo = _x select 1;
						
						if(_magazine != "" && _ammo > 0) then {
							player addMagazine _x;
						};
					} forEach _arme_principale_magasines; // add all default primery weapon magazines
					
					player addWeapon _arme_principale;
					
					{ if(_x!="") then { player addPrimaryWeaponItem _x; }; } foreach (_arme_principale_accessoires);
					
					player selectWeapon _arme_principale;
					//player selectWeapon (getArray (configFile >> "cfgWeapons" >> _arme_principale >> "muzzles") select 0);
				};
			};
		};
	};
};
