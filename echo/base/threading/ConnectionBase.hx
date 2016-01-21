package echo.base.threading;

import sys.net.Host;
import sys.net.Socket;

/**
 * Common class for host & client connections.
 * @type {[type]}
 */
class ConnectionBase
{
	private var _port		: Int = 0;
	private var _mainHost	: Host = null;
	private var _mainSocket : Socket = null;

	private var _tickTime	: Float = 0.05;

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @param  {String} p_addr The address to use.
	 * @param  {Int}    p_port The port to use.
	 * @return {[type]}
	 */
	public function new(p_addr : String, p_port : Int)
	{
		_port = p_port;

		// Create Socket & Host
		_mainSocket = new Socket();
		_mainHost = new Host(p_addr);
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Set the time a single tick shall take.
	 * @param  {Float} p_time [description]
	 * @return {Void}
	 */
	public inline function setTickTime(p_time : Float) : Void
	{
		_tickTime = p_time;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Main thread function.
	 * @return {Void}
	 */
	public function threadFunc() : Void
	{

	}
}
