import json 
from strformat import fmt
from os import getCurrentDir, commandLineParams
# import src/lexer/tokens
import src/lexer/lexer
import src/parser/parser
import src/evaluator/evaluator, src/evaluator/symbolTable

proc repl() = 
    var st = newSt()

    echo "Type \"quit\" to leave the repl"

    while true:
        write(stdout, ">> ")
        var input = readLine(stdin)

        if input == "quit":
            system.quit(0)

        var l = newLexer(input, nil)
        var p = newParser(l)
        var program = p.parseProgram()
        echo %program

        discard eval(program, st)

proc execFromFile(filePath: string) =
    let f = open(os.getCurrentDir() & "./{filePath}".fmt)
    var input = f.readLine()

    var st = newSt()

    var l = newLexer(input, f)
    var p = newParser(l)

    var program = p.parseProgram()
    discard eval(program, st)

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