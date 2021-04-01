import tables
import obj

type
    SymbolTable* = object 
        symbols: Table[string, Obj]
        outer: ref SymbolTable

proc newSt*(): ref SymbolTable = 
    var st = new(SymbolTable)

    st.symbols = initTable[string, Obj]()

    return st

proc newStWithOuter*(outer: ref SymbolTable): ref SymbolTable = 
    var st = new(SymbolTable)

    st.symbols = initTable[string, Obj]()
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
    if not st.symbols.hasKey(name):
        return nil

    if st.symbols[name].objType == objConst:
        echo "Evaluation error: a constant can not be reassigned"
        system.quit(0)

    st.symbols[name] = newValue
    return newValue