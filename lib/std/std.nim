import tables, numbers, strutils
import ../../src/evaluator/obj
from strformat import fmt

#I/O functions for the standard library

proc raiseError(err: string): Obj = 
    return Obj(objType: objError, error: "Evaluation error: {err}".fmt)

proc std_log*(args: varargs[Obj]): Obj = 
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

proc std_prompt*(args: varargs[Obj]): Obj = 
    if args.len > 1:
        return raiseError("prompt can not use more than one argument")

    if args.len != 0:
        discard std_log(args)

    try:
        var input = readLine(stdin)
        return Obj(objType: objString, strValue: input)
    except:
        return raiseError("could not read from the console")

proc std_parseInt*(args: varargs[Obj]): Obj = 
    if args.len != 1:
        return raiseError("expected one argument for parseInt, got {args.len} instead".fmt)
        
    var res: Obj

    try:
        res = Obj(objType: objInt, intValue: parseInt(args[0].strValue))
    except ValueError:
        return raiseError("argument passed to parseInt is not an int")

    return res

proc std_parseFloat*(args: varargs[Obj]): Obj = 
    if args.len != 1:
        return raiseError("expected one argument for parseFloat, got {args.len} instead".fmt)
    
    var res: Obj

    try:
        res = Obj(objType: objFloat, floatValue: parseFloat(args[0].strValue))
    except ValueError:
        return raiseError("argument passed to parseFloat is not a float")

    return res

var 
    DefaultObjects* = {
        "console": {
            "log": std_log
        }.toTable
    }.toTable

    Builtin* = {
        "prompt": std_prompt,
        "parseInt": std_parseInt,
        "parseFloat": std_parseFloat
    }.toTable

    ObjectMethods* = {
        objInt, objFloat: {
            "toString": numbers_toString
        }.toTable,
    }.toTable

