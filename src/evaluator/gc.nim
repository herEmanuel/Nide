import symbolTable
from strformat import fmt

const
    FREE_LIST_ALLOCATION_AMOUNT = 10

type 
    Allocation* = object
        marked: bool
        value: int
        next: ptr Allocation

type
    GarbageCollector = object 
        head: ptr Allocation
        freeList: array[FREE_LIST_ALLOCATION_AMOUNT, ptr Allocation]
        allocatedObjects: int
        st: ref SymbolTable

proc collect(gc: ptr GarbageCollector)
proc allocateOutsideFreeList(gc: ptr GarbageCollector, value: int): ptr Allocation

proc gcInit*(st: ref SymbolTable): ptr GarbageCollector = 
    var gc = cast[ptr GarbageCollector](alloc0(sizeof(GarbageCollector)))
    gc.head = nil
    gc.allocatedObjects = 0
    gc.st = st
    
    for i in 0..9:
        gc.freeList[i] = cast[ptr Allocation](alloc0(sizeof(Allocation)))
        echo gc.freeList[i].repr
        
    echo "Allocated 10 objects"
    return gc

proc allocate*(gc: ptr GarbageCollector, value: int): ptr Allocation = 
    var newAllocation: ptr Allocation

    if gc.allocatedObjects == FREE_LIST_ALLOCATION_AMOUNT:
        echo "All the free list is already allocated, starting the garbage collector"
        #collect the garbage
        gc.collect()
    
        if gc.allocatedObjects == FREE_LIST_ALLOCATION_AMOUNT:
            echo "Could not collect any object, allocating outside the free list now"
            return gc.allocateOutsideFreeList(value) 

    for i in 0..9:
        if gc.freeList[i] == nil:
            continue

        newAllocation = gc.freeList[i]
        gc.freeList[i] = nil
        break

    newAllocation.value = value
    newAllocation.marked = false
    newAllocation.next = gc.head

    gc.head = newAllocation
    gc.allocatedObjects += 1
    
    return newAllocation

proc allocateOutsideFreeList(gc: ptr GarbageCollector, value: int): ptr Allocation = 
    var allocation = cast[ptr Allocation](alloc0(sizeof(Allocation)))
    allocation.marked = false
    allocation.value = value
    allocation.next = gc.head

    gc.head = allocation
    echo allocation.repr
    return allocation

proc free*(allocation: ptr Allocation) = 
    dealloc(allocation)

proc mark(gc: ptr GarbageCollector) = 
    for allocation in gc.st.pointerSymbols:
        var allocPtr = cast[ptr Allocation](allocation)
        allocPtr.marked = true

proc sweep(gc: ptr GarbageCollector) = 
    var allocation = gc.head
    var previous: ptr Allocation

    while allocation != nil:
        if not allocation.marked:
            var freeMemory = allocation
            previous.next = allocation.next
            allocation = allocation.next

            freeMemory.zeroMem(sizeof(Allocation))

            for i in 0..9:
                if gc.freeList[i] == nil:
                    gc.freeList[i] = freeMemory
                    break

            gc.allocatedObjects -= 1
        else:
            allocation.marked = false
            previous = allocation
            allocation = allocation.next

proc collect(gc: ptr GarbageCollector) = 
    var totalObjects = gc.allocatedObjects
    gc.mark()
    gc.sweep()
    echo "Collected {totalObjects - gc.allocatedObjects} objects".fmt