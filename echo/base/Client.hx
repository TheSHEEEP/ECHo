package echo.base;

import cpp.vm.Thread;
import cpp.vm.Mutex;
import echo.base.threading.ClientConnection;
import echo.base.data.ClientData;
import echo.commandInterface.commands.InviteClient;
import echo.commandInterface.commands.RejectConnection;
import echo.commandInterface.commands.RequestConnection;
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

	private var _isConnected 	: Bool = false;
	private var _state 			: ClientState = None;

	private var _clientConnection : ClientConnection = null;

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

		_connection = new ClientConnection(p_hostAddr, p_port, this);
		_clientConnection = cast _connection;
		_connection.setSharedData(_inCommands, _inCommandsMutex, _outCommands, _outCommandsMutex);
		_thread = Thread.create(_connection.threadFunc);

		// Add callbacks for base ECHo functionality
		addCommandCallback(InviteClient.getId(), executeClientCommand);
		addCommandCallback(RejectConnection.getId(), executeClientCommand);

		// Randomize hostId to prevent external sources picking a default
		_clientConnection.getHostData().id = Std.int(Math.random() * 10000);
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
			var timer : ConditionalTimer = new ConditionalTimer(5.0,
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

		// Invitation
		if (id == InviteClient.getId())
		{
			handleInviteClient(cast(p_command, InviteClient));
		}
		// Connection rejected
		else if (id == RejectConnection.getId())
		{
			handleRejectConnection(cast(p_command, RejectConnection));
		}
		else
		{
			if (ECHo.logLevel >= 2)
			{
				trace("Warning: executeClientCommand: Unhandled client command: " + p_command.getName());
			}
			p_command.errorMsg = "Unhandled client command";
			return false;
		}

		return true;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Handles the InviteClient command.
	 * @param  {InviteClient} p_command The command.
	 * @return {Void}
	 */
	private function handleInviteClient(p_command : InviteClient) : Void
	{
		// Ignore this when already connected
		if (_isConnected)
		{
			if (ECHo.logLevel >= 2) trace("Warning: handleInviteClient: already connected! Sender was : "
											+ p_command.getSenderId());
			return;
		}

		// Now we know the ID of the host
		_clientConnection.getHostData().id = p_command.hostId;

		// Send RequestConnection as an answer
		var command : RequestConnection = new RequestConnection();
		command.setRecipientId(p_command.hostId);
		command.identifier = _clientData.identifier;
		command.secret = p_command.secret;
		sendCommand(command);
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Handles the RejectConnection command.
	 * @param  {RejectConnection} p_command The command.
	 * @return {Void}
	 */
	private function handleRejectConnection(p_command : RejectConnection) : Void
	{
		// Ignore this when not coming from the host
		if (p_command.getSenderId() != _clientConnection.getHostData().id)
		{
			if (ECHo.logLevel >= 2) trace("Warning: handleRejectConnection: sender was not host: "
											+ p_command.getSenderId());
			return;
		}
		var reason : RejectionReason = cast(p_command, RejectConnection).reason;

		switch(reason)
		{
		case RejectionReason.RoomIsFull:
			_connection.shutdown();
			_isConnected = false;
			_state = ClientState.None;
			if (ECHo.logLevel >= 4) trace("Info: handleRejectConnection: Host rejected connection due to full room.");
		case RejectionReason.AlreadyConnected:
			// Nothing
		default:
			_connection.shutdown();
			_isConnected = false;
			_state = ClientState.None;
			if (ECHo.logLevel >= 2) trace("Warning: handleRejectConnection: Connection rejected without reason.");
		}
	}
}
