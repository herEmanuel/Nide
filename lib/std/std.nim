import tables
import ../../src/evaluator/obj
from strformat import fmt

#I/O functions for the standard library

proc raiseError(err: string): Obj = 
    return Obj(objType: objError, error: "Evaluation error: {err}".fmt)

proc log*(args: varargs[Obj]): Obj = 
    if args.len == 0:
        return raiseError("expected 1 argument or more, got 0")

    for arg in args:
        case arg.objType:
        of objString:
            write(stdout, arg.strValue)
        of objInt:
            write(stdout, arg.intValue)
        of objFloat:
            write(stdout, arg.floatValue)
        of objBool:
            write(stdout, arg.boolValue)
        else:
            return raiseError("can not use {arg.objType} as an argument for log".fmt)

    return NULL

var DefaultObjects* = {
    "console": {
        "log": log
    }.toTable
}.toTable

proc prompt*(args: varargs[Obj]): Obj = 
    if args.len > 1:
        return raiseError("prompt can not use more than one argument")

    if args.len != 0:
        discard log(args)

    var input = readLine(stdin)

    return Obj(objType: objString, strValue: input)

var Builtin* = {
    "prompt": prompt
}.toTable

