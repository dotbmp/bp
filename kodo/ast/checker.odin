/*
 *  @Name:     checker
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 19-06-2018 17:08:31 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 15-08-2018 02:14:03 UTC-5
 *  
 *  @Description:
 *  
 */

package ast



Checker :: struct {
    global:  ^Block,
    current: ^Block,
}



type_int   := new_type_basic(Int);
type_int8  := new_type_basic(Int8);
type_int16 := new_type_basic(Int16);
type_int32 := new_type_basic(Int32);
type_int64 := new_type_basic(Int64);

is_int :: proc(typ: Type) -> bool {
    typ = dealias_type(typ);

    switch t in typ {
    case Type_Basic:
        switch t.basic {
        case Int, Int8, Int16, Int32, Int64:
            return true;
        }
    }

    return false;
}

type_uint8  := new_type_basic(Uint8);
type_uint16 := new_type_basic(Uint16);
type_uint32 := new_type_basic(Uint32);
type_uint64 := new_type_basic(Uint64);

is_uint :: proc(typ: Type) -> bool {
    typ = dealias_type(typ);

    switch t in typ {
    case Type_Basic:
        switch t.basic{
        case Uint, Uint8, Uint16, Uint32, Uint64:
            return true;
        }
    }

    return false;
}

type_bool8  := new_type_basic(Bool8);
type_bool16 := new_type_basic(Bool16);
type_bool32 := new_type_basic(Bool32);
type_bool64 := new_type_basic(Bool64);

is_bool :: proc(typ: Type) -> bool {
    typ = dealias_type(typ);

    switch t in typ {
    case Type_Basic:
        switch t.basic{
        case Bool, Bool8, Bool16, Bool32, Bool64:
            return true;
        }
    }

    return false;
}

type_float32 := new_type_basic(Float32);
type_float64 := new_type_basic(Float64);

is_float :: proc(typ: Type) -> bool {
    typ = dealias_type(typ);

    switch t in typ {
    case Type_Basic:
        switch t.basic {
        case Float32, Float64:
            return true;
        }
    }

    return false;
}

type_string := new_type_basic(String);
type_ztring := new_type_basic(Ztring);

is_string :: proc(typ: Type) -> bool {
    typ = dealias_type(typ);

    switch t in typ {
    case Type_Basic:
        switch t.basic {
        case String, Ztring:
            return true;
        }
    }

    return false;
}



dealias_type :: proc(using checker: ^Checker, typ: Type) -> Type {
    switch n in typ {
    case ^Name:
        if e := get_entity(current, n.tok.text); e != nil {
            return e.typ;
        }
        else {
            panic(); // @error(bpunsky)
        }

    case ^Type_Struct: return typ;
    case ^Type_Enum:   return typ;
    case ^Type_Proc:   return typ;
    case ^Type_Array:  return typ;
    case ^Type_Ptr:    return typ;
    case ^Type_Basic:  return typ;

    case: panic(); // @error(bpunsky)
    }

    return nil;
}

compare_types :: proc(using checker: ^Checker, lhs, rhs: Type, dealias := true) -> bool {
    if lhs != nil && rhs != nil {
        if dealias {
            lhs = dealias_type(checker, lhs);
            rhs = dealias_type(checker, rhs);
        }

        if (^rawptr)(&lhs)^ == (^rawptr)(&rhs)^ {
            return true; // @note(bpunsky): assumes no type can be equal to another distinct type; assumes interning
        }
    }

    return false;
}



check :: proc[check_stmt, check_decl, check_type, check_expr];

check_stmt :: proc(using checker: ^Checker, stmt: Stmt) -> bool {
    switch s in stmt {
    case ^Block:     return check_block    (checker, s);
    case ^Stmt_Goto: return check_stmt_goto(checker, s);
    case ^Stmt_If:   return check_stmt_if  (checker, s);
    case ^Stmt_For:  return check_stmt_for (checker, s);
    case ^Stmt_Assn: return check_stmt_assn(checker, s);
    case Decl:       return check_decl     (checker, s);
    case ^Expr_Call: return check_expr_call(checker, s);
    }

    return nil, false;
}

check_decl :: proc(using checker: ^Checker, decl: Decl) -> (Type, bool) {
    switch d in decl {
    case ^Field:       return check_field      (checker, s);
    case ^Decl_Scope:  return check_decl_scope (checker, s);
    case ^Decl_Import: return check_decl_import(checker, s);
    case ^Decl_Label:  return check_decl_label (checker, s);
    case ^Decl_Type:   return check_decl_type  (checker, s);
    case ^Decl_Var:    return check_decl_var   (checker, s);
    }

    return nil, false;
}

