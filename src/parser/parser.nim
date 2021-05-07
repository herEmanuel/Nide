import ../lexer/lexer, ../lexer/tokens
from strformat import fmt
import ast
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
        NEQUAL, # ==, !=
        GL, # <, >, <= and >=
        SUM, # + and -
        DIVISION, # / and *
        DOTEXPR, # console.log
        ARRACCESS, # x[y]
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
    LPAREN: ord(CALL),
    LSQBRACK: ord(ARRACCESS),
    EQUAL: ord(NEQUAL),
    NOT_EQUAL: ord(NEQUAL),
    DOT: ord(DOTEXPR)
}.toTable

proc advance(p: var Parser) = 
    p.currentToken = p.peekToken
    p.peekToken = p.l.nextToken()

proc advanceOnSemicolon(p: var Parser) = 
    if p.peekToken.tokenType == SEMICOLON:
        p.advance()

proc addError(p: var Parser, err: string) = 
    styledEcho fgRed, "Parsing error: ", fgWhite, "" & err
    styledEcho fgYellow, "Line: {p.l.line}".fmt
    system.quit(0)

proc expectToken(p: var Parser, tok: string) = 
    if p.peekToken.tokenType != tok:
        p.addError("expected token of type {tok}, got {p.peekToken.tokenType} instead".fmt)

    p.advance()

proc peekPrecedence(p: var Parser): int = 

    var tok = p.peekToken.tokenType

    if not tokenPrecedence.hasKey(tok):
        return ord(LOWEST)

    return ord(tokenPrecedence[tok])

proc newParser*(l: var Lexer): Parser = 
    var p = Parser(l: l)

    return p

proc parseExpression(p: var Parser, precedence: int): Node
proc parseImport(p: var Parser): Node 
proc parseExport(p: var Parser): Node
proc parseLet(p: var Parser): Node
proc parseConst(p: var Parser): Node
proc parseReassignment(p: var Parser): Node
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
        of IMPORT:
            node = p.parseImport()
        of EXPORT:
            node = p.parseExport()
        of LET, VAR:
            node = p.parseLet()
        of IDENTIFIER:
            if p.peekToken.tokenType == ASSIGN:
                node = p.parseReassignment()
                return node

            node = p.parseExpression(ord(LOWEST))
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

proc parseImport(p: var Parser): Node = 
    var node = Node(nodeType: astImport)

    if p.peekToken.tokenType == LBRACE:
        #import non default exports
        node.everything = false

        p.advance()
        p.advance()

        if p.currentToken.tokenType != IDENTIFIER:
            p.addError("expected an identifier, got {p.currentToken.tokenType} instead".fmt)

        node.imports.add(p.currentToken.value)

        if p.peekToken.tokenType == RBRACE:
            p.advance()
        else:
            p.expectToken(COMMA)

        while p.currentToken.tokenType == COMMA:
            p.advance()

            if p.currentToken.tokenType != IDENTIFIER:
                p.addError("expected an identifier, got {p.currentToken.tokenType} instead".fmt)

            node.imports.add(p.currentToken.value) 

            p.advance()


    elif p.peekToken.tokenType == ASTERISK:
        #import everything from a file
        node.everything = true

        p.advance()
        p.expectToken(AS)
        p.advance()

        if p.currentToken.tokenType != IDENTIFIER:
            p.addError("expected an identifier, got {p.currentToken.tokenType} instead".fmt)
        
        node.imports.add(p.currentToken.value)
    else:
        #import default export
        node.everything = false
        if p.peekToken.tokenType != IDENTIFIER:
            p.addError("expected an identifier, got {p.currentToken.tokenType} instead".fmt)

        p.advance()
        var defaultName = p.currentToken.value

        if p.peekToken.tokenType == AS:
            p.advance()
            p.advance()

            if p.currentToken.tokenType != IDENTIFIER:
                p.addError("expected an identifier, got {p.currentToken.tokenType} instead".fmt)
        
            node.defaultImport = Node(nodeType: astAs, original: defaultName, modified: p.currentToken.value)

        else:
            node.defaultImport = Node(nodeType: astAs, original: defaultName)

    p.advance()

    if p.currentToken.tokenType != FROM:
        p.addError("expected from, got {p.currentToken.tokenType} instead".fmt)

    p.advance()

    if p.currentToken.tokenType != STRING:
        p.addError("expected a string, got {p.currentToken.tokenType} instead".fmt)

    node.module = p.currentToken.value

    p.advanceOnSemicolon()

    return node

