package echo.util;

import easylog.EasyLogger;
import cpp.vm.Mutex;
import haxe.PosInfos;

/**
 * Singleton implementation of the EasyLogger.
 * @type {[type]}
 */
class Logger extends EasyLogger
{
	private static var _instance	: Logger = null;

	private var _mutex 	: Mutex = null;

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Get the instance of the logger.
	 * @return {Logger}
	 */
	public static function instance() : Logger
	{
		if (_instance == null)
		{
			_instance = new Logger();
		}

		return _instance;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @return {[type]}
	 */
    private function new()
    {
		super("logs/echo/[logType].log");
		_mutex = new Mutex();
    }

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Override function to allow thread-safe logging.
	 * @param  {String} p_type    The log type.
	 * @param  {String} p_message The message to log.
	 * @return {Void}
	 */
	override public function log(p_type : String, p_message : String, ?p_posInfo : PosInfos) : Void
	{
		_mutex.acquire();
		super.log(p_type, p_message, p_posInfo);
		_mutex.release();
	}
}
