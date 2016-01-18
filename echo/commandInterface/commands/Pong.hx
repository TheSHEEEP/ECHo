package echo.commandInterface.commands;

import echo.commandInterface.Command;

/**
 * Pong command for ping testing.
 * @type {[type]}
 */
class Pong extends Command
{
	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @return {[type]}
	 */
    public function new()
    {
        super("pong");
    }
}