check_type :: proc(using checker: ^Checker, typ: Type) -> (Type, bool) {
    switch t in typ {
    case ^Name:        return check_name       (checker, s);
    case ^Type_Struct: return check_type_struct(checker, s);
    case ^Type_Enum:   return check_type_enum  (checker, s);
    case ^Type_Proc:   return check_type_proc  (checker, s);
    case ^Type_Array:  return check_type_array (checker, s);
    case ^Type_Ptr:    return check_type_ptr   (checker, s);
    case ^Type_Basic:  return check_type_basic (checker, s);
    }

    return nil, false;
}

check_expr :: proc(using checker: ^Checker, expr: Expr) -> (Type, bool) {
    switch e in expr {
    case ^Name:           return check_name          (checker, s);
    case ^Literal:        return check_literal       (checker, s);
    case ^Arg:            return check_arg           (checker, s);
    case ^Expr_Binary:    return check_expr_binary   (checker, s);
    case ^Expr_Unary:     return check_expr_unary    (checker, s);
    case ^Expr_Selector:  return check_expr_selector (checker, s);
    case ^Expr_Subscript: return check_expr_subscript(checker, s);
    case ^Expr_Call:      return check_expr_call     (checker, s);
    case ^Expr_Compound:  return check_expr_compound (checker, s);
    }

    return nil, false;
}



check_block :: proc(using checker: ^Checker, block: ^Block) -> bool {
    assert(block != nil);

    for stmt in block.stmts {
        if _, ok := check_stmt(checker, stmt); !ok {
            return false;
        }
    }

    return true;
}



check_stmt_goto :: proc(using checker: ^Checker, stmt: ^Stmt_Goto) -> bool {
    assert(stmt != nil);

    return false; // @error
}

check_stmt_if :: proc(using checker: ^Checker, stmt: ^Stmt_If) -> bool {
    assert(stmt != nil);

    if typ, ok := check_expr(checker, stmt.cond); ok {
        if is_bool(typ) {
            if check_block(checker, stmt.then) {
                return check_stmt(checker, stmt.els);
            }
        } 
        else {
            // @error
        }
    }

    return false;
}

check_stmt_for :: proc(using checker: ^Checker, stmt: ^Stmt_For) -> bool {
    assert(stmt != nil);

    if _, ok := check_decl(checker, stmt.decl); ok {
        if typ, ok := check_expr(checker, stmt.cond); ok {
            if is_bool(typ) {
                if check_stmt(checker, stmt.iter) {
                    return check_block(checker, stmt.block);
                }
            }
            else {
                // @error
            }
        }
    }

    return false;
}

check_stmt_assn :: proc(using checker: ^Checker, stmt: ^Stmt_Assn) -> bool {
    assert(stmt != nil);

    if len(stmt.lhs) == len(stmt.rhs) && len(stmt.lhs) != 0 {
        for _, i in stmt.lhs {
            lhs := stmt.lhs[i];
            rhs := stmt.rhs[i];

            if ltyp, ok := check_expr(checker, lhs); ok {
                if rtyp, ok := check_expr(checker, rhs); ok {
                    if compare_types(ltyp, rtyp) {
                        return true;
                    }
                    else {
                        // @error
                    }
                }
            }
        }
    }
    else {
        // @error
    }

    return false;
}



collision :: inline proc(using checker: ^Checker, name: ^Name) -> bool {
    return has_entity(current, decl.name.tok.text);
}



// @todo(bpunsky): actually create/resolve entities in decl procs

check_decl_scope :: proc(using checker: ^Checker, decl: ^Decl_Scope) -> bool {
    assert(decl != nil);

    if !collision(current, decl.name) {
        return check_block(checker, decl.block);
    }
    else {
        // @error
    }

    return false;
}

check_decl_import :: proc(using checker: ^Checker, decl: ^Decl_Scope) -> bool {
    assert(decl != nil);

    if !collision(current, decl.name) {
        panic(); // @todo(bpunsky): figure this out! I guess the parser has to resolve imports?
        // @todo(bpunsky): handle foreign
    }
    else {
        // @error
    }

    return false;
}

check_decl_label :: proc(using checker: ^Checker, decl: ^Decl_Label) -> bool {
    assert(decl != nil);

    if !collision(current, decl.name) {
        return true;
    }
    else {
        // @error
    }

    return false;
}

check_decl_type :: proc(using checker: ^Checker, decl: ^Decl_Type) -> bool {
    assert(decl != nil);

    if !collision(current, decl.name) {
        // @todo(bpunsky): handle aliases
        if _, ok := check_type(checker, decl.typ); ok {
            return true;
        }
    }
    else {
        // @error
    }

    return false;
}

