package echo.commandInterface.commands;

import echo.base.data.ClientData;
import echo.commandInterface.Command;
import echo.util.InputBytes;
import echo.util.OutputBytes;

/**
 * A list of all clients, sent around by the host.
 * @type {[type]}
 */
class ClientList extends Command
{
	public var clients	: Array<ClientData> = new Array<ClientData>();

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @return {[type]}
	 */
    public function new()
    {
		super("clientList");
    }

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Write the command's data.
	 * @param  {BytesBuffer} p_outBuffer The buffer to fill.
	 * @return {Void}
	 */
	override public function writeCommandData(p_outBuffer :OutputBytes) : Void
	{
		p_outBuffer.writeInt32(clients.length);
		for (client in clients)
		{
			client.writeData(p_outBuffer);
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
		var length : Int = p_inBuffer.readInt32();
		for (i in 0 ... length)
		{
			var data : ClientData = new ClientData();
			data.readData(p_inBuffer);
			clients.push(data);
		}
	}
}
