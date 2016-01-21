package echo.base.threading;

import sys.net.Socket;
import sys.net.Host;
import haxe.Timer;
import haxe.io.Error;

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

			// Listening to clients step

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

			trace("Incoming connection from " + connectedClient.peer().host.toString() + " on port "
					+ connectedClient.peer().port);
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
}
