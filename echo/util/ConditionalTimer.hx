package echo.util;

/**
 * A timer that will run for a certain time, or until the condition is fulfilled.
 * is met or not met.
 * @type {[type]}
 */
class ConditionalTimer
{
	private var _condition 	: Void->Bool = null;
	private var _trueFunc 	: Void->Void = null;
	private var _falseFunc 	: Void->Void = null;

	private var _timeToRun 	: Float = 0.0;
	private var _time 		: Float = 0.0;
	private var _done		: Bool = false;

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Constructor.
	 * @param  {Float}      p_time      The time the timer will run.
	 * @param  {Void->Bool} p_condition The function that acts as the condition.
	 * @param  {Void->Void} p_trueFunc  The function to be called in case of a true condition. May be null.
	 * @param  {Void->Void} p_falseFunc The function to be called in case the time runs out. May be null.
	 * @return {[type]}
	 */
    public function new(p_time : Float, p_condition : Void->Bool,
						p_trueFunc : Void->Void, p_falseFunc : Void->Void)
    {
		_condition = p_condition;
		_trueFunc = p_trueFunc;
		_falseFunc = p_falseFunc;

		_timeToRun = p_time;
    }

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Updates the timer.
	 * @param  {Float} p_timeSinceLastFrame The time since the last frame in seconds.
	 * @return {Void}
	 */
	public function update(p_timeSinceLastFrame : Float) : Void
	{
		check();
		
		_time += p_timeSinceLastFrame;

		if (_time >= _timeToRun)
		{
			_falseFunc != null ? _falseFunc() : null;
			_done = true;
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Returns true when the timer is done.
	 * @return {Bool}
	 */
	public inline function isDone() : Bool
	{
		return _done;
	}

	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Will do the condition checking and callback calling.
	 * @return {Void}
	 */
	private function check() : Void
	{
		if (_condition())
		{
			_trueFunc != null ? _trueFunc() : null;
			_done = true;
		}
	}
}
