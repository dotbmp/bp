/*
 *  @Name:     ssa
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 22-07-2018 00:11:10 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 22-07-2018 01:06:13 UTC-5
 *  
 *  @Description:
 *  
 */

package intera


Type :: union {
    ^Type_Basic,
    ^Type_Struct,
}

Basic :: enum {
    I8,
    I16,
    I32,
    I64,
    
    U8,
    U16,
    U32,
    U64,

    F32,
    F64,
}

Type_Basic :: struct {
    basic : Basic,
    size  : int,
}

Type_Struct :: struct {
    fields : []Type,
    size   : int,
}


Instr :: union {
    ^Instr_Binary,
    ^Instr_Unary,
    ^Instr_Goto,
}

Binary :: struct {
    ADD,
    SUB,
    MUL,
    DIV,
    REM,

    AND,
    OR,
    NOR,
}

Instr_Binary :: struct {
    kind : Binary,
    lhs  : ^Value,
    rhs  : ^Value,
}

Unary :: enum {
    NOT,
    DEREF,
    ADDR,
    NEG,
}

Instr_Unary :: struct {
    kind : Unary,
    exp  : ^Value,
}

Instr_Goto :: struct {
    index : int,
}


Value :: union {
    ^Literal,
    ^Selector,
    ^Name,
}

Literal :: union {
    i8,
    i16,
    i32,
    i64,
    i64,
    
    u8,
    u16,
    u32,
    u64,
    u64,

    f32,
    f64,
}

Symbol :: struct {
    ^Var,
    ^Temp,
    ^Block,
}

Name :: struct {
    text : string,
}

Var :: struct {
    name : string,
    typ  : Type,
    temps : []^Temp,
}

Selector :: struct {
    lhs : Value,
    rhs : Value,
}

Temp :: struct {
    index : int,
    typ   : Type,
}

Block :: struct {
    index  : int,
    locals : []Var,
    exprs  : []Instr,
    symbols : map[string]Symbol,
}

Proc :: struct {
    blocks : []Block,
}



