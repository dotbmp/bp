/*
 *  @Name:     ir
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 20-07-2018 13:15:40 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 22-07-2018 13:05:41 UTC-5
 *  
 *  @Description:
 *  
 */

package ir

import "cio:kodo/ast"



Generator :: struct {
    global : ^Block,
    block  : ^Block,
}



write_code :: inline proc(using gen : ^Generator, format : string, args : ...any) {
    fmt.sbprintf(&code, format, ...args);
}

write_code_indent :: inline proc(using gen : ^Generator, format := "", args : ...any) {
    for in 0..code_indent {
        fmt.sbprint(&code, "    ");
    }

    fmt.sbprintf(&code, format, ...args);
}

write_data :: inline proc(using gen : ^Generator, format : string, args : ...any) {
    fmt.sbprintf(&data, format, ...args);
}

write_data_indent :: inline proc(using gen : ^Generator, format := "", args : ...any) {
    for in 0..data_indent {
        fmt.sbprint(&data, "    ");
    }

    fmt.sbprintf(&data, format, ...args);
}

write_import_indent :: inline proc(using gen : ^Generator, format : string, args : ...any) {
    for in 0..import_indent {
        fmt.sbprint(&imports, "    ");
    }

    fmt.sbprintf(&imports, format, ...args);
}



next_temp :: inline proc(using gen : ^Generator) -> string {
    defer temp_index += 1;

    return fmt.aprintf("t%d", temp_index);
}

next_type :: inline proc(using gen : ^Generator) -> string {
    defer type_index += 1;

    return fmt.aprintf("type%d", type_index);
}



generate_module_file :: proc(module : ^ast.Module, file_name : string) -> bool {
    if source := generate_module_text(module); source != "" {
        if os.write_entire_file(file_name, ([]byte)(source)) {
            return true;
        }
    }

    return false;
}

generate_module_text :: proc(module : ^ast.Module) -> string {
    gen : Generator;
    
    defer {
        delete(gen.imports);
        delete(gen.data);
        delete(gen.code);
    }

    block := generate_block(&gen, module.block);

    if block := generate_block(&gen, module.block); block != "" {
        defer delete(block);

        buf : fmt.String_Buffer;

        return fmt.aprintf("%s\n%s\nint main(int argc, char **argv) %s\n\n",
            fmt.to_string(gen.imports),
            fmt.to_string(gen.data),
            block,
        );
    }

    return "";
}



generate_stmt :: proc(using gen : ^Generator, stmt : ast.Stmt) -> string {
    switch s in stmt {
    case ^ast.Block:     return generate_block(gen, s);
    case ^ast.Stmt_Goto: return generate_stmt_goto(gen, s);
    case ^ast.Stmt_If:   return generate_stmt_if(gen, s);
    case ^ast.Stmt_For:  return generate_stmt_for(gen, s);
    case ^ast.Stmt_Assn: return generate_stmt_assn(gen, s);
    case ast.Decl:       return generate_decl(gen, s);

    case ^ast.Expr_Call:
        if call := generate_expr(gen, s); call != "" {
            defer delete(call);

            return fmt.aprintf("%s;", call);
        }
    }

    return "";
}

generate_block :: proc(using gen : ^Generator, block : ^ast.Block) -> string {
    buf : fmt.String_Buffer;

    fmt.sbprint(&buf, "{\n");
    code_indent += 1;

    for stmt, i in block.stmts {
        if s := generate_stmt(gen, stmt); s != "" {
            tmp := fmt.to_string(code);
            defer {
                delete(code);
                code = fmt.String_Buffer{};
            }

            fmt.sbprint(&buf, tmp);

            fmt.sbprintf(&buf, "%s\n", s);
        }
        else {
            panic(); // @error
        }
    }

    code_indent -= 1;
    fmt.sbprint(&buf, "}");

    return fmt.to_string(buf);
}

generate_stmt_goto :: proc(using gen : ^Generator, stmt : ^ast.Stmt_Goto) -> string {
    if name := generate_name(gen, stmt.name); name != "" {
        defer delete(name);

        return fmt.aprintf("goto %s;", name);
    }

    return "";
}

generate_stmt_if :: proc(using gen : ^Generator, stmt : ^ast.Stmt_If) -> string {
    if cond := generate_expr(gen, stmt.cond); cond != "" {
        defer delete(cond);
        
        if then := generate_block(gen, stmt.then); then != "" {
            defer delete(then);

            if stmt.els != nil {
                if els := generate_stmt(gen, stmt.els); els != "" {
                    return fmt.aprintf("if (%s) %s else %s", cond, then, els);
                }
            }
            else {
                return fmt.aprintf("if (%s) %s", cond, then);
            }
        }
    }
    
    return "";
}

