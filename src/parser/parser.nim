import ../lexer/lexer, ../lexer/tokens
import ast
import strformat
import tables
import terminal

type 
    Parser = object 
        l: Lexer
        currentToken: Token
        peekToken: Token

type 
    precedences = enum
        LOWEST, #lowest precedence
        OR_AND, # && and ||
        GL, # <, >, <= and >=
        SUM, # + and -
        DIVISION, # / and *
        PREFIX, #-, !
        CALL # teste()

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
    AND: ord(OR_AND),
    LPAREN: ord(CALL)
}.toTable

proc advance(p: var Parser) = 
    p.currentToken = p.peekToken
    p.peekToken = p.l.nextToken()

proc addError(p: var Parser, err: string) = 
    styledEcho fgRed, "Parsing error: ", fgWhite, "" & err
    system.quit(0)

proc expectToken(p: var Parser, tok: string): bool = 
    if p.peekToken.tokenType != tok:
        p.addError("expected token of type {tok}, got {p.peekToken.tokenType} instead".fmt)
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

    return p

proc parseExpression(p: var Parser, precedence: int): Node
proc parseLet(p: var Parser): Node
proc parseConst(p: var Parser): Node
proc parseReturn(p: var Parser): Node
proc parseNodes(p: var Parser): Node
proc parseIf(p: var Parser): Node
proc parseWhile(p: var Parser): Node
proc parseFor(p: var Parser): Node

proc parseProgram*(p: var Parser): Node = 

    p.currentToken = p.l.nextToken()
    p.peekToken = p.l.nextToken()

    var program = Node(nodeType: astProgram)

    while p.currentToken.tokenType != EOF:
        program.elements.add(p.parseNodes())
        p.advance()

    return program

proc parseNodes(p: var Parser): Node = 
    var node: Node

    case p.currentToken.tokenType
        of LET, VAR:
            node = p.parseLet()
        of CONST:
            node = p.parseConst()
        of RETURN:
            node = p.parseReturn()
        of IF:
            node = p.parseIf()
        of WHILE:
            node = p.parseWhile()
        of FOR: 
            node = p.parseFor()
        else:
            node = p.parseExpression(ord(LOWEST))

    return node

proc parseVariableBody(p: var Parser, nodeType: NodeType): Node = 
    var node = Node(nodeType: nodeType)

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

proc parseLet(p: var Parser): Node = 
    return p.parseVariableBody(astLet)

proc parseConst(p: var Parser): Node =
    return p.parseVariableBody(astConst)

proc parseReturn(p: var Parser): Node = 
    var node = Node(nodeType: astReturn)

    p.advance()

    node.value = p.parseExpression(ord(LOWEST))

    return node

proc parseBlock(p: var Parser): Node = 
    var node = Node(nodeType: astBlock)

    p.advance()

    while p.currentToken.tokenType != RBRACE:
        if p.currentToken.tokenType == EOF:
            p.addError("expected }, got EOF instead")
            return Node()

        node.elements.add(p.parseNodes())
        p.advance()

    return node

proc parseIf(p: var Parser): Node = 
    var node = Node(nodeType: astIf)

    if not p.expectToken(LPAREN):
        return Node()

    p.advance()

    node.add(p.parseExpression(ord(LOWEST)))

    if not p.expectToken(RPAREN):
        return Node()

    if not p.expectToken(LBRACE):
        return Node()

    node.add(p.parseBlock())

    if p.peekToken.tokenType == ELSE:
        p.advance()

        if not p.expectToken(LBRACE):
            return Node()

        node.add(p.parseBlock())

    return node

proc parseWhile(p: var Parser): Node = 
    var node = Node(nodeType: astWhile)

    if not p.expectToken(LPAREN):
        return Node()

    p.advance()

    node.add(p.parseExpression(ord(LOWEST)))

    if not p.expectToken(RPAREN):
        return Node()

    if not p.expectToken(LBRACE):
        return Node()

    node.add(p.parseBlock())

    return node

proc parseFor(p: var Parser): Node = 
    var node = Node(nodeType: astFor)

    if not p.expectToken(LPAREN):
        return Node()

    p.advance()

    node.add(p.parseNodes())
    #TODO: come back later to see if the code works
    if p.currentToken.tokenType != SEMICOLON:
        p.addError("expected a ;, got {p.currentToken.tokenType} instead".fmt)

    p.advance()

    node.add(p.parseExpression(ord(LOWEST)))

    if not p.expectToken(SEMICOLON):
        return Node()

    p.advance()

    node.add(p.parseExpression(ord(LOWEST)))

    if not p.expectToken(RPAREN):
        return Node()

    if not p.expectToken(LBRACE):
        return Node()

    node.add(p.parseBlock())

    return node

