import ../parser/ast
import obj
import symbolTable
import strutils
import strformat

let 
    TRUE = Obj(objType: objBool, boolValue: true)
    FALSE = Obj(objType: objBool, boolValue: false)
    NULL = Obj(objType: objNull)

proc raiseError(err: string): Obj = 
    return Obj(objType: objError, error: "Evaluation error: {err}".fmt)

proc evalProgram(nodes: seq[Node], st: var SymbolTable): Obj
proc evalIntInfix(left: Obj, right: Obj, operation: string): Obj
proc evalFloatInfix(left: Obj, right: Obj, operation: string): Obj

proc eval*(node: Node, st: var SymbolTable): Obj =
    case node.nodeType 
    of astProgram:
        return evalProgram(node.elements, st)
    of astInt:
        return Obj(objType: objInt, intValue: parseInt(node.intValue))
    of astFloat:
        return Obj(objType: objFloat, floatValue: parseFloat(node.floatValue))
    of astString:
        return Obj(objType: objString, strValue: node.strValue)
    of astPrefix:
        var right = eval(node.sons[1], st)

        case node.sons[0].operator:
        of "-":
            if right.objType == objInt:
                return Obj(objType: objInt, intValue: -right.intValue)
            elif right.objType == objFloat:
                return Obj(objType: objFloat, floatValue: -right.floatValue)
            else:
                return raiseError("the - operator can only be used with numbers")
        of "!":
            case right.objType:
            of objBool:
                if right == TRUE:
                    return FALSE
                else:
                    return TRUE
            else:
                return raiseError("the ! operator can not be used with booleans")

    of astInfix:
        var left = eval(node.sons[0], st)
        var right = eval(node.sons[2], st)

        if left.objType == objInt and right.objType == objInt:
            return evalIntInfix(left, right, node.sons[1].operator)

        elif left.objType == objFloat and right.objType == objFloat:
            return evalFloatInfix(left, right, node.sons[1].operator)

        elif left.objType == objString and right.objType == objString:
            case node.sons[1].operator
            of "+":
                return Obj(objType: objString, strValue: left.strValue & right.strValue)
            of "==":
                if left.strValue == right.strValue:
                    return TRUE
                else:
                    return FALSE
            of "!=":
                if left.strValue != right.strValue:
                    return TRUE
                else:
                    return FALSE

        elif left.objType == objBool and right.objType == objBool:
            case node.sons[1].operator
            of "!=":
                if left == right:
                    return FALSE 
                else:
                    return TRUE
            of "==":
                if left == right:
                    return TRUE
                else:
                    return FALSE
            of "&&":
                if left == TRUE and right == TRUE:
                    return TRUE
                else:
                    return FALSE
            of "||":
                if left == TRUE or right == TRUE:
                    return TRUE
                else: 
                    return FALSE
        else:
            return raiseError("operation not supported between {left.objType} and {right.objType}".fmt)
    
    of astIdent:
        
        var res = st.getSymbol(node.identifier)
        if res == nil:
            return raiseError("undeclared identifier: {node.identifier}".fmt)

        return res

    of astLet:
        var value = eval(node.sons[1], st)

        if st.setSymbol(node.sons[0].identifier, value) != nil: 
            return NULL

        return raiseError("{node.sons[0].identifier} can not be redeclared".fmt)

    else:
        discard


proc evalProgram(nodes: seq[Node], st: var SymbolTable): Obj =
    var result: Obj

    for node in nodes:
        result = eval(node, st)

        if result.objType == objError:
            echo result.error
            system.quit(0)

    return result

proc evalIntInfix(left: Obj, right: Obj, operation: string): Obj = 
    case operation
    of "+":
        return Obj(objType: objInt, intValue: left.intValue + right.intValue)
    of "-":
        return Obj(objType: objInt, intValue: left.intValue - right.intValue)
    of "*":
        return Obj(objType: objInt, intValue: left.intValue * right.intValue)
    of "/":
        return Obj(objType: objFloat, floatValue: left.intValue / right.intValue)
    of ">":
        if left.intValue > right.intValue:
            return TRUE
        else: 
            return FALSE
    of "<":
        if left.intValue < right.intValue:
            return TRUE
        else: 
            return FALSE
    of ">=":
        if left.intValue >= right.intValue:
            return TRUE
        else: 
            return FALSE
    of "<=":
        if left.intValue <= right.intValue:
            return TRUE
        else: 
            return FALSE
    of "==":
        if left.intValue == right.intValue:
            return TRUE
        else: 
            return FALSE
    of "!=":
        if left.intValue != right.intValue:
            return TRUE
        else: 
            return FALSE
    of "&&":
        if left.intValue != 0 and right.intValue != 0:
            return TRUE
        else: 
            return FALSE
    of "||":
        if left.intValue != 0 or right.intValue != 0:
            return TRUE
        else: 
            return FALSE
    else: 
        discard

proc evalFloatInfix(left: Obj, right: Obj, operation: string): Obj = 
    case operation
    of "+":
        return Obj(objType: objFloat, floatValue: left.floatValue + right.floatValue)
    of "-":
        return Obj(objType: objFloat, floatValue: left.floatValue - right.floatValue)
    of "*":
        return Obj(objType: objFloat, floatValue: left.floatValue * right.floatValue)
    of "/":
        return Obj(objType: objFloat, floatValue: left.floatValue / right.floatValue)
    of ">":
        if left.floatValue > right.floatValue:
            return TRUE
        else: 
            return FALSE
    of "<":
        if left.floatValue < right.floatValue:
            return TRUE
        else: 
            return FALSE
    of ">=":
        if left.floatValue >= right.floatValue:
            return TRUE
        else: 
            return FALSE
    of "<=":
        if left.floatValue <= right.floatValue:
            return TRUE
        else: 
            return FALSE
    of "==":
        if left.floatValue == right.floatValue:
            return TRUE
        else: 
            return FALSE
    of "!=":
        if left.floatValue != right.floatValue:
            return TRUE
        else: 
            return FALSE
    of "&&":
        if left.floatValue != 0 and right.floatValue != 0:
            return TRUE
        else: 
            return FALSE
    of "||":
        if left.floatValue != 0 or right.floatValue != 0:
            return TRUE
        else: 
            return FALSE
    else: 
        discard