generate_stmt_for :: proc(using gen : ^Generator, stmt : ^ast.Stmt_For) -> string {
    if decl := generate_decl(gen, stmt.decl); decl != "" {
        defer delete(decl);

        if cond := generate_expr(gen, stmt.cond); cond != "" {
            defer delete(cond);

            if iter := generate_stmt(gen, stmt.iter); iter != "" {
                defer delete(iter);

                if block := generate_block(gen, stmt.block); block != "" {
                    defer delete(block);

                    return fmt.aprintf("%s\nfor (; %s; %s) %s", decl, cond, iter, block);
                }
            }
        }
    }

    return "";
}

generate_stmt_assn :: proc(using gen : ^Generator, stmt : ^ast.Stmt_Assn) -> string {
    for _, i in stmt.lhs {
        if lhs := generate_expr(gen, stmt.lhs[i]); lhs != "" {
            defer delete(lhs);

            if rhs := generate_expr(gen, stmt.rhs[i]); rhs != "" {
                defer delete(rhs);

                return fmt.aprintf("%s %s %s;\n", lhs, stmt.op.text, rhs);
            }
        }
    }

    return "";
}



generate_decl :: proc(using gen : ^Generator, decl : ast.Decl) -> string {
    switch d in decl {
    case ^ast.Field:       return generate_field(gen, d);
    case ^ast.Decl_Scope:  return generate_decl_scope(gen, d);
    case ^ast.Decl_Import: return generate_decl_import(gen, d);
    case ^ast.Decl_Label:  return generate_decl_label(gen, d);
    case ^ast.Decl_Type:   return generate_decl_type(gen, d);
    case ^ast.Decl_Var:    return generate_decl_var(gen, d);
    case: panic();
    }

    return "";
}

generate_field :: proc(using gen : ^Generator, decl : ^ast.Field) -> string {
    for _, i in decl.names {
        write_data_indent(gen);

        if decl.typ != nil {
            if typ := generate_type(gen, decl.typ); typ != "" {
                defer delete(typ);

                write_data(gen, "%s ", typ);
            }
        }
        else {
            write_data(gen, "auto ");
        }

        if name := generate_expr(gen, decl.names[i]); name != "" {
            defer delete(name);

            write_data(gen, name);

            if decl.exprs != nil {
                write_data(gen, " = ");

                if expr := generate_expr(gen, decl.exprs[i]); expr != "" {
                    defer delete(expr);

                    write_data(gen, expr);
                }
            }
        }
    }

    return "";
}

generate_decl_scope :: proc(using gen : ^Generator, decl : ^ast.Decl_Scope) -> string {
    panic();
    return "";
}

generate_decl_import :: proc(using gen : ^Generator, decl : ^ast.Decl_Import) -> string {
    switch decl.kwd.text {
    case "import":
        panic();

    case "foreign":
        write_import_indent(gen, "#include <%s>\n", decl.path.text[1..len(decl.path.text)-1]);
    }

    return "";
}

generate_decl_label :: proc(using gen : ^Generator, decl : ^ast.Decl_Label) -> string {
    if name := generate_expr(gen, decl.name); name != "" {
        defer delete(name);

        return fmt.aprintf("%s:", name);
    }

    return "";
}

generate_decl_type :: proc(using gen : ^Generator, decl : ^ast.Decl_Type) -> string {
    if typ := generate_type(gen, decl.typ); typ != "" {
        defer delete(typ);

        if name := generate_expr(gen, decl.name); name != "" {
            defer delete(name);

            write_data(gen, "typedef %s %s;\n", typ, name);
        }
    }

    return "";
}

generate_decl_var :: proc(using gen : ^Generator, decl : ^ast.Decl_Var) -> string {
    for _, i in decl.names {
        write_code_indent(gen);

        if decl.typ != nil {
            if typ := generate_type(gen, decl.typ); typ != "" {
                defer delete(typ);
            
                write_code(gen, "%s ", typ);
            }
        }
        else {
            write_code(gen, "auto ");
        }

        if name := generate_expr(gen, decl.names[i]); name != "" {
            defer delete(name);

            write_code(gen, name);

            if decl.alt != nil {
                write_code(gen, " = %s", decl.alt.text[1..len(decl.alt.text)-1]);
            }
            else if decl.exprs != nil {
                write_code(gen, " = ");

                if expr := generate_expr(gen, decl.exprs[i]); expr != "" {
                    defer delete(expr);

                    write_code(gen, expr);
                }
            }

            write_code(gen, ";\n");
        }
    }

    return "";
}



