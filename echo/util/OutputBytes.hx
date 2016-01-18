package echo.util;

import haxe.io.BytesOutput;
import haxe.io.Bytes;

/**
 * Extends Haxe's own BytesOutput with some useful functionality.
 * @type {[type]}
 */
class OutputBytes extends BytesOutput
{
	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @return {[type]}
	 */
    public function new()
    {
		super();
    }

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Writes the string to the bytes.
	 * @param  {String} p_string The string to write.
	 * @return {Void}
	 */
	override public function writeString(p_string :String) :Void
	{
		writeInt32(Bytes.ofString(p_string).length);
		super.writeString(p_string);
	}
}
