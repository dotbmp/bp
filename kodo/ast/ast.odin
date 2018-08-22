/*
 *  @Name:     ast
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 01-06-2018 19:21:07 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 16-08-2018 12:45:19 UTC-5
 *  
 *  @Description:
 *  
 */

package ast

import "core:fmt"



Value :: union {
    i64,
    u64,
    f64,
    bool,
    string,
}



Cursor :: struct {
    start : int,
    end   : int,
    lines : int,
    chars : int,
}

using Token_Kind :: enum {
    Invalid,

    Comment,
    Newline,

    Directive,
    Keyword,
    Ident,
    Symbol,
    Int,
    Float,
    Text,
    Bool,

    End,
}

Token :: struct {
    using cursor : Cursor,

    kind : Token_Kind,
    text : string,
}



Module :: struct {
    file_name : string,

    block : ^Block,
}

print_module :: proc(module : ^Module, indent := 0) {
    fmt.printf("module (%s)\n", module.file_name);

    print_stmt(module.block, indent+1);
}



Block :: struct {
    open:  ^Token,
    close: ^Token,

    parent:   ^Block,
    entities: map[string]^Entity,
    stmts:    []Stmt,

    status: Status,
}

Entity :: struct {
    name: string,

    decl: Decl,
    typ: Type,
    val: Value,

    status: Status,
}

Name :: struct {
    using tok: ^Token,
    
    block: ^Block,

    status: Status,
}

Literal :: struct {
    tok: ^Token,
    
    val: Value,

    status: Status,
}

Field :: struct {
    col: ^Token,
    equ: ^Token,

    names: []^Name,
    typ:   Type,
    exprs: []Expr,

    status: Status,
}

Arg :: struct {
    equ  : ^Token,
    name : ^Name,
    expr : Expr,
}



using Status :: enum {
    Unresolved,
    Resolving,
    Resolved,
}



Stmt :: union {
    ^Block,

    ^Stmt_Goto,
    ^Stmt_If,
    ^Stmt_For,
    ^Stmt_Assn,
    
    Decl,

    ^Expr_Call,
}

Stmt_Goto :: struct {
    kwd  : ^Token,
    name : ^Name,
}

Stmt_If :: struct {
    kwd: ^Token,
    
    cond: Expr,
    then: ^Block,
    els:  Stmt,
}

Stmt_For :: struct {
    kwd: ^Token,
    
    decl:  Decl,
    cond:  Expr,
    iter:  Stmt,
    block: ^Block,
}

Stmt_Assn :: struct {
    op: ^Token,
    
    lhs: []Expr,
    rhs: []Expr,
}

print_stmt :: proc(stmt : Stmt, indent := 0) {
    for in 0..indent do fmt.print("  ");

    switch s in stmt {
    case ^Block:
        fmt.println("block");
        for stmt in s.stmts {
            print_stmt(stmt, indent+1);
        }

    case ^Stmt_Goto:
        fmt.println("goto");
        print_expr(s.name, indent);

    case ^Stmt_If:
        fmt.println("if");
        print_expr(s.cond, indent+1);
        print_stmt(s.then, indent+1);
        print_stmt(s.els,  indent+1);

    case ^Stmt_For:
        fmt.println("for");
        print_decl(s.decl, indent+1);
        print_expr(s.cond, indent+1);
        print_stmt(s.iter, indent+1);
        print_stmt(s.block, indent+1);

    case ^Stmt_Assn:
        fmt.println("=");
        for lhs in s.lhs {
            print_expr(lhs, indent+1);
        }
        for rhs in s.rhs {
            print_expr(rhs, indent+1);
        }

    case Decl:
        fmt.println("decl");
        print_decl(s, indent+1);

    case ^Expr_Call:
        fmt.println("call");
        print_expr(s, indent+1);
    }
}



Decl :: union {
    ^Field,

    ^Decl_Scope,
    ^Decl_Import,
    ^Decl_Label,
    ^Decl_Type,
    ^Decl_Var,
}

