/*
 *  @Name:     parser
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 16-06-2018 04:00:18 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 09-08-2018 22:22:00 UTC-5
 *  
 *  @Description:
 *  
 */

package kodo

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

import "cio:kodo/ast"
import "cio:kodo/util"



Parser :: struct {
    file_name : string,

    tokens : []ast.Token,
    token  : ^ast.Token,
    index  : int,

    error_num : int,
}

next_token :: proc(using parser : ^Parser) -> ^ast.Token {
    token = &tokens[index];
    index += 1;
    return token;
}



match :: proc[match_kind, match_text];

match_kind :: inline proc(using parser : ^Parser, kinds : ..ast.Token_Kind) -> bool {
    for kind in kinds {
        if kind == token.kind {
            return true;
        }
    }

    return false;
}

match_text :: inline proc(using parser : ^Parser, texts : ..string) -> bool {
    for text in texts {
        if text == token.text {
            return true;
        }
    }

    return false;
}



allow :: proc[allow_kind, allow_text];

allow_kind :: inline proc(using parser : ^Parser, kinds : ..ast.Token_Kind) -> ^ast.Token {
    for match(parser, ..kinds) {
        tok := token;
        next_token(parser);
        return tok;
    }

    return nil;
}

allow_text :: inline proc(using parser : ^Parser, texts : ..string) -> ^ast.Token {
    for match(parser, ..texts) {
        tok := token;
        next_token(parser);
        return tok;
    }

    return nil;
}



expect :: proc[expect_kind, expect_text];

expect_kind :: inline proc(using parser : ^Parser, kinds : ..ast.Token_Kind, loc := #caller_location) -> ^ast.Token {
    if tok := allow(parser, ..kinds); tok != nil {
        return tok;
    }

    error(parser=parser, format="Expected %v; got %v", args=[]any{kinds, token.kind}, loc=loc);
    error_num += 1;

    return nil;
}

expect_text :: inline proc(using parser : ^Parser, texts : ..string, loc := #caller_location) -> ^ast.Token {
    if tok := allow(parser, ..texts); tok != nil {
        return tok;
    }

    error(parser=parser, format="Expected %v; got %v", args=[]any{texts, token.text}, loc=loc);
    error_num += 1;

    return nil;
}



parse_file :: proc(file_name : string) -> ^ast.Module {
    if bytes, ok :=  os.read_entire_file(file_name); ok {
        return parse_text(string(bytes), file_name);
    }

    return nil;
}

parse_text :: proc(source : string, file_name := "") -> ^ast.Module {
    if tokens := lex_text(source); tokens != nil {
        parser := Parser{
            file_name = file_name,
            tokens    = tokens,
        };

        tok := next_token(&parser);

        if block := parse_block_inner(&parser); block != nil {
            module := new(ast.Module);

            module.block = block;

            return module;
        }
    }

    return nil;
}



parse_block_inner :: proc(using parser : ^Parser) -> ^ast.Block {
    stmts : [dynamic]ast.Stmt;

    for {
        if stmt := parse_stmt(parser); stmt != nil {
            append(&stmts, stmt);
        }
        else {
            allow(parser, ";");
            break;
        }

        allow(parser, ";");
    }

    block := new(ast.Block);
    block.stmts = stmts[:];

    return block;
}

parse_block :: proc(using parser : ^Parser) -> ^ast.Block {
    if open := expect(parser, "{"); open != nil {
        block := parse_block_inner(parser);

        if close := expect(parser, "}"); close != nil {
            block.open  = open;
            block.close = close;

            return block;
        }
    }

    return nil;
}



parse_literal :: proc(using parser : ^Parser) -> ^ast.Literal {
    if tok := expect(parser, ast.Int, ast.Float, ast.String, ast.Bool); tok != nil {
        lit := new(ast.Literal);

        lit.tok = tok;
        
        switch tok.kind {
        case ast.Int:    lit.val    = strconv.parse_u64(tok.text);
        case ast.Float:  lit.val    = strconv.parse_f64(tok.text);
        case ast.Bool:   lit.val, _ = strconv.parse_bool(tok.text);
        case ast.String: lit.val    = util.unescape_string(tok.text); // @todo(bpunsky): unescape
        }

        return lit;
    }

    return nil;
}

