/*
 *  @Name:     c
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 01-06-2018 19:21:54 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 12-08-2018 22:11:03 UTC-5
 *  
 *  @Description:
 *  
 */

package c

import "core:fmt"
import "core:mem"
import "core:os"

import "bp:kodo/ast"
import "bp:kodo/util"



Generator :: struct {
    imports : fmt.String_Buffer,
    code    : fmt.String_Buffer,
    data    : fmt.String_Buffer,
    
    pred : fmt.String_Buffer,
    succ : fmt.String_Buffer,

    stack : [dynamic]string,

    import_indent : int,
    code_indent   : int,
    data_indent   : int,
    
    temp_index : int,
    type_index : int,
}



next_temp :: inline proc(using gen : ^Generator) -> string {
    defer temp_index += 1;

    return fmt.aprintf("t%d", temp_index);
}

next_type :: inline proc(using gen : ^Generator) -> string {
    defer type_index += 1;

    return fmt.aprintf("type%d", type_index);
}



write_imports :: inline proc(using gen : ^Generator, format : string, args : ..any) {
    fmt.sbprintf(&imports, format, ..args);
}

write_import_indent :: inline proc(using gen : ^Generator, format : string, args : ..any) {
    for in 0..import_indent {
        fmt.sbprint(&imports, "    ");
    }

    fmt.sbprintf(&imports, format, ..args);
}

write_data :: inline proc(using gen : ^Generator, format : string, args : ..any) {
    fmt.sbprintf(&data, format, ..args);
}

write_data_indent :: inline proc(using gen : ^Generator, format := "", args : ..any) {
    for in 0..data_indent {
        fmt.sbprint(&data, "    ");
    }

    fmt.sbprintf(&data, format, ..args);
}

write_code :: inline proc(using gen : ^Generator, format : string, args : ..any) {
    fmt.sbprintf(&code, format, ..args);
}

write_code_indent :: inline proc(using gen : ^Generator, format := "", args : ..any) {
    for in 0..code_indent {
        fmt.sbprint(&code, "    ");
    }

    fmt.sbprintf(&code, format, ..args);
}



push_stack :: inline proc(using gen : ^Generator, format : string, args : ..any) {
    append(&stack, fmt.aprintf(format, ..args));
}

pop_stack_data :: inline proc(using gen : ^Generator) {
    tmp := stack[len(stack)-1];
    defer delete(tmp);

    (^mem.Raw_Dynamic_Array)(&stack).len -= 1;
    
    fmt.sbprint(&data, tmp);
}

pop_stack_pred :: inline proc(using gen : ^Generator) {
    tmp := stack[len(stack)-1];
    defer delete(tmp);

    (^mem.Raw_Dynamic_Array)(&stack).len -= 1;
    
    fmt.sbprint(&pred, tmp);
}

pop_stack_succ :: inline proc(using gen : ^Generator) {
    tmp := stack[len(stack)-1];
    defer delete(tmp);

    (^mem.Raw_Dynamic_Array)(&stack).len -= 1;
    
    fmt.sbprint(&succ, tmp);
}



write_pred :: inline proc(using gen : ^Generator, format : string, args : ..any) {
    fmt.sbprintf(&pred, format, ..args);
}

write_pred_indent :: inline proc(using gen : ^Generator, format := "", args : ..any) {
    for in 0..code_indent {
        fmt.sbprint(&pred, "    ");
    }

    fmt.sbprintf(&pred, format, ..args);
}

flush_pred :: inline proc(using gen : ^Generator) {
    fmt.sbprint(&code, fmt.to_string(pred));
    clear(&pred);
}

write_succ :: inline proc(using gen : ^Generator, format : string, args : ..any) {
    fmt.sbprintf(&succ, format, ..args);
}

write_succ_indent :: inline proc(using gen : ^Generator, format := "", args : ..any) {
    for in 0..code_indent {
        fmt.sbprint(&succ, "    ");
    }

    fmt.sbprintf(&succ, format, ..args);
}

