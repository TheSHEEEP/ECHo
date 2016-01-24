package echo.base.threading;

import sys.net.Host;
import sys.net.Socket;
import cpp.vm.Mutex;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.Error;
import echo.base.data.ExtendedClientData;
import echo.commandInterface.Command;
import echo.commandInterface.CommandFactory;
import echo.commandInterface.CommandRegister;
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

	private var _readBytes : Bytes = null;

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

		// Create the byte buffer to use for reading
		_readBytes = Bytes.alloc(2048);
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
		tempBuffer.writeInt32(p_command.getCommandId());
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
	 * @return {Void}gel
	 */
	private function receiveCommands(p_clientData : ExtendedClientData) : Void
	{
		var socket : Socket = p_clientData.socket;

		// Read as much data as possible (this is non-blocking, remember)
		var toRead : Int = 0;
		try
		{
			toRead = socket.input.readBytes(_readBytes, 0, 512);
		}
		catch (stringError : String)
		{
			switch (stringError)
			{
			case "Blocking":
				// Expected
			default:
				if (ECHo.logLevel >= 1) trace("Unexpected error in receiveCommands 1: " + stringError + ".");
			}
		}
		catch (error : Dynamic)
		{
			if (Std.is(error, Error))
			{
				if (cast(error, Error).equals(Blocked))
				{
					// Expected
				}
				else
				{
					if (ECHo.logLevel >= 1) trace("Unexpected error in receiveCommandsp 2: " + error);
				}
			}
			else
			{
				if (ECHo.logLevel >= 1) trace("Unexpected error in receiveCommands 3: " + error);
			}
		}

		// Read the input until everything is processes or at least stored
		var pos : Int = 0;
		while (toRead > 0)
		{
			// Do we expect some leftover data?
			if (p_clientData.expectedRestReceive > 0)
			{
				// If the inBytes are enough, we can finish the currently waited for command
				if (toRead >= p_clientData.expectedRestReceive)
				{
					p_clientData.recvBuffer.addBytes(_readBytes, pos, p_clientData.expectedRestReceive);

					// Store the command
					storeCommandFromData(p_clientData, null);

					// Advance position
					pos += p_clientData.expectedRestReceive;
					toRead -= p_clientData.expectedRestReceive;
					p_clientData.expectedRestReceive = 0;
				}
				// If the inBytes are not enough, just add them to the receive buffer and continue waiting
				else
				{
					p_clientData.recvBuffer.addBytes(_readBytes, pos, toRead);
					p_clientData.expectedRestReceive -= toRead;
					pos += toRead;
					toRead = 0;
				}
			}
			// If we are not waiting for rest of the data for the current command...
			else
			{
				// Make sure we have at least four bytes, as those tell the size of the entire command
				if (toRead >= 4)
				{
					p_clientData.expectedRestReceive = _readBytes.getInt32(0);
					if (ECHo.logLevel >= 5) trace("Expected command size: " + p_clientData.expectedRestReceive);
					pos += 4;
					toRead -= 4;

					// Do we even have all the data for the command?
					if (toRead >= p_clientData.expectedRestReceive)
					{
						// Store it!
						storeCommandFromData(p_clientData, _readBytes.sub(pos, p_clientData.expectedRestReceive));

						// Shorten the inBytes
						pos += p_clientData.expectedRestReceive;
						toRead -= p_clientData.expectedRestReceive;
					}
					// If not, just store in the client data's receive buffer
					else
					{
						p_clientData.recvBuffer = new BytesBuffer();
						p_clientData.recvBuffer.addBytes(_readBytes, 0, toRead);
						p_clientData.expectedRestReceive -= toRead;
						pos += toRead;
						toRead = 0;
					}
				}
				else
				{
					if (ECHo.logLevel >= 1)
					{
						trace("Error: Not even the first 4 bytes of command could be received. If this ever happens, it must be handled by ECHo. Which it does not currently do...");
					}
				}
			} // END new command begins
		} // END while inBytes.length > 0
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Will store the command from the passed data.
	 * @param  {ExtendedClientData} p_clientData The client data associated with this command.
	 * @param  {BytesBuffer}        p_bytes      The bytes to read from. Can be null to use p_clientData's recvBuffer instead. If they are not null, they MUST contain the entire command.
	 * @return {Void}
	 */
	private function storeCommandFromData(p_clientData : ExtendedClientData, p_bytes : Bytes) : Void
	{
		// Use the correct source
		var source : InputBytes;
		if (p_bytes != null)
		{
			source = new InputBytes(p_bytes);
		}
		else
		{
			source = new InputBytes(p_clientData.recvBuffer.getBytes());
		}
		p_clientData.recvBuffer = new BytesBuffer();

		// Get a command instance from the ID
		var id : Int = source.readInt32();
		var command : Command = CommandFactory.getInst().createCommand(id);
		if (command == null)
		{
			if (ECHo.logLevel >= 1) trace("Error: storeCommandFromData: Could not store incoming command, "
											+ "id unknown: " + id);
			return;
		}
		if (ECHo.logLevel >= 5) trace("Storing incoming command " + command.getName());

		// Read the data
		command.readBaseData(source);
		command.readCommandData(source);
		if (source.position != source.length)
		{
			if (ECHo.logLevel >= 2) trace("Warning: storeCommandFromData: there are unused bytes after "
											+ "reading input command: " + command.getName() + " "
											+ source.position + "/" + source.length);
		}

		// Store it
		_inCommands.push(command);
	}
}