parse_name :: proc(using parser : ^Parser) -> ^ast.Name {
    if token := expect(parser, ast.Ident); token != nil {
        name := new(ast.Name);

        name.tok = token;

        return name;
    }

    return nil;
}

parse_arg :: proc(using parser : ^Parser) -> ^ast.Arg {
    if expr := parse_expr(parser); expr != nil {
        arg := new(ast.Arg);

        if name, ok := expr.(^ast.Name); ok {
            if equ := allow(parser, "="); equ != nil {
                if expr = parse_expr(parser); expr != nil {
                    arg.equ = equ;
                    arg.name = name;
                    arg.expr = expr;
                    
                    return arg;
                }
            }
        }

        arg.expr = expr;

        return arg;
    }

    return nil;
}

parse_field :: proc(using parser : ^Parser) -> ^ast.Field {
    if name := parse_name(parser); name != nil {
        decl := new(ast.Field);

        names : [dynamic]^ast.Name;

        append(&names, name);

        for allow(parser, ",") != nil {
            append(&names, parse_name(parser));
        }

        decl.names = names[:];

        if col := allow(parser, ":"); col != nil {
            decl.col = col;

            if !match(parser, "=") {
                decl.typ = parse_type(parser);
            }
        }

        if allow(parser, "=") != nil {
            exprs : [dynamic]ast.Expr;

            for _ in names {
                if expr := parse_expr(parser); expr != nil {
                    append(&exprs, expr);
                }
                else {
                    break;
                }
            }

            decl.exprs = exprs[:];
        }

        return decl;
    }

    return nil;
}



parse_stmt :: proc(using parser : ^Parser) -> ast.Stmt {
    for {
        switch token.kind {
        case ast.Comment, ast.Newline:
            next_token(parser);
            continue;
        }

        break;
    }

    switch token.text {
    case "if":
        return parse_stmt_if(parser);
    
    case "for":
        return parse_stmt_for(parser);
    
    case "{":
        return parse_block(parser);
    
    case "goto":
        return parse_stmt_goto(parser);

    case "scope", "import", "foreign", "type", "alias", "label", "const", "static", "var":
        return parse_decl(parser);
    }

    return parse_stmt_simple(parser);
}

parse_stmt_goto :: proc(using parser : ^Parser) -> ^ast.Stmt_Goto {
    if kwd := expect(parser, "goto"); kwd != nil {
        stmt := new(ast.Stmt_Goto);

        stmt.kwd  = kwd;
        stmt.name = parse_name(parser);

        return stmt;
    }

    return nil;
}

parse_stmt_if :: proc(using parser : ^Parser) -> ^ast.Stmt_If {
    if kwd := expect(parser, "if"); kwd != nil {
        stmt := new(ast.Stmt_If);

        stmt.kwd = kwd;
        stmt.cond    = parse_expr(parser);

        stmt.then = parse_block(parser);
     
        if allow(parser, "else") != nil {
            stmt.els = parse_block(parser);
        }

        return stmt;
    }

    return nil;
}

parse_stmt_for :: proc(using parser : ^Parser) -> ^ast.Stmt_For {
    if kwd := expect(parser, "for"); kwd != nil {
        stmt := new(ast.Stmt_For);

        stmt.kwd  = kwd;
        stmt.decl = parse_decl(parser);

        if expect(parser, ";") != nil {
            stmt.cond = parse_expr(parser);

            if expect(parser, ";") != nil {
                stmt.iter  = parse_stmt_assn(parser);
                stmt.block = parse_block(parser);

                return stmt;
            }
        }
    }

    return nil;
}

parse_stmt_assn :: proc(using parser : ^Parser, lhs : []ast.Expr = nil) -> ^ast.Stmt_Assn {
    if lhs == nil {
        exprs : [dynamic]ast.Expr;

        for {
            if expr := parse_expr(parser); expr != nil {
                append(&exprs, expr);
            }
            else {
                break;
            }

            if allow(parser, ",") == nil {
                break;
            }
        }

        if len(exprs) > 0 {
            if match(parser, "=", "+=", "-=", "*=", "/=", "%=", "|=", "&=", "~=", "~~=") {
                return parse_stmt_assn(parser, exprs[:]);
            }
        }

        return nil;
    }

    if op := expect(parser, "=", "+=", "-=", "*=", "/=", "%=", "|=", "&=", "~=", "~~="); op != nil {
        assn := new(ast.Stmt_Assn);

        assn.op  = op;
        assn.lhs = lhs;

        rhs : [dynamic]ast.Expr;

        for {
            if expr := parse_expr(parser); expr != nil {
                append(&rhs, expr);
            }
            else {
                break;
            }

            if allow(parser, ",") == nil {
                break;
            }
        }

        assn.rhs = rhs[:];

        return assn;
    }

    return nil;
}

