package echo.commandInterface;

/**
 * The base class for a command.
 * @type {[type]}
 */
class Command
{
	private var _name 	: String = "";
	private var _id 	: Int = -1;

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @param  {String} p_name The name of the command.
	 * @return {[type]}
	 */
	public function new(p_name :String)
	{
		_name = p_name;
		getId();
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Returns the ID of this command.
	 * @return {Int}
	 */
	public inline function getId() :Int
	{
		// If not yet done, get the actual id from the register
		if (_id == -1)
		{
			_id = CommandRegister.getInst().getCommandId(_name);
		}
		return _id;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Returns the name of this command.
	 * @return {String}
	 */
	public inline function getName() :String
	{
		return _name;
	}

	public inline function writeBaseData
	// TODO: here 	- think of way to put & get data in binary format
	// 				- including separation between always-data & custom data
}
