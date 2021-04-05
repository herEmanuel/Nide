import symbolTable
from strformat import fmt

#NOTE: GENERICS DONT WORK FOR THIS SHIT!!!!!!!!!!

const 
    MAX_ALLOCATION_NUMBER = 10

type 
    Allocation*[T] = object
        marked: bool
        value: T
        next: pointer

type
    GarbageCollector = object 
        head: pointer
        allocatedObjects: int
        st: ref SymbolTable

proc collect[T](gc: ptr GarbageCollector)

proc gcInit*(st: ref SymbolTable): ptr GarbageCollector = 
    var gc = cast[ptr GarbageCollector](alloc0(sizeof(GarbageCollector)))
    gc.head = nil
    gc.allocatedObjects = 0
    gc.st = st
    
    return gc

proc allocate*[T](gc: ptr GarbageCollector, value: T): ptr Allocation[T] = 
    if gc.allocatedObjects == MAX_ALLOCATION_NUMBER:
        gc.collect[:T]()
    # echo sizeof(Allocation[T])
    var newAllocation = cast[ptr Allocation[T]](alloc0(sizeof(Allocation[T])))

    newAllocation.value = value
    newAllocation.marked = false
    newAllocation.next = cast[ptr Allocation[T]](gc.head)

    gc.head = newAllocation
    gc.allocatedObjects += 1
    echo value
    echo newAllocation.repr
    
    return newAllocation

proc free*(gc: ptr GarbageCollector, allocation: ptr Allocation) = 
    dealloc(allocation)

proc mark[T](gc: ptr GarbageCollector) = 
    for allocation in gc.st.pointerSymbols:
        var allocPtr = cast[ptr Allocation[T]](allocation)
        allocPtr.marked = true

proc sweep[T](gc: ptr GarbageCollector) = 
    var allocation = cast[ptr Allocation[T]](gc.head)
    var previous: ptr Allocation[T]

    while allocation != nil:
        echo allocation.value
        if not allocation.marked:
            var freeMemory = allocation
            
            if previous == nil:
                gc.head = allocation.next
            else:
                previous.next = allocation.next

            allocation = cast[ptr Allocation[T]](allocation.next)

            gc.free(freeMemory)

            gc.allocatedObjects -= 1
        else:
            allocation.marked = false
            previous = allocation
            allocation = cast[ptr Allocation[T]](allocation.next)

proc collect[T](gc: ptr GarbageCollector) = 
    var totalObjects = gc.allocatedObjects
    gc.mark[:T]()
    gc.sweep[:T]()
    echo "Collected {totalObjects - gc.allocatedObjects} objects".fmt