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

var GC*: ptr GarbageCollector

proc collect(gc: ptr GarbageCollector): bool

proc gc_init*() = 
    var gc = cast[ptr GarbageCollector](alloc0(sizeof(GarbageCollector)))

    gc.head = nil
    gc.allocatedObjects = 0

    GC = gc

proc gc_stop*() = 
    dealloc(GC)

proc allocate*(gc: ptr GarbageCollector, size: int, st: ref SymbolTable): pointer = 
    
    if MAX_ALLOCATION_NUMBER == gc.allocatedObjects:
        if not gc.collect():
            #[ if it didn't collect anything, increase the max number 
            of objects that can be alocated, and allocate a new one ]#
            MAX_ALLOCATION_NUMBER = int(MAX_ALLOCATION_NUMBER / 2)
            return gc.allocate(size, st)
    
    gc.st = st

    var mem = cast[ptr AllocationHeader](alloc0(size + sizeof(AllocationHeader)))
    mem.marked = false
    mem.next = gc.head
    mem.size = uint(size)

    gc.head = mem
    gc.allocatedObjects += 1
    
    return mem

proc reallocate*(gc: ptr GarbageCollector, value: pointer, newSize: int): pointer =
    var newMem = realloc(value, newSize + sizeof(AllocationHeader))
    var valHeader = cast[ptr AllocationHeader](value)

    cast[ptr AllocationHeader](newMem).size = uint(newSize)

    var allocation = cast[ptr AllocationHeader](gc.head)
    var previous: ptr AllocationHeader

    while allocation != nil:
        if allocation == valHeader:
            if previous != nil:
                previous.next = newMem
            else:
                gc.head = newMem

            break
        else:
            previous = allocation
            allocation = cast[ptr AllocationHeader](allocation.next)

    return newMem

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
