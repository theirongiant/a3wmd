/**
 * Sélectionne un objet à charger dans un transporteur
 * GT: Selects an object to be loaded into a carrier
 * 
 * @param 0 l'objet à sélectionner
 * GT: the object to select
 */

//MD- If we're busy then exit
if (R3F_LOG_mutex_local_verrou) then
{
	player globalChat STR_R3F_LOG_mutex_action_en_cours;
}
else
{
	//
	_tempVar = false;
	//MD- If the object has a side
	if(!isNil {(_this select 0) getVariable "R3F_Side"}) then 
	{
		//MD if it's not the same side as the player
		if(playerSide != ((_this select 0) getVariable "R3F_Side")) then 
		{
			{//MD- Loop round all active units
				if(side _x ==  ((_this select 0) getVariable "R3F_Side") && alive _x && _x distance (_this select 0) < 150) 
					//MD- if there is a unit of the same side as the object within 150m then exit
					exitwith {_tempVar = true;};
			} foreach AllUnits;
		};
	};
	if(_tempVar) exitwith 
	{
		hint format["This object belongs to %1 and they're nearby you cannot take this.", (_this select 0) getVariable "R3F_Side"]; 
		R3F_LOG_mutex_local_verrou = false; //MD- Not busy now
	};

	R3F_LOG_mutex_local_verrou = true; //MD- Busy
	
	R3F_LOG_objet_selectionne = _this select 0; //MD- set the selected object public var
	//MD- Say: Now select the vehicle in which to load the object ""%1""...
	player globalChat format [STR_R3F_LOG_action_selectionner_objet_charge_fait, getText (configFile >> "CfgVehicles" >> (typeOf R3F_LOG_objet_selectionne) >> "displayName")];
	
	R3F_LOG_mutex_local_verrou = false; //MD- Not busy
};