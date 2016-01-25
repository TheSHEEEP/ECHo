package echo.base.threading;

import sys.net.Socket;
import sys.net.Host;
import haxe.Timer;
import haxe.io.Error;
import haxe.CallStack;
import echo.base.data.ExtendedClientData;
import echo.util.TryCatchMacros;

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
				TryCatchMacros.tryCatchBlockedOk( "client doHostConnection", function() {
					doHostConnection();
				},
				shutdown);
			}

			// Send to host step
			TryCatchMacros.tryCatchBlockedOk( "client doSendStep", function() {
				doSendStep();
			},
			shutdown);

			// Receive from host step
			TryCatchMacros.tryCatchBlockedOk( "client doListenStep", function() {
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
	 * Shuts down the client connection.
	 * @return {Void}
	 */
	override private function doShutdownInternal() : Void
	{
		super.doShutdownInternal();
		_isConnected = false;

		if (ECHo.logLevel >= 5) trace("Client threaded connection shut down.");
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Will attempt to connect to a host.
	 * @return {Void}
	 */
	public function doHostConnection() : Void
	{
		_mainSocket.setTimeout(1.0);
		_mainSocket.connect(_mainHost, _port);
		_mainSocket.setBlocking(false);
		_isConnected = true;

		if (ECHo.logLevel >= 5) trace("Successfully established socket connection to host.");
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Send commands & remaining bytes to the host.
	 * @return {Void}
	 */
	public function doSendStep() : Void
	{
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Listen to incoming commands from the host.
	 * @return {Void}
	 */
	public function doListenStep() : Void
	{
		// Try to receive as many commands as possible
		receiveCommands(_hostData);
	}
}
