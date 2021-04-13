import json 
from strformat import fmt
from os import getCurrentDir, commandLineParams
# import src/lexer/tokens
import src/lexer/lexer
import src/parser/parser
import src/evaluator/evaluator, src/evaluator/symbolTable, src/evaluator/gc 

proc repl() = 
    var st = newSt()
    gc_init()

    echo "Type \"quit\" to leave the repl"

    while true:
        write(stdout, ">> ")
        var input = readLine(stdin)

        if input == "quit":
            gc_stop()
            system.quit(0)

        var l = newLexer(input, nil)
        var p = newParser(l)
        var program = p.parseProgram()
        echo %program

        echo eval(program, st).repr

proc execFromFile(filePath: string) =
    let f = open(os.getCurrentDir() & "./{filePath}".fmt)
    var input = f.readLine()

    var st = newSt()
    gc_init()

    var l = newLexer(input, f)
    var p = newParser(l)

    var program = p.parseProgram()
    echo %program
    discard eval(program, st)

    gc_stop()
    f.close()

var args = os.commandLineParams()

if len(args) == 0:
    repl()
else:
    execFromFile(args[0])

# echo %program

# var tok = l.nextToken()

# while tok.tokenType != EOF:
#     echo "{tok}\n".fmt
#     tok = l.nextToken()

# echo "Input end"