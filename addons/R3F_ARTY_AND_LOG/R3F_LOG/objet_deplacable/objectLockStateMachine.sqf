//	@file Author: [404] Costlyy
//	@file Version: 1.0
//  @file Date:	21/11/2012	
//	@file Description: Locks an object until the player disconnects.
//	@file Args: [object,player,int,lockState(lock = 0 / unlock = 1)]

// Check if mutex lock is active.
if(R3F_LOG_mutex_local_verrou) exitWith {
	player globalChat STR_R3F_LOG_mutex_action_en_cours;
};

private["_locking", "_object", "_lockState", "_lockDuration", "_stringEscapePercent", "_interation", "_unlockDuration", "_totalDuration"];

_object = _this select 0;
_lockState = _this select 3;

_totalDuration = 0;
_stringEscapePercent = "%";


//MD- 0=LOCK, 1=UNLOCK
switch (_lockState) do
{
  case 0: // LOCK 
	{
		//MD- We're performing an action
    R3F_LOG_mutex_local_verrou = true;
		_totalDuration = 5;
		_lockDuration = _totalDuration;
		_iteration = 0;
		
		//MD- perform animation (the medic one from experience)
		player switchMove "AinvPknlMstpSlayWrflDnon_medic";
		
		//MD- for 1 to 5
		for "_iteration" from 1 to _lockDuration do
		{
			// If the player is too far or dies, revert state.
      if (player distance _object > 14 || !alive player) exitWith
			{
				//MD- layer cutText[string, effect/type, speed, showOnMap(optional, defaults to false)]
		    2 cutText ["Object lock interrupted...", "PLAIN DOWN", 1];
		    //MD- end operation
      	R3F_LOG_mutex_local_verrou = false;
			};
            
			// Keep the player locked in medic animation for the full duration of the unlock.
      if (animationState player != "AinvPknlMstpSlayWrflDnon_medic") then 
      {
        player switchMove "AinvPknlMstpSlayWrflDnon_medic";
      };
            
      //MD- why are we decrementing the loop end value?
			_lockDuration = _lockDuration - 1;
			//MD- calculate the percentage
		  _iterationPercentage = floor (_iteration / _totalDuration * 100);
		  
		  //MD- display pecentage on screen  
			2 cutText [format["Object lock %1%2 complete", _iterationPercentage, _stringEscapePercent], "PLAIN DOWN", 1];
			//MD- power nap
		  sleep 1;
		    
			// Sleep a little extra to show that lock has completed.
			//MD- if lockDuration is being decremented then iteration will never be greater than totalduration
			//MD- but i've played it and it clearly does so need to test this.
			if (_iteration >= _totalDuration) exitWith
			{
		  	sleep 1;
		  	//MD- note that the last true means this is being broadcast to network
        _object setVariable ["objectLocked", true, true];
				_object setVariable ["ownerUID", getPlayerUID player, true];
        2 cutText ["", "PLAIN DOWN", 1];
        R3F_LOG_mutex_local_verrou = false;
		  }; 
		};
		
		player switchMove ""; // Redundant reset of animation state to avoid getting locked in animation.       
  };
  case 1: // UNLOCK
	{ //MD- this is basically the reverse of above
    R3F_LOG_mutex_local_verrou = true;
		_totalDuration = if (_object getVariable ["ownerUID", ""] == getPlayerUID player) then { 10 } else { 45 }; // Allow owner to unlock quickly
		_unlockDuration = _totalDuration;
		_iteration = 0;
		
		player switchMove "AinvPknlMstpSlayWrflDnon_medic";
		
		for "_iteration" from 1 to _unlockDuration do
		{
			// If the player is too far or dies, revert state.
      if (player distance _object > 5 || !alive player) exitWith
			{
		  	2 cutText ["Object unlock interrupted...", "PLAIN DOWN", 1];
        R3F_LOG_mutex_local_verrou = false;
			};
            
			// Keep the player locked in medic animation for the full duration of the unlock.
      if (animationState player != "AinvPknlMstpSlayWrflDnon_medic") then 
      {
      	player switchMove "AinvPknlMstpSlayWrflDnon_medic";
      };
            
			_unlockDuration = _unlockDuration - 1;
		  _iterationPercentage = floor (_iteration / _totalDuration * 100);
		    
			2 cutText [format["Object unlock %1%2 complete", _iterationPercentage, _stringEscapePercent], "PLAIN DOWN", 1];
		  sleep 1;
		    
			// Sleep a little extra to show that lock has completed
			if (_iteration >= _totalDuration) exitWith
			{
		    sleep 1;
        _object setVariable ["objectLocked", false, true];
				_object setVariable ["ownerUID", nil, true];
				_object setVariable ["baseSaving_hoursAlive", nil, true];
				_object setVariable ["baseSaving_spawningTime", nil, true];
        2 cutText ["", "PLAIN DOWN", 1];
        R3F_LOG_mutex_local_verrou = false;
		  }; 
		};
		
	player switchMove ""; // Redundant reset of animation state to avoid getting locked in animation.     
  };
  default //MD- Should always get 0 or 1
  {  // This should not happen... 
  	diag_log format["WASTELAND DEBUG: An error has occured in LockStateMachine.sqf. _lockState was unknown. _lockState actual: %1", _lockState];
  };
  
  //MD- Catch any unfinished operations  
  if !(R3F_LOG_mutex_local_verrou) then 
  {
    R3F_LOG_mutex_local_verrou = false;
    diag_log format["WASTELAND DEBUG: An error has occured in LockStateMachine.sqf. Mutex lock was not reset. Mutex lock state actual: %1", R3F_LOG_mutex_local_verrou];
  }; 
};
