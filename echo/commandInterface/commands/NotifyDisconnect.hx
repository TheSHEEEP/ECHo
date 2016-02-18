package echo.commandInterface.commands;

import echo.commandInterface.Command;
import echo.util.InputBytes;
import echo.util.OutputBytes;

/**
 * Message sent to all other clients by the host when a client disconnected (either regularly or by error).
 * @type {[type]}
 */
class NotifyDisconnect extends Command
{
	public var clientId : Int = -1;

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @return {[type]}
	 */
    public function new()
    {
		super("notifyDisconnect");
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
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Read the command's data.
	 * @param  {InputBytes} p_inBuffer The buffer to read from.
	 * @return {Void}
	 */
	override public function readCommandData(p_inBuffer :InputBytes) : Void
	{
		clientId = p_inBuffer.readInt32();
	}
}
