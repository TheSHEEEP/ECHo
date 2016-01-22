package echo.base.threading;

import sys.net.Host;
import sys.net.Socket;
import cpp.vm.Mutex;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import echo.base.data.ExtendedClientData;
import echo.commandInterface.Command;
import echo.util.InputBytes;
import echo.util.OutputBytes;

/**
 * Common class for host & client connections.
 * @type {[type]}
 */
class ConnectionBase
{
	private var _port		: Int = 0;
	private var _mainHost	: Host = null;
	private var _mainSocket : Socket = null;

	private var _tickTime	: Float = 0.05;

	private var _outCommands		: Array<Command> = null;
	private var _outCommandsMutex	: Mutex = null;
	private var _inCommands			: Array<Command> = null;
	private var _inCommandsMutex	: Mutex = null;

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @param  {String} p_addr The address to use.
	 * @param  {Int}    p_port The port to use.
	 * @return {[type]}
	 */
	public function new(p_addr : String, p_port : Int)
	{
		_port = p_port;

		// Create Socket & Host
		_mainSocket = new Socket();
		_mainHost = new Host(p_addr);
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Set the time a single tick shall take.
	 * @param  {Float} p_time [description]
	 * @return {Void}
	 */
	public inline function setTickTime(p_time : Float) : Void
	{
		_tickTime = p_time;
	}

	/**
	 * Sets the data to share between the threaded connection and the host/client class.
	 * @param  {Array<Command>} p_inCommands       Array for incoming commands.
	 * @param  {Mutex}          p_inCommandsMutex  Mutex for inCommands.
	 * @param  {Array<Command>} p_outCommands      Array for outgoing commands.
	 * @param  {Mutex}          p_outCommandsMutex Mutex for outCommands.
	 * @return {[type]}
	 */
	public inline function setSharedData(	p_inCommands : Array<Command>, p_inCommandsMutex : Mutex,
											p_outCommands : Array<Command>, p_outCommandsMutex : Mutex)
	{
		_inCommands = p_inCommands;
		_inCommandsMutex = p_inCommandsMutex;
		_outCommands = p_outCommands;
		_outCommandsMutex = p_outCommandsMutex;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Main thread function.
	 * @return {Void}
	 */
	public function threadFunc() : Void
	{

	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Sends the passed command on the socket.
	 * @param  {Command} p_command The command to send.
	 * @param  {ExtendedClientData}  p_clientData  The client data to be used for the sending.
	 * @param  {Bool}	p_forceFullSend	If a full send is forced, ignoring the usual non-blocking nature.
	 * @return {Void}
	 */
	private function sendCommand(	p_command : Command, p_clientData : ExtendedClientData,
									p_forceFullSend : Bool = false) : Void
	{
		// Create the command data
		var tempBuffer : OutputBytes = new OutputBytes();
		p_command.writeBaseData(tempBuffer);
		p_command.writeCommandData(tempBuffer);

		// Precede the whole data by its length
		var finalBuffer : OutputBytes = new OutputBytes();
		var tempBytes : Bytes = tempBuffer.getBytes();
		finalBuffer.writeInt32(tempBytes.length);
		finalBuffer.writeBytes(tempBytes, 0, tempBytes.length);

		// Send it
		var finalBytes : Bytes = finalBuffer.getBytes();
		var written : Int = p_clientData.socket.output.writeBytes(finalBytes, 0, finalBytes.length);
		if (written < finalBytes.length)
		{
			if (ECHo.logLevel >= 5)
			{
				trace("Did not write all bytes on sendCommand: " + written + "/" + finalBytes.length);
			}

			if (!p_forceFullSend)
			{
				// Add the rest to the send buffer
				p_clientData.sendBuffer.add(finalBytes.sub(written, finalBytes.length - written));
			}
			else
			{
				// Force a full send
				if (ECHo.logLevel >= 5)
				{
					trace("Forcing full send command write.");
				}
				p_clientData.socket.setBlocking(true);
				p_clientData.socket.setTimeout(10.0);
				p_clientData.socket.output.writeBytes(finalBytes, written, finalBytes.length - written);
				p_clientData.socket.setBlocking(false);
				p_clientData.socket.setTimeout(1.0);
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Sends the passed command on the socket.
	 * @param  {Command} p_command The command to send.
	 * @param  {ExtendedClientData}  p_clientData  The client data to be used for the sending.
	 * @param  {Bool}	p_forceFullSend	If a full send is forced, ignoring the usual non-blocking nature.
	 * @return {Void}
	 */
	private function sendLeftoverBytes(p_clientData : ExtendedClientData, p_forceFullSend : Bool = false) : Void
	{
		// Send the buffer
		var bytes : Bytes = p_clientData.sendBuffer.getBytes();
		p_clientData.sendBuffer = new BytesBuffer();
		var written : Int = p_clientData.socket.output.writeBytes(bytes, 0, bytes.length);
		if (written < bytes.length)
		{
			if (ECHo.logLevel >= 5)
			{
				trace("Did not write all bytes on sendLeftoverBytes: " + written + "/" + bytes.length);
			}

			if (!p_forceFullSend)
			{
				// Add the rest to the send buffer
				p_clientData.sendBuffer.add(bytes.sub(written, bytes.length - written));
			}
			else
			{
				// Force a full send
				if (ECHo.logLevel >= 5)
				{
					trace("Forcing full send leftovers write.");
				}
				p_clientData.socket.setBlocking(true);
				p_clientData.socket.setTimeout(1000.0);
				p_clientData.socket.output.writeBytes(bytes, written, bytes.length - written);
				p_clientData.socket.setBlocking(false);
				p_clientData.socket.setTimeout(0.05);
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Tries to read as many full commands as possible from the passed client data.
	 * @param  {ExtendedClientData} p_clientData The client data to use for the connection.
	 * @return {Void}
	 */
	private function receiveCommands(p_clientData : ExtendedClientData) : Void
	{
		var socket : Socket = p_clientData.socket;

		// Read as much data as possible
		var inBytes : Bytes = socket.input.readAll();

		// Got nothing, return
		if (inBytes.length == 0)
		{
			return;
		}

		// Do we expect some leftover data?
		if (p_clientData.expectedRestReceive > 0)
		{
			// TODO: here
		}
	}
}