flush_succ :: inline proc(using gen : ^Generator) {
    fmt.sbprint(&code, fmt.to_string(succ));
    clear(&succ);
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
        delete(gen.pred);
        delete(gen.succ);
    }


    if generate_block(&gen, module.block) {
        flush_pred(&gen);
        flush_succ(&gen);

        buf : fmt.String_Buffer;

        return fmt.aprintf("%s\n%s\nint main(int argc, char **argv) %s",
            fmt.to_string(gen.imports),
            fmt.to_string(gen.data),
            fmt.to_string(gen.code),
        );
    }

    return "";
}



generate_stmt :: proc(using gen : ^Generator, stmt : ast.Stmt) -> bool {
    switch s in stmt {
    case ^ast.Block:     return generate_block(gen, s);
    case ^ast.Stmt_Goto: return generate_stmt_goto(gen, s);
    case ^ast.Stmt_If:   return generate_stmt_if(gen, s);
    case ^ast.Stmt_For:  return generate_stmt_for(gen, s);
    case ^ast.Stmt_Assn: return generate_stmt_assn(gen, s);
    case ast.Decl:       return generate_decl(gen, s);

    case ^ast.Expr_Call:
        write_succ_indent(gen);

        if generate_expr(gen, s) {
            write_succ(gen, ";\n");

            return true;
        }

    case: panic();
    }

    return false;
}

generate_block :: proc(using gen : ^Generator, block : ^ast.Block) -> bool {
    write_succ_indent(gen, "{\n");

    flush_pred(gen);
    flush_succ(gen);
    code_indent += 1;

    for stmt, i in block.stmts {
        if generate_stmt(gen, stmt) {
            flush_pred(gen);
            flush_succ(gen);
        }
        else {
            ast.print(stmt);
            return false;
        }
    }

    code_indent -= 1;
    write_succ_indent(gen, "}\n");

    return true;
}

generate_stmt_goto :: proc(using gen : ^Generator, stmt : ^ast.Stmt_Goto) -> bool {
    write_succ(gen, "goto ");

    if generate_name(gen, stmt.name) {
        pop_stack_succ(gen);

        write_succ(gen, ";");

        return true;
    }

    return false;
}

generate_stmt_if :: proc(using gen : ^Generator, stmt : ^ast.Stmt_If) -> bool {
    write_succ_indent(gen, "{\n");

    flush_pred(gen);
    flush_succ(gen);
    code_indent += 1;

    write_succ_indent(gen, "if (");

    if generate_expr(gen, stmt.cond) {
        pop_stack_succ(gen);
        
        write_succ(gen, ")\n");

        if generate_block(gen, stmt.then) {
            if stmt.els != nil {
                write_succ(gen, " else ");

                if generate_stmt(gen, stmt.els) {
                    code_indent -= 1;
                    write_succ_indent(gen, "}\n");

                    return true;
                }
            }
            else {
                code_indent -= 1;
                write_succ_indent(gen, "}\n");

                return true;
            }
        }
    }
    
    return false;
}

generate_stmt_for :: proc(using gen : ^Generator, stmt : ^ast.Stmt_For) -> bool {
    write_succ_indent(gen, "{\n");

    flush_pred(gen);
    flush_succ(gen);
    code_indent += 1;
    
    if generate_decl(gen, stmt.decl) {
        write_succ_indent(gen, "while (1)\n");
        write_succ_indent(gen, "{\n");

        flush_pred(gen);
        flush_succ(gen);
        code_indent += 1;

        write_succ_indent(gen, "if (!");

        if generate_expr(gen, stmt.cond) {
            pop_stack_succ(gen);

            write_succ(gen, ") break;\n");

            if generate_block(gen, stmt.block) {

                if generate_stmt(gen, stmt.iter) {
                    code_indent -= 1;
                    write_succ_indent(gen, "}\n");
                    
                    code_indent -= 1;
                    write_succ_indent(gen, "}\n");

                    return true;
                }
            }
        }
    }

    return false;
}

