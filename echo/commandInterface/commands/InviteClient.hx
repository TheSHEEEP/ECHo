package echo.commandInterface.commands;

import echo.commandInterface.Command;
import echo.util.InputBytes;
import echo.util.OutputBytes;

/**
 * Message sent to a new socket when the host accept's it.
 * @type {[type]}
 */
class InviteClient extends Command
{
	public var hostId 	: Int = -1;
	public var secret	: Int = -1;

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @return {[type]}
	 */
    public function new()
    {
		super("inviteClient");
    }

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Write the command's data.
	 * @param  {BytesBuffer} p_outBuffer The buffer to fill.
	 * @return {Void}
	 */
	override public function writeCommandData(p_outBuffer :OutputBytes) : Void
	{
		p_outBuffer.writeInt32(hostId);
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
		hostId = p_inBuffer.readInt32();
		secret = p_inBuffer.readInt32();
	}
}
