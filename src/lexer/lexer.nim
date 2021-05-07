import tokens, strutils, terminal
from strformat import fmt

type 
    Lexer* = object
        position: int
        nextPosition: int
        currentChar: char
        line*: int
        input: string
        file: File

proc nextChar(l: var Lexer) = 

    if l.position >= len(l.input):

        try:
            var newLine = l.file.readLine()
            l.line += 1
            if newLine == "":
                l.nextChar()
                return

            l.input.add(" " & newLine)
        except:
            l.currentChar = '\0'
            return  
        
    l.currentChar = l.input[l.position]

    l.position = l.nextPosition
    l.nextPosition += 1

proc peekChar(l: var Lexer): char = 
    if l.position >= len(l.input):
        return '\0'

    return l.input[l.position]

proc addError(l: var Lexer, err: string) = 
    styledEcho fgRed, "Lexing error: ", fgWhite, "" & err
    styledEcho fgYellow, "Line: {l.line}".fmt
    system.quit(0)

proc newLexer*(input: string, file: File): Lexer =
    var l = Lexer(input: input, file: file, line: 1)

    l.nextChar()
    l.nextChar()

    return l

proc consumeWhitespace(l: var Lexer) = 
    while l.currentChar in Whitespace:
        l.nextChar()    

proc readIdentifier(l: var Lexer): string
proc readString(l: var Lexer): string
proc readNumber(l: var Lexer): string

proc nextToken*(l: var Lexer): Token = 

    var tok: Token
  
    l.consumeWhitespace()
    
    case l.currentChar
    of '.':
        tok = Token(tokenType: DOT, value: $l.currentChar)
    of ',':
        tok = Token(tokenType: COMMA, value: $l.currentChar)
    of ':':
        tok = Token(tokenType: COLON, value: $l.currentChar)
    of ';':
        tok = Token(tokenType: SEMICOLON, value: $l.currentChar)
    of '(':
        tok = Token(tokenType: LPAREN, value: $l.currentChar)
    of ')':
        tok = Token(tokenType: RPAREN, value: $l.currentChar)
    of '{':
        tok = Token(tokenType: LBRACE, value: $l.currentChar)
    of '}':
        tok = Token(tokenType: RBRACE, value: $l.currentChar)
    of '[':
        tok = Token(tokenType: LSQBRACK, value: $l.currentChar)
    of ']':
        tok = Token(tokenType: RSQBRACK, value: $l.currentChar)
    of '+':
        tok = Token(tokenType: PLUS, value: $l.currentChar)

        if l.peekChar() == '+':
            tok = Token(tokenType: INC, value: "++")
            l.nextChar()
    of '-':
        tok = Token(tokenType: MINUS, value: $l.currentChar)

        if l.peekChar() == '-':
            tok = Token(tokenType: DEC, value: "--")
            l.nextChar()
    of '*':
        tok = Token(tokenType: ASTERISK, value: $l.currentChar)
    of '/':
        if l.peekChar() == '/':
            var currLine = l.line
            while l.line == currLine and l.currentChar != '\0':
                l.nextChar()
            
            return l.nextToken()
        elif l.peekChar() == '*':
            while l.currentChar != '*' or l.peekChar() != '/':
                if l.currentChar == '\0':
                    l.addError("expected end of the multiline comment, got EOF instead")
                
                l.nextChar()

            l.nextChar()
            l.nextChar()
            
            return l.nextToken()

        tok = Token(tokenType: SLASH, value: $l.currentChar)
    of '\\':
        tok = Token(tokenType: BACKSLASH, value: $l.currentChar)
    of '=':
        tok = Token(tokenType: ASSIGN, value: $l.currentChar)

        if l.peekChar() == '=':
            tok = Token(tokenType: EQUAL, value: "==")
            l.nextChar()            
    of '!':
        tok = Token(tokenType: NOT, value: $l.currentChar)

        if l.peekChar() == '=':
            tok = Token(tokenType: NOT_EQUAL, value: "!=")
            l.nextChar()
    of '>':
        tok = Token(tokenType: GREATER_THAN, value: $l.currentChar)
        
        if l.peekChar() == '=':
            tok = Token(tokenType: GREATER_THAN_OR_EQUAL, value: ">=")
            l.nextChar()
    of '<':
        tok = Token(tokenType: LESS_THAN, value: $l.currentChar)
        
        if l.peekChar() == '=':
            tok = Token(tokenType: LESS_THAN_OR_EQUAL, value: "<=")
            l.nextChar()
    of '&':
        tok = Token(tokenType: ILLEGAL, value: $l.currentChar)
        
        if l.peekChar() == '&':
            tok = Token(tokenType: AND, value: "&&")
            l.nextChar()
    of '|':
        tok = Token(tokenType: ILLEGAL, value: $l.currentChar)

        if l.peekChar() == '|':
            tok = Token(tokenType: OR, value: "||")
            l.nextChar()
    of '"':
        var value = l.readString()

        tok = Token(tokenType: STRING, value: value)
    of '\0':
        tok = Token(tokenType: EOF, value: EOF)
        return tok
    else:
        if isAlphaAscii(l.currentChar):
            var value = l.readIdentifier()
            var tokType = isKeywordOrIdentifier(value)

            tok = Token(tokenType: tokType, value: value)
            return tok
        elif isDigit(l.currentChar):
            var number = l.readNumber()
            var tokType = INT

            if '.' in number:
                tokType = FLOAT

            tok = Token(tokenType: tokType, value: number)
            return tok

    l.nextChar()
    return tok

proc readIdentifier(l: var Lexer): string =
    var value = ""

    while isAlphaNumeric(l.currentChar):
        value.add(l.currentChar)
        l.nextChar()

    return value

proc readString(l: var Lexer): string = 
    var value = ""

    l.nextChar()

    while l.currentChar != '"':

        if l.currentChar == '\0':
            l.addError("expected \", got EOF instead")

        if l.currentChar == '\\':
            
            case l.peekChar
            of '\\':
                value.add(l.currentChar)
            of 'n':
                value.add("\n")
            of '"':
                value.add("\"")
            else:
                l.addError("can not escape {l.peekChar}".fmt)

            l.nextChar()
            l.nextChar()
        else:
            value.add(l.currentChar)
            l.nextChar()
    
    return value

proc readNumber(l: var Lexer): string = 
    var number = ""
    var hasDot = false
    
    while isDigit(l.currentChar):
        number.add(l.currentChar)
        l.nextChar()

        if l.currentChar == '.' and not hasDot:
            number.add(l.currentChar)
            hasDot = true
            l.nextChar()

    
    return number