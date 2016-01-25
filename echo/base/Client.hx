package echo.base;

import cpp.vm.Thread;
import cpp.vm.Mutex;
import echo.base.threading.ClientConnection;
import echo.base.data.ClientData;
import echo.commandInterface.commands.InviteClient;
import echo.commandInterface.commands.RejectConnection;
import echo.commandInterface.Command;
import echo.util.ConditionalTimer;

/**
 * The state the client can be in.
 * @type {[type]}
 */
enum ClientState
{
	None;
	WaitForInvite;
}

/**
 * Client class.
 * Used to connect to a host, command handling, callback handling, etc.
 * @type {[type]}
 */
class Client extends ClientHostBase
{
	private var _clientData : ClientData = new ClientData();

	private var _isConnected : Bool = false;
	private var _state : ClientState = None;

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @param  {String = "localhost"} p_hostAddr The address of the host.
	 * @param  {Int	= 20301}	   p_port	 The port to connect to.
	 * @return {[type]}
	 */
	public function new(p_identifier : String, p_hostAddr : String = "localhost", p_port : Int = 20301)
	{
		super();

		_clientData.identifier = p_identifier;

		_connection = new ClientConnection(p_hostAddr, p_port);
		_connection.setSharedData(_inCommands, _inCommandsMutex, _outCommands, _outCommandsMutex);
		_thread = Thread.create(_connection.threadFunc);

		// Add callbacks for base ECHo functionality
		addCommandCallback(InviteClient.getId(), executeClientCommand);
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Returns true if the connection to the host is established.
	 * Note that this may lag behind one client tick due to threading.
	 * @return {Bool}
	 */
	public function isConnected() : Bool
	{
		return _isConnected;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Returns the ClientData of this client.
	 * @return {ClientData}
	 */
	public inline function getClientData() : ClientData
	{
		return _clientData;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Updates the client, executing commands (aka calling their callbacks).
	 * @param  {Float}  p_timeSinceLastFrame	The time since the last frame in seconds.
	 * @return {Void}
	 */
	override public function update(p_timeSinceLastFrame : Float) : Void
	{
		super.update(p_timeSinceLastFrame);

		// If we have a socket connection, but no full Host->Client connection, set a timer
		if (cast(_connection, ClientConnection).isConnected() && !_isConnected && _state == None)
		{
			_state = WaitForInvite;
			var timer : ConditionalTimer = new ConditionalTimer(1.5,
				isConnected,
				null,
				_connection.shutdown
			);
			_conditionalTimers.push(timer);
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Executes the passed command.
	 * @param  {Command} p_command The command to execute.
	 * @return {Bool}
	 */
	public function executeClientCommand(p_command : Command) : Bool
	{
		var id : Int = p_command.getCommandId();
		if (id == InviteClient.getId())
		{
			trace("Received InviteClient!");
			_isConnected = true;

			// TODO: here
		}
		else
		{
			if (ECHo.logLevel >= 2)
			{
				trace("Warning: executeClientCommand: Unhandled client command: " + p_command.getCommandId());
			}
			p_command.errorMsg = "Unhandled client command";
			return false;
		}

		return true;
	}
}