generate_type :: proc(using gen : ^Generator, typ : ast.Type) -> string {
    switch t in typ {
    case ^ast.Name:        return generate_name(gen, t);
    case ^ast.Type_Struct: return generate_type_struct(gen, t);
    case ^ast.Type_Enum:   return generate_type_enum(gen, t);
    case ^ast.Type_Proc:   return generate_type_proc(gen, t);
    case ^ast.Type_Array:  return generate_type_array(gen, t);
    case ^ast.Type_Ptr:    return generate_type_ptr(gen, t);
    case ^ast.Type_Basic:  return generate_type_basic(gen, t);
    case: panic();
    }

    return "";
}

generate_type_struct :: proc(using gen : ^Generator, typ : ^ast.Type_Struct) -> string {
    panic();
    return "";
}

generate_type_enum :: proc(using gen : ^Generator, typ : ^ast.Type_Enum) -> string {
    panic();
    return "";
}

generate_type_proc :: proc(using gen : ^Generator, typ : ^ast.Type_Proc) -> string {
    write_data(gen, "typedef ");

    switch len(typ.returns) {
    case 0:
        write_data(gen, "void");

    case:
        write_data(gen, "struct{");
        
        for ret, i in typ.returns {
            generate_field(gen, ret);

            write_data(gen, ";");
            
            if i == len(typ.returns)-1 {
                write_data(gen, " ");
            }
        }

        write_data(gen, "}");
    }

    temp := next_type(gen);

    write_data(gen, " (*%s)(", temp);

    for param, i in typ.params {
        generate_field(gen, param);

        if i < len(typ.params)-1 {
            write_data(gen, ", ");
        }
    }
    
    write_data(gen, ");\n");

    return temp;
}

generate_type_array :: proc(using gen : ^Generator, typ : ^ast.Type_Array) -> string {
    panic();
    return "";
}

generate_type_ptr :: proc(using gen : ^Generator, typ : ^ast.Type_Ptr) -> string {
    panic();
    return "";
}

generate_type_basic :: proc(using gen : ^Generator, typ : ^ast.Type_Basic) -> string {
    using ast.Basic;

    switch typ.basic {
    case Int:     return fmt.aprint("i64");
    case Int8:    return fmt.aprint("i8");
    case Int16:   return fmt.aprint("i16");
    case Int32:   return fmt.aprint("i32");
    case Int64:   return fmt.aprint("i64");

    case Uint:    return fmt.aprint("u64");
    case Uint8:   return fmt.aprint("u8");
    case Uint16:  return fmt.aprint("u16");
    case Uint32:  return fmt.aprint("u32");
    case Uint64:  return fmt.aprint("u64");

    case Float32: return fmt.aprint("f32");
    case Float64: return fmt.aprint("f64");

    case Bool:    return fmt.aprint("i8");
    case Bool8:   return fmt.aprint("i8");
    case Bool16:  return fmt.aprint("i16");
    case Bool32:  return fmt.aprint("i32");
    case Bool64:  return fmt.aprint("i64");

    case String:  return fmt.aprint("struct{uint8_t *data; uint64_t len;}");
    case Ztring:  return fmt.aprint("char *");
    }

    return "";
}



generate_expr :: proc(using gen : ^Generator, expr : ast.Expr) -> string {
    switch e in expr {
    case ^ast.Name:           return generate_name(gen, e);
    case ^ast.Literal:        return generate_literal(gen, e);
    case ^ast.Arg:            return generate_arg(gen, e);
    case ^ast.Expr_Binary:    return generate_expr_binary(gen, e);
    case ^ast.Expr_Unary:     return generate_expr_unary(gen, e);
    case ^ast.Expr_Selector:  return generate_expr_selector(gen, e);
    case ^ast.Expr_Subscript: return generate_expr_subscript(gen, e);
    case ^ast.Expr_Call:      return generate_expr_call(gen, e);
    case ^ast.Expr_Compound:  return generate_expr_compound(gen, e);
    case: panic();
    }

    return "";
}

generate_name :: proc(using gen : ^Generator, expr : ^ast.Name) -> ir.Symbol {
    return block.symbols[expr.tok.text];
}

generate_literal :: proc(using gen : ^Generator, expr : ^ast.Literal) -> ^ir.Literal {
    lit := new(ir.Literal);

    if expr.val == nil {
        lit = 0;
    }
    else {
        switch v in expr.val {
        case i64:    lit = v;
        case u64:    lit = v;
        case bool:   lit = v ? 1 : 0;
        case string: lit = v;
        case:        lit = v;
        }
    }

    return lit;
}

generate_arg :: proc(using gen : ^Generator, expr : ^ast.Arg) -> string {
    if expr.name != nil {
        if name := generate_expr(gen, expr.name); name != "" {
            defer delete(name);

            if exp := generate_expr(gen, expr.expr); exp != "" {
                defer delete(exp);
                
                return fmt.aprintf("%s = %s", name, exp);
            }
        }
    }
    else {
        if exp := generate_expr(gen, expr.expr); exp != "" {
            defer delete(exp);

            return fmt.aprintf("%s", exp);
        }
    }

    return "";
}

