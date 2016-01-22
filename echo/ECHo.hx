package echo;

import echo.commandInterface.CommandRegister;
import echo.commandInterface.commands.Ping;
import echo.commandInterface.commands.Pong;

/**
 * ECHo startup & shutdown class.
 * @type {[type]}
 */
class ECHo
{
    private function new(){}

	/**
	 * Log levels are:
	 * 0	- Nothing
	 * 1	- Errors
	 * 5	- Everything
	 * @type {Int}
	 */
	public static var logLevel : Int = 5;

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Initializes ECHo.
	 * Must be called before ECHo is usable.
	 * @return {Void}
	 */
	public static function init() : Void
	{
		// Register all predefined commands
		Reflect.callMethod(CommandRegister.getInst(),
							Reflect.field(CommandRegister.getInst(), "registerPredefinedCommand"),
							["ping", Type.getClassName(Ping)]);
		Reflect.callMethod(CommandRegister.getInst(),
							Reflect.field(CommandRegister.getInst(), "registerPredefinedCommand"),
							["pong", Type.getClassName(Pong)]);

		// Compile command IDs
		Reflect.callMethod(CommandRegister.getInst(),
							Reflect.field(CommandRegister.getInst(), "compileCommandIds"),
							[]);
	}
}
