import ../lexer/lexer, ../lexer/tokens
import ast
import strformat
import tables

type 
    Parser = object 
        l: Lexer
        currentToken: Token
        peekToken: Token
        errors*: seq[string]

type 
    precedences = enum
        LOWEST, #lowest precedence
        OR_AND, # && and ||
        GL, # <, >, <= and >=
        SUM, # + and -
        DIVISION # / and *


var tokenPrecedence = {
    PLUS: ord(SUM),
    MINUS: ord(SUM),
    ASTERISK: ord(DIVISION),
    SLASH: ord(DIVISION),
    GREATER_THAN: ord(GL),
    LESS_THAN: ord(GL),
    GREATER_THAN_OR_EQUAL: ord(GL),
    LESS_THAN_OR_EQUAL: ord(GL),
    OR: ord(OR_AND),
    AND: ord(OR_AND)
}.toTable

proc advance(p: var Parser) = 
    p.currentToken = p.peekToken
    p.peekToken = p.l.nextToken()

proc addError(p: var Parser, err: string) = 
    p.errors.add("Parsing error: " & err)

proc expectToken(p: var Parser, tok: string): bool = 
    if p.peekToken.tokenType != tok:
        p.addError("expected token of type {tok}, got {p.currentToken} instead".fmt)
        return false 

    p.advance()
    return true

proc peekPrecedence(p: var Parser): int = 

    var tok = p.peekToken.tokenType

    if not tokenPrecedence.hasKey(tok):
        return ord(LOWEST)

    return ord(tokenPrecedence[tok])

proc newParser*(l: var Lexer): Parser = 
    var p = Parser(l: l)

    p.currentToken = l.nextToken()
    p.peekToken = l.nextToken()

    return p

proc parseLet(p: var Parser): Node
proc parseExpression(p: var Parser, precedence: int): Node

proc parseProgram*(p: var Parser): Node = 
    var program = Node(nodeType: astProgram)

    while p.peekToken.tokenType != EOF:
        
        case p.currentToken.tokenType
        of LET:
            program.elements.add(p.parseLet())
        else:
            program.elements.add(p.parseExpression(ord(LOWEST)))

    return program

proc parseLet(p: var Parser): Node = 
    var node = Node(nodeType: astLet)

    if not p.expectToken(IDENTIFIER):
        return Node()

    var name = Node(nodeType: astIdent, identifier: p.currentToken.value)
    node.add(name)

    if not p.expectToken(ASSIGN):
        return Node()

    p.advance()

    var value = p.parseExpression(ord(LOWEST))

    node.add(value)

    if p.peekToken.tokenType == SEMICOLON:
        p.advance()
    
    return node

proc parseIdentifier(p: var Parser): Node = 
    var node = Node(nodeType: astIdent, identifier: p.currentToken.value)

    return node

proc parseInteger(p: var Parser): Node = 
    var node = Node(nodeType: astInt, intValue: p.currentToken.value)

    return node

proc parseString(p: var Parser): Node = 
    var node = Node(nodeType: astString, strValue: p.currentToken.value)

    return node

proc parseBool(p: var Parser): Node = 
    var node = Node(nodeType: astBool, boolValue: p.currentToken.value == "true")

    return node

proc parseInfix(p: var Parser, left: Node): Node = 
    var node = Node(nodeType: astInfix)

    node.add(left)

    node.add(Node(nodeType: astOperator, operator: p.peekToken.value))

    var precedence = p.peekPrecedence()
    echo "infix current token: " & $p.currentToken
    p.advance()
    echo "infix current token: " & $p.currentToken
    p.advance()
    echo "infix current token: " & $p.currentToken
    echo "infix next token: " & $p.peekToken
    node.add(p.parseExpression(precedence))

    return node

proc parseGroupedExpression(p: var Parser): Node =
    p.advance()

    var expression = p.parseExpression(ord(LOWEST))

    if not p.expectToken(RPAREN):
        return Node()

    return expression

proc parseExpression(p: var Parser, precedence: int): Node = 

    var left: Node
    echo p.currentToken.tokenType
    case p.currentToken.tokenType
    of IDENTIFIER:
        left = p.parseIdentifier()
    of LPAREN:
        left = p.parseGroupedExpression()
    of INT:
        left = p.parseInteger()
    of STRING:
        left = p.parseString()
    # of IF:
    #     left = p.parseIf()
    # of FUNCTION:
    #     left = p.parseFunction()
    of TRUE, FALSE:
        left = p.parseBool()
    # of TYPEOF:
    #     left = p.parseTypeOf()
    else:
        p.addError("{p.currentToken.tokenType} can not be used as an expression".fmt)
        return Node()

    while p.peekToken.tokenType != SEMICOLON and p.peekPrecedence() > precedence:
        #TODO: check for other functions available to infix expressions
        left = p.parseInfix(left)
    
    return left