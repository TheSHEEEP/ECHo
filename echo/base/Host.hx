package echo.base;

import cpp.vm.Thread;
import echo.base.threading.HostConnection;
import echo.commandInterface.commands.RequestConnection;
import echo.commandInterface.commands.RejectConnection;
import echo.commandInterface.Command;

/**
 * Host class.
 * Used to listen on a port, handle incoming connections, command handling, etc.
 * @type {[type]}
 */
class Host extends ClientHostBase
{
	private var _hostConnection : HostConnection = null;

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @param  {String = "0.0.0.0"} p_inaddr The accepted incoming addresses. Default will allow everyone to connect.
	 * @param  {Int    = 20301}     p_port   The port to listen at.
	 * @return {[type]}
	 */
    public function new(p_maxConn : Int = 5, p_inaddr : String = "0.0.0.0", p_port : Int = 20301)
    {
		super();

        // Create the host thread
        _connection = new HostConnection(p_inaddr, p_port, p_maxConn, this);
		_connection.setSharedData(_inCommands, _inCommandsMutex, _outCommands, _outCommandsMutex);
		_hostConnection = cast _connection;
        _thread = Thread.create(_connection.threadFunc);

		// Command callbacks
		addCommandCallback(RequestConnection.getId(), executeHostCommand);
    }

    //------------------------------------------------------------------------------------------------------------------
    /**
     * Updates the host, executing commands (aka calling their callbacks).
	 * @param  {Float}  p_timeSinceLastFrame	The time since the last frame in seconds.
     * @return {Void}
     */
    override public function update(p_timeSinceLastFrame : Float) : Void
    {
		super.update(p_timeSinceLastFrame);
    }

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Tries executing the passed command.
	 * @param  {Command} p_command The command to be executed.
	 * @return {Bool}
	 */
	private function executeHostCommand(p_command : Command) : Bool
	{
		var id : Int = p_command.getCommandId();

		// Request connection
		if (id == RequestConnection.getId())
		{
			handleRequestConnection(cast(p_command, RequestConnection));
		}
		else
		{
			if (ECHo.logLevel >= 2)
			{
				trace("Warning: executeHostCommand: Unhandled host command: " + p_command.getName());
			}
			p_command.errorMsg = "Unhandled client command";
			return false;
		}

		return true;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Handles the RequestConnection command.
	 * @param  {RequestConnection} p_command The command to handle.
	 * @return {Void}
	 */
	private function handleRequestConnection(p_command : RequestConnection) : Void
	{
		// Make sure that this comes from one of the candidates
		if (!_hostConnection.isACandidateSecret(p_command.secret))
		{
			if (ECHo.logLevel >= 2) trace("Warning: handleRequestConnection: Received RequestConnection with wrong secret.");
			return;
		}

		// Set the flag as there is a timer waiting for this
		addFlag("c:" + RequestConnection.getId() + ":" + p_command.secret);

		// Check if the same client is already connected
		if (_hostConnection.isClientConnected(p_command.getData()))
		{
			// Send rejection
			var command : RejectConnection = new RejectConnection();
			command.reason = RejectionReason.AlreadyConnected;
			command.setSenderId(_hostConnection.getId());
			command.setRecipientId(p_command.getRecipientId());
			sendCommand(command);
			return;
		}

		// TODO: here
	}
}
