import ../parser/ast

type
    ObjType* = enum
        objInt,
        objString,
        objFloat,
        objBool,
        objNull,
        objError,
        objReturn,
        objConst,
        objInfix,
        objPrefix,
        objFunction

type 
    Obj* = ref object 
        case objType*: ObjType
        of objInt:
            intValue*: int
        of objString:
            strValue*: string
        of objFloat:
            floatValue*: float
        of objBool:
            boolValue*: bool
        of objError:
            error*: string
        of objConst:
            constValue*: Obj
        of objFunction:
            funcName*: Node
            funcParams*: seq[string]
            funcBody*: Node
        of objReturn:
            returnValue*: Obj
        else:
            discard
