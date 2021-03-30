import src/lexer/lexer
# import src/lexer/tokens
import src/parser/parser
import src/evaluator/evaluator
import src/evaluator/symbolTable
import strformat
import json

var st = newSt()

while true:
    echo ">> "
    var input = readLine(stdin)

    var l = newLexer(input)

    var p = newParser(l)

    var program = p.parseProgram()

    echo %eval(program, st)

# echo %program

# var tok = l.nextToken()

# while tok.tokenType != EOF:
#     echo "{tok}\n".fmt
#     tok = l.nextToken()

# echo "Input end"