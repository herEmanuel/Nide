import ../parser/ast
import obj
import strutils

proc evalProgram(nodes: seq[Node]): Obj

proc eval*(node: Node): Obj =
    case node.nodeType 
    of astProgram:
        return evalProgram(node.elements)
    of astInt:
        return Obj(objType: objInt, intValue: parseInt(node.intValue))
    of astFloat:
        return Obj(objType: objFloat, floatValue: parseFloat(node.floatValue))
    else:
        discard

proc evalProgram(nodes: seq[Node]): Obj =
    var result: Obj

    for node in nodes:
        result = eval(node)

    return result