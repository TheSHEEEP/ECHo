package echo.base.threading;

import sys.net.Socket;
import sys.net.Host;
import haxe.Timer;
import haxe.io.Error;
import haxe.CallStack;
import echo.base.data.ExtendedClientData;
import echo.commandInterface.Command;
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
	 * @param  {ClientHostBase} p_parent  The parent of this connection thread.
	 * @return {[type]}
	 */
    public function new(p_hostAddr : String, p_port : Int, p_parent : ClientHostBase)
    {
		super(p_hostAddr, p_port, p_parent);

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
	 * Returns the "client" data of the host.
	 * @return {ExtendedClientData}
	 */
	public inline function getHostData() : ExtendedClientData
	{
		return _hostData;
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
				function() {
					trace("Could not connect to host, shutting down client.");
					shutdown();
				});
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
		_mainSocket.close();

		if (ECHo.logLevel >= 5) trace("Client threaded connection shut down.");
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Will attempt to connect to a host.
	 * @return {Void}
	 */
	public function doHostConnection() : Void
	{
		if (_doShutdown) return;

		_mainSocket.setTimeout(5.0);
		_mainSocket.connect(_mainHost, _port);
		_mainSocket.setBlocking(false);
		_isConnected = true;

		_hostData.ip = _mainSocket.peer().host.toString();
		_hostData.socket = _mainSocket;

		if (ECHo.logLevel >= 5) trace("Successfully established socket connection to host.");
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Send commands & remaining bytes to the host.
	 * @return {Void}
	 */
	public function doSendStep() : Void
	{
		if (_doShutdown) return;

		// Send leftover bytes
		sendLeftoverBytes(_hostData);

		// Keep sending rest bytes until all are sent, only then, send the next command
		if (_hostData.sendBuffer.length != 0)
		{
			if (ECHo.logLevel >= 5) trace('Client: still got bytes to send: ' + _hostData.sendBuffer.length);
			return;
		}

		// Send commands
		_outCommandsMutex.acquire();
		var commands : Array<Command> = _outCommands.splice(0, _outCommands.length);
		_outCommandsMutex.release();
		for (command in commands)
		{
			TryCatchMacros.tryCatchBlockedOk("sending command " + command.getName(),
				function() {
					sendCommand(command, _hostData);
				},
				doNothing
			);
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Listen to incoming commands from the host.
	 * @return {Void}
	 */
	public function doListenStep() : Void
	{
		if (_doShutdown) return;

		// Try to receive as many commands as possible
		if (!receiveCommands(_hostData))
		{
			shutdown();
			if (ECHo.logLevel >= 4) trace("Connection to host closed because of error (disconnect?).");
		}
	}
}