parse_stmt_simple :: proc(using parser : ^Parser) -> ast.Stmt {
    exprs : [dynamic]ast.Expr;

    for {
        if expr := parse_expr(parser); expr != nil {
            append(&exprs, expr);
        }
        else {
            break;
        }

        if allow(parser, ",") == nil {
            break;
        }
    }

    if len(exprs) > 0 {
        switch token.text {
        //case ":":
        //    return parse_decl_simple(parser, exprs[..]);

        case "=", "+=", "-=", "*=", "/=", "%=", "|=", "&=", "~=", "~~=":
            return parse_stmt_assn(parser, exprs[:]);
        
        case:
            if len(exprs) == 1 {
                if call, ok := exprs[0].(^ast.Expr_Call); ok {
                    return call;
                }
            }
        }
    }

    return nil;
}



parse_decl :: proc(using parser : ^Parser) -> ast.Decl {
    switch token.text {
    case "scope":
        return parse_decl_scope(parser);
    
    case "import", "foreign":
        return parse_decl_import(parser);
    
    case "label":
        return parse_decl_label(parser);
    
    case "type", "alias":
        return parse_decl_type(parser);
    
    case "const", "static", "var":
        return parse_decl_var(parser);
    }

    return nil;
}

parse_decl_scope :: proc(using parser : ^Parser) -> ^ast.Decl_Scope {
    if kwd := expect(parser, "scope"); kwd != nil {
        decl := new(ast.Decl_Scope);

        decl.kwd  = kwd;
        decl.name = parse_name(parser);

        if expect(parser, ":") != nil {
            decl.block = parse_block(parser);
            
            return decl;
        }

    }

    return nil;
}

parse_decl_import :: proc(using parser : ^Parser) -> ^ast.Decl_Import {
    if kwd := expect(parser, "import", "foreign"); kwd != nil {
        decl := new(ast.Decl_Import);

        decl.kwd = kwd;

        if match(parser, ast.Ident) {
            decl.name = parse_name(parser);
        }

        if expect(parser, ":") != nil {
            decl.path = expect(parser, ast.String);

            return decl;
        }
    }

    return nil;
}

parse_decl_label :: proc(using parser : ^Parser) -> ^ast.Decl_Label {
    if kwd := expect(parser, "label"); kwd != nil {
        decl := new(ast.Decl_Label);

        decl.kwd  = kwd;
        decl.name = parse_name(parser);

        if expect(parser, ":") != nil {
            return decl;
        }
    }

    return nil;
}

parse_decl_type :: proc(using parser : ^Parser) -> ^ast.Decl_Type {
    if kwd := expect(parser, "type", "alias"); kwd != nil {
        if name := parse_name(parser); name != nil {
            if col := expect(parser, ":"); col != nil {
                if typ := parse_type(parser); typ != nil {
                    decl := new(ast.Decl_Type);

                    decl.kwd  = kwd;
                    decl.col  = col;
                    decl.name = name;
                    decl.typ  = typ;

                    return decl;
                }
            }
        }
    }

    return nil;
}

parse_decl_var :: proc(using parser : ^Parser) -> ^ast.Decl_Var {
    if kwd := expect(parser, "const", "static", "var"); kwd != nil {
        decl := new(ast.Decl_Var);

        decl.kwd = kwd;

        if name := parse_name(parser); name != nil {
            names : [dynamic]^ast.Name;

            append(&names, name);

            if alt := allow(parser, ast.String); alt != nil {
                decl.alt = alt;
            }
            else {
                for allow(parser, ",") != nil {
                    append(&names, parse_name(parser));
                }
            }

            decl.names = names[:];

            if col := allow(parser, ":"); col != nil {
                decl.col = col;

                if !match(parser, "=") {
                    decl.typ = parse_type(parser);
                }
            }

            if allow(parser, "=") != nil {
                exprs : [dynamic]ast.Expr;

                for _ in names {
                    if expr := parse_expr(parser); expr != nil {
                        append(&exprs, expr);
                    }
                    else {
                        break;
                    }
                }

                decl.exprs = exprs[:];
            }

            return decl;
        }
    }

    return nil;
}



