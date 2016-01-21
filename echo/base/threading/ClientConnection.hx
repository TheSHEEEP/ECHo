package echo.base.threading;

import sys.net.Socket;
import sys.net.Host;
import haxe.Timer;
import haxe.io.Error;

/**
 * The class doing all of the client's socket interaction.
 * Use threadFunc in a thread.
 * The functionality is done in ticks. Each tick, there will be sending data to the host
 * and receiving data from the host. Then, the thread will sleep for the rest of the tick's time.
 * @type {[type]}
 */
class ClientConnection extends ConnectionBase
{
	private var _isConnected 	: Bool = false;

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @param  {String} p_hostAddr The address to connect to.
	 * @param  {Int}    p_port	   The port to connect at.
	 * @return {[type]}
	 */
    public function new(p_hostAddr : String, p_port : Int)
    {
		super(p_hostAddr, p_port);

		// Create the socket the host
		_mainSocket.setBlocking(true);
    }

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Returns true if connected to the host.
	 * Note that this may lag behind one client tick due to threading.
	 * @return {Bool}
	 */
	public inline function isConnected() : Bool
	{
		return _isConnected;
	}

	/**
	 * The client's main thread function.
	 * @return {Void}
	 */
	override public function threadFunc() : Void
	{
		// Main loop
		var startTime : Float = 0.0;
		var currentTickTime : Float = 0.0;
		var sleepTime : Float = 0.0;
		while (true)
		{
			startTime = Timer.stamp();

			// Connect to the host
			if (!_isConnected)
			{
				doHostConnection();
			}

			// Sleep
			currentTickTime = Timer.stamp() - startTime;
			sleepTime = _tickTime - currentTickTime;
			if (sleepTime > 0.0)
			{
				Sys.sleep(sleepTime);
			}
		}
	}

	/**
	 * Will attempt to connect to a host.
	 * @return {Void}
	 */
	public function doHostConnection() : Void
	{
		try
		{
			_mainSocket.setTimeout(1.0);
			_mainSocket.connect(_mainHost, _port);
			_isConnected = true;

			trace("Successfully connected to host.");
		}
		catch (stringError : String)
		{
			switch (stringError)
			{
			case "Blocking":
				// Expected
			default:
				trace("Unexpected error in doHostConnection 1: " + stringError + ".");
			}
		}
		catch (error : Dynamic)
		{
			trace("Unexpected error in doHostConnection 2: " + error);
		}
	}
}
