/**
 * Sélectionne un objet à remorquer
 * 
 * @param 0 l'objet à sélectionner
 */

if (R3F_LOG_mutex_local_lock) then
{
	player globalChat STR_R3F_LOG_action_isnt_completed;
}
else
{
	R3F_LOG_mutex_local_lock = true;
	
	R3F_LOG_selected_object = _this select 0;
	player globalChat format [STR_R3F_LOG_action_select_vehicle_to_load, getText (configFile >> "CfgVehicles" >> (typeOf R3F_LOG_selected_object) >> "displayName")];
	
	R3F_LOG_mutex_local_lock = false;
};