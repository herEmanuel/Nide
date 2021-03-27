type 
    NodeType* = enum
        Integer,
        String,
        Bool,
        Identifier,
        InfixExpression
        PrefixExpression

    Node* = ref object 
        case nodeType*: NodeType
        of Integer, String, Identifier: value*: string
        of Bool: bValue*: bool
        of InfixExpression:
            inLeft*: Node
            inOperator*: string
            inRight*: Node
        of PrefixExpression:
            pLeft*: Node
            pOperator*: string
        


