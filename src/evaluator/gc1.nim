import symbolTable 
from strformat import fmt 

var
    MAX_ALLOCATION_NUMBER = 15

type 
    AllocationHeader* = object 
        marked: bool
        size*: uint
        next: pointer

type
    GarbageCollector* = object
        head: pointer
        allocatedObjects: int
        st: ref SymbolTable

proc `+`(p1: pointer, val: int): pointer = 
    return cast[pointer](cast[int](p1) + val)

proc collect(gc: ptr GarbageCollector): bool

proc gc_init*(): ptr GarbageCollector = 
    var gc = cast[ptr GarbageCollector](alloc0(sizeof(GarbageCollector)))

    gc.head = nil
    gc.allocatedObjects = 0

    return gc

proc gc_stop(gc: ptr GarbageCollector) = 
    dealloc(gc)

proc allocate*(gc: ptr GarbageCollector, sizePerUnit: int, units: int, st: ref SymbolTable): pointer = 
    
    if MAX_ALLOCATION_NUMBER == gc.allocatedObjects:
        if not gc.collect():
            #[ if it didn't collect anything, increase the max number 
            of objects that can be alocated, and allocate a new one ]#
            MAX_ALLOCATION_NUMBER = int(MAX_ALLOCATION_NUMBER / 2)
            return gc.allocate(sizePerUnit, units, st)
    
    gc.st = st

    var mem = cast[ptr AllocationHeader](alloc0(sizePerUnit * units + sizeof(AllocationHeader)))
    mem.marked = false
    mem.next = gc.head
    mem.size = uint(sizePerUnit * units)

    gc.head = mem
    gc.allocatedObjects += 1
    
    return mem

proc free*(gc: ptr GarbageCollector, allocation: pointer) = 
    dealloc(allocation)

proc mark(gc: ptr GarbageCollector, st: ref SymbolTable) = 
    for alloc in st.pointerSymbols:
        var header = cast[ptr AllocationHeader](alloc)
        header.marked = true

    if st.outer != nil:
        gc.mark(st.outer)

proc sweep(gc: ptr GarbageCollector) = 
    var allocation = cast[ptr AllocationHeader](gc.head)
    var previous: ptr AllocationHeader

    while allocation != nil:
        if not allocation.marked:
            var freeMem = allocation
            if previous != nil:
                previous.next = allocation.next
            else:
                gc.head = allocation.next
            allocation = cast[ptr AllocationHeader](allocation.next)

            gc.free(freeMem)
            gc.allocatedObjects -= 1

        else:
            allocation.marked = false
            previous = allocation
            allocation = cast[ptr AllocationHeader](allocation.next)

proc collect(gc: ptr GarbageCollector): bool = 
    echo "Starting to collect the garbage"
    var totalObjects = gc.allocatedObjects

    gc.mark(gc.st)
    gc.sweep()

    echo "Collected {totalObjects - gc.allocatedObjects} objects".fmt
    return totalObjects != gc.allocatedObjects
