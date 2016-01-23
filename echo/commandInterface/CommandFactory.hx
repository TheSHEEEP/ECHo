package echo.commandInterface;

/**
 * This class will create instances of Commands for you.
 * @type {[type]}
 */
class CommandFactory
{
	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Singleton definition.
	 */
	private static var _instance : CommandFactory = null;
	private function new() {}
	public static function getInst() : CommandFactory
	{
		if (_instance == null)
		{
			_instance = new CommandFactory();
		}
		return _instance;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Will create a command instance from the passed ID.
	 * Will return null if the ID is unknown.
	 * @param  {Int}  p_id The command ID.
	 * @return {Void}
	 */
	public function createCommand(p_id : Int) : Command
	{
		// Is the ID even known?
		var theClass : Class<Command> = CommandRegister.getInst().getCommandClass(p_id);
		if (theClass == null)
		{
			return null;
		}

		var inst : Command = Type.createInstance(theClass, []);
		return inst;
	}
}