proc parseExport(p: var Parser): Node = 
    var node = Node(nodeType: astExport)
    var default = false

    p.advance()

    if p.currentToken.tokenType == DEFAULT:
        default = true
        p.advance()

    var res: Node

    case p.currentToken.tokenType
    of LET, VAR:
        res = p.parseLet()
    of CONST:
        res = p.parseConst()    
    else:
        res = p.parseExpression(ord(LOWEST))

    if default:
        node.defaultImport = res
    else:
        node.exportNode = res

    if p.peekToken.tokenType == SEMICOLON and p.currentToken.tokenType != SEMICOLON:
        p.advance()

    return node

proc parseVariableBody(p: var Parser, nodeType: NodeType): Node = 
    var node = Node(nodeType: nodeType)

    p.expectToken(IDENTIFIER)
    
    var name = Node(nodeType: astIdent, identifier: p.currentToken.value)
    node.add(name)
    
    if p.peekToken.tokenType != ASSIGN:
        node.add(Node(nodeType: astNull))

        if p.peekToken.tokenType == SEMICOLON:
            p.advance()
            
        return node
    
    p.advance()
    p.advance()
    
    var value = p.parseExpression(ord(LOWEST))

    node.add(value)

    p.advanceOnSemicolon()
    
    return node

proc parseLet(p: var Parser): Node = 
    return p.parseVariableBody(astLet)

proc parseConst(p: var Parser): Node =
    return p.parseVariableBody(astConst)

proc parseReassignment(p: var Parser): Node = 
    var node = Node(nodeType: astReassignment)

    var name = Node(nodeType: astIdent, identifier: p.currentToken.value)
    node.add(name)

    p.advance()
    p.advance()

    node.add(p.parseExpression(ord(LOWEST)))

    p.advanceOnSemicolon()

    return node

proc parseReturn(p: var Parser): Node = 
    var node = Node(nodeType: astReturn)

    p.advance()

    node.value = p.parseExpression(ord(LOWEST))

    p.advanceOnSemicolon()

    return node

proc parseBlock(p: var Parser): Node = 
    var node = Node(nodeType: astBlock)

    p.advance()

    while p.currentToken.tokenType != RBRACE:
        if p.currentToken.tokenType == EOF:
            p.addError("expected }, got EOF instead")
        
        node.elements.add(p.parseNodes())
        p.advance()

    return node

proc parseIf(p: var Parser): Node = 
    var node = Node(nodeType: astIf)

    p.expectToken(LPAREN)
    
    p.advance()

    node.add(p.parseExpression(ord(LOWEST)))

    p.expectToken(RPAREN)
    
    p.expectToken(LBRACE)
    
    node.add(p.parseBlock())

    if p.peekToken.tokenType == ELSE:
        p.advance()

        p.expectToken(LBRACE)
        
        node.add(p.parseBlock())

    return node

proc parseWhile(p: var Parser): Node = 
    var node = Node(nodeType: astWhile)

    p.expectToken(LPAREN)
    
    p.advance()

    node.add(p.parseExpression(ord(LOWEST)))

    p.expectToken(RPAREN)
    
    p.expectToken(LBRACE)
    
    node.add(p.parseBlock())

    return node

proc parseFor(p: var Parser): Node = 
    var node = Node(nodeType: astFor)

    p.expectToken(LPAREN)
    
    p.advance()

    node.add(p.parseNodes())
    
    if p.currentToken.tokenType != SEMICOLON:
        p.addError("expected ;, got {p.currentToken.tokenType} instead".fmt)

    p.advance()

    node.add(p.parseExpression(ord(LOWEST)))

    p.expectToken(SEMICOLON)
    
    p.advance()

    node.add(p.parseExpression(ord(LOWEST)))

    p.expectToken(RPAREN)
    
    p.expectToken(LBRACE)
    
    node.add(p.parseBlock())

    return node

proc parseFunction(p: var Parser): Node = 
    var node = Node(nodeType: astFunction)

    p.expectToken(IDENTIFIER)
    
    node.add(Node(nodeType: astIdent, identifier: p.currentToken.value))

    p.expectToken(LPAREN)
    
    if p.peekToken.tokenType == RPAREN:
        p.advance() 

        p.expectToken(LBRACE)
        
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

        p.advance()

    if p.currentToken.tokenType != RPAREN:
        p.addError("expected token of type ), got {p.currentToken.tokenType} instead".fmt)

    p.expectToken(LBRACE)

    node.add(p.parseBlock())

    return node

