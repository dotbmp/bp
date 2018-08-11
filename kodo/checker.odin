/*
 *  @Name:     checker
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 19-06-2018 17:08:31 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 11-07-2018 22:35:54 UTC-5
 *  
 *  @Description:
 *  
 */

package kodo



/*

Checker :: struct {
    global_scope  : ^Scope,
    current_scope : ^Scope,
}

Symbol_Kind :: enum {
    Scope,
    Label,
    Type,
    Var,
}

Symbol :: struct {
    kind  : Symbol_Kind,
    decl  : ^Node,
    type_ : ^Node,
    name  : ^Node,
}

Scope :: struct {
    symbols  : map[string]Symbol,
    children : map[string]Symbol,
}



type_int8   := new_type_basic("#int8",   1, 1);
type_int16  := new_type_basic("#int16",  2, 2);
type_int32  := new_type_basic("#int32",  4, 4);
type_int64  := new_type_basic("#int64",  8, 8);

type_uint8  := new_type_basic("#uint8",  1, 1);
type_uint16 := new_type_basic("#uint16", 2, 2);
type_uint32 := new_type_basic("#uint32", 4, 4);
type_uint64 := new_type_basic("#uint64", 8, 8);

type_bool8  := new_type_basic("#bool8",  1, 1);
type_bool16 := new_type_basic("#bool16", 2, 2);
type_bool32 := new_type_basic("#bool32", 4, 4);
type_bool64 := new_type_basic("#bool64", 8, 8);

type_float32 := new_type_basic("#float32", 4, 4);
type_float64 := new_type_basic("#float64", 8, 8);



unalias_type :: proc(type_ : ^Node) -> ^Node {
    switch n in type_ {
    case Name:

    case Type_Struct:
    case Type_Enum:
    case Type_Proc:
    case Type_Array:
    case Type_Ptr:
    case Type_Basic:
        return type_;
    }

    /*
    if alias, ok := type_.(Type_Alias); ok {
        return unalias_type(alias.base);
    }
    */

    return type_;
}

compare_types :: proc(lhs, rhs : ^Node) -> bool {
    if lhs != nil && rhs != nil {
        if unalias_type(lhs) == unalias_type(rhs) {
            return true;
        }
    }

    return false;
}



check :: proc(using checker : ^Checker, node : ^Node) -> (type_ : ^Node, success : bool) {
    switch n in node {
    case Stmt_Goto:
    case Stmt_If:
    case Stmt_For:
    case Decl_Scope:
    case Decl_Import:
    case Decl_Label:
    case Decl_Type:
    case Decl_Var:
    case Assn_Binary:
    case Assn_Unary:
    case Type_Struct:
    case Type_Enum:
    case Type_Proc:
    case Type_Array:
    case Type_Ptr:
    case Type_Basic:
    case Expr_Binary:
        ltype, lok := check(checker, n.lhs);
        rtype, rok := check(checker, n.rhs);

        if (lok && rok) && ltype != nil && compare_types(ltype, rtype) {
            return ltype, true;
        }

    case Expr_Unary:
        if type_, ok := check(checker, n.expr); ok {
            return type_, true;
        }

    case Expr_Selector:
        // @todo(bpunsky): implement

    case Expr_Subscript:
        // @todo(bpunsky): implement

    case Expr_Call:
        // @todo(bpunsky): implement

    case Block:
        return nil, true;

    case Literal:
        switch n.kind {
        case Int:    return type_int64,   true;
        case Float:  return type_float64, true;
        case Bool:   return type_bool8,   true;
        //case String: return type_string;
        }

    case Name:
    }

    return nil, false;
}

*/
