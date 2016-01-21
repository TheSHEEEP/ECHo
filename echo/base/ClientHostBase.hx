package echo.base;

import haxe.ds.IntMap;
import cpp.vm.Mutex;
import cpp.vm.Thread;
import echo.commandInterface.Command;
import echo.base.threading.ConnectionBase;

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

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @return {[type]}
	 */
	public function new()
	{
		_outCommands = new Array<Command>();
		_outCommandsMutex = new Mutex();
		_inCommands = new Array<Command>();
		_inCommandsMutex = new Mutex();
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Updates the client/host.
	 * @return {Void}
	 */
	public function update() : Void
	{
		// Handle incoming messages
		handleIncomingMessages();

		// handle outgoing messages
		handleOutgoingMessages();
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Handle the incoming messages, calling the registered callbacks.
	 * @return {Void}
	 */
	private function handleIncomingMessages() : Void
	{
		// Iterate over all incoming commands
		var id : Int = -1;
		var abort : Bool = false;
		var success : Bool = false;
		for (command in _inCommands)
		{
			id = command.getId();

			// Pre-command listeners
			if (_preCommandListeners.exists(id))
			{
				for (callback in _preCommandListeners.get(id))
				{
					var result : Bool = callback(command);
					abort = (result ? abort : result);
				}
			}

			// Command listeners
			if (!abort && _commandListeners.exists(id))
			{
				for (callback in _commandListeners.get(id))
				{
					var result : Bool = callback(command);
					success = (!result ? result : success);
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


	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Handle the outgoing messages, sending them to their recipients.
	 * @return {Void}
	 */
	private function handleOutgoingMessages() : Void
	{
		// TODO: here
	}
}