proc parseFunction(p: var Parser): Node = 
    var node = Node(nodeType: astFunction)

    if not p.expectToken(IDENTIFIER):
        return Node()
    
    node.add(Node(nodeType: astIdent, identifier: p.currentToken.value))

    if not p.expectToken(LPAREN):
        return Node()

    if p.peekToken.tokenType == RPAREN:
        p.advance() 

        if not p.expectToken(LBRACE):
            return Node()

        node.add(p.parseBlock())

        return node

    if p.peekToken.tokenType != IDENTIFIER:
        p.addError("expected an identifier, got {p.currentToken.tokenType} instead".fmt)
    
    p.advance()
    node.add(Node(nodeType: astIdent, identifier: p.currentToken.value))
    p.advance()

    while p.currentToken.tokenType == COMMA:
        p.advance()
       
        if p.currentToken.tokenType != IDENTIFIER:
            p.addError("expected an identifier, got {p.currentToken.tokenType} instead".fmt)

        node.add(Node(nodeType: astIdent, identifier: p.currentToken.value))

        if p.peekToken.tokenType == COMMA:
            p.advance()

    if not p.expectToken(RPAREN):
        return Node()

    if not p.expectToken(LBRACE):
        return Node()

    node.add(p.parseBlock())

    return node

proc parseFunctionCall(p: var Parser, left: Node): Node = 
    var node = Node(nodeType: astFuncCall)

    node.add(left)

    p.advance()

    if p.peekToken.tokenType == RPAREN:
        p.advance()
        return node

    p.advance()

    node.add(p.parseExpression(ord(LOWEST)))
    p.advance()

    while p.currentToken.tokenType == COMMA:
        p.advance()

        node.add(p.parseExpression(ord(LOWEST)))

        p.advance()

    return node

proc parseIdentifier(p: var Parser): Node = 
    var node = Node(nodeType: astIdent, identifier: p.currentToken.value)

    return node

proc parseInteger(p: var Parser): Node = 
    var node = Node(nodeType: astInt, intValue: p.currentToken.value)

    return node

proc parseFloat(p: var Parser): Node = 
    var node = Node(nodeType: astFloat, floatValue: p.currentToken.value)

    return node

proc parseString(p: var Parser): Node = 
    var node = Node(nodeType: astString, strValue: p.currentToken.value)

    return node

proc parseBool(p: var Parser): Node = 
    var node = Node(nodeType: astBool, boolValue: p.currentToken.value == "true")

    return node

proc parseTypeOf(p: var Parser): Node = 
    var node = Node(nodeType: astTypeOf)

    node.value = p.parseExpression(ord(LOWEST))

    return node

proc parseInfix(p: var Parser, left: Node): Node = 
    var node = Node(nodeType: astInfix)

    node.add(left)

    node.add(Node(nodeType: astOperator, operator: p.peekToken.value))

    var precedence = p.peekPrecedence()

    p.advance()
    p.advance()
 
    node.add(p.parseExpression(precedence))

    return node

proc parsePrefix(p: var Parser): Node = 
    var node = Node(nodeType: astPrefix)

    node.add(Node(nodeType: astOperator, operator: p.currentToken.value))

    p.advance()

    node.add(p.parseExpression(ord(PREFIX)))

    return node

proc parseGroupedExpression(p: var Parser): Node =
    p.advance()

    var expression = p.parseExpression(ord(LOWEST))

    if not p.expectToken(RPAREN):
        return Node()

    return expression

proc parsePostfixIfExists(p: var Parser, token: string, left: Node): Node = 
    case token
    of INC, DEC:
        var node = Node(nodeType: astPostfix)

        node.add(left)

        node.add(Node(nodeType: astOperator, operator: token))

        p.advance()
        
        return node
    else: 
        return left

proc parsePrefixNode(p: var Parser): Node = 
    case p.currentToken.tokenType
    of IDENTIFIER:
        return p.parseIdentifier()
    of LPAREN:
        return p.parseGroupedExpression()
    of INT:
        return p.parseInteger()
    of FLOAT:
        return p.parseFloat()
    of STRING:
        return p.parseString()
    of FUNCTION:
        return p.parseFunction()
    of TRUE, FALSE:
        return p.parseBool()
    of TYPEOF:
        return p.parseTypeOf()
    of NOT, MINUS:
        return p.parsePrefix()
    else:
        p.addError("{p.currentToken.tokenType} can not be used as an expression".fmt)
        return Node()

proc parseExpression(p: var Parser, precedence: int): Node = 

    var left: Node
  
    left = p.parsePrefixNode()

    left = p.parsePostfixIfExists(p.peekToken.tokenType, left)

    while p.peekToken.tokenType != SEMICOLON and p.peekPrecedence() > precedence:
        #TODO: check for other functions available to infix expressions
        case p.peekToken.tokenType
        of LPAREN:
            left = p.parseFunctionCall(left)
        else:
            left = p.parseInfix(left)

    return left