generate_stmt_assn :: proc(using gen : ^Generator, stmt : ^ast.Stmt_Assn) -> bool {
    for _, i in stmt.lhs {
        write_succ_indent(gen);

        if generate_expr(gen, stmt.lhs[i]) {
            pop_stack_succ(gen);

            write_succ(gen, " %s ", stmt.op.text);

            if generate_expr(gen, stmt.rhs[i]) {
                pop_stack_succ(gen);

                write_succ(gen, ";\n");

                return true;
            }
        }
    }

    return false;
}



generate_decl :: proc(using gen : ^Generator, decl : ast.Decl) -> bool {
    switch d in decl {
    case ^ast.Field:       return generate_field(gen, d);
    case ^ast.Decl_Scope:  return generate_decl_scope(gen, d);
    case ^ast.Decl_Import: return generate_decl_import(gen, d);
    case ^ast.Decl_Label:  return generate_decl_label(gen, d);
    case ^ast.Decl_Type:   return generate_decl_type(gen, d);
    case ^ast.Decl_Var:    return generate_decl_var(gen, d);
    case: panic();
    }

    return false;
}

generate_field :: proc(using gen : ^Generator, decl : ^ast.Field) -> bool {
    for _, i in decl.names {
        if decl.typ != nil {
            if generate_type(gen, decl.typ) {
                pop_stack_data(gen);

                write_data(gen, " ");
            }
            else {
                return false;
            }
        }
        else {
            write_data(gen, "auto ");
        }

        if generate_expr(gen, decl.names[i]) {
            pop_stack_data(gen);

            if decl.exprs != nil {
                write_data(gen, " = ");

                if generate_expr(gen, decl.exprs[i]) {
                    pop_stack_data(gen);
                }
                else {
                    return false;
                }
            }
        }
        else {
            return false;
        }
    }

    return true;
}

generate_decl_scope :: proc(using gen : ^Generator, decl : ^ast.Decl_Scope) -> bool {
    panic();
    return false;
}

generate_decl_import :: proc(using gen : ^Generator, decl : ^ast.Decl_Import) -> bool {
    switch decl.kwd.text {
    case "import":
        panic();

    case "foreign":
        write_import_indent(gen, "#include <%s>\n", decl.path.text[1:len(decl.path.text)-1]);
        return true;
    }

    return false;
}

generate_decl_label :: proc(using gen : ^Generator, decl : ^ast.Decl_Label) -> bool {
    if generate_expr(gen, decl.name) {
        pop_stack_succ(gen);

        write_succ(gen, ":");

        return true;
    }

    return false;
}

generate_decl_type :: proc(using gen : ^Generator, decl : ^ast.Decl_Type) -> bool {
    write_data_indent(gen, "typedef ");

    if generate_type(gen, decl.typ) {
        write_data(gen, " ");

        if generate_name(gen, decl.name) {
            pop_stack_data(gen);
            
            write_data(gen, ";\n");

            return true;
        }
    }

    return false;
}

generate_decl_var :: proc(using gen : ^Generator, decl : ^ast.Decl_Var) -> bool {
    for _, i in decl.names {
        write_pred_indent(gen);

        if decl.typ != nil {
            if generate_type(gen, decl.typ) {
                pop_stack_pred(gen);

                write_pred(gen, " ");
            }
            else {
                return false;
            }
        }
        else {
            write_pred(gen, "auto ");
        }

        if generate_expr(gen, decl.names[i]) {
            pop_stack_pred(gen);

            write_pred(gen, " = ");
            
            if decl.alt != nil {
                write_pred(gen, decl.alt.text[1:len(decl.alt.text)-1]);
            }
            else if decl.exprs != nil {
                if generate_expr(gen, decl.exprs[i]) {
                    pop_stack_pred(gen);
                }
                else {
                    return false;
                }
            }

            write_pred(gen, ";\n");
        }
        else {
            return false;
        }
    }

    return true;
}