check_decl_var :: proc(using checker: ^Checker, decl: ^Decl_Type) -> bool {
    assert(decl != nil);

    if len(decl.names) != 0 && len(decl.names) == len(decl.exprs) {
        for _, i in decl.names {
            name := decl.names[i];

            if !collision(current, name) {
                expr := decl.exprs[i];
                
                if decl.typ != nil {
                    if typ, ok := check_type(checker, decl.typ); ok {
                        if typ2, ok := check_expr(checker, expr); ok {
                            if compare_types(typ, typ2) {
                                return true;
                            }
                            else {
                                // @error
                            }
                        }
                    }
                }
                else {
                    if _, ok := check_expr(checker, expr); ok {
                        return true;
                    }
                }
            }
            else {
                // @error
            }
        }
    }
    else {
        // @error
    }

    return false;
}



eval :: proc(using checker: ^Checker, expr: Expr) -> Value {
    switch e in expr {
    case ^ast.Name:
        panic(); // @error(bpunsky)

    case ^ast.Literal:
        return e.val;
        
    case ^ast.Arg:
        return nil, false;

    case ^ast.Expr_Binary:
        lhs := eval(checker, e.lhs);
        rhs := eval(checker, e.rhs);

        switch e.tok.text {
        case "+":
            switch l in lhs {
            case i64: return l + rhs.(i64);
            case u64: return l + rhs.(i64);
            case f64: return l + rhs.(i64);

            case string:
                r := rhs.(string);
                str := string(make([]byte, len(l) + len(r)); // @todo(bpunsky): gotta free
                copy(str,          l);
                copy(str[len(l):], r);
                return str;

            case bool: panic(); // @error
            }

        case "-":
            switch l in lhs {
            case i64: return l - rhs.(i64);
            case u64: return l - rhs.(i64);
            case f64: return l - rhs.(i64);

            case bool:   panic(); // @error
            case string: panic(); // @error
            }

        case "*":
            switch l in lhs {
            case i64: return l * rhs.(i64);
            case u64: return l * rhs.(i64);
            case f64: return l * rhs.(i64);

            case bool:   panic(); // @error
            case string: panic(); // @error
            }

        case "/":
            switch l in lhs {
            case i64: return l / rhs.(i64);
            case u64: return l / rhs.(i64);
            case f64: return l / rhs.(i64);

            case bool:   panic(); // @error
            case string: panic(); // @error
            }

        case "%":
            switch l in lhs {
            case i64: return l - rhs.(i64);
            case u64: return l - rhs.(i64);

            case f64:    panic(); // @error
            case bool:   panic(); // @error
            case string: panic(); // @error
            }

        case: panic(); // @todo(bpunsky): implement the rest of the binary operators!
        }

    case ^ast.Expr_Unary:
        val := eval(checker, e.expr);

        switch e.tok.text {
        case "+":
            switch v in val {
            case i64: return +v;
            case u64: return +v;
            case f64: return +v;

            case bool:   panic(); // @error
            case string: panic(); // @error
            }

        case "-":
            switch v in val {
            case i64: return -v;
            case u64: return -v;
            case f64: return -v;
            
            case bool:   panic(); // @error
            case string: panic(); // @error
            }

        case "!":
            switch v in val {
            case i64: panic(); // @error
            case u64: panic(); // @error
            case f64: panic(); // @error
            case string: panic(); // @error

            case bool: return !v;
            }

        case "~":
            switch v in val {
            case i64: return ~v;
            case u64: return ~v;
            case f64: return ~v;

            case bool:   panic(); // @error
            case string: panic(); // @error
            }

        case "&": panic(); // @error
        case "^": panic(); // @error
        }
    }

    return nil, false;
}



check_type_struct :: proc(using checker: ^Checker, typ: ^Type_Struct) -> (Type, bool) {
    assert(typ != nil);

    for field in fields {
        if !check_field(checker, field) {
            return false;
        }
    }

    return true;
}

check_type_enum :: proc(using checker: ^Checker, typ: ^Type_Enum) -> (Type, bool) {
    assert(typ != nil);

    if _, ok := check_type(checker, typ.base); ok {
        for field in typ.fields {
            if !check_field(checker, field) {
                return false;
            }
        }

        return true;
    }

    return false;
}

check_type_proc :: proc(using checker: ^Checker, typ: ^Type_Proc) -> (Type, bool) {
    assert(typ != nil);

    for param in params {
        if !check_field(checker, param) {
            return false;
        }
    }

    for ret in returns {
        if !check_field(checker, ret) {
            return false;
        }
    }

    return true;
}

check_type_array :: proc(using checker: ^Checker, typ: ^Type_Array) -> (Type, bool) {
    assert(typ != nil);

    if typ, ok := check_expr(checker, typ.arg); ok {
        if is_int(typ) {
            // @todo(bpunsky): this just feels wrong
            if len, ok := eval(checker, typ.arg); ok {
                typ.len = len;
         
                if _, ok := check_type(checker, typ.base); ok {
                    return true;
                }
            }
        }
        else {
            // @error
        }
    }

    return false;
}
