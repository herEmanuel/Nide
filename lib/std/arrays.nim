import ../../src/evaluator/obj, ../../src/evaluator/gc
import ../../src/utils/gc_utils
from strformat import fmt

proc raiseError(err: string): Obj = 
    return Obj(objType: objError, error: "Evaluation error: {err}".fmt)

proc arrays_push*(args: varargs[Obj]): Obj = 
    if args.len != 2:
        return raiseError("expected one argument to push, got {args.len - 1} instead".fmt)
    
    var arr = args[0]
    var obj = args[1]

    var previousSize = int(cast[ptr AllocationHeader](arr.elements).size)
    
    var newMem = GC.reallocate(arr.elements, previousSize + sizeof(obj))
    newMem.arrayContent[].add(obj)

    arr.elements = newMem
    arr.length += 1

    return arr