package echo.base;

import echo.base.threading.HostConnection;
import cpp.vm.Thread;

/**
 * Host class.
 * Used to listen on a port, handle incoming connections, command handling, etc.
 * @type {[type]}
 */
class Host
{
    private var _hostConnection : HostConnection;
    private var _hostThread     : Thread;

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @param  {String = "0.0.0.0"} p_inaddr The accepted incoming addresses. Default will allow everyone to connect.
	 * @param  {Int    = 20301}     p_port   The port to listen at.
	 * @return {[type]}
	 */
    public function new(p_maxConn : Int = 5, p_inaddr : String = "0.0.0.0", p_port : Int = 20301)
    {
        // Create the host thread
        _hostConnection = new HostConnection(p_inaddr, p_port, p_maxConn);
        _hostThread = Thread.create(_hostConnection.threadFunc);
    }

    //------------------------------------------------------------------------------------------------------------------
    /**
     * Updates the host, executing commands (aka calling their callbacks).
     * @return {Void}
     */
    public function update() : Void
    {
        // TODO: here
    }
}
