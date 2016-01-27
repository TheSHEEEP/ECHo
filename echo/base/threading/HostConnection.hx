package echo.base.threading;

import sys.net.Socket;
import sys.net.Host;
import haxe.Timer;
import haxe.io.Error;
import echo.base.data.ClientData;
import echo.base.data.ExtendedClientData;
import echo.commandInterface.Command;
import echo.commandInterface.commands.RejectConnection;
import echo.commandInterface.commands.RequestConnection;
import echo.commandInterface.commands.InviteClient;
import echo.commandInterface.commands.Ping;
import echo.commandInterface.commands.Pong;
import echo.util.TryCatchMacros;
import echo.util.ConditionalTimer;

/**
 * The class doing all of the host's socket interaction.
 * Use threadFunc in a thread.
 * The functionality is done in ticks. Each tick, there will be a try to accept new clients, sending data to clients
 * and receiving data from clients. Then, the thread will sleep for the rest of the tick's time.
 * @type {[type]}
 */
class HostConnection extends ConnectionBase
{
	private var _maxConn	: Int = 0;

	private var _connectionCandidates	: Array<ExtendedClientData> = new Array<ExtendedClientData>();
	private var _connectedClients 		: Array<ExtendedClientData> = new Array<ExtendedClientData>();

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @param  {String} p_inAddr 	The address to be open for.
	 * @param  {Int}    p_port   	The port to listen at.
	 * @param  {Int}	p_maxConn	The maximum number of connections to accept.
	 * @param  {ClientHostBase} p_parent  The parent of this connection thread.
	 * @return {[type]}
	 */
    public function new(p_inAddr : String, p_port : Int, p_maxConn : Int, p_parent : ClientHostBase)
    {
		super(p_inAddr, p_port, p_parent);

		_port = p_port;
		_maxConn = p_maxConn;

		// Create the host
		_mainSocket.setBlocking(true);
		_mainSocket.bind(_mainHost, _port);
		_id = Std.int(Math.random() * 10000);
    }

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * The main thread function of the host thread.
	 * @return {Void}
	 */
	override public function threadFunc() : Void
	{
		// Start listening (with additional connections so that we can send custom replies in case of a full room)
		_mainSocket.listen(_maxConn + 2);

		// Main loop
		var startTime 		: Float = 0.0;
		var currentTickTime : Float = 0.0;
		var sleepTime		: Float = 0.0;
		while (true)
		{
			startTime = Timer.stamp();

			_mainSocket.setBlocking(false);

			// Accepting step
			TryCatchMacros.tryCatchBlockedOk( "host doAcceptStep", function() {
				doAcceptStep();
			},
		    shutdown);

			// Sending to clients step
			TryCatchMacros.tryCatchBlockedOk( "host doSendStep", function() {
				doSendStep();
			},
		    shutdown);

			// Listening to clients step
			TryCatchMacros.tryCatchBlockedOk( "host doListenStep", function() {
				doListenStep();
			},
		    shutdown);

			// Sleep
			currentTickTime = Timer.stamp() - startTime;
			sleepTime = _tickTime - currentTickTime;
			if (sleepTime > 0.0)
			{
				Sys.sleep(sleepTime);
			}

			// Shutdown required?
			if (_doShutdown)
			{
				doShutdownInternal();
				_doShutdown = false;
				return;
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Shuts down the host connection.
	 * @return {Void}
	 */
	override private function doShutdownInternal() : Void
	{
		super.doShutdownInternal();

		// Close all client and candidate connections
		for (candidate in _connectionCandidates)
		{
			candidate.socket.close();
		}
		_connectionCandidates.splice(0, _connectionCandidates.length);
		for (client in _connectedClients)
		{
			client.socket.close();
		}
		_connectedClients.splice(0, _connectedClients.length);

		if (ECHo.logLevel >= 5) trace("Host threaded connection shut down.");
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Do the step of accepting/rejecting incoming connections.
	 * @return {Void}
	 */
	private function doAcceptStep() : Void
	{
		// Accept an incoming connection
		var connectedClient : Socket = _mainSocket.accept();
		connectedClient.setFastSend(true);
		connectedClient.setBlocking(false);
		var data : ExtendedClientData = new ExtendedClientData();
		data.ip = connectedClient.peer().host.toString();
		data.socket = connectedClient;

		if (ECHo.logLevel >= 5) trace("Incoming connection from " + connectedClient.peer().host.toString()
									+ " on port " + connectedClient.peer().port);

		// If we have too many clients already connected, send the reject message and close
		if (_connectedClients.length >= _maxConn)
		{
			var command : RejectConnection = new RejectConnection();
			command.reason = RejectionReason.RoomIsFull;
			command.setSenderId(_id);
			sendCommand(command, data, true);
			connectedClient.close();
		}
		else
		{
			// Add this one to the candidates
			_connectionCandidates.push(data);

			// Create invitation command
			var command : InviteClient = new InviteClient();
			command.hostId = _id;
			command.secret = Std.int(Math.random() * 1000000);
			data.secret = command.secret;
			command.setSenderId(_id);

			// Tell parent to wait for requestConnection answer
			var timer : ConditionalTimer = new ConditionalTimer(5.0,
				_parent.checkFlag.bind("c:" + RequestConnection.getId() + ":" + command.secret),
				_parent.removeFlag.bind("c:" + RequestConnection.getId() + ":" + command.secret),
				function () {
					data.socket.close();
					_connectionCandidates.remove(data);
				});
			_parent.addConditionalTimer(timer);

			// Send it
			sendCommand(command, data);
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Does the sending to connected clients and candidates.
	 * @return {Void}
	 */
	private function doSendStep() : Void
	{
		// Send to candidates first
		for (candidate in _connectionCandidates)
		{
			// Send leftover bytes
			TryCatchMacros.tryCatchBlockedOk("host->client candidate sending",
				function() {
					sendLeftoverBytes(candidate);
				},
				function() {
					candidate.socket.close();
					_connectionCandidates.remove(candidate);
					throw "";
				}
		 	);
		}

		// Send to clients
		_outCommandsMutex.acquire();
		var commands : Array<Command> = _outCommands.splice(0, _outCommands.length);
		_outCommandsMutex.release();
		for (client in _connectedClients)
		{
			// Send commands, mind sending only to correct recipient
			var index : Int = commands.length -1;
			while (index >= 0)
			{
				if (commands[index].getRecipientId() == client.id)
				{
					TryCatchMacros.tryCatchBlockedOk("host->client command sending",
						function() {
							sendCommand(commands[index], client);
						},
						function() {
							client.socket.close();
							_connectedClients.remove(client);
							throw "";
						}
				 	);
				}
			}

			// Send leftover bytes
			TryCatchMacros.tryCatchBlockedOk("host->client leftover sending",
				function() {
					sendLeftoverBytes(client);
				},
				function() {
					client.socket.close();
					_connectedClients.remove(client);
					throw "";
				}
		 	);
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Does the listening to connected clients and candidates.
	 * @return {Void}
	 */
	private function doListenStep() : Void
	{
		// Listen to candidates first
		for (candidate in _connectionCandidates)
		{

		}
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
	 * Checks if the passed client data is identical to one of the connected clients.
	 * @param  {ExtendedClientData} p_data The data to check.
	 * @return {Bool}
	 */
	public function isClientConnected(p_data : ExtendedClientData) : Bool
	{
		for (client in _connectedClients)
		{
			if (client.socket.peer().host.toString() == p_data.socket.peer().host.toString() &&
				client.socket.peer().port == p_data.socket.peer().port)
			{
				return true;
			}
		}
		return false;
	}

}
