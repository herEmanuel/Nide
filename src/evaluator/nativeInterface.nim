import dynlib, obj, tables, terminal

type
    moduleFunction = proc(args: varargs[Obj]): Obj {.cdecl.}
    initFunction = proc(): Table[string, moduleFunction] {.stdcall.}

const 
    initFunctionName = "NideModuleInit"

proc raiseError(error: string) = 
        styledEcho fgRed, "Error: ", fgWhite, error
        system.quit(0)

proc getLibFunctions*(path: string): Table[string, moduleFunction] = 
    var lib = loadLib(path)
   
    if lib == nil:
        raiseError("The dll could not be found")

    var initFunc: initFunction
    
    try:
        #cast is unsafe here
        initFunc = cast[initFunction](lib.checkedSymAddr(initFunctionName))
    except:
        raiseError("Module's init function could not be found")
    
    var functions = initFunc()
    
    #TODO: find a way to unload the dll after
    return functions




