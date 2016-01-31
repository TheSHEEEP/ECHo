package echo.commandInterface;

import echo.base.data.ExtendedClientData;
import echo.util.InputBytes;
import echo.util.OutputBytes;

/**
 * The base class for a command.
 * @type {[type]}
 */
#if !macro
@:build(echo.util.CommandBuildMacro.addGetId())
@:autoBuild(echo.util.CommandBuildMacro.addGetId(true))
#end
class Command
{
	private var _name 			: String = "";
	private var _recipientId	: Int = -1;
	private var _senderId		: Int = -1;
	private var _timestamp		: Float = 0.0;

	private var _clientData 	: ExtendedClientData = null;

	public var errorMsg : String = "";

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @param  {String} p_name The name of the command.
	 * @return {[type]}
	 */
	public function new(p_name : String)
	{
		_name = p_name;
		getId();
		setTimestampCurrent();
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Returns the name of this command.
	 * @return {String}
	 */
	public inline function getName() : String
	{
		return _name;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Sets the ID of the sender.
	 * @param  {Int}  p_id The ID of the sender.
	 * @return {Void}
	 */
	public function setSenderId(p_id : Int) : Void
	{
		_senderId = p_id;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Returns the ID of the sender.
	 * @return {Int}
	 */
	public function getSenderId() : Int
	{
		return _senderId;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Sets the ID of the recipient.
	 * @param  {Int}  p_id The ID of the recipient.
	 * @return {Void}
	 */
	public function setRecipientId(p_id : Int) : Void
	{
		_recipientId = p_id;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Returns the ID of the recipient.
	 * @return {Int}
	 */
	public function getRecipientId() : Int
	{
		return _recipientId;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Set the timestamp of this command.
	 * @param  {Float} p_timestamp The timestamp in milliseconds.
	 * @return {Void}
	 */
	public function setTimestamp(p_timestamp : Float) : Void
	{
		_timestamp = p_timestamp;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Will set the timestamp to the current time.
	 * @return {Void}
	 */
	public function setTimestampCurrent() : Void
	{
		_timestamp = haxe.Timer.stamp();
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Returns the timestamp of this command (in milliseconds).
	 * @return {Float}
	 */
	public function getTimestamp() : Float
	{
		return _timestamp;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Sets the ClientData this command was received from.
	 * @param  {ExtendedClientData} p_clientData The ClientData this command was received from.
	 * @return {Void}
	 */
	public inline function setData(p_clientData : ExtendedClientData) : Void
	{
		_clientData = p_clientData;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Gets the ClientData this command was received from.
	 * @return {ClientData}
	 */
	public inline function getData() : ExtendedClientData
	{
		return _clientData;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Writes the basic data to the passed buffer.
	 * @param  {BytesOutput} p_outBuffer The buffer to fill.
	 * @return {Void}
	 */
	public inline function writeBaseData(p_outBuffer : OutputBytes) : Void
	{
		p_outBuffer.writeInt32(_recipientId);
		p_outBuffer.writeInt32(_senderId);
		p_outBuffer.writeFloat(_timestamp);
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * [readBaseData description]
	 * @param  {BytesInput} p_inBuffer [description]
	 * @return {Void}
	 */
	public inline function readBaseData(p_inBuffer : InputBytes) : Void
	{
		_recipientId = p_inBuffer.readInt32();
		_senderId = p_inBuffer.readInt32();
		_timestamp = p_inBuffer.readFloat();
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Writes the command specific data.
	 * Implement this in the actual commands!
	 * @param  {BytesBuffer} p_outBuffer The buffer to fill.
	 * @return {Void}
	 */
	public function writeCommandData(p_outBuffer : OutputBytes) : Void
	{
		// Implement in subclass
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Reads the command's specific data.
	 * @param  {BytesInput} p_inBuffer The buffer to read from.
	 * @return {Void}
	 */
	public function readCommandData(p_inBuffer : InputBytes) : Void
	{
		// Implement in subclass
	}
}
