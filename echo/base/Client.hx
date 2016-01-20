package echo.base;

import cpp.vm.Thread;
import echo.base.threading.ClientConnection;

/**
 * Client class.
 * Used to connect to a host, command handling, callback handling, etc.
 * @type {[type]}
 */
class Client
{
    private var _clientConnection   : ClientConnection;
    private var _clientThread       : Thread;

    //------------------------------------------------------------------------------------------------------------------
    /**
     * Constructor.
     * @param  {String = "localhost"} p_hostAddr The address of the host.
     * @param  {Int    = 20301}       p_port     The port to connect to.
     * @return {[type]}
     */
    public function new(p_hostAddr : String = "localhost", p_port : Int = 20301)
    {
        _clientConnection = new ClientConnection(p_hostAddr, p_port);
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
     * Updates the client, executing commands (aka calling their callbacks).
     * @return {Void}
     */
    public function update() : Void
    {
        // TODO: here
    }
}
