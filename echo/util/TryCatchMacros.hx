package echo.util;

import haxe.macro.Expr;
import haxe.io.Error;

#if !macro
import echo.util.Logger;
#end

/**
 * Some practical try catch macros to prevent cluttering the files with this.
 * @type {[type]}
 */
class TryCatchMacros
{
	/**
	 * Will construct a try/catch around the passed expression, printing errors with the passed name.
	 * @param  {[type]}          p_name       The name to print on errors.
	 * @param  {[type]}          p_expression The expression to execute.
	 * @param  {[type]}          p_onError    The function to call in case of unexpected errors.
	 * @return {haxe.macro.Expr}
	 */
	macro static public function tryCatchBlockedOk(p_name, p_expression,
													p_onError) : haxe.macro.Expr
	{
		return macro
		{
			try
			{
				$p_expression();
			}
			catch (stringError : String)
			{
				switch (stringError)
				{
				case "Blocking":
					// Expected
				default:
					if (ECHo.logLevel >= 1)
					{
						var message : String = "Unexpected string error in " + $p_name + " 1: " + stringError + ".\n";
						message += "********** Callstack: **********" + "\n";
						message += haxe.CallStack.toString(haxe.CallStack.callStack()) + "\n";
						message += "********** Exception stack: **********" + "\n";
						message += haxe.CallStack.toString(haxe.CallStack.exceptionStack());
						echo.util.Logger.instance().log("Error", message);
					}
					$p_onError();
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
						if (ECHo.logLevel >= 1)
						{
							var message : String = "Unexpected error in " + $p_name + " 2: " + error + "\n";
							message += "********** Callstack: **********" + "\n";
							message += haxe.CallStack.toString(haxe.CallStack.callStack()) + "\n";
							message += "********** Exception stack: **********" + "\n";
							message += haxe.CallStack.toString(haxe.CallStack.exceptionStack());
							echo.util.Logger.instance().log("Error", message);
						}
						$p_onError();
					}
				}
				else if (Std.is(error, haxe.io.Eof))
				{
					if (ECHo.logLevel >= 1)
					{
						var message : String = "Error: End-Of-File in " + $p_name + "\n";
						message += "********** Callstack: **********" + "\n";
						message += haxe.CallStack.toString(haxe.CallStack.callStack()) + "\n";
						message += "********** Exception stack: **********" + "\n";
						message += haxe.CallStack.toString(haxe.CallStack.exceptionStack());
						echo.util.Logger.instance().log("Error", message);
					}
					$p_onError();
				}
				else
				{
					if (ECHo.logLevel >= 1)
					{
						var message : String = "Unexpected error in " + $p_name + " 3: " + Type.getClass(error) + ": " + error + "\n";
						message += "********** Callstack: **********" + "\n";
						message += haxe.CallStack.toString(haxe.CallStack.callStack()) + "\n";
						message += "********** Exception stack: **********" + "\n";
						message += haxe.CallStack.toString(haxe.CallStack.exceptionStack());
						echo.util.Logger.instance().log("Error", message);
					}
					$p_onError();
				}
			}
		}
 	}
}
