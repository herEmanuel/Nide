import ../../src/evaluator/obj
import strutils
from strformat import fmt

proc raiseError(err: string): Obj = 
    return Obj(objType: objError, error: "Evaluation error: {err}".fmt)

proc numbers_toString*(args: varargs[Obj]): Obj =     
    if args.len != 1:
        return raiseError("invalid number of arguments to toString, expected 1, got {args.len} instead".fmt)

    var number = args[0]

    case number.objType
    of objInt:
        return Obj(objType: objString, strValue: intToStr(number.intValue))
    of objFloat:
        return Obj(objType: objString, strValue: formatFloat(number.floatValue))
    else:
        return NULL