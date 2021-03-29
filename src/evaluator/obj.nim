type
    ObjType* = enum
        objInt,
        objString,
        objFloat

type 
    Obj* = ref object 
        case objType*: ObjType
        of objInt:
            intValue*: int
        of objString:
            strValue*: string
        of objFloat:
            floatValue*: float
        
