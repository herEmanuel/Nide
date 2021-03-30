import tables
import obj

type
    SymbolTable* = object 
        symbols: Table[string, Obj]
        outer: Table[string, Obj]

proc newSt*(): SymbolTable = 
    var st = SymbolTable(symbols: initTable[string, Obj]())

    return st

proc getSymbol*(st: var SymbolTable, name: string): Obj = 
    if st.symbols.hasKey(name):
        return st.symbols[name]

    return nil

proc setSymbol*(st: var SymbolTable, name: string, value: Obj): Obj = 
    if st.symbols.hasKey(name):
        return nil

    st.symbols[name] = value
    return value

proc reassignSymbol*(st: var SymbolTable, name: string, newValue: Obj): Obj = 
    if not st.symbols.hasKey(name):
        return nil

    st.symbols[name] = newValue
    return newValue