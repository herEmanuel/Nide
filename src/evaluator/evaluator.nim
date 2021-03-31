import ../parser/ast, obj, symbolTable
from strformat import fmt
import strutils, json

let 
    TRUE = Obj(objType: objBool, boolValue: true)
    FALSE = Obj(objType: objBool, boolValue: false)
    NULL = Obj(objType: objNull)

proc raiseError(err: string): Obj = 
    return Obj(objType: objError, error: "Evaluation error: {err}".fmt)

proc isError(obj: Obj) = 
    if obj.objType == objError:
        echo obj.error
        system.quit(0)

proc evalProgram(nodes: seq[Node], st: ref SymbolTable): Obj
proc evalIntInfix(left: Obj, right: Obj, operation: string): Obj
proc evalFloatInfix(left: Obj, right: Obj, operation: string): Obj
proc evalFunctionBody(function: Obj, args: seq[Obj], outerSt: ref SymbolTable): Obj

proc eval*(node: Node, st: ref SymbolTable): Obj =
    case node.nodeType 
    of astProgram:
        return evalProgram(node.elements, st)
    of astInt:
        return Obj(objType: objInt, intValue: parseInt(node.intValue))
    of astFloat:
        return Obj(objType: objFloat, floatValue: parseFloat(node.floatValue))
    of astString:
        return Obj(objType: objString, strValue: node.strValue)
    of astBool:
        if node.boolValue:
            return TRUE
        
        return FALSE
    of astReturn:
        var value = eval(node.value, st)
        isError(value)

        return Obj(objType: objReturn, returnValue: value)
    of astPrefix:
        var right = eval(node.sons[1], st)
        isError(right)

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
        isError(left)
        var right = eval(node.sons[2], st)
        isError(right)

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

        if res.objType == objConst:
            res = res.constValue

        return res

    of astLet:
        var value = eval(node.sons[1], st)
        isError(value)

        if st.setSymbol(node.sons[0].identifier, value) != nil: 
            return NULL

        return raiseError("{node.sons[0].identifier} can not be redeclared".fmt)

    of astConst:
        var value = eval(node.sons[1], st)
        isError(value)

        if st.setSymbol(node.sons[0].identifier, Obj(objType: objConst, constValue: value)) != nil:
            return NULL
        
        return raiseError("{node.sons[0].identifier} can not be redeclared".fmt)

    of astFunction:
        var funcObj = Obj(objType: objFunction)

        funcObj.funcName = node.sons[0]

        var x = 1
        while node.sons[x].nodeType != astBlock:
            funcObj.funcParams.add(node.sons[x].identifier)
            x += 1
        
        funcObj.funcBody = node.sons[x]

        if st.setSymbol(funcObj.funcName.identifier, funcObj) == nil:
            return raiseError("{node.sons[0].identifier} can not be redeclared".fmt)

        return funcObj

    of astFuncCall:
        var function = eval(node.sons[0], st)
        isError(function)
        echo %function
        if function.objType != objFunction:
            return raiseError("{node.sons[0].identifier} is not callable".fmt)

        var args: seq[Obj]

        for arg in node.sons:
            if node.sons[0] == arg:
                continue

            args.add(eval(arg, st))

        return evalFunctionBody(function, args, st)

    else:
        discard


proc evalProgram(nodes: seq[Node], st: ref SymbolTable): Obj =
    var result: Obj

    for node in nodes:
        result = eval(node, st)
        isError(result)

        if result.objType == objReturn:
            return result

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

proc evalFunctionBody(function: Obj, args: seq[Obj], outerSt: ref SymbolTable): Obj = 
    var st = newStWithOuter(outerSt)

    for i, arg in function.funcParams:
        discard st.setSymbol(arg, args[i])

    var bodyResult = evalProgram(function.funcBody.elements, st)
    if bodyResult.objType == objReturn:
        return bodyResult.returnValue

    return bodyResult
