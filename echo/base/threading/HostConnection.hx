package echo.base.threading;

import sys.net.Socket;
import sys.net.Host;
import haxe.Timer;
import haxe.io.Error;
import cpp.vm.Mutex;
import echo.base.data.ClientData;
import echo.base.data.ExtendedClientData;
import echo.commandInterface.Command;
import echo.commandInterface.commands.RejectConnection;
import echo.commandInterface.commands.RequestConnection;
import echo.commandInterface.commands.InviteClient;
import echo.commandInterface.commands.Ping;
import echo.commandInterface.commands.Pong;
import echo.commandInterface.commands.NotifyDisconnect;
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

	private var _connectionCandidates	: Array<ExtendedClientData> = null;
	private var _connectedClients 		: Array<ExtendedClientData> = null;
	private var _clientListMutex		: Mutex = null;

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
	 * Set additional shared data for the host.
	 * @param  {Array<ExtendedClientData>} p_candidates The array of client candidates.
	 * @param  {Array<ExtendedClientData>} p_clients    The array of connected clients.
	 * @return {Void}
	 */
	public function setHostSharedData(	p_candidates : Array<ExtendedClientData>,
										p_clients : Array<ExtendedClientData>,
										p_mutex : Mutex) : Void
	{
		_connectionCandidates = p_candidates;
		_connectedClients = p_clients;
		_clientListMutex = p_mutex;
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
			_clientListMutex.acquire();
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
			_clientListMutex.release();

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
		_clientListMutex.acquire();
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
		_clientListMutex.release();

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
		_mainSocket.setBlocking(false);
		var connectedClient : Socket = _mainSocket.accept();
		connectedClient.setFastSend(true);
		connectedClient.setBlocking(false);
		var data : ExtendedClientData = new ExtendedClientData();
		data.ip = connectedClient.peer().host.toString();
		data.socket = connectedClient;

		if (ECHo.logLevel >= 5) trace("Incoming connection from " + connectedClient.peer().host.toString()
									+ " on port " + connectedClient.peer().port);

		// If we have too many clients already connected, send the reject message and close
		var num : Int = _connectedClients.length;
		if (num >= _maxConn)
		{
			var command : RejectConnection = new RejectConnection();
			command.reason = RejectionReason.RoomIsFull;
			command.setSenderId(_id);
			sendCommand(command, data, true);
			if (ECHo.logLevel >= 4) trace("Closing connection due to full room.");
			connectedClient.close();
		}
		else
		{
			// Add this one to the candidates
			cast(_parent, echo.base.Host).addToCandidates(data);

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
					if (ECHo.logLevel >= 5) trace("Closing candidate connection due to no answer to inviteclient.");
					data.socket.close();
					_clientListMutex.acquire();
					_connectionCandidates.remove(data);
					_clientListMutex.release();
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
		_outCommandsMutex.acquire();
		var commands : Array<Command> = _outCommands.splice(0, _outCommands.length);
		_outCommandsMutex.release();

		// Send to candidates first
		for (candidate in _connectionCandidates)
		{
			// Send leftover bytes
			TryCatchMacros.tryCatchBlockedOk("host->client candidate sending",
				function() {
					sendLeftoverBytes(candidate);
				},
				function() {
					if (ECHo.logLevel >= 5) trace("Closing candidate connection due host->candidate sending error.");
					candidate.socket.close();
					_connectionCandidates.remove(candidate);
					throw "";
				}
		 	);

			// Keep sending rest bytes until all are sent, only then, send the next command
			if (candidate.sendBuffer.length != 0)
			{
				if (ECHo.logLevel >= 5) trace('Host: candidate still got bytes to send: ' + candidate.sendBuffer.length);
				continue;
			}

			// On the special recipient id, send to candidate
			for (command in commands)
			{
				if (command.getRecipientId() == -1000 && candidate.secret == command.getData().secret)
				{
					TryCatchMacros.tryCatchBlockedOk("host->client command sending",
						function() {
							sendCommand(command, candidate);
						},
						function() {
							if (ECHo.logLevel >= 5) trace("Closing candidate connection due special host->candidate sending error.");
							candidate.socket.close();
							_connectionCandidates.remove(candidate);
							throw "";
						}
					);
				}
			}
		}

		// Send to clients
		for (client in _connectedClients)
		{
			// Send leftover bytes
			TryCatchMacros.tryCatchBlockedOk("host->client leftover sending",
				function() {
					sendLeftoverBytes(client);
				},
				function() {
					removeClient(client);
					if (ECHo.logLevel >= 4) trace("Connected client removed due to error in connection.");
					throw "";
				}
		 	);

			// Keep sending rest bytes until all are sent, only then, send the next command
			if (client.sendBuffer.length != 0)
			{
				if (ECHo.logLevel >= 5) trace('Host: client ${client.id} still got bytes to send: ' + client.sendBuffer.length);
				continue;
			}

			// Send commands, mind sending only to correct recipient, 0 = to all clients
			for (command in commands)
			{
				if (command.getRecipientId() == client.id ||
					command.getRecipientId() == 0)
				{
					TryCatchMacros.tryCatchBlockedOk("host->client command sending",
						function() {
							sendCommand(command, client);
						},
						function() {
							removeClient(client);
							if (ECHo.logLevel >= 4) trace("Connected client removed due to error in connection.");
						}
				 	);
				}
			}
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
		var index : Int = _connectionCandidates.length - 1;
		while (index >= 0)
		{
			// Try to receive as many commands as possible
			if (!receiveCommands(_connectionCandidates[index]))
			{
				_connectionCandidates[index].socket.close();
				_connectionCandidates.splice(index, 1);
				if (ECHo.logLevel >= 4) trace("Connection candidate removed due to error in connection.");
			}
			index--;
		}

		// Listen to clients
		var index : Int = _connectedClients.length - 1;
		while (index >= 0)
		{
			// Try to receive as many commands as possible
			if (!receiveCommands(_connectedClients[index]))
			{
				removeClient(_connectedClients[index]);
				if (ECHo.logLevel >= 4) trace("Connected client removed due to error in connection.");
			}
			index--;
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Will close the socket connection to the passed client and remove it from the list.
	 * Also notifies the rest of the connected clients that a client has dropped.
	 * @param  {ExtendedClientData} p_client The client to remove.
	 * @return {Void}
	 */
	private function removeClient(p_client : ExtendedClientData) : Void
	{
		p_client.socket.close();
		_connectedClients.remove(p_client);

		// Send client removed message to notify other clients
		var command : NotifyDisconnect = new NotifyDisconnect();
		command.clientId = p_client.id;
		command.setSenderId(_id);
		command.setRecipientId(0);
		_parent.sendCommand(command);
	}
}
