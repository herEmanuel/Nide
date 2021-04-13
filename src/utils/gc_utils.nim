import ../evaluator/obj

type 
    AllocationHeader* = object 
        marked*: bool
        size*: uint
        next*: pointer

proc `+`*(p1: pointer, val: int): pointer = 
    return cast[pointer](cast[int](p1) + val)

proc arrayContent*(arr: pointer): ptr seq[Obj] = 
    return cast[ptr seq[Obj]](arr + sizeof(AllocationHeader))