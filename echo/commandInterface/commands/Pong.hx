package echo.commandInterface.commands;

import echo.commandInterface.Command;
import echo.util.InputBytes;
import echo.util.OutputBytes;

/**
 * Pong command for ping testing.
 * @type {[type]}
 */
class Pong extends Command
{
    public var pingTimestamp : Float = 0.0;

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @return {[type]}
	 */
    public function new()
    {
        super("pong");
    }

    //------------------------------------------------------------------------------------------------------------------
	/**
	 * Write the command's data.
	 * @param  {BytesBuffer} p_outBuffer The buffer to fill.
	 * @return {Void}
	 */
	override public function writeCommandData(p_outBuffer : OutputBytes) : Void
	{
		p_outBuffer.writeFloat(pingTimestamp);
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Read the command's data.
	 * @param  {InputBytes} p_inBuffer The buffer to read from.
	 * @return {Void}
	 */
	override public function readCommandData(p_inBuffer : InputBytes) :Void
	{
		pingTimestamp = p_inBuffer.readFloat();
	}
}