parse_type :: proc(using parser : ^Parser) -> ast.Type {
    switch token.text {
    case "struct", "union":
        return parse_type_struct(parser);
    
    case "enum":
        return parse_type_enum(parser);
    
    case "proc", "inline":
        return parse_type_proc(parser);

    case "{":
        return parse_type_array(parser);

    case "^":
        return parse_type_ptr(parser);

    case "#uint", "#uint8", "#uint16", "#uint32", "#uint64",
         "#int",  "#int8",  "#int16",  "#int32",  "#int64",
         "#bool", "#bool8", "#bool16", "#bool32", "#bool64",
         "#float32", "#float64", "#string", "#ztring":
        return parse_type_basic(parser);
    }

    switch token.kind {
    case ast.Ident:
        return parse_name(parser);
    }

    return nil;
}

parse_type_struct :: proc(using parser : ^Parser) -> ^ast.Type_Struct {
    if kwd := expect(parser, "struct", "union"); kwd != nil {
        typ := new(ast.Type_Struct);

        typ.kwd = kwd;

        if expect(parser, "{") != nil {
            fields : [dynamic]^ast.Field;

            for {
                if field := parse_field(parser); field != nil {
                    append(&fields, field);
                }
                else {
                    break;
                }
            }

            typ.fields = fields[:];

            if expect(parser, "}") != nil {
                return typ;
            }
        }
    }

    return nil;
}

parse_type_enum :: proc(using parser : ^Parser) -> ^ast.Type_Enum {
    if kwd := expect(parser, "enum"); kwd != nil {
        typ := new(ast.Type_Enum);

        typ.kwd = kwd;

        if expect(parser, "{") != nil {
            fields : [dynamic]^ast.Field;

            for {
                if field := parse_field(parser); field != nil {
                    append(&fields, field);
                }
                else {
                    break;
                }
            }

            typ.fields = fields[:];

            if expect(parser, "}") != nil {
                return typ;
            }
        }
    }

    return nil;
}

parse_type_proc :: proc(using parser : ^Parser) -> ^ast.Type_Proc {
    if kwd := expect(parser, "proc", "inline"); kwd != nil {
        typ := new(ast.Type_Proc);

        typ.kwd = kwd;

        if expect(parser, "(") != nil {
            params : [dynamic]^ast.Field;

            for {
                if field := parse_field(parser); field != nil {
                    append(&params, field);
                }
                else {
                    break;
                }

                if allow(parser, ",") == nil {
                    break;
                }
            }

            typ.params = params[:];

            if expect(parser, ")") != nil {
                if allow(parser, ":") != nil {
                    if allow(parser, "(") != nil {
                        returns : [dynamic]^ast.Field;

                        for {
                            if field := parse_field(parser); field != nil {
                                append(&returns, field);
                            }
                            else {
                                break;
                            }

                            if allow(parser, ",") == nil {
                                break;
                            }
                        }

                        typ.returns = returns[:];

                        expect(parser, ")"); // @note(bpunsky): solid?
                    }

                    return typ;
                }
                else {
                    return typ;
                }
            }
        }
    }

    return nil;
}

parse_type_array :: proc(using parser : ^Parser) -> ^ast.Type_Array {
    if open := expect(parser, "["); open != nil {
        typ := new(ast.Type_Array);

        typ.open = open;

        if tok := allow(parser, "?", "..", "..."); tok != nil {
            typ.tok = tok;
        }
        else if tok = allow(parser, ast.Int); tok != nil {
            typ.tok = tok;
        }

        if close := expect(parser, "]"); close != nil {
            typ.close = close;
            typ.base     = parse_type(parser);   

            return typ;
        }
    }

    return nil;
}

