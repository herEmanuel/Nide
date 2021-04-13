import ../../src/evaluator/obj, ../../src/evaluator/gc
from strformat import fmt

proc raiseError(err: string): Obj = 
    return Obj(objType: objError, error: "Evaluation error: {err}".fmt)

proc `+`(p1: pointer, val: int): pointer = 
    return cast[pointer](cast[int](p1) + val)

proc arrays_push*(args: varargs[Obj]): Obj = 
    if args.len != 2:
        return raiseError("expected one argument to push, got {args.len - 1} instead".fmt)
    
    var arr = args[0]
    var obj = args[1]

    var previousSize = int(cast[ptr AllocationHeader](arr.elements).size)
    echo previousSize
    var newMem = GC.reallocate(arr.elements, previousSize + sizeof(obj))
    echo cast[ptr AllocationHeader](newMem).repr
    echo sizeof(obj)
    echo previousSize + sizeof(obj)
    echo newMem == nil
    var arrArea = cast[ptr seq[Obj]](newMem + sizeof(AllocationHeader))[]
    arrArea.add(obj)

    arr.elements = newMem
    arr.length += 1

    return arr