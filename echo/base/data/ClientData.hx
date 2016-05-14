package echo.base.data;

import sys.net.Socket;
import echo.util.InputBytes;
import echo.util.OutputBytes;
import echo.util.RingBuffer;
import echo.util.Logger;

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
	public var ping 		: Int = 100;
	public var lastPings	: RingBuffer<Int> = new RingBuffer<Int>(5, 150);

	// This is only known to the host and the actual client itself, not sent around
	// 		- in the "clientList" command, for example
	public var secret		: Int = 0;

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @return {[type]}
	 */
    public function new()
    {
    }

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Writes the public (not secret!) data to the buffer.
	 * @param  {OutputBytes} p_outBuffer The buffer to write to.
	 * @return {Void}
	 */
	public function writeData(p_outBuffer : OutputBytes) : Void
	{
		p_outBuffer.writeInt32(id);
		p_outBuffer.writeString(identifier);
		p_outBuffer.writeInt8(cast isHost);
		p_outBuffer.writeInt32(ping);
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Reads the public (not secret!) data from the buffer.
	 * @param  {InputBytes} p_outBuffer The buffer to read from.
	 * @return {Void}
	 */
	public function readData(p_inBuffer : InputBytes) : Void
	{
		id = p_inBuffer.readInt32();
		identifier = p_inBuffer.readString(0);
		isHost = cast p_inBuffer.readInt8();
		ping = p_inBuffer.readInt32();
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Print the data.
	 * @return {Void}
	 */
	public function dump() : Void
	{
		Logger.instance().log("Info", '\nId: $id\nIdentifier: $identifier\nHost: $isHost\nPing: $ping');
	}
}
