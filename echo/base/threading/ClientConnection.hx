package echo.base.threading;

import sys.net.Socket;
import sys.net.Host;
import haxe.Timer;
import haxe.io.Error;
import echo.base.data.ExtendedClientData;

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

	private var _hostData	: ExtendedClientData = new ExtendedClientData();

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

		// Create the socket
		_mainSocket.setBlocking(true);
		_hostData.socket = _mainSocket;
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

	//------------------------------------------------------------------------------------------------------------------
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

			// Send to host step
			doSendStep();

			// Receive from host step
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
	 * Will attempt to connect to a host.
	 * @return {Void}
	 */
	public function doHostConnection() : Void
	{
		try
		{
			_mainSocket.setTimeout(1.0);
			_mainSocket.connect(_mainHost, _port);
			_mainSocket.setBlocking(false);
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

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Send commands & remaining bytes to the host.
	 * @return {Void}
	 */
	public function doSendStep() : Void
	{
		try
		{

		}
		catch (stringError : String)
		{
			switch (stringError)
			{
			case "Blocking":
				// Expected
			default:
				trace("Unexpected error in doSendStep 1: " + stringError + ".");
			}
		}
		catch (error : Dynamic)
		{
			trace("Unexpected error in doSendStep 2: " + error);
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Listen to incoming commands from the host.
	 * @return {Void}
	 */
	public function doListenStep() : Void
	{
		try
		{
			// Try to receive as many commands as possible
			receiveCommands(_hostData);
		}
		catch (stringError : String)
		{
			switch (stringError)
			{
			case "Blocking":
				// Expected
			default:
				trace("Unexpected error in doListenStep 1: " + stringError + ".");
			}
		}
		catch (error : Dynamic)
		{
			trace("Unexpected error in doListenStep 2: " + error);
		}
	}
}
