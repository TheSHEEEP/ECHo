package echo.commandInterface.commands;

import echo.util.InputBytes;
import echo.util.OutputBytes;
import echo.commandInterface.Command;

/**
 * Helper struct containing ID & ping of a client.
 * @type {[type]}
 */
class PingInfo
{
    public var id : Int = 0;
    public var ping : Int = 0;
    public function new(){}
}

/**
 * The command sent by the host to all connected clients containing ID & ping of each client.
 * @type {[type]}
 */
class PingList extends Command
{
	public var list	: Array<PingInfo> = new Array<PingInfo>();

    //------------------------------------------------------------------------------------------------------------------
    /**
     * Constructor
     * @return {[type]}
     */
    public function new()
    {
        super("pingList");
    }

    //------------------------------------------------------------------------------------------------------------------
	/**
	 * Write the command's data.
	 * @param  {BytesBuffer} p_outBuffer The buffer to fill.
	 * @return {Void}
	 */
	override public function writeCommandData(p_outBuffer : OutputBytes) : Void
	{
		p_outBuffer.writeInt32(list.length);
        for (i in 0 ... list.length)
        {
            p_outBuffer.writeInt32(list[i].id);
            p_outBuffer.writeInt32(list[i].ping);
        }
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Read the command's data.
	 * @param  {InputBytes} p_inBuffer The buffer to read from.
	 * @return {Void}
	 */
	override public function readCommandData(p_inBuffer : InputBytes) : Void
	{
		var size : Int = p_inBuffer.readInt32();
        for (i in 0 ... size)
        {
            var item : PingInfo = new PingInfo();
            item.id = p_inBuffer.readInt32();
            item.ping = p_inBuffer.readInt32();
            list.push(item);
        }
	}
}
