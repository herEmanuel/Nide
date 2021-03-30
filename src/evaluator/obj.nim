type
    ObjType* = enum
        objInt,
        objString,
        objFloat,
        objBool,
        objNull,
        objError,
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
        else:
            discard
