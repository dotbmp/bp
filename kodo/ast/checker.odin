/*
 *  @Name:     checker
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 19-06-2018 17:08:31 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 15-08-2018 22:13:14 UTC-5
 *  
 *  @Description:
 *  
 */

package ast



Checker :: struct {
    global:  ^Block,
    current: ^Block,
}



untyped_int := new_type_basic(Untyped_Int);

type_int64 := new_type_basic(Int64);
type_int32 := new_type_basic(Int32);
type_int16 := new_type_basic(Int16);
type_int8  := new_type_basic(Int8);

is_int :: proc(checker: ^Checker, typ: Type) -> bool {
    typ = dealias_type(checker, typ);

    switch typ {
    case type_int, type_int8, type_int16, type_int32, type_int64:
        return true;
    }

    return false;
}

untyped_uint := new_type_basic(Untyped_Uint);

type_uint64 := new_type_basic(Uint64);
type_uint32 := new_type_basic(Uint32);
type_uint16 := new_type_basic(Uint16);
type_uint8  := new_type_basic(Uint8);

is_uint :: proc(checker: ^Checker, typ: Type) -> bool {
    typ = dealias_type(checker, typ);

    switch typ {
    case type_uint, type_uint8, type_uint16, type_uint32, type_uint64:
        return true;
    }

    return false;
}

untyped_bool := new_type_basic(Untyped_Bool);

type_bool8  := new_type_basic(Bool8);
type_bool16 := new_type_basic(Bool16);
type_bool32 := new_type_basic(Bool32);
type_bool64 := new_type_basic(Bool64);

is_bool :: proc(checker: ^Checker, typ: Type) -> bool {
    typ = dealias_type(checker, typ);

    switch typ {
    case type_bool, type_bool8, type_bool16, type_bool32, type_bool64:
        return true;
    }

    return false;
}

type_float32 := new_type_basic(Float32);
type_float64 := new_type_basic(Float64);

is_float :: proc(checker: ^Checker, typ: Type) -> bool {
    typ = dealias_type(checker, typ);

    switch typ {
    case type_float32, type_float64:
        return true;
    }

    return false;
}

untyped_string := new_type_basic(Untyped_String);

type_string := new_type_basic(String);
type_ztring := new_type_basic(Ztring);

is_string :: proc(checker: ^Checker, typ: Type) -> bool {
    typ = dealias_type(checker, typ);

    switch typ {
    case type_string, type_ztring:
        return true;
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

        // @todo(bpunsky): something something untyped constants?
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
    
    case Decl:
        _, ok := check_decl(checker, s);
        return ok;

    case ^Expr_Call:
        _, ok := check_expr_call(checker, s);
        return ok;
    }

    return false;
}

check_decl :: proc(using checker: ^Checker, decl: Decl) -> (Type, bool) {
    switch d in decl {
    case ^Field:       return check_field      (checker, d);
    case ^Decl_Scope:  return nil, check_decl_scope (checker, d);
    case ^Decl_Import: return nil, check_decl_import(checker, d);
    case ^Decl_Label:  return nil, check_decl_label (checker, d);
    case ^Decl_Type:   return check_decl_type  (checker, d);
    case ^Decl_Var:    return check_decl_var   (checker, d);
    }

    return nil, false;
}

check_type :: proc(using checker: ^Checker, typ: Type) -> (Type, bool) {
    switch t in typ {
    case ^Name:        return check_type_name  (checker, t);
    case ^Type_Struct: return check_type_struct(checker, t);
    case ^Type_Enum:   return check_type_enum  (checker, t);
    case ^Type_Proc:   return check_type_proc  (checker, t);
    case ^Type_Array:  return check_type_array (checker, t);
    case ^Type_Ptr:    return check_type_ptr   (checker, t);
    case ^Type_Basic:  return check_type_basic (checker, t);
    }

    return nil, false;
}