generate_expr_binary :: proc(using gen : ^Generator, expr : ^ast.Expr_Binary) -> string {
    instr := new(ir.Instr_Binary);

    instr.lhs = generate_expr(gen, expr.lhs);
    instr.rhs = generate_expr(gen, expr.rhs);

    switch expr.op.text {
    case "+":  instr.kind = ir.Binary.ADD;
    case "-":  instr.kind = ir.Binary.SUB;
    case "*":  instr.kind = ir.Binary.MUL;
    case "/":  instr.kind = ir.Binary.DIV;
    case "%":  instr.kind = ir.Binary.REM;
    case ">":  instr.kind = ir.Binary.GT;
    case "<":  instr.kind = ir.Binary.LT;
    case "&":  instr.kind = ir.Binary.BAND;
    case "|":  instr.kind = ir.Binary.BOR;
    case "~~": instr.kind = ir.Binary.XOR;
    case "==": instr.kind = ir.Binary.CMP;
    case ">>": instr.kind = ir.Binary.SHR;
    case "<<": instr.kind = ir.Binary.SHL;
    case "!=": instr.kind = ir.Binary.NEQ;
    case ">=": instr.kind = ir.Binary.GTE;
    case "<=": instr.kind = ir.Binary.LTE;
    }

    return instr;
}

generate_expr_unary :: proc(using gen : ^Generator, expr : ^ast.Expr_Unary) -> string {
    if exp := generate_expr(gen, expr.exp); exp != "" {
        defer delete(exp);

        temp := next_temp(gen);

        switch expr.op.text {
        case "^": write_code(gen, "auto %s = &%s;\n", temp, exp);
        case "+": write_code(gen, "auto %s = +%s;\n", temp, exp);
        case "-": write_code(gen, "auto %s = -%s;\n", temp, exp);
        case "!": write_code(gen, "auto %s = !%s;\n", temp, exp);
        case "~": write_code(gen, "auto %s = ~%s;\n", temp, exp);
        }

        return temp;
    }

    return "";
}

generate_expr_selector :: proc(using gen : ^Generator, expr : ^ast.Expr_Selector) -> string {
    if lhs := generate_expr(gen, expr.lhs); lhs != "" {
        defer delete(lhs);

        if rhs := generate_expr(gen, expr.rhs); rhs != "" {
            defer delete(rhs);
            
            fmt.aprintf("%s.%s", lhs, rhs);
        }
    }

    return "";
}

generate_expr_subscript :: proc(using gen : ^Generator, expr : ^ast.Expr_Subscript) -> string {
    if item := generate_expr(gen, expr.item); item != "" {
        defer delete(item);
        
        if arg := generate_expr(gen, expr.arg); arg != "" {
            defer deletes(arg);
            
            return fmt.aprintf("%s[%s]", item, arg);
        }
    }

    return "";
}

generate_expr_call :: proc(using gen : ^Generator, expr : ^ast.Expr_Call) -> string {
    buf : fmt.String_Buffer;

    if item := generate_expr(gen, expr.item); item != "" {
        defer delete(item);
    
        fmt.sbprintf(&buf, "%s(", item);

        for _, i in expr.args {
            if arg := generate_expr(gen, expr.args[i]); arg != "" {
                defer delete(arg);

                fmt.sbprintf(&buf, arg);

                if i < len(expr.args)-1 {
                    fmt.sbprintf(&buf, ", ");
                }
            }
        }

        fmt.sbprintf(&buf, ")");

        return fmt.to_string(buf);
    }

    return "";
}

generate_expr_compound :: proc(using gen : ^Generator, expr : ^ast.Expr_Compound) -> string {
    buf : fmt.String_Buffer;

    if lhs := generate_type(gen, expr.item); lhs != "" {
        defer delete(lhs);

        args : [dynamic]string;
        defer delete(args);

        for _, i in expr.args {
            if arg := generate_arg(gen, expr.args[i]); arg != "" {            
                append(&args, arg);

                for in 0..code_indent {
                    fmt.sbprint(&buf, "    ");
                }

                fmt.sbprint(&buf, arg);

                if i != len(expr.args)-1 {
                    fmt.sbprint(&buf, ";\n");
                }
            }
        }

        fmt.sbprintf(&buf, "%s{\n", lhs);
        code_indent += 1;
        
        for arg in args {
            fmt.sbprint(&buf, arg);       
        }
        
        code_indent -= 1;
        fmt.sbprint(&buf, "}");

        return fmt.to_string(buf);
    }

    return "";
}
