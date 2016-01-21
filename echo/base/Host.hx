package echo.base;

import echo.base.threading.HostConnection;
import cpp.vm.Thread;

/**
 * Host class.
 * Used to listen on a port, handle incoming connections, command handling, etc.
 * @type {[type]}
 */
class Host extends ClientHostBase
{

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @param  {String = "0.0.0.0"} p_inaddr The accepted incoming addresses. Default will allow everyone to connect.
	 * @param  {Int    = 20301}     p_port   The port to listen at.
	 * @return {[type]}
	 */
    public function new(p_maxConn : Int = 5, p_inaddr : String = "0.0.0.0", p_port : Int = 20301)
    {
		super();

        // Create the host thread
        _connection = new HostConnection(p_inaddr, p_port, p_maxConn);
        _thread = Thread.create(_connection.threadFunc);
    }

    //------------------------------------------------------------------------------------------------------------------
    /**
     * Updates the host, executing commands (aka calling their callbacks).
     * @return {Void}
     */
    override public function update() : Void
    {
		super.update();
    }
}