check_expr :: proc(using checker: ^Checker, expr: Expr) -> (Type, bool) {
    switch e in expr {
    case ^Name:           return check_expr_name     (checker, e);
    case ^Literal:        return check_literal       (checker, e);
    case ^Arg:            return check_arg           (checker, e);
    case ^Expr_Binary:    return check_expr_binary   (checker, e);
    case ^Expr_Unary:     return check_expr_unary    (checker, e);
    case ^Expr_Selector:  return check_expr_selector (checker, e);
    case ^Expr_Subscript: return check_expr_subscript(checker, e);
    case ^Expr_Call:      return check_expr_call     (checker, e);
    case ^Expr_Compound:  return check_expr_compound (checker, e);
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

check_field :: proc(using checker: ^Checker, field: ^Field) -> (Type, bool) {
    assert(field != nil);

    if len(field.names) != 0 && len(field.names) == len(field.exprs) {
        for _, i in field.names {
            name := field.names[i];

            e := declare_name(checker, name);
            defer e.status = Resolved;

            expr := field.exprs[i];
                
            if field.typ != nil {
                if typ, ok := check_type(checker, field.typ); ok {
                    if typ2, ok := check_expr(checker, expr); ok {
                        if compare_types(checker, typ, typ2) {
                            // @todo(bpunsky): untyped constant inference
                            e.typ = typ;

                            return typ, true;
                        }
                        else {
                            panic(); // @error
                        }
                    }
                }
            }
            else {
                if typ, ok := check_expr(checker, expr); ok {
                    return typ, true;
                }
            }

        }
    }
    else {
        panic(); // @error
    }

    return nil, false;
}

check_type_name :: proc(using checker: ^Checker, name: ^Name) -> (Type, bool) {
    assert(name != nil);

    if e := find_name(checker, name); e != nil {
        assert(e.typ != nil); // @error

        // @todo(bpunsky): make sure the entity is a type
        
        return e.typ, true;
    }

    return nil, false;
}

check_expr_name :: proc(using checker: ^Checker, name: ^Name) -> (Type, bool) {
    assert(name != nil);

    if e := find_name(checker, name); e != nil {
        assert(e.typ != nil); // @error

        // @todo(bpunsky): make sure entity is var, handle const differently?

        return e.typ, true;
    }

    return nil, false;
}

check_literal :: proc(using checker: ^Checker, lit: ^Literal) -> (Type, bool) {
    assert(lit != nil);

    switch v in lit.val {
    case i64:    return untyped_int,    true;
    case u64:    return untyped_uint,   true;
    case f64:    return untyped_float,  true;
    case bool:   return untyped_bool,   true;
    case string: return untyped_string, true;
    }

    return nil, false;
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
            if is_bool(checker, typ) {
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



add_entity :: proc(block: ^Block, name: string) -> ^Entity {
    if !has_entity(block, name) {
        e := new(Entity);

        block.entities[name] = e;

        return e;
    }

    return nil;
}

get_entity :: proc(block: ^Block, name: string, recurse := false) -> ^Entity {
    if e, ok := block.entities[name]; ok {
        return e;
    }
    else if recurse {
        return get_entity(block.parent, name);
    }

    return nil;
}

has_entity :: inline proc(block: ^Block, name: string, recurse := false) -> bool {
    _, ok := block.entities[name];
    return ok;
}



find_name :: proc(using checker: ^Checker, name: ^Name) -> ^Entity {
    return get_entity(checker, name.text, true);
}

declare_name :: proc(using checker: ^Checker, name: ^Name) -> ^Entity {
    if e := get_entity(current, name.text); e != nil {
        if e.status != Unresolved {
            panic(); // @error
        }

        return e;
    }

    e := add_entity(current, name.text);
    e.status = Resolving;
    return e;
}



check_decl_scope :: proc(using checker: ^Checker, decl: ^Decl_Scope) -> bool {
    assert(decl != nil);

    e := declare_name(checker, decl.name);
    defer e.status = Resolved;

    return check_block(checker, decl.block);
}

check_decl_import :: proc(using checker: ^Checker, decl: ^Decl_Import) -> bool {
    assert(decl != nil);

    e := declare_name(checker, decl.name);
    defer e.status = Resolved;

    panic(); // @todo(bpunsky): figure this out! I guess the parser has to resolve imports?
    // @todo(bpunsky): handle foreign
    
    return true;
}

check_decl_label :: proc(using checker: ^Checker, decl: ^Decl_Label) -> bool {
    assert(decl != nil);

    e := declare_name(checker, decl.name);
    defer e.status = Resolved;

    // panic(); @error
    // @todo(bpunsky): mark the entity as a label somehow!

    return true;
}

check_decl_type :: proc(using checker: ^Checker, decl: ^Decl_Type) -> (Type, bool) {
    assert(decl != nil);

    e := declare_name(checker, decl.name);
    defer e.status = Resolved;

    // @todo(bpunsky): handle aliases
    if typ, ok := check_type(checker, decl.typ); ok {
        return typ, true;
    }

    return nil, false;
}

check_decl_var :: proc(using checker: ^Checker, decl: ^Decl_Var) -> (Type, bool) {
    assert(decl != nil);

    if len(decl.names) != 0 && len(decl.names) == len(decl.exprs) {
        for _, i in decl.names {
            name := decl.names[i];

            e := declare_name(checker, name);
            defer e.status = Resolved;

            expr := decl.exprs[i];
                
            if decl.typ != nil {
                if typ, ok := check_type(checker, decl.typ); ok {
                    if typ2, ok := check_expr(checker, expr); ok {
                        if compare_types(checker, typ, typ2) {
                            // @todo(bpunsky): untyped constant inference
                            e.typ = typ;

                            return typ, true;
                        }
                        else {
                            panic(); // @error
                        }
                    }
                }
            }
            else {
                if typ, ok := check_expr(checker, expr); ok {
                    return typ, true;
                }
            }

        }
    }
    else {
        panic(); // @error
    }

    return nil, false;
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
                str := string(make([]byte, len(l) + len(r))); // @todo(bpunsky): gotta free
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
        if _, ok := check_field(checker, field); !ok {
            return nil, false;
        }
    }

    return typ, true;
}

check_type_enum :: proc(using checker: ^Checker, typ: ^Type_Enum) -> (Type, bool) {
    assert(typ != nil);

    if _, ok := check_type(checker, typ.base); ok {
        for field in typ.fields {
            if _, ok := check_field(checker, field); !ok {
                return nil, false;
            }
        }

        return typ, true;
    }

    return nil, false;
}

check_type_proc :: proc(using checker: ^Checker, typ: ^Type_Proc) -> (Type, bool) {
    assert(typ != nil);

    for param in params {
        if _, ok := check_field(checker, param); !ok {
            return nil, false;
        }
    }

    for ret in returns {
        if _, ok := check_field(checker, ret); !ok {
            return nil, false;
        }
    }

    return typ, true;
}

check_type_array :: proc(using checker: ^Checker, typ: ^Type_Array) -> (Type, bool) {
    assert(typ != nil);

    if t, ok := check_expr(checker, typ.arg); ok {
        if is_int(t) {
            // @todo(bpunsky): this just feels wrong
            if len, ok := eval(checker, typ.arg); ok {
                typ.len = len;
         
                if _, ok := check_type(checker, typ.base); ok {
                    return typ, true;
                }
            }
        }
        else {
            // @error
        }
    }

    return nil, false;
}

check_type_ptr :: proc(using checker: ^Checker, typ: ^Type_Ptr) -> (Type, bool) {
    assert(typ != nil);

    if _, ok := check_type(checker, base); ok {
        return typ, true;
    }

    return nil, false;
}

check_type_basic :: proc(using checker: ^Checker, typ: ^Type_Basic) -> (Type, bool) {
    return typ, true; // @note(bpunsky): ???
}



check_expr_binary :: proc(using checker: ^Checker, expr: ^Expr_Binary) -> (Type, bool) {
    assert(expr != nil);

    if lhs, ok := check_expr(checker, expr.lhs); !ok {
        if rhs, ok := check_expr(checker, expr.rhs); !ok {
            if compare_types(lhs, rhs) {
                return lhs, true; // @todo(bpunsky): untyped constants
            }
            else {
                // @error
            }
        }
    }

    return nil, false;
}

check_expr_unary :: proc(using checker: ^Checker, expr: ^Expr_Unary) -> (Type, bool) {
    assert(expr != nil);

    if exp, ok := check_expr(checker, expr.exp); ok {
        return exp, true;
    }

    return nil, false;
}

check_expr_selector :: proc(using checker: ^Checker, expr: ^Expr_Selector) -> (Type, bool) {
    assert(expr != nil);

    if _, ok := check_expr(checker, expr.lhs); ok {

    }

    return nil, false;
}

check_expr_subscript :: proc(using checker: ^Checker, expr: ^Expr_Subscript) -> (Type, bool) {
    assert(expr != nil);

    return nil, false;
}

check_expr_call :: proc(using checker: ^Checker, expr: ^Expr_Call) -> (Type, bool) {
    assert(expr != nil);

    return nil, false;
}

check_expr_compound :: proc(using checker: ^Checker, expr: ^Expr_Compound) -> (Type, bool) {
    assert(expr != nil);

    return nil, false;
}

