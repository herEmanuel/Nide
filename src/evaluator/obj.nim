import ../parser/ast

type
    ObjType* = enum
        objInt,
        objString,
        objFloat,
        objBool,
        objArray, 
        objNull,
        objError,
        objReturn,
        objConst,
        objInfix,
        objPrefix,
        objFunction,
        objBuiltin,
        objObject

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
        of objBuiltin:
            name*: string
        of objArray:
            elements*: seq[Obj]
            length*: int
        else:
            discard

let 
    TRUE* = Obj(objType: objBool, boolValue: true)
    FALSE* = Obj(objType: objBool, boolValue: false)
    NULL* = Obj(objType: objNull)
