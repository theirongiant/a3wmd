/**
 * Initialise un objet déplaçable/héliportable/remorquable/transportable
 * GT: Initializes a movable object / liftable / towable / transportable
 * 
 * @param 0 l'objet
 * 
 * Copyright (C) 2010 madbull ~R3F~
 * 
 * This program is free software under the terms of the GNU General Public License version 3.
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

private ["_objet", "_est_desactive", "_est_transporte_par", "_est_deplace_par", "_objectState", "_doLock", "_doUnlock","_currentAnim","_config","_onLadder"];

_objet = _this select 0;

_doLock = 0;
_doUnlock = 1;


//MD- If object doesn't have disabled flag then set it to false
_est_desactive = _objet getVariable "R3F_LOG_disabled";
if (isNil "_est_desactive") then
{
	_objet setVariable ["R3F_LOG_disabled", false];  //on altis its smarter to only enable deplacement on objects we WANT players to move so if it doesnt find an r3f tag, it disables r3f on the object
};

// Définition locale de la variable si elle n'est pas définie sur le réseau
// GT: Resolution of the local variable if it is not defined in the network
// MD- if object doesn't have is_transportable(moveable) flag then set it to objNull
_est_transporte_par = _objet getVariable "R3F_LOG_est_transporte_par";
if (isNil "_est_transporte_par") then
{
	//MD- boolean param is whether object is broadcast to network
	_objet setVariable ["R3F_LOG_est_transporte_par", objNull, false];
};

// Définition locale de la variable si elle n'est pas définie sur le réseau
// GT: Resolution of the local variable if it is not defined in the network
//MD- If object doesn't have is moved by(moving?) flag set then set to objNull
_est_deplace_par = _objet getVariable "R3F_LOG_est_deplace_par";
if (isNil "_est_deplace_par") then
{
	_objet setVariable ["R3F_LOG_est_deplace_par", objNull, false];
};

// Ne pas monter dans un véhicule qui est en cours de transport
// GT: Do not ride in a vehicle that is in transit
//MD- GetIn event is called with [vehicle, position, unit]
_objet addEventHandler ["GetIn",
{
	_veh = _this select 0;
	_movedBy = _veh getVariable ["R3F_LOG_est_deplace_par", objNull];
	_towedBy = _veh getVariable ["R3F_LOG_est_transporte_par", objNull];
	
	//MD- If the unit is the player && (the position is driver || towedBy is chopper
	//MD- this event is triggered globally whenever any unit gets in any vehicle (this may not be quite true)
	//MD- so if our player is either getting in as driver or the vehicle is being towed by a helicopter
	if (_this select 2 == player && (_this select 1 == "DRIVER" || _towedBy isKindOf "Helicopter")) then
	{
		//MD- if the vehicle is being towed or it's being moved by something that is alive
		if (!isNull _towedBy || {!isNull _movedBy && alive _movedBy}) then
		{
			//MD- kick that bitch out
			player action ["eject", _veh];
			//MD- Say: This vehicle is being transported.
			player globalChat STR_R3F_LOG_transport_en_cours;
		};
	};
}];

//MD- If the object is moveable
if ({_objet isKindOf _x} count R3F_LOG_CFG_objets_deplacables > 0) then
{
	//MD- This is a chunky function I'll list the parms for this one
	//MD- https://community.bistudio.com/wiki/addAction
	_objet addAction [ //MD- Move this object
		("<img image='client\icons\r3f_lift.paa' color='#ffff00'/> <t color='#ffff00'>" + STR_R3F_LOG_action_deplacer_objet + "</t>"), //MD- title
		"addons\R3F_ARTY_AND_LOG\R3F_LOG\objet_deplacable\deplacer.sqf", //MD- script, gets passed [target, caller, ID, arguments] 
		nil, //MD- arguments
		5, //MD- priority in list,  shown in descending order
		false, //MD- showWindow, show highest action on screen
		true, //MD- hideOnUse
		"", //MD- shortcut
		"R3F_LOG_objet_addAction == _target && R3F_LOG_action_deplacer_objet_valide && !(_target getVariable ['objectLocked', false])" 
		//MD- condition, special variables are _target (object action was called from) and _this (calling unit) (seems counter intuitive)
		//MD- if we have a target (why wouldn't we?) and the move object action is valid and the object isn't locked
	];

	_objet addAction [ //MD- Lock Object
	("<img image='client\icons\r3f_lock.paa' color='#ff0000'/> <t color='#ff0000'>" + STR_LOCK_OBJECT + "</t>"), 
		"addons\R3F_ARTY_AND_LOG\R3F_LOG\objet_deplacable\objectLockStateMachine.sqf", 
		_doLock, 
		-5, 
		false, 
		true, 
		"", 
		"R3F_LOG_objet_addAction == _target && R3F_LOG_action_deplacer_objet_valide && Object_canLock && !(_target isKindOf 'AllVehicles')"
		//MD- got an object, it's a valid move object and it's lockable and object isn't a kind of vehicle*
		//MD- *quads and boats are included in the moveable list so this makes sure that they aren't lockable
	];

	_objet addAction [ //MD- Unlock Object
		("<img image='client\icons\r3f_unlock.paa' color='#06ef00'/> <t color='#06ef00'>" + STR_UNLOCK_OBJECT + "</t>"), 
		"addons\R3F_ARTY_AND_LOG\R3F_LOG\objet_deplacable\objectLockStateMachine.sqf", 
		_doUnlock, 
		-5, 
		false, 
		true, 
		"", 
		"R3F_LOG_objet_addAction == _target && R3F_LOG_action_deplacer_objet_valide && !Object_canLock"];
		//MD- i'm guessing this doesn't have the vehicle check as if you prevent vehicles from being locked then only non-vehicles are unlockable.
};

//MD- if object is towable
if ({_objet isKindOf _x} count R3F_LOG_CFG_objets_remorquables > 0) then
{
	//MD- if it's also a moveable by player object
	if ({_objet isKindOf _x} count R3F_LOG_CFG_objets_deplacables > 0) then
	{
		//MD- Current config has no towable/player-moveable objects but might include AA guns which were towable in some versions of A2 wasteland
		_objet addAction [ //MD- Tow the object
			("<img image='client\icons\r3f_tow.paa' color='#ffff00'/> <t color='#ffff00'>" + STR_R3F_LOG_action_remorquer_deplace + "</t>"), 
			"addons\R3F_ARTY_AND_LOG\R3F_LOG\remorqueur\remorquer_deplace.sqf", 
			nil, 
			6, 
			true, 
			true, 
			"", 
			"R3F_LOG_objet_addAction == _target && R3F_LOG_action_remorquer_deplace_valide"
			//MD- object is a valid tow object
		];
	};
	
	_objet addAction [ //MD- Tow (hitch) to a vehicle
		("<img image='client\icons\r3f_tow.paa' color='#ffff00'/> <t color='#ffff00'>" + STR_R3F_LOG_action_selectionner_objet_remorque + "</t>"), 
		"addons\R3F_ARTY_AND_LOG\R3F_LOG\remorqueur\selectionner_objet.sqf", 
		nil, 
		5, 
		false, 
		true, 
		"", 
		"R3F_LOG_objet_addAction == _target && R3F_LOG_action_selectionner_objet_remorque_valide && Object_canLock"
		// Object is a valid tow object and object can be locked?
	];
	
	_objet addAction [ //MD- Untow (unhitch) the object
		("<img image='client\icons\r3f_untow.paa' color='#06ef00'/> <t color='#06ef00'>" + STR_R3F_LOG_action_detacher + "</t>"), 
		"addons\R3F_ARTY_AND_LOG\R3F_LOG\remorqueur\detacher.sqf", 
		nil, 
		6, 
		true, 
		true, 
		"", 
		"R3F_LOG_objet_addAction == _target && R3F_LOG_action_detacher_valide"];
		//MD- it's a valid detach target
};

//MD- if it's a transportable
if ({_objet isKindOf _x} count R3F_LOG_classes_objets_transportables > 0) then
{
	// If it's a moveable
	if ({_objet isKindOf _x} count R3F_LOG_CFG_objets_deplacables > 0) then
	{
		_objet addAction [ //MD- Load in vehicle
			("<img image='client\icons\r3f_loadin.paa' color='#06ef00'/> <t color='#06ef00'>" + STR_R3F_LOG_action_charger_deplace + "</t>"), 
			"addons\R3F_ARTY_AND_LOG\R3F_LOG\transporteur\charger_deplace.sqf", 
			nil, 
			6, 
			true, 
			true, 
			"", 
			"R3F_LOG_objet_addAction == _target && R3F_LOG_action_charger_deplace_valide"
			//MD- load movable valid
		];		
	};
	
	_objet addAction [ //MD- Load in...
		("<img image='client\icons\r3f_loadin.paa' color='#06ef00'/> <t color='#06ef00'>" + STR_R3F_LOG_action_selectionner_objet_charge + "</t>"), 
		"addons\R3F_ARTY_AND_LOG\R3F_LOG\transporteur\selectionner_objet.sqf", 
		nil, 
		5, 
		false, 
		true, 
		"", 
		"R3F_LOG_objet_addAction == _target && R3F_LOG_action_selectionner_objet_charge_valide && Object_canLock"];
		//MD- load in is valid and object isn't locked
};