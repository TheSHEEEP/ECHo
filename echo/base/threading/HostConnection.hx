package echo.base.threading;

import sys.net.Socket;
import sys.net.Host;
import haxe.Timer;
import haxe.io.Error;
import echo.base.data.ClientData;
import echo.base.data.ExtendedClientData;
import echo.commandInterface.commands.RejectConnection;
import echo.commandInterface.commands.InviteClient;
import echo.commandInterface.commands.Ping;
import echo.commandInterface.commands.Pong;
import echo.util.TryCatchMacros;

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
	 * @return {[type]}
	 */
    public function new(p_inAddr : String, p_port : Int, p_maxConn : Int)
    {
		super(p_inAddr, p_port);

		_port = p_port;
		_maxConn = p_maxConn;

		// Create the host
		_mainSocket.setBlocking(true);
		_mainSocket.bind(_mainHost, _port);
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
			sendCommand(command, data, true);
			connectedClient.close();
		}
		else
		{
			// Add this one to the candidates
			_connectionCandidates.push(data);

			// Test
			trace("Host is sleeping now...");
			Sys.sleep(3.0);

			// Send invitation message
			var command : InviteClient = new InviteClient();
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
			// Send commands

			// Send leftover bytes
			TryCatchMacros.tryCatchBlockedOk("host client candidate sending", function() {
				sendLeftoverBytes(candidate);
				},
				_connectionCandidates.remove.bind(candidate)
		 	);
		}

		// Send to clients
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
}
