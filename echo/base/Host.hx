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
		_connection.setSharedData(_inCommands, _inCommandsMutex, _outCommands, _outCommandsMutex);
        _thread = Thread.create(_connection.threadFunc);
    }

    //------------------------------------------------------------------------------------------------------------------
    /**
     * Updates the host, executing commands (aka calling their callbacks).
	 * @param  {Float}  p_timeSinceLastFrame	The time since the last frame in seconds.
     * @return {Void}
     */
    override public function update(p_timeSinceLastFrame : Float) : Void
    {
		super.update(p_timeSinceLastFrame);
    }
}
