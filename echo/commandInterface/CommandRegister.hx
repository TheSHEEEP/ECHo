package echo.commandInterface;

import haxe.ds.ArraySort;
import haxe.ds.StringMap;

class CommandRegister
{
	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Singleton definition.
	 */
	private static var _instance : CommandRegister = null;
	private function new() {}
	public static function getInst() : CommandRegister
	{
		if (_instance == null)
		{
			_instance = new CommandRegister();
		}
		return _instance;
	}


	//------------------------------------------------------------------------------------------------------------------
	private var _commandNameToClassName 			: StringMap<String> = new StringMap<String>();
	private var _predefinedCommandNameToClassName 	: StringMap<String> = new StringMap<String>();
	private var _commandNameToId					: StringMap<Int> = new StringMap<Int>();

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Register a new command with its name.
	 * @param  {String} p_commandName 	The name of the command.
	 * @param  {String} p_className		The class name to be used for the command. Use Type.getClassName().
	 * @return {Void}
	 */
	public function registerCommand(p_commandName : String, p_className : String) : Void
	{
		_commandNameToClassName.set(p_commandName, p_className);
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Returns the command Id for the command with the passed name.
	 * @param  {String} p_commandName The command name to look for.
	 * @return {Int}	Returns -1 if no command with the name was found.
	 */
	public function getCommandId(p_commandName : String) : Int
	{
		if (_commandNameToId.exists(p_commandName))
		{
			return _commandNameToId.get(p_commandName);
		}
		return -1;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Register a new predefined command with its name.
	 * @param  {String} p_commandName 	The name of the command.
	 * @param  {String} p_className		The class name to be used for the command. Use Type.getClassName().
	 * @return {Void}
	 */
	private function registerPredefinedCommand(p_commandName : String, p_className : String) : Void
	{
		_predefinedCommandNameToClassName.set(p_commandName, p_className);
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Compiles all registered command
	 * @return {Void} [description]
	 */
	private function compileCommandIds () : Void
	{
		// Pre-defined commands first
		compileCommandIdsInternal(_predefinedCommandNameToClassName, true);

		// User-defined commands next
		compileCommandIdsInternal(_commandNameToClassName, false);

		// Dump infos
		if (ECHo.logLevel >= 5)
		{
			trace("These are our commands -> ids: ");
			trace(_commandNameToId.toString());
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Internal function to compile command IDs and assign them to the command classes.
	 * @param  {StringMap<String>} p_namesAndClassNames The StringMap to work on.
	 * @return {Void}
	 */
	private function compileCommandIdsInternal(p_namesAndClassNames : StringMap<String>, p_predefined : Bool) : Void
	{
		// Get the names
		var nameArray : Array<String> = new Array<String>();
		for (key in p_namesAndClassNames.keys())
		{
			nameArray.push(key);
		}

		// Sort the Array
		ArraySort.sort(nameArray,
			function (left : String, right : String) : Int
			{
				left = left.toLowerCase();
				right = right.toLowerCase();
				if (left == right) 		return 0;
				else if (left > right) 	return 1;
				else 					return -1;
			}
		);

		// Apply the IDs to the command names
		var offset : Int = p_predefined ? 0 : 300;
		for (i in 0 ... nameArray.length)
		{
			_commandNameToId.set(nameArray[i], i + offset);
		}
	}
}
