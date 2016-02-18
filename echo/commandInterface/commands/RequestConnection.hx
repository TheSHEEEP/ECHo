package echo.commandInterface.commands;

import echo.commandInterface.Command;
import echo.util.InputBytes;
import echo.util.OutputBytes;

/**
 * A request to the server to accept this client as a new connection.
 * @type {[type]}
 */
class RequestConnection extends Command
{
	public var identifier 	: String = "";
	public var secret		: Int = -1;

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @return {[type]}
	 */
    public function new()
    {
		super("requestConnection");
    }

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Write the command's data.
	 * @param  {BytesBuffer} p_outBuffer The buffer to fill.
	 * @return {Void}
	 */
	override public function writeCommandData(p_outBuffer :OutputBytes) : Void
	{
		p_outBuffer.writeString(identifier);
		p_outBuffer.writeInt32(secret);
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Read the command's data.
	 * @param  {InputBytes} p_inBuffer The buffer to read from.
	 * @return {Void}
	 */
	override public function readCommandData(p_inBuffer :InputBytes) : Void
	{
		identifier = p_inBuffer.readString(0);
		secret = p_inBuffer.readInt32();
	}
}
