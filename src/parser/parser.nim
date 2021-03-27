import ../lexer/lexer, ../lexer/tokens
import ast

type 
    Parser = object 
        l: Lexer
        currentToken: Token
        peekToken: Token


proc advance(p: var Parser) = 
    p.currentToken = p.l.nextToken()
    p.peekToken = p.l.nextToken()

proc newParser*(l: var Lexer): Parser = 
    var p = Parser(l: l)

    p.advance()

    return p

proc parseProgram*(): seq[Node] = 
    discard