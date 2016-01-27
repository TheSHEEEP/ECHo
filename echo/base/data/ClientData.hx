package echo.base.data;

import sys.net.Socket;

/**
 * The data belonging to a single client.
 * This is just information about the client, and does not offer any connection functionality.
 * @type {[type]}
 */
class ClientData
{
	public var id			: Int = -1;
	public var identifier 	: String = "";
	public var isHost 		: Bool = false;
	public var isAdmin 		: Bool = false;
	public var ping 		: Int = 100;
	public var secret		: Int = 0;

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @return {[type]}
	 */
    public function new()
    {
    }
}
