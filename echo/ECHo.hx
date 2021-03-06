package echo;

import haxe.Timer;
import echo.commandInterface.CommandRegister;
import echo.commandInterface.commands.Ping;
import echo.commandInterface.commands.Pong;
import echo.commandInterface.commands.PingList;
import echo.commandInterface.commands.InviteClient;
import echo.commandInterface.commands.RejectConnection;
import echo.commandInterface.commands.AcceptConnection;
import echo.commandInterface.commands.RequestConnection;
import echo.commandInterface.commands.ClientList;
import echo.commandInterface.commands.NotifyDisconnect;
import echo.util.Logger;

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
	 * 2 	- Warnings
	 * 4 	- Important infos
	 * 5	- Verbose - EVERYTHING
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
		registerPredefinedCommand("ping", Ping);
        registerPredefinedCommand("pong", Pong);
		registerPredefinedCommand("pingList", PingList);
		registerPredefinedCommand("inviteClient", InviteClient);
		registerPredefinedCommand("rejectConnection", RejectConnection);
		registerPredefinedCommand("acceptConnection", AcceptConnection);
		registerPredefinedCommand("requestConnection", RequestConnection);
		registerPredefinedCommand("notifyDisconnect", NotifyDisconnect);
		registerPredefinedCommand("clientList", ClientList);

		// Compile command IDs
		Reflect.callMethod(CommandRegister.getInst(),
							Reflect.field(CommandRegister.getInst(), "compileCommandIds"),
							[]);

        // At least Windows requires to call this once for non-bs values
        Timer.stamp();
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Registers a predefined command.
	 * @param  {String}         p_name  The name of the command.
	 * @param  {Class<Dynamic>} p_class The class of the command.
	 * @return {Void}
	 */
	private static function registerPredefinedCommand(p_name : String, p_class : Class<Dynamic>) : Void
	{
		Reflect.callMethod(CommandRegister.getInst(),
							Reflect.field(CommandRegister.getInst(), "registerPredefinedCommand"),
							[p_name, Type.getClassName(p_class)]);
	}
}
