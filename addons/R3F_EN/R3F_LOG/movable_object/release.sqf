/*
	@file Author: [404] Costlyy (Original code part of R3F)
	@file Version: 1.0
   	@file Date:	22/11/2012	
	@file Description: Releases the object that the player has currently selected.
	@file Args: [ , , ,boolean(true = release horizontally)]
*/
if (R3F_LOG_mutex_local_lock) then
{
	player globalChat STR_R3F_LOG_action_isnt_completed;
}
else
{
	_doReleaseHorizontally = _this select 3;

	R3F_LOG_mutex_local_lock = true;
	
	if (_doReleaseHorizontally) then {
		R3F_LOG_force_horizontally = true; // Force the object horizontally according the the centre of said object.
	};

	R3F_LOG_player_target_object = objNull;
	sleep 0.1;
	
	R3F_LOG_mutex_local_lock = false;
};