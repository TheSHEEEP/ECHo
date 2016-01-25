package echo.base;

import haxe.ds.IntMap;
import cpp.vm.Mutex;
import cpp.vm.Thread;
import echo.commandInterface.Command;
import echo.base.threading.ConnectionBase;
import echo.util.ConditionalTimer;

/**
 * Common interface for Client & Host classes.
 * @type {[type]}
 */
class ClientHostBase
{
    private var _connection : ConnectionBase;
    private var _thread     : Thread;

	private var _outCommands		: Array<Command> = new Array<Command>();
	private var _outCommandsMutex	: Mutex = new Mutex();
	private var _inCommands			: Array<Command> = new Array<Command>();
	private var _inCommandsMutex	: Mutex = new Mutex();

	private var _preCommandListeners 	: IntMap<Array<Command->Bool>> = new IntMap<Array<Command->Bool>>();
	private var _commandListeners 		: IntMap<Array<Command->Bool>> = new IntMap<Array<Command->Bool>>();
	private var _postCommandListeners 	: IntMap<Array<Command->Bool->Void>> = new IntMap<Array<Command->Bool->Void>>();

	private var _conditionalTimers : Array<ConditionalTimer> = new Array<ConditionalTimer>();

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @return {[type]}
	 */
	public function new()
	{
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Adds a callback function to be called before the execution of the command.
	 * @param  {Int}		   p_id	  The ID of the command.
	 * @param  {Command->Bool} p_func The function to be used as a callback.
	 * @return {Void}
	 */
	public function addPreCommandCallback(p_id : Int, p_func : Command->Bool) : Void
	{
		if (!_preCommandListeners.exists(p_id))
		{
			_preCommandListeners.set(p_id, new Array<Command->Bool>());
		}
		var array : Array<Command->Bool> = _preCommandListeners.get(p_id);
		array.push(p_func);
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Adds a callback function to be called as the execution of the command.
	 * @param  {Int}		   p_id	  The ID of the command.
	 * @param  {Command->Bool} p_func The function to be used as a callback.
	 * @return {Void}
	 */
	public function addCommandCallback(p_id : Int, p_func : Command->Bool) : Void
	{
		if (!_commandListeners.exists(p_id))
		{
			_commandListeners.set(p_id, new Array<Command->Bool>());
		}
		var array : Array<Command->Bool> = _commandListeners.get(p_id);
		array.push(p_func);
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Adds a callback function to be called after the execution of the command.
	 * @param  {Int}		   p_id	  The ID of the command.
	 * @param  {Command->Bool} p_func The function to be used as a callback.
	 * @return {Void}
	 */
	public function addPostCommandCallback(p_id : Int, p_func : Command->Bool->Void) : Void
	{
		if (!_postCommandListeners.exists(p_id))
		{
			_postCommandListeners.set(p_id, new Array<Command->Bool->Void>());
		}
		var array : Array<Command->Bool->Void> = _postCommandListeners.get(p_id);
		array.push(p_func);
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Removes the passed callback function.
	 * @param  {Int}           p_id   The ID of the command to remove the callback from.
	 * @param  {Command->Bool} p_func The callback function to remove.
	 * @return {Void}
	 */
	public function removePreCommandCallback(p_id : Int, p_func : Command->Bool) : Void
	{
		if (_preCommandListeners.exists(p_id))
		{
			var array : Array<Command->Bool> = _preCommandListeners.get(p_id);
			array.remove(p_func);
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Removes the passed callback function.
	 * @param  {Int}           p_id   The ID of the command to remove the callback from.
	 * @param  {Command->Bool} p_func The callback function to remove.
	 * @return {Void}
	 */
	public function removeCommandCallback(p_id : Int, p_func : Command->Bool) : Void
	{
		if (_commandListeners.exists(p_id))
		{
			var array : Array<Command->Bool> = _commandListeners.get(p_id);
			array.remove(p_func);
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Removes the passed callback function.
	 * @param  {Int}           p_id   The ID of the command to remove the callback from.
	 * @param  {Command->Bool} p_func The callback function to remove.
	 * @return {Void}
	 */
	public function removePostCommandCallback(p_id : Int, p_func : Command->Bool->Void) : Void
	{
		if (_postCommandListeners.exists(p_id))
		{
			var array : Array<Command->Bool->Void> = _postCommandListeners.get(p_id);
			array.remove(p_func);
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Will add the passed command to send out as soon as possible.
	 * @param  {Command} p_command The command to send. Make sure it is set up properly.
	 * @return {Void}
	 */
	public function sendCommand(p_command : Command) : Void
	{
		_outCommandsMutex.acquire();
		_outCommands.push(p_command);
		_outCommandsMutex.release();
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Updates the client/host.
	 * @param  {Float}  p_timeSinceLastFrame	The time since the last frame in seconds.
	 * @return {Void}
	 */
	public function update(p_timeSinceLastFrame : Float) : Void
	{
		// Update timers
		var i : Int = 0;
		while(i < _conditionalTimers.length)
		{
			_conditionalTimers[i].update(p_timeSinceLastFrame);
			if (_conditionalTimers[i].isDone())
			{
				_conditionalTimers.splice(i, 1);
				i--;
			}
			i++;
		}
		
		// Handle incoming messages
		handleIncomingMessages();
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Handle the incoming messages, calling the registered callbacks.
	 * @return {Void}
	 */
	private function handleIncomingMessages() : Void
	{
		// Copy the array to block the mutex as little as possible
		_inCommandsMutex.acquire();
		var commands :Array<Command> = _inCommands.splice(0, _inCommands.length);
		_inCommandsMutex.release();

		// Iterate over all incoming commands
		var id : Int = -1;
		var abort : Bool = false;
		var success : Bool = false;
		for (command in commands)
		{
			id = command.getCommandId();

			// Pre-command listeners
			if (_preCommandListeners.exists(id))
			{
				for (callback in _preCommandListeners.get(id))
				{
					var result : Bool = callback(command);
					abort = (result ? abort : false);
				}
			}

			// Command listeners
			if (!abort && _commandListeners.exists(id))
			{
				for (callback in _commandListeners.get(id))
				{
					var result : Bool = callback(command);
					success = (result ? success : false);
				}
			}

			// Post-command listeners
			if (_postCommandListeners.exists(id))
			{
				for (callback in _postCommandListeners.get(id))
				{
					callback(command, success);
				}
			}
		}
	}
}