generate_type :: proc(using gen : ^Generator, typ : ast.Type) -> bool {
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

    return false;
}

generate_type_struct :: proc(using gen : ^Generator, typ : ^ast.Type_Struct) -> bool {
    panic();
    return false;
}

generate_type_enum :: proc(using gen : ^Generator, typ : ^ast.Type_Enum) -> bool {
    panic();
    return false;
}

generate_type_proc :: proc(using gen : ^Generator, typ : ^ast.Type_Proc) -> bool {
    write_data_indent(gen, "typedef ");

    if len(typ.returns) == 0 {
        write_data(gen, "void");
    }
    else {
        write_data(gen, "struct{");
        
        for ret, i in typ.returns {
            write_data_indent(gen);

            if !generate_field(gen, ret) {
                return false;
            }

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
        write_data_indent(gen);

        if !generate_field(gen, param) {
            return false;
        }

        if i < len(typ.params)-1 {
            write_data(gen, ", ");
        }
    }
    
    write_data(gen, ");\n");

    push_stack(gen, temp); // @todo

    return true;
}

generate_type_array :: proc(using gen : ^Generator, typ : ^ast.Type_Array) -> bool {
    panic();
    return false;
}

generate_type_ptr :: proc(using gen : ^Generator, typ : ^ast.Type_Ptr) -> bool {
    panic();
    return false;
}

generate_type_basic :: proc(using gen : ^Generator, typ : ^ast.Type_Basic) -> bool {
    using ast.Basic;

    switch typ.basic {
    case Int:     write_data(gen, "int64_t");
    case Int8:    write_data(gen, "int8_t");
    case Int16:   write_data(gen, "int16_t");
    case Int32:   write_data(gen, "int32_t");
    case Int64:   write_data(gen, "int64_t");

    case Uint:    write_data(gen, "uint64_t");
    case Uint8:   write_data(gen, "uint8_t");
    case Uint16:  write_data(gen, "uint16_t");
    case Uint32:  write_data(gen, "uint32_t");
    case Uint64:  write_data(gen, "uint64_t");

    case Float32: write_data(gen, "float");
    case Float64: write_data(gen, "double");

    case Bool:    write_data(gen, "int8_t");
    case Bool8:   write_data(gen, "int8_t");
    case Bool16:  write_data(gen, "int16_t");
    case Bool32:  write_data(gen, "int32_t");
    case Bool64:  write_data(gen, "int64_t");

    case String:  write_data(gen, "struct{uint8_t *data; uint64_t len;}");
    case Ztring:  write_data(gen, "uint8_t *");

    case:
        panic();
        return false;
    }

    return true;
}



generate_expr :: proc(using gen : ^Generator, expr : ast.Expr) -> bool {
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

    return false;
}

generate_name :: proc(using gen : ^Generator, expr : ^ast.Name) -> bool {
    push_stack(gen, "_%s", expr.tok.text);

    return true;
}

generate_literal :: proc(using gen : ^Generator, expr : ^ast.Literal) -> bool {
    if expr.val == nil {
        push_stack(gen, "%d", 0);
    }
    else {
        switch v in expr.val {
        case string: push_stack(gen, `"%s"`, util.escape_string(v));
        case bool:   push_stack(gen, "%d",   v ? 1 : 0);
        case:        push_stack(gen, "%v",   v);
        }
    }

    return true;
}

generate_arg :: proc(using gen : ^Generator, expr : ^ast.Arg) -> bool {
    if expr.name != nil {
        /*
        if generate_expr(gen, expr.name) {
            pop_stack_succ(gen);

            write_succ(gen, " = ");

            if generate_expr(gen, expr.expr) {
                pop_stack_succ(gen);

                return true;
            }
        }
        */

        panic();
    }
    else {
        if generate_expr(gen, expr.expr) {
            // pop_stack_succ(gen);
            
            return true;
        }
    }

    return false;
}

generate_expr_binary :: proc(using gen : ^Generator, expr : ^ast.Expr_Binary) -> bool {

    if generate_expr(gen, expr.rhs) {
        if generate_expr(gen, expr.lhs) {
            temp := next_temp(gen);
            
            write_pred_indent(gen, "auto %s = ", temp);

            pop_stack_pred(gen);
            
            switch expr.op.text {
            case "+":   write_pred(gen, " + ");
            case "-":   write_pred(gen, " - ");
            case "*":   write_pred(gen, " * ");
            case "/":   write_pred(gen, " / ");
            case "%":   write_pred(gen, " % ");
            case ">":   write_pred(gen, " > ");
            case "<":   write_pred(gen, " < ");
            case "&":   write_pred(gen, " & ");
            case "|":   write_pred(gen, " | ");
            case "==":  write_pred(gen, " == ");
            case ">>":  write_pred(gen, " >> ");
            case "<<":  write_pred(gen, " << ");
            case "&&":  write_pred(gen, " && ");
            case "||":  write_pred(gen, " || ");
            case "~~":  write_pred(gen, " ^ ");
            case "!=":  write_pred(gen, " != ");
            case ">=":  write_pred(gen, " >= ");
            case "<=":  write_pred(gen, " <= ");
            case: panic();
            }

            pop_stack_pred(gen);
            
            write_pred(gen, ";\n");

            push_stack(gen, temp);

            return true;
        }
    }

    return false;
}

generate_expr_unary :: proc(using gen : ^Generator, expr : ^ast.Expr_Unary) -> bool {
    if generate_expr(gen, expr.exp) {
        temp := next_temp(gen);

        write_pred_indent(gen, "auto %s = ", temp);
        
        switch expr.op.text {
        case "^": write_pred(gen, "^");
        case "+": write_pred(gen, "+");
        case "-": write_pred(gen, "-");
        case "!": write_pred(gen, "!");
        case "~": write_pred(gen, "~");
        }

        pop_stack_pred(gen);

        write_pred(gen, ";\n");

        push_stack(gen, temp);

        return true;
    }

    return false;
}

generate_expr_selector :: proc(using gen : ^Generator, expr : ^ast.Expr_Selector) -> bool {
    if generate_expr(gen, expr.lhs) {
        pop_stack_succ(gen);

        write_succ(gen, ".");

        if generate_expr(gen, expr.rhs) {
            pop_stack_succ(gen);

            return true;
        }
    }

    return false;
}

generate_expr_subscript :: proc(using gen : ^Generator, expr : ^ast.Expr_Subscript) -> bool {
    if generate_expr(gen, expr.item) {
        pop_stack_succ(gen);

        write_succ(gen, "[");

        if generate_expr(gen, expr.arg) {
            pop_stack_succ(gen);

            write_succ(gen, "]");

            return true;
        }
    }

    return false;
}

generate_expr_call :: proc(using gen : ^Generator, expr : ^ast.Expr_Call) -> bool {
    if generate_expr(gen, expr.item) {
        pop_stack_succ(gen);

        write_succ(gen, "(");

        for _, i in expr.args {
            if generate_arg(gen, expr.args[i]) {
                pop_stack_succ(gen);

                if i < len(expr.args)-1 {
                    write_succ(gen, ", ");
                }
            }
            else {
                return false;
            }
        }

        write_succ(gen, ")");

        return true;
    }

    return false;
}

generate_expr_compound :: proc(using gen : ^Generator, expr : ^ast.Expr_Compound) -> bool {
    if generate_type(gen, expr.item) {
        pop_stack_succ(gen);

        write_succ(gen, "{\n");
        code_indent += 1;
        
        for _, i in expr.args {
            write_succ_indent(gen);

            if generate_arg(gen, expr.args[i]) {
                pop_stack_succ(gen);

                if i != len(expr.args)-1 {
                    write_succ(gen, ";\n");
                }
            }
        }
        
        code_indent -= 1;
        write_succ(gen, "}");

        return true;
    }

    return false;
}
