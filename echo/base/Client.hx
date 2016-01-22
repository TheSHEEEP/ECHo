package echo.base;

import cpp.vm.Thread;
import cpp.vm.Mutex;
import echo.base.threading.ClientConnection;
import echo.base.data.ClientData;

/**
 * Client class.
 * Used to connect to a host, command handling, callback handling, etc.
 * @type {[type]}
 */
class Client extends ClientHostBase
{
	private var _clientConnection	: ClientConnection;
	private var _clientThread		: Thread;

	private var _clientData : ClientData = new ClientData();

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @param  {String = "localhost"} p_hostAddr The address of the host.
	 * @param  {Int	= 20301}	   p_port	 The port to connect to.
	 * @return {[type]}
	 */
	public function new(p_identifier : String, p_hostAddr : String = "localhost", p_port : Int = 20301)
	{
		super();

		_clientData.identifier = p_identifier;
		
		_clientConnection = new ClientConnection(p_hostAddr, p_port);
		_clientConnection.setSharedData(_inCommands, _inCommandsMutex, _outCommands, _outCommandsMutex);
		_clientThread = Thread.create(_clientConnection.threadFunc);
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Returns true if the connection to the host is established.
	 * Note that this may lag behind one client tick due to threading.
	 * @return {Bool}
	 */
	public function isConnected() : Bool
	{
		return _clientConnection.isConnected();
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Returns the ClientData of this client.
	 * @return {ClientData}
	 */
	public inline function getClientData() : ClientData
	{
		return _clientData;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Updates the client, executing commands (aka calling their callbacks).
	 * @return {Void}
	 */
	override public function update() : Void
	{
		super.update();
	}
}
