package echo.util;

import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * This macro makes sure that each child class of Command gets a static "getId()" field.
 * @type {[type]}
 */
class CommandBuildMacro
{
	//------------------------------------------------------------------------------------------------------------------
	/**
	 * Adds a "getId" function.
	 * @param  {Bool}   p_override If this is a child class and must thus use the "override" keyword a few times.
	 * @return {[type]}
	 */
    macro static public function addGetId(p_override : Bool = false) :Array<Field>
	{
		var fields : Array<Field> = Context.getBuildFields();

		// The static _id field
		var idField = {
			name : "_id",
			doc	: null,
			meta : [],
			access : [AStatic, APrivate],
			kind : FVar(macro : Int, macro -1),
			pos : Context.currentPos()
		};

		// The getId & setId function template
		var getIdBody = macro
		{
			return _id;
		};
		var setIdBody = macro
		{
			_id = p_id;
		};
		var getCommandIdBody = macro
		{
			return Reflect.callMethod(Type.getClass(this), Reflect.field(Type.getClass(this), "getId"), []);
		}

		// The getId function field
		var getIdField = {
			name : "getId",
			doc : "Returns the ID of this command type.",
			meta : [],
			access : [AStatic, APublic],
			kind : FFun({
				params : [],
				args : [],
				expr: getIdBody,
				ret : macro : Int
			}),
			pos : Context.currentPos()
		};

		// The getId function field
		var accessProperty = [APublic];
		if (p_override)
		{
			accessProperty = [APublic, AOverride];
		}
		var getCommandIdField = {
			name : "getCommandId",
			doc : "Returns the ID of this command type.",
			meta : [],
			access : accessProperty,
			kind : FFun({
				params : [],
				args : [],
				expr: getCommandIdBody,
				ret : macro : Int
			}),
			pos : Context.currentPos()
		};

		// The setId function field
		var setIdField = {
			name : "setId",
			doc : "DO NOT USE THIS. It is only here for macro magic.",
			meta : [],
			access : [AStatic, APrivate],
			kind : FFun({
				params : [],
				args : [{
					value: null,
					type: macro : Int,
					opt: false,
					name: "p_id"
				}],
				expr: setIdBody,
				ret : macro : Void
			}),
			pos : Context.currentPos()
		};

		fields.push(idField);
		fields.push(getIdField);
		fields.push(getCommandIdField);
		fields.push(setIdField);
		return fields;
	}
}
