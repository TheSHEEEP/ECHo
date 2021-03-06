package echo.base;

import cpp.vm.Mutex;
import cpp.vm.Thread;
import haxe.Timer;
import echo.base.threading.HostConnection;
import echo.base.data.ExtendedClientData;
import echo.commandInterface.commands.RequestConnection;
import echo.commandInterface.commands.RejectConnection;
import echo.commandInterface.commands.AcceptConnection;
import echo.commandInterface.commands.ClientList;
import echo.commandInterface.commands.NotifyDisconnect;
import echo.commandInterface.commands.Ping;
import echo.commandInterface.commands.Pong;
import echo.commandInterface.commands.PingList;
import echo.commandInterface.Command;
import echo.util.Logger;

/**
 * Host class.
 * Used to listen on a port, handle incoming connections, command handling, etc.
 * @type {[type]}
 */
class Host extends ClientHostBase
{
	private var _hostConnection : HostConnection = null;

	private var _connectionCandidates	: Array<ExtendedClientData> = new Array<ExtendedClientData>();
	private var _connectedClients 		: Array<ExtendedClientData> = new Array<ExtendedClientData>();
	private var _clientListMutex 		: Mutex = new Mutex();

	private var _maxConn 				: Int = 0;
	private var _idCounter				: Int = 1; //< Has to start at 1 as 0 is the "everyone" id

	private var _pingTime 		: Float = 0.5;
	private var _pingListTime 	: Float = 2.0;

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
		_maxConn = p_maxConn;

        // Create the host thread
        _connection = new HostConnection(p_inaddr, p_port, p_maxConn, this);
		_connection.setSharedData(_inCommands, _inCommandsMutex, _outCommands, _outCommandsMutex);
		_hostConnection = cast _connection;
		_hostConnection.setHostSharedData(_connectionCandidates, _connectedClients, _clientListMutex);
        _thread = Thread.create(_connection.threadFunc);

		// Command callbacks
		addCommandCallback(RequestConnection.getId(), executeHostCommand);
		addCommandCallback(Pong.getId(), executeHostCommand);
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

		// Check if a client disconnected, if so, send the client list to the remaining ones
		if (checkFlag("clientDisconnected"))
		{
			removeFlag("clientDisconnected");

			_clientListMutex.acquire();
			sendClientList();
			_clientListMutex.release();
		}

