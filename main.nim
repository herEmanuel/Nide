import lexer/lexer
import lexer/tokens
import strformat

echo ">> "
var input = readLine(stdin)

var l = newLexer(input)

var tok = l.nextToken()

while tok.tokenType != EOF:
    echo "{tok}\n".fmt
    tok = l.nextToken()

echo "Input end"