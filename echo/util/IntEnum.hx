import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * http://yal.cc/haxe-c-style-enum-macros/
 * @author YellowAfterlife
*/
class IntEnum
{
	public static macro function build():Array<Field>
    {
		switch (Context.getLocalClass().get().kind)
        {
			case KAbstractImpl(_.get() => { type: TAbstract(_.get() => { name: "Int" }, _) }): // OK
			default: Context.error(
				"This macro should only be applied to abstracts with base type Int",
				Context.currentPos());
		}
		var fields:Array<Field> = Context.getBuildFields();
		var nextIndex:Int = 0;
		var getNameCases:Array<Case> = [];
		for (field in fields)
        {
			var value:String = null;
			switch (field.kind)
            {
                // `var some = 1;`
				case FVar(t, { expr: EConst(CInt(int)) }):
                {
					value = int;
					nextIndex = Std.parseInt(value) + 1;
				};
                // `var some;`
				case FVar(t, null):
                {
					value = Std.string(nextIndex++);
					field.kind = FVar(t, { expr: EConst(CInt(value)), pos: field.pos });
				};
				default:
			}
			if (value != null)
            {
                getNameCases.push({
    				values: [{ expr: EConst(CInt(value)), pos: field.pos }],
    				expr: { expr: EConst(CString(field.name)), pos: field.pos }
    			});
            }
		} // for (field in fields)
		var getNameExpr:Expr = {
			expr: ESwitch(macro this, getNameCases, macro null),
			pos: Context.currentPos()
		};
		fields.push((macro class Magic {
			public function getName():String return $getNameExpr;
		}).fields[0]);
		return fields;
	}
}
