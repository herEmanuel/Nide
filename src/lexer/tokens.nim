import tables

type 
    Token* = object 
        tokenType*: string
        value*: string


const 
    EOF* = "EOF"
    ILLEGAL* = "ILLEGAL"
    IDENTIFIER* = "IDENTIFIER"
    STRING* = "STRING"
    INT* = "INT"
    FLOAT* = "FLOAT"

    DOT* = "."
    COMMA* = ","
    SEMICOLON* = ";"
    LPAREN* = "("
    RPAREN* = ")"
    LBRACE* = "{"
    RBRACE* = "}"
    LSQBRACK* = "["
    RSQBRACK* = "]"

    PLUS* = "+"
    MINUS* = "-"
    ASTERISK* = "*"
    SLASH* = "/"
    ASSIGN* = "="
    NOT* = "!"
    GREATER_THAN* = ">"
    LESS_THAN* = "<"

    EQUAL* = "=="
    NOT_EQUAL* = "!="
    GREATER_THAN_OR_EQUAL* = ">="
    LESS_THAN_OR_EQUAL* = "<="
    AND* = "&&"
    OR* = "||"

    FUNCTION* = "FUNCTION"
    TYPEOF* = "TYPEOF"
    LET* = "LET"
    VAR* = "VAR"
    CONST* = "CONST"
    TRUE* = "TRUE"
    FALSE* = "FALSE"
    IF* = "IF"
    ELSE* = "ELSE"
    RETURN* = "RETURN"
    WHILE* = "WHILE"
    FOR* = "FOR"


var keywords = {
    "function": FUNCTION,
    "let": LET,
    "const": CONST,
    "var": VAR,
    "true": TRUE,
    "false": FALSE,
    "if": IF,
    "else": ELSE,
    "return": RETURN,
    "while": WHILE,
    "for": FOR,
    "typeof": TYPEOF
}.toTable

proc isKeywordOrIdentifier*(value: string): string = 
    if keywords.hasKey(value):
        return keywords[value]

    return IDENTIFIER