parse_type_ptr :: proc(using parser : ^Parser) -> ^ast.Type_Ptr {
    if op := expect(parser, "^"); op != nil {
        typ := new(ast.Type_Ptr);

        typ.op   = op;
        typ.base = parse_type(parser);

        return typ;
    }

    return nil;
}

parse_type_basic :: proc(using parser : ^Parser) -> ^ast.Type_Basic {
    if tok := expect(parser, "#uint", "#uint8",  "#uint16", "#uint32", "#uint64",
                             "#int",  "#int8",   "#int16",  "#int32",  "#int64",
                             "#bool", "#bool8",  "#bool16", "#bool32", "#bool64",
                             "#float32", "#float64", "#string", "#ztring"); tok != nil {
        typ := new(ast.Type_Basic);

        typ.tok = tok;

        switch tok.text[1:] {
        case "uint":    typ.basic = ast.Basic.Uint;
        case "uint8":   typ.basic = ast.Basic.Uint8;
        case "uint16":  typ.basic = ast.Basic.Uint16;
        case "uint32":  typ.basic = ast.Basic.Uint32;
        case "uint64":  typ.basic = ast.Basic.Uint64;

        case "int":     typ.basic = ast.Basic.Int;
        case "int8":    typ.basic = ast.Basic.Int8;
        case "int16":   typ.basic = ast.Basic.Int16;
        case "int32":   typ.basic = ast.Basic.Int32;
        case "int64":   typ.basic = ast.Basic.Int64;

        case "float32": typ.basic = ast.Basic.Float32;
        case "float64": typ.basic = ast.Basic.Float64;

        case "bool":    typ.basic = ast.Basic.Bool;
        case "bool8":   typ.basic = ast.Basic.Bool8;
        case "bool16":  typ.basic = ast.Basic.Bool16;
        case "bool32":  typ.basic = ast.Basic.Bool32;
        case "bool64":  typ.basic = ast.Basic.Bool64;

        case "string":  typ.basic = ast.Basic.String;
        case "ztring":  typ.basic = ast.Basic.Ztring;
        }

        return typ;
    }

    return nil;
}



parse_expr :: inline proc(using parser : ^Parser) -> ast.Expr {
    return parse_expr_binary(parser);
}

parse_expr_subexpr :: proc(using parser : ^Parser) -> ast.Expr {
    if expect(parser, "(") != nil {
        expr := parse_expr(parser);

        if expect(parser, ")") != nil {
            return expr;
        }
    }

    return nil;
}

parse_expr_binary :: inline proc(using parser : ^Parser) -> ast.Expr {
    return parse_expr_or(parser);
}

parse_expr_or :: proc(using parser : ^Parser, lhs : ast.Expr = nil) -> ast.Expr {
    if lhs == nil do lhs = parse_expr_and(parser);
    if lhs == nil do return nil;

    if op := allow(parser, "||"); op != nil {
        expr := new(ast.Expr_Binary);

        expr.op  = op;
        expr.lhs = lhs;
        expr.rhs = parse_expr_and(parser);

        return parse_expr_or(parser, expr);
    }

    return lhs;
}

parse_expr_and :: proc(using parser : ^Parser, lhs : ast.Expr = nil) -> ast.Expr {
    if lhs == nil do lhs = parse_expr_cmp(parser);
    if lhs == nil do return nil;

    if op := allow(parser, "&&"); op != nil {
        expr := new(ast.Expr_Binary);

        expr.op  = op;
        expr.lhs = lhs;
        expr.rhs = parse_expr_cmp(parser);

        return parse_expr_and(parser, expr);
    }

    return lhs;
}

parse_expr_cmp :: proc(using parser : ^Parser, lhs : ast.Expr = nil) -> ast.Expr {
    if lhs == nil do lhs = parse_expr_add(parser);
    if lhs == nil do return nil;

    if op := allow(parser, "==", "!=", ">", "<", ">=", "<="); op != nil {
        expr := new(ast.Expr_Binary);

        expr.op  = op;
        expr.lhs = lhs;
        expr.rhs = parse_expr_add(parser);

        return parse_expr_cmp(parser, expr);
    }

    return lhs;
}

