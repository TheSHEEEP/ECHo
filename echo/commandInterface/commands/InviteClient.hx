package echo.commandInterface.commands;

import echo.commandInterface.Command;

/**
 * Message sent to a new socket when the host accept's it.
 * @type {[type]}
 */
class InviteClient extends Command
{
	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @return {[type]}
	 */
    public function new()
    {
		super("inviteClient");
    }
}