proc parseFunctionCall(p: var Parser, left: Node): Node = 
    var node = Node(nodeType: astFuncCall)

    node.add(left)

    p.advance()

    if p.peekToken.tokenType == RPAREN:
        p.advance()
        p.advanceOnSemicolon()
        return node

    p.advance()

    node.add(p.parseExpression(ord(LOWEST)))
    p.advance()

    while p.currentToken.tokenType == COMMA:
        p.advance()

        node.add(p.parseExpression(ord(LOWEST)))

        p.advance()
    
    if p.currentToken.tokenType != RPAREN:
        p.addError("expected ), got {p.currentToken.tokenType} instead".fmt)

    p.advanceOnSemicolon()

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

proc parseNull(p: var Parser): Node = 
    var node = Node(nodeType: astNull)

    return node

proc parseTypeOf(p: var Parser): Node = 
    var node = Node(nodeType: astTypeOf)

    p.advance()

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

proc parseDotExpression(p: var Parser, left: Node): Node = 
    var node = Node(nodeType: astDotExpr)

    if left.nodeType != astIdent:
        p.addError("expected an identifier, got {left.nodeType} instead".fmt)
    
    node.add(left)

    p.advance()
    p.advance()

    var value = p.parseExpression(ord(DOTEXPR))
    if value.nodeType != astIdent and value.nodeType != astFuncCall:
         p.addError("expected an identifier or a function call, got {value.nodeType} instead".fmt)

    node.add(value)

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

    p.expectToken(RPAREN)
    
    return expression

proc parseArrayDeclaration(p: var Parser): Node = 
    var node = Node(nodeType: astArray)

    p.advance()

    var element = p.parseExpression(ord(LOWEST))
    node.elements.add(element)
    
    if p.peekToken.tokenType == RSQBRACK:
        p.advance()
        return node

    p.expectToken(COMMA)

    while p.currentToken.tokenType == COMMA:
        p.advance()
        element = p.parseExpression(ord(LOWEST))
        node.elements.add(element)
        p.advance()

    if p.currentToken.tokenType != RSQBRACK:
        p.addError("expected ], got {p.currentToken.tokenType} instead".fmt)

    return node

proc parseArrayAccess(p: var Parser, left: Node): Node = 
    var node = Node(nodeType: astArrayAccess, arr: left)

    p.advance()
    p.advance()

    node.index = p.parseExpression(ord(LOWEST))

    p.expectToken(RSQBRACK)

    return node

proc parseObjectProperty(p: var Parser, node: var Node) = 
    if p.currentToken.tokenType != IDENTIFIER:
        p.addError("expected an identifier, got {p.currentToken.tokenType} instead".fmt)

    node.add(Node(nodeType: astIdent, identifier: p.currentToken.value))

    p.expectToken(COLON)
    p.advance()

    node.add(p.parseExpression(ord(LOWEST)))

    p.advance()       

proc parseObjectDeclaration(p: var  Parser): Node = 
    var node = Node(nodeType: astObject)

    p.advance()

    if p.currentToken.tokenType == RBRACE:
        return node

    p.parseObjectProperty(node)

    while p.currentToken.tokenType == COMMA:
        p.advance()
        p.parseObjectProperty(node)
    
    if p.currentToken.tokenType != RBRACE:
        p.addError("expected }}, got {p.currentToken.value} instead".fmt)

    return node

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
    of LSQBRACK:
        return p.parseArrayDeclaration()
    of LBRACE:
        return p.parseObjectDeclaration()
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
    of NULL:
        return p.parseNull()
    of TYPEOF:
        return p.parseTypeOf()
    of NOT, MINUS:
        return p.parsePrefix()
    else:
        p.addError("{p.currentToken.tokenType} can not be used as an expression".fmt)
    
proc parseExpression(p: var Parser, precedence: int): Node = 

    var left: Node
  
    left = p.parsePrefixNode()

    left = p.parsePostfixIfExists(p.peekToken.tokenType, left)

    while p.peekToken.tokenType != SEMICOLON and p.peekPrecedence() > precedence:
        
        case p.peekToken.tokenType
        of LPAREN:
            left = p.parseFunctionCall(left)
        of LSQBRACK:
            left = p.parseArrayAccess(left)
        of DOT:
            left = p.parseDotExpression(left)
        else:
            left = p.parseInfix(left)

    return left