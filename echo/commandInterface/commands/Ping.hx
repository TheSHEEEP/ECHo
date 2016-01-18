package echo.commandInterface.commands;

import echo.commandInterface.Command;

/**
 * Ping command for ping testing.
 * @type {[type]}
 */
class Ping extends Command
{
	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @return {[type]}
	 */
    public function new()
    {
        super("ping");
    }
}