Decl_Scope :: struct {
    kwd: ^Token,

    name:  ^Name,
    block: ^Block,
}

Decl_Import :: struct {
    kwd: ^Token,
    
    name: ^Name,
    path: ^Token,
}

Decl_Label :: struct {
    kwd: ^Token,
    
    name: ^Name,   
}

Decl_Type :: struct {
    kwd: ^Token,
    col: ^Token,
    
    name: ^Name,
    typ:  Type,
}

Decl_Var :: struct {
    kwd: ^Token,
    alt: ^Token, // @note(bpunsky): ???
    col: ^Token,
    equ: ^Token,

    names: []^Name,
    typ:   Type,
    exprs: []Expr,
}

print_decl :: proc(decl : Decl, indent := 0) {
    for in 0..indent do fmt.print("  ");

    switch d in decl {
    case ^Field:
        fmt.println("field");
        for name in d.names {
            print_expr(name, indent+1);
        }
        print_type(d.typ, indent+1);
        for expr in d.exprs {
            print_expr(expr, indent+1);
        }   

    case ^Decl_Scope:
        fmt.println(d.kwd.text);
        print_decl(d, indent+1);

    case ^Decl_Import:
        fmt.printf("%s %s\n", d.kwd.text, d.path.text);
        if d.name != nil {
            print_expr(d.name, indent+1);
        }

    case ^Decl_Label:
        fmt.print(d.kwd.text);
        print_expr(d.name, indent+1);
    
    case ^Decl_Type:
        fmt.println(d.kwd.text);
        print_expr(d.name, indent+1);
        print_type(d.typ,  indent+1);
    
    case ^Decl_Var:
        fmt.println(d.kwd.text);
        for name in d.names {
            print_expr(name, indent+1);
        }
        print_type(d.typ, indent);
        for expr in d.exprs {
            print_expr(expr, indent+1);
        }
    }
}



Type :: union {
    ^Name,

    ^Type_Struct,
    ^Type_Enum,
    ^Type_Proc,
    ^Type_Array,
    ^Type_Ptr,
    ^Type_Basic,
}

Type_Struct :: struct {
    kwd: ^Token,
    
    fields: []^Field,
}

Type_Enum :: struct {
    kwd: ^Token,

    base:   Type,
    fields: []^Field,
}

Type_Proc :: struct {
    kwd: ^Token,
   
    params:  []^Field,
    returns: []^Field,
}

Type_Array :: struct {
    open:  ^Token,
    close: ^Token,
    tok:   ^Token, // @todo(bpunsky): ???
    
    arg:  Expr,
    base: Type,
    len:  i64,
}

Type_Ptr :: struct {
    op: ^Token,
    
    base: Type,
}

using Basic :: enum {
    Untyped_Int,
    Int64,
    Int32,
    Int16,
    Int8,

    Untyped_Uint,
    Uint64,
    Uint32,
    Uint16,
    Uint8,

    Untyped_Float,
    Float64,
    Float32,

    Untyped_Bool,
    Bool64,
    Bool32,
    Bool16,
    Bool8,

    Untyped_String,
    String,
    Ztring,
}

Type_Basic :: struct {
    tok   : ^Token,
    basic : Basic,
    size : int,
}

print_type :: proc(typ : Type, indent := 0) {
    for in 0..indent do fmt.print("  ");

    switch t in typ {
    case ^Name:
        fmt.println(t.tok.text);

    case ^Type_Struct:
        fmt.println(t.kwd.text);
        for field in t.fields {
            print_decl(field, indent+1);
        }

    case ^Type_Enum:
        fmt.println(t.kwd.text);
        for field in t.fields {
            print_decl(field, indent+1);
        }

    case ^Type_Proc:
        fmt.println(t.kwd.text);
        for param in t.params {
            print_decl(param, indent+1);
        }
        for ret in t.returns {
            print_decl(ret, indent+1);
        }

    case ^Type_Array:
        fmt.print("[");
        print_expr(t.arg, indent);
        fmt.print("]");
        print_type(t.base, indent);

    case ^Type_Ptr:
        fmt.print("^");
        print_type(t.base, indent);

    case ^Type_Basic:
        fmt.println(t.tok.text);
    }
}

