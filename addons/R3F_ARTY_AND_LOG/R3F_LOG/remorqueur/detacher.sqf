/**
 * Détacher un objet d'un véhicule
 * GT: Remove an object of a vehicle
 * 
 * @param 0 l'objet à détacher
 * 
 * Copyright (C) 2010 madbull ~R3F~
 * 
 * This program is free software under the terms of the GNU General Public License version 3.
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

//MD- Usual warning if we're already doing something
if (R3F_LOG_mutex_local_verrou) then
{
	player globalChat STR_R3F_LOG_mutex_action_en_cours;
}
else
{
	R3F_LOG_mutex_local_verrou = true; //MD- Set busy flag
	
	private ["_remorqueur", "_objet"];
	
	_objet = _this select 0; 
	//MD- Set tow-er to the objects "transported by" variable
	_remorqueur = _objet getVariable "R3F_LOG_est_transporte_par"; //
	
	// Ne pas permettre de décrocher un objet s'il est porté héliporté
	// GT: Do not allow to drop an object when worn helicopter
	//MD- I suspect google translate is making an arse of this one
	//MD- the if is checking for tow-ers rather than helicopters
	if ({_remorqueur isKindOf _x} count R3F_LOG_CFG_remorqueurs > 0) then
	{
		//MD- play the medic animation
		player switchMove "AinvPknlMstpSlayWrflDnon_medic";
		
		/*player addEventHandler ["AnimDone", 
		{
			if (_this select 1 == "AinvPknlMstpSlayWrflDnon_medic") then
			{
				player switchMove "";
				player removeAllEventHandlers "AnimDone";
			};
		}];*/
		
		//MD- get accurate boundingBox and split minand max arrays
		_towerBB = _remorqueur call fn_boundingBoxReal;
		_towerMinBB = _towerBB select 0;
		_towerMaxBB = _towerBB select 1;
		
		//MD- if the player is above sea level
		if ((getPosASL player) select 2 > 0) then
		{
			//MD- Attach player to tow-er
			player attachTo [_remorqueur,
			[
				(_towerMinBB select 0) - 0.25,
				(_towerMinBB select 1) - 0.25,
				_towerMinBB select 2
			]];
			
			//MD- set direction and position
			player setDir 90;
			player setPos (getPos player);
			sleep 0.05;
			//MD- Then detach
			detach player;

			//MD- Used to position the player relative to object
		};
		
		sleep 2;
		
		// On mémorise sur le réseau que le véhicule remorque quelque chose
		// GT: Is stored on the network that the vehicle towing something
		//MD- the last (true) param sends it to network
		//MD- contrary to the comment, the towing variable of the tow-er is being set to null
		_remorqueur setVariable ["R3F_LOG_remorque", objNull, true];
		// On mémorise aussi sur le réseau que le objet est attaché en remorque
		// GT: It also stores the network as the object is attached trailer 
		//MD- Again the is setting the "is being tranported by" flag to null
		_objet setVariable ["R3F_LOG_est_transporte_par", objNull, true];
		
		//MD- if object is local
		//MD- Vehicles are local to the driver
		//MD- vehicles created after mission start are local to the creator (possibily store bought vehicles?)
		if (local _objet) then
		{
			//MD- Perform the actual detach
			_objet call detachTowedObject;
		}
		else
		{
			//MD- pass to vehicle init to perform the detach.
			[_objet, {_this call detachTowedObject}, false, false, _objet] call fn_vehicleInit;
		};

		//MD- allow medic anim to run for 4 more seconds...		
		sleep 4;
		//MD- before clearing
		player switchMove "";
		
		//MD- if the object is a moveable as welll as towable (e.g. a2 wasteland AA gun)
		if ({_objet isKindOf _x} count R3F_LOG_CFG_objets_deplacables > 0) then
		{
			// Si personne n'a re-remorquer l'objet pendant le sleep 6
			// GT: If no one has re-tow the object during sleep 6
			//MD- if anyone has fucked about with the object while the medic animation as playing out
			if (isNull (_remorqueur getVariable "R3F_LOG_remorque") &&
				(isNull (_objet getVariable "R3F_LOG_est_transporte_par")) &&
				(isNull (_objet getVariable "R3F_LOG_est_deplace_par"))
			) then
			{
				//MD- The object is unhitch now make the player carry it
				[_objet] execVM "addons\R3F_ARTY_AND_LOG\R3F_LOG\objet_deplacable\deplacer.sqf";
			};
		}
		else
		{
			// Say: Object untowed
			player globalChat STR_R3F_LOG_action_detacher_fait;
		};
	}
	else // if it's not a tow-er (by reduction it must be a chopper)
	{
		//MD- Say: Only pilot can detach this vehicle
		player globalChat STR_R3F_LOG_action_detacher_impossible_pour_ce_vehicule;
	};
	
	//MD- finishd the operation
	R3F_LOG_mutex_local_verrou = false;
};