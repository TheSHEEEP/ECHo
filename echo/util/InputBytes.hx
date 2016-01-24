package echo.util;

import haxe.io.BytesInput;
import haxe.io.Bytes;

/**
 * Extends Haxe's own BytesInput with some useful functionality.
 * @type {[type]}
 */
class InputBytes extends BytesInput
{
	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @return {[type]}
	 */
    public function new(p_b : Bytes)
    {
		super(p_b, 0, p_b.length);
    }

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Reads the full next string from the buffer and returns it.
	 * @param p_offset {Int}	The offset to read from within the string.
	 * @return {String}
	 */
	override public function readString(p_offset : Int) : String
	{
		var retVal : String = "";
		var size : Int = readInt32();
		retVal = super.readString(size);

		// Apply offset
		if (p_offset > 0 && p_offset < retVal.length)
		{
			retVal = retVal.substr(p_offset);
		}

		return retVal;
	}
}
