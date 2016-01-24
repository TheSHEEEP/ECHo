package echo.util;

import haxe.macro.Context;

/**
 * Helps getting the current class name.
 * @type {[type]}
 */
class ClassNameHelper
{
    macro static public function getClassName():ExprOf<String>
	{
        return { expr: EConst(CString(Context.getLocalClass().toString())), pos: Context.currentPos() }
    }
}
