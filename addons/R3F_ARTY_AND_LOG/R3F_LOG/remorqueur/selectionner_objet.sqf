/**
 * Sélectionne un objet à remorquer
 * GT: Selects an object to be towed
 * 
 * @param 0 l'objet à sélectionner
 */

//MD- If we're doing something already
if (R3F_LOG_mutex_local_verrou) then
{
	//MD- Say: The current operation isn't finished.
	player globalChat STR_R3F_LOG_mutex_action_en_cours;
}
else
{
	//MD- Set the operation in progress flag to true
	R3F_LOG_mutex_local_verrou = true;

	//MD- set public object selected var to the object passed in
	R3F_LOG_objet_selectionne = _this select 0;
	//MD- Say: Now select the vehicle in which to load the object ""%1""...
	player globalChat format [STR_R3F_LOG_action_selectionner_objet_remorque_fait, getText (configFile >> "CfgVehicles" >> (typeOf R3F_LOG_objet_selectionne) >> "displayName")];
	
	//MD- Set the operation in progress flag to false
	R3F_LOG_mutex_local_verrou = false;
};