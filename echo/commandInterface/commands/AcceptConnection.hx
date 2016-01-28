package echo.commandInterface.commands;

import echo.commandInterface.Command;
import echo.util.InputBytes;
import echo.util.OutputBytes;

/**
 * Command sent in case the host accepts a new client.
 * @type {[type]}
 */
class AcceptConnection extends Command
{
	public var clientId 		: Int = -1;
	public var newIdentifier 	: String = null;

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @return {[type]}
	 */
    public function new()
    {
		super("acceptConnection");
    }

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Write the command's data.
	 * @param  {BytesBuffer} p_outBuffer The buffer to fill.
	 * @return {Void}
	 */
	override public function writeCommandData(p_outBuffer :OutputBytes) : Void
	{
		p_outBuffer.writeInt32(clientId);
		if (newIdentifier != null)
		{
			p_outBuffer.writeString(newIdentifier);
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Read the command's data.
	 * @param  {InputBytes} p_inBuffer The buffer to read from.
	 * @return {Void}
	 */
	override public function readCommandData(p_inBuffer :InputBytes) :Void
	{
		clientId = p_inBuffer.readInt32();
		if (p_inBuffer.position < p_inBuffer.length)
		{
			newIdentifier = p_inBuffer.readString(0);
		}
	}
}
