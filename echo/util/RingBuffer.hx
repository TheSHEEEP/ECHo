package echo.util;

/**
 * A simple ring buffer able to take any number of elements of any type.
 * When a new value is inserted, the first value will be removed.
 * @type {[type]}
 */
class RingBuffer<T>
{
    private var _elements : Array<T> = null;

    //------------------------------------------------------------------------------------------------------------------
    /**
     * Constructor.
     * @param  {Int}    p_numElements  The number of elements in the ring.
     * @param  {T}      p_defaultValue The default value to place in the elements at start.
     * @return {[type]}
     */
    public function new(p_numElements : Int, p_defaultValue : T)
    {
        _elements = new Array<T>();

        for (i in 0 ... p_numElements)
        {
            _elements.push(p_defaultValue);
        }
    }

    //------------------------------------------------------------------------------------------------------------------
    /**
     * Adds the passed value, kicking out the current first one.
     * @param  {T}    p_value The value to add.
     * @return {Void}
     */
    public function add(p_value : T) : Void
    {
        // Remove the first element
        _elements.splice(0, 1);
        _elements.push(p_value);
    }

    //------------------------------------------------------------------------------------------------------------------
    /**
     * Array getter.
     * @param  {Int}    p_index The index.
     * @return {[type]}
     */
    @:arrayAccess
    public inline function get(p_index : Int)
    {
      return _elements[p_index];
    }

    //------------------------------------------------------------------------------------------------------------------
    /**
     * Array setter.
     * @param  {Int}    p_index The index.
     * @return {[type]}
     */
    @:arrayAccess
    public inline function set(p_index : Int, p_value : T)
    {
        _elements[p_index] = p_value;
        return p_value;
    }
}
