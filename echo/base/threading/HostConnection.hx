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
			doAcceptStep();

			// Sending to clients step
			doSendStep();

			// Listening to clients step
			doListenStep();

			// Sleep
			currentTickTime = Timer.stamp() - startTime;
			sleepTime = _tickTime - currentTickTime;
			if (sleepTime > 0.0)
			{
				Sys.sleep(sleepTime);
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Do the step of accepting/rejecting incoming connections.
	 * @return {Void}
	 */
	private function doAcceptStep() : Void
	{
		try
		{
			// Accept an incoming connection
			var connectedClient : Socket = _mainSocket.accept();
			connectedClient.setFastSend(true);
			connectedClient.setBlocking(false);
			var data : ExtendedClientData = new ExtendedClientData();
			data.ip = connectedClient.peer().host.toString();
			data.socket = connectedClient;

			trace("Incoming connection from " + connectedClient.peer().host.toString() + " on port "
					+ connectedClient.peer().port);

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

				// Send invitation message
				var command : InviteClient = new InviteClient();
				sendCommand(command, data);
			}
		}
		catch (stringError : String)
		{
			switch (stringError)
			{
			case "Blocking":
				// Expected
			default:
				trace("Unexpected error in doAcceptStep 1: " + stringError);
			}
		}
		catch (error : Dynamic)
		{
			trace("Unexpected error in doAcceptStep 2: " + error);
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Does the sending to connected clients and candidates.
	 * @return {Void}
	 */
	private function doSendStep() : Void
	{
		try
		{
			// Send to candidates first
			for (candidate in _connectionCandidates)
			{
				// Send commands

				// Send leftover bytes
				sendLeftoverBytes(candidate);
			}

			// Send to clients
		}
		catch (stringError : String)
		{
			switch (stringError)
			{
			case "Blocking":
				// Expected
			default:
				trace("Unexpected error in doSendStep 1: " + stringError);
			}
		}
		catch (error : Dynamic)
		{
			trace("Unexpected error in doSendStep 2: " + error);
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Does the listening to connected clients and candidates.
	 * @return {Void}
	 */
	private function doListenStep() : Void
	{
		try
		{
			// Listen to candidates first
			for (candidate in _connectionCandidates)
			{

			}
		}
		catch (stringError : String)
		{
			switch (stringError)
			{
			case "Blocking":
				// Expected
			default:
				trace("Unexpected error in doListenStep 1: " + stringError);
			}
		}
		catch (error : Dynamic)
		{
			if (Std.is(error, Error))
			{
				if (cast(error, Error).equals(Blocked))
				{
					// Expected
				}
				else
				{
					trace("Unexpected error in host doListenStep 2: " + error);
				}
			}
			else
			{
				trace("Unexpected error in host doListenStep 3: " + error);
			}
		}
	}
}
