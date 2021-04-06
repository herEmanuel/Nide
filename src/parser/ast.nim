type 
    NodeType* = enum
        astProgram,
        astBlock,
        astInt,
        astFloat,
        astString,
        astBool,
        astNull, 
        astOperator,
        astArray,
        astArrayAccess,
        astIdent,
        astInfix,
        astPrefix,
        astPostfix,
        astLet,
        astReassignment,
        astConst,
        astFunction,
        astReturn,
        astFuncCall,
        astIf,
        astWhile,
        astFor,
        astTypeOf,
        astImport,
        astDotExpr

    Node* = ref object 
        case nodeType*: NodeType
        of astInt:
            intValue*: string
        of astFloat:
            floatValue*: string
        of astString:
            strValue*: string
        of astBool:
            boolValue*: bool
        of astTypeOf, astReturn:
            value*: Node
        of astIdent:
            identifier*: string
        of astOperator:
            operator*: string
        of astArray, astProgram, astBlock:
            elements*: seq[Node]
        else:
            sons*: seq[Node]
        
proc add*(n: var Node, son: Node) = 
    n.sons.add(son)


