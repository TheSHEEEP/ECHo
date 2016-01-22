package echo.base.data;

import sys.net.Socket;
import haxe.io.BytesBuffer;

/**
 * The additional fields in this class are only used internally by ECHo.
 * @type {[type]}
 */
class ExtendedClientData extends ClientData
{
	public var ip			: String = "";
	public var socket		: Socket = null;

	public var sendBuffer			: BytesBuffer = new BytesBuffer();
	public var recvBuffer			: BytesBuffer = new BytesBuffer();
	public var expectedRestReceive 	: Int = 0;

	/**
	 * Constructor.
	 * @return {[type]}
	 */
    public function new()
    {
		super();
    }
}
