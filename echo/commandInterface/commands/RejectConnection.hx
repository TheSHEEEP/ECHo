package echo.commandInterface.commands;

import echo.commandInterface.Command;
import echo.util.OutputBytes;
import echo.util.InputBytes;

/**
 * Reasons for a rejected connection.
 * @type {[type]}
 */
@:enum
abstract RejectionReason(Int)
{
	var NoError = 0;
	var RoomIsFull	= 1;
	var AlreadyConnected = 2;
}


/**
 * Sent by the host when the connection of a client is rejected.
 * @type {[type]}
 */
class RejectConnection extends Command
{
	public var reason : RejectionReason = NoError;

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @return {[type]}
	 */
    public function new()
    {
		super("rejectConnection");
    }

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Write the command's data.
	 * @param  {BytesBuffer} p_outBuffer The buffer to fill.
	 * @return {Void}
	 */
	override public function writeCommandData(p_outBuffer :OutputBytes) : Void
	{
		p_outBuffer.writeInt32(cast reason);
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Read the command's data.
	 * @param  {InputBytes} p_inBuffer The buffer to read from.
	 * @return {Void}
	 */
	override public function readCommandData(p_inBuffer :InputBytes) :Void
	{
		reason = cast p_inBuffer.readInt32();
	}
}