		// Do the ping calculations
		doPingCalculations(p_timeSinceLastFrame);
    }

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Does the ping calculations for all connected clients and regularly sends pingList commands.
	 * @param  {Float}  p_timeSinceLastFrame	The time since the last frame in seconds.
	 * @return {Void}
	 */
	private function doPingCalculations(p_timeSinceLastFrame : Float) : Void
	{
		// Send the ping command to all clients every 2 seconds
		_pingTime -= p_timeSinceLastFrame;
		if (_pingTime <= 0.0)
		{
			_pingTime = 0.5;

			var command : Ping = new Ping();
			command.setSenderId(_hostConnection.getId());
			command.setRecipientId(0);
			sendCommand(command);
		}

		// Send the ping list every two seconds
		_pingListTime -= p_timeSinceLastFrame;
		if (_pingListTime <= 0.0)
		{
			_pingListTime = 2.0;

			var command : PingList = new PingList();
			_clientListMutex.acquire();
			for(client in _connectedClients)
			{
				var info : PingInfo = new PingInfo();
				info.id = client.id;
				info.ping = client.ping;
				command.list.push(info);
			}
			_clientListMutex.release();
			command.setSenderId(_hostConnection.getId());
			command.setRecipientId(0);
			sendCommand(command);
		}
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
		else if (id == Pong.getId())
		{
			handlePong(cast(p_command, Pong));
		}
		else
		{
			if (ECHo.logLevel >= 2)
			{
				Logger.instance().log("Warning", "executeHostCommand: Unhandled host command: " + p_command.getName());
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
		_clientListMutex.acquire();
		// Make sure that this comes from one of the candidates
		if (!isACandidateSecret(p_command.secret))
		{
			if (ECHo.logLevel >= 2) Logger.instance().log("Warning", "handleRequestConnection: Received RequestConnection with wrong secret.");
			return;
		}

		// Set the flag as there is a timer waiting for this
		addFlag("c:" + RequestConnection.getId() + ":" + p_command.secret);

		// Check if the same client is already connected
		var id : Int = isClientConnected(p_command.getData());
		if (id != -1)
		{
			// Send rejection
			var command : RejectConnection = new RejectConnection();
			command.reason = RejectionReason.AlreadyConnected;
			command.setSenderId(_hostConnection.getId());
			command.setRecipientId(id);
			sendCommand(command);
			return;
		}

		// Check if the room is full
		if (_connectedClients.length >= _maxConn)
		{
			// Send rejection
			var command : RejectConnection = new RejectConnection();
			command.reason = RejectionReason.RoomIsFull;
			command.setSenderId(_hostConnection.getId());
			command.setRecipientId(-1000); // -1000 means it will be sent to the socket associated to p_command
			command.setData(p_command.getData());
			sendCommand(command);
			return;
		}

		// Check if there is another connected client with the same identifier
		var count : Int = 1;
		var found : Bool = true;
		var identifier = p_command.identifier;
		while (found)
		{
			found = false;
			for (client in _connectedClients)
			{
				if (client.identifier == identifier)
				{
					count++;
					identifier = p_command.identifier + '($count)';
					found = true;
				}
			}
		}

		// Add the client to the connected ones and remove it from the candidates
		p_command.getData().id = _idCounter++;
		if (p_command.getData().id == _hostConnection.getId())
		{
			p_command.getData().id = _idCounter++;
		}
		p_command.getData().identifier = identifier;
		_connectedClients.push(p_command.getData());
		_connectionCandidates.remove(p_command.getData());

		// Create and send the accept connection command
		var command : AcceptConnection = new AcceptConnection();
		command.clientId = _idCounter++;
		if (identifier != p_command.identifier)
		{
			command.newIdentifier = identifier;
		}
		command.setSenderId(_hostConnection.getId());
		command.setRecipientId(p_command.getData().id);
		sendCommand(command);

		// Create and send the clientList command
		sendClientList();

		_clientListMutex.release();
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Handles an incoming pong from a client.
	 * @param  {Pong} p_command The command data sent.
	 * @return {Void}
	 */
	private function handlePong(p_command : Pong) : Void
	{
		// Get the total time it took to receive this pong
		var totalTime : Float = Timer.stamp() - p_command.pingTimestamp;

		// Take note of the time in the correct client's variable
		var client : ExtendedClientData = p_command.getData();
		client.lastPings.add(Std.int(totalTime * 1000.0));
		var average : Int = 0;
		for (i in 0 ... 5)
		{
			average += client.lastPings[i];
		}
		average = Std.int(average / 5);
		client.ping = average;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Sends the current client list to all clients.
	 * @return {Void}
	 */
	private function sendClientList() : Void
	{
		var listCommand : ClientList = new ClientList();
		for (client in _connectedClients)
		{
			listCommand.clients.push(client);
		}
		listCommand.setSenderId(_hostConnection.getId());
		listCommand.setRecipientId(0);
		sendCommand(listCommand);
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Checks if the passed client data is identical to one of the connected clients.
	 * Returns the ID if connected or -1 if not.
	 * @param  {ExtendedClientData} p_data The data to check.
	 * @return {Int}
	 */
	public function isClientConnected(p_data : ExtendedClientData) : Int
	{
		for (client in _connectedClients)
		{
			if (client.socket.peer().host.toString() == p_data.socket.peer().host.toString() &&
				client.socket.peer().port == p_data.socket.peer().port)
			{
				return client.id;
			}
		}
		return -1;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Returns true if the passed secret belongs to a client candidate.
	 * @param  {Int}  p_secret [description]
	 * @return {Bool}
	 */
	public function isACandidateSecret(p_secret : Int) : Bool
	{
		for (candidate in _connectionCandidates)
		{
			if (p_secret == candidate.secret)
			{
				return true;
			}
		}
		return false;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Adds the passed client data to the candidates.
	 * @param  {ExtendedClientData} p_data The data to add.
	 * @return {Void}
	 */
	public function addToCandidates(p_data : ExtendedClientData) : Void
	{
		_internalMutex.acquire();
		_connectionCandidates.push(p_data);
		_internalMutex.release();
	}
}