parse_expr_add :: proc(using parser : ^Parser, lhs : ast.Expr = nil) -> ast.Expr {
    if lhs == nil do lhs = parse_expr_mul(parser);
    if lhs == nil do return nil;

    if op := allow(parser, "+", "-", "|"); op != nil {
        expr := new(ast.Expr_Binary);

        expr.op  = op;
        expr.lhs = lhs;
        expr.rhs = parse_expr_mul(parser);

        return parse_expr_add(parser, expr);
    }

    return lhs;
}

parse_expr_mul :: proc(using parser : ^Parser, lhs : ast.Expr = nil) -> ast.Expr {
    if lhs == nil do lhs = parse_expr_unary(parser);
    if lhs == nil do return nil;

    if op := allow(parser, "*", "/", "%", "&", ">>", "<<"); op != nil {
        expr := new(ast.Expr_Binary);

        expr.op  = op;
        expr.lhs = lhs;
        expr.rhs = parse_expr_unary(parser);

        return parse_expr_mul(parser, expr);
    }

    return lhs;
}

parse_expr_unary :: proc(using parser : ^Parser) -> ast.Expr {
    if op := allow(parser, "+", "-", "^", "&", "!", "~"); op != nil {
        expr := new(ast.Expr_Unary);

        expr.op  = op;
        expr.exp = parse_expr_unary(parser);

        return expr;
    }

    return parse_expr_operand(parser);
}

parse_expr_operand :: proc(using parser : ^Parser, lhs : ast.Expr = nil) -> ast.Expr {
    switch token.text {
    case "(":
        return parse_expr_subexpr(parser);
    }

    switch token.kind {
    case ast.Ident, ast.Int, ast.Float, ast.String, ast.Bool:
        return parse_expr_atom(parser);
    }

    return nil;
}

parse_expr_atom :: proc(using parser : ^Parser, lhs : ast.Expr = nil) -> ast.Expr {
    if lhs == nil do lhs = parse_expr_basic(parser);

    loop: for {
        switch token.text {
        case ".": lhs = parse_expr_selector(parser, lhs);
        case "[": lhs = parse_expr_subscript(parser, lhs);
        case "(": lhs = parse_expr_call(parser, lhs);
        case:     break loop;
        }
    }

    return lhs;
}

parse_expr_selector :: proc(using parser : ^Parser, lhs : ast.Expr) -> ^ast.Expr_Selector {
    if op := expect(parser, "."); op != nil {
        expr := new(ast.Expr_Selector);

        expr.op  = op;
        expr.lhs = lhs;
        expr.rhs = parse_expr_basic(parser);

        return expr;
    }

    return nil;
}

parse_expr_subscript :: proc(using parser : ^Parser, lhs : ast.Expr) -> ^ast.Expr_Subscript {
    if open := expect(parser, "["); open != nil {
        expr := new(ast.Expr_Subscript);

        expr.open = open;
        expr.arg  = parse_expr_basic(parser);

        if close := expect(parser, "]"); close != nil {
            expr.close = close;

            return expr;
        }
    }

    return nil;
}

parse_expr_call :: proc(using parser : ^Parser, lhs : ast.Expr) -> ^ast.Expr_Call {
    if open := expect(parser, "("); open != nil {
        expr := new(ast.Expr_Call);

        expr.open = open;
        expr.item = lhs;

        args : [dynamic]^ast.Arg;

        for {
            if arg := parse_arg(parser); arg != nil {
                append(&args, arg);
            }
            else {
                break;
            }

            if comma := allow(parser, ","); comma == nil {
                break;
            }
        }

        expr.args = args[:];

        if close := expect(parser, ")"); close != nil {
            expr.close = close;
            
            return expr;
        }
    }

    return nil;
}

parse_expr_basic :: proc(using parser : ^Parser) -> ast.Expr {
    switch token.kind {
    case ast.Int, ast.Float, ast.String, ast.Bool: return parse_literal(parser);
    case ast.Ident:                                return parse_name(parser);
    }

    return nil;
}



parser_error :: inline proc(using parser : ^Parser, format : string, args : ..any, loc := #caller_location) {
    message := fmt.aprintf(format, ..args);
    fmt.printf_err("%s(%d,%d): %s (from %s(%d,%d))\n", file_name, token.lines, token.chars, message, loc.file_path, loc.line, loc.column);
}