new_type_basic :: proc(basic : Basic) -> ^Type_Basic {
    typ := new(Type_Basic);
    
    typ.basic = basic;

    using Basic;
    switch basic {
    case Untyped_Int:  typ.size = size_of(i32);
    case Int64:        typ.size = size_of(i64);
    case Int32:        typ.size = size_of(i32);
    case Int16:        typ.size = size_of(i16);
    case Int8:         typ.size = size_of(i8);
    
    case Untyped_Uint: typ.size = size_of(u64);
    case Uint64:       typ.size = size_of(u64);
    case Uint32:       typ.size = size_of(u32);
    case Uint16:       typ.size = size_of(u16);
    case Uint8:        typ.size = size_of(u8);
    
    case Untyped_Bool: typ.size = size_of(b8);
    case Bool64:       typ.size = size_of(b64);
    case Bool32:       typ.size = size_of(b32);
    case Bool16:       typ.size = size_of(b16);
    case Bool8:        typ.size = size_of(b8);

    case Float64:      typ.size = size_of(f64);
    case Float32:      typ.size = size_of(f32);

    case Untyped_String: typ.size = size_of(^u8) + size_of(i64);
    case String:         typ.size = size_of(^u8) + size_of(i64);
    case Ztring:         typ.size = size_of(^u8);

    case: panic();
    }

    return typ;
}


Expr :: union {
    ^Name,
    ^Literal,
    ^Arg,

    ^Expr_Binary,
    ^Expr_Unary,
    ^Expr_Selector,
    ^Expr_Subscript,
    ^Expr_Call,
    ^Expr_Compound,
}

Expr_Binary :: struct {
    op: ^Token,
    
    lhs: Expr,
    rhs: Expr,
}

Expr_Unary :: struct {
    op: ^Token,

    exp: Expr,
}

Expr_Selector :: struct {
    op: ^Token,
    
    lhs: Expr,
    rhs: Expr,
}

Expr_Subscript :: struct {
    open:  ^Token,
    close: ^Token,
    
    item: Expr,
    arg:  Expr,
}

Expr_Call :: struct {
    open  : ^Token,
    close : ^Token,
    item  : Expr,
    args  : []^Arg,
}

Expr_Compound :: struct {
    open  : ^Token,
    close : ^Token,
    item  : Type,
    args  : []^Arg,
}

print_expr :: proc(expr : Expr, indent := 0) {
    for in 0..indent do fmt.print("  ");

    switch e in expr {
    case ^Name:
        fmt.println(e.tok.text);

    case ^Literal:
        fmt.println(e.val);

    case ^Arg:
        fmt.println("arg");
        if e.name != nil {
            print_expr(e.name, indent+1);
        }
        print_expr(e.expr, indent+1);

    case ^Expr_Binary:
        fmt.println(e.op.text);
        print_expr(e.lhs, indent+1);
        print_expr(e.rhs, indent+1);

    case ^Expr_Unary:
        fmt.println(e.op.text);
        print_expr(e.exp, indent+1);

    case ^Expr_Selector:
        fmt.println(".");
        print_expr(e.lhs, indent+1);
        print_expr(e.rhs, indent+1);

    case ^Expr_Subscript:
        fmt.println("[]");
        print_expr(e.item, indent+1);
        print_expr(e.arg,  indent+1);

    case ^Expr_Call:
        fmt.println("()");
        print_expr(e.item, indent+1);
        for arg in e.args {
            print_expr(arg, indent+1);
        }

    case ^Expr_Compound:
        fmt.println("{}");
        print_type(e.item, indent+1);
        for arg in e.args {
            print_expr(arg, indent+1);
        }
    }
}



print :: proc[print_module, print_stmt, print_decl, print_type, print_expr];
