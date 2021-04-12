import tables
import obj

type
    SymbolTable* = object 
        symbols*: Table[string, Obj]
        pointerSymbols*: seq[pointer]
        outer*: ref SymbolTable

proc newSt*(): ref SymbolTable = 
    var st = new(SymbolTable)
    st.outer = nil

    return st

proc newStWithOuter*(outer: ref SymbolTable): ref SymbolTable = 
    var st = new(SymbolTable)
    st.outer = outer

    return st

proc getSymbol*(st: ref SymbolTable, name: string): Obj = 
    if st.symbols.hasKey(name):
        return st.symbols[name]
    elif st.outer != nil:
        return st.outer.getSymbol(name)

    return nil

proc setSymbol*(st: ref SymbolTable, name: string, value: Obj): Obj = 
    if st.symbols.hasKey(name):
        return nil

    st.symbols[name] = value
    return value

proc reassignSymbol*(st: ref SymbolTable, name: string, newValue: Obj): Obj = 
    var symbol = st.getSymbol(name)
    if symbol == nil:
        return nil

    if symbol.objType == objConst:
        echo "Evaluation error: a constant can not be reassigned"
        system.quit(0)

    if not st.symbols.hasKey(name):
        var outer: ref SymbolTable
        if st.outer != nil:
            outer = st.outer

        discard outer.reassignSymbol(name, newValue)
    else:
        st.symbols[name] = newValue
    
    return newValue