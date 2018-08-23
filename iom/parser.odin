/*
 *  @Name:     parser
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 19-08-2018 12:41:53 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 22-08-2018 20:29:03 UTC-5
 *  
 *  @Description:
 *  
 */

package iom

import "core:fmt"
import "core:mem"
import "core:strconv"

import "bp:path"



parser_error :: proc(using parser: ^Parser, format: string, args: ..any, loc := #caller_location) {
    caller: string;

    when true {
        caller = fmt.aprintf(" %s(%d:%d)", loc.file_path, loc.line, loc.column);
        defer delete(caller);
    }

    message := fmt.aprintf(format, ..args);
    defer delete(message);

    full_path := path.full(file_name);
    defer delete(full_path);

    fmt.printf_err("%s(%d:%d) %s%s\n", full_path, token.lines, token.chars, message, caller);
}



Parser :: struct {
    file_name: string,

    tokens: []Token,
    token:  ^Token,
    index:  int,

    builder: Builder,
}

next_token :: inline proc(using parser: ^Parser) -> ^Token {
    token = &tokens[index];
    index += 1;

    return token;
}

match :: proc[match_kind, match_text];

match_kind :: inline proc(using parser: ^Parser, kinds: ..Token_Kind) -> ^Token {
    for kind in kinds {
        if token.kind == kind {
            return token;
        }
    }

    return nil;
}

match_text :: inline proc(using parser: ^Parser, texts: ..string) -> ^Token {
    for text in texts {
        if token.text == text {
            return token;
        }
    }

    return nil;
}

allow :: proc[allow_kind, allow_text];

allow_kind :: inline proc(using parser: ^Parser, kinds: ..Token_Kind) -> ^Token {
    for kind in kinds {
        if token.kind == kind {
            tok := token;
            next_token(parser);
            return tok;
        }
    }

    return nil;
}

allow_text :: inline proc(using parser: ^Parser, texts: ..string) -> ^Token {
    for text in texts {
        if token.text == text {
            tok := token;
            next_token(parser);
            return tok;
        }
    }

    return nil;
}

expect :: proc[expect_kind, expect_text];

expect_kind :: inline proc(using parser: ^Parser, kinds: ..Token_Kind, loc := #caller_location) -> ^Token {
    if tok := allow_kind(parser, ..kinds); tok != nil {
        return tok;
    }
    else {  
        parser_error(parser=parser, format="Expected %v; got %v", args=[]any{kinds, token.kind}, loc=loc);
    }

    return nil;
}

expect_text :: inline proc(using parser: ^Parser, texts: ..string, loc := #caller_location) -> ^Token {
    if tok := allow_text(parser, ..texts); tok != nil {
        return tok;
    }
    else {  
        parser_error(parser=parser, format="Expected %v; got %v", args=[]any{texts, tok.text}, loc=loc);
    }

    return nil;
}

consume_whitespace :: inline proc(using parser: ^Parser) {
    for token.kind == Newline || token.kind == Comment {
        next_token(parser);
    }
}



parse_string :: proc(source: string) -> (Builder, bool) {
    parser: Parser;

    if tokens := lex_string(source); tokens != nil {
        defer delete(tokens);

        parser.tokens = tokens;

        next_token(&parser);

        consume_whitespace(&parser);

        for parser.token.kind != End {
            if !parse_line(&parser) {
                return Builder{}, false;
            }

            consume_whitespace(&parser);
        }

        return parser.builder, true;
    }

    return Builder{}, false;
}

parse_file :: proc(file_name: string) -> (Builder, bool) {
    parser: Parser;


    if tokens := lex_file(file_name); tokens != nil {
        defer delete(tokens);

        parser.file_name = file_name;
        parser.tokens    = tokens;

        next_token(&parser);

        consume_whitespace(&parser);

        for parser.token.kind != End {
            if !parse_line(&parser) {
                return Builder{}, false;
            }

            consume_whitespace(&parser);
        }

        return parser.builder, true;
    }

    return Builder{}, false;
}

parse_line :: inline proc(using parser: ^Parser) -> bool {
    switch token.kind {
    case Op_Name:
        if parse_instr(parser) {
            return true;
        }
    
    case Ref_Name:
        token := token;

        next_token(parser);

        if expect(parser, ":") != nil {
            add_label(&builder, token.text);

            return true;
        }

    case String:
        add_bytes(&builder, ([]byte)(token.text[1:len(token.text)-1]));
        next_token(parser);
        return true;

    case Type_Name:
        if parse_values(parser) {
            return true;
        }

    case Uint:
        token := token;

        next_token(parser);

        if expect(parser, ":") != nil {
            add_anon(&builder, token.text);

            return true;
        }

    case Symbol:
        switch token.text {
        case "@":
            next_token(parser);

            switch token.text {
            case "spawn":
                next_token(parser);

                if token := expect(parser, Ref_Name); token != nil {
                    add_spawn(&builder, token.text);

                    return true;
                }
            }

            parser_error(parser, "Expected a directive.");
        }
    }

    parser_error(parser, "Something bad happened!"); // @todo(bpunsky): cmon dude fix this up
    return false;
}

parse_instr :: inline proc(using parser: ^Parser) -> bool {
    using instr: Instr;

    if op := expect(parser, Op_Name); op != nil {
        switch op.text {
        case "panic":
            panic(); // @error
            return false;

        case "nop":
            build(&builder, nop());
            return true;

        case "halt":
            build(&builder, halt());
            return true;

        case "sv64":
            if rd, im, ok := parse_reg_offset(parser); ok {
                allow(parser, ",");

                if rs, ok := parse_reg(parser); ok {
                    build(&builder, sv64(rd, im, rs));
                    return true;
                }
            }

        case "sv32":
            if rd, im, ok := parse_reg_offset(parser); ok {
                allow(parser, ",");

                if rs, ok := parse_reg(parser); ok {
                    build(&builder, sv32(rd, im, rs));
                    return true;
                }
            }

        case "sv16":
            if rd, im, ok := parse_reg_offset(parser); ok {
                allow(parser, ",");

                if rs, ok := parse_reg(parser); ok {
                    build(&builder, sv16(rd, im, rs));
                    return true;
                }
            }

        case "sv8":
            if rd, im, ok := parse_reg_offset(parser); ok {
                allow(parser, ",");

                if rs, ok := parse_reg(parser); ok {
                    build(&builder, sv8(rd, im, rs));
                    return true;
                }
            }

        case "ld64":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs, im, ok := parse_reg_offset(parser); ok {
                    build(&builder, ld64(rd, rs, im));
                    return true;
                }
            }

        case "ld32":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs, im, ok := parse_reg_offset(parser); ok {
                    build(&builder, ld32(rd, rs, im));
                    return true;
                }
            }

        case "ld16":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs, im, ok := parse_reg_offset(parser); ok {
                    build(&builder, ld16(rd, rs, im));
                    return true;
                }
            }

        case "ld8":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs, im, ok := parse_reg_offset(parser); ok {
                    build(&builder, ld8(rd, rs, im));
                    return true;
                }
            }

        case "sys":
            if im, ok := parse_uint(parser); ok {
                build(&builder, sys(im));
                return true;
            }

        case "goto":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if match(parser, Reg_Name) != nil {
                    if rs, ok := parse_reg(parser); ok {
                        build(&builder, goto(rd, rs));
                        return true;
                    }
                }
                else {
                    build(&builder, goto(rd));
                    return true;
                }
            }

        case "jump":
            if match(parser, Reg_Name) != nil {
                if rd, ok := parse_reg(parser); ok {
                    allow(parser, ",");

                    if ref, ok := parse_ref(parser, true); ok {
                        build(&builder, jump(rd, ref));
                        return true;
                    }
                }
            }
            else {
                if ref, ok := parse_ref(parser, true); ok {
                    build(&builder, jump(ref));
                    return true;
                }
            }

        case "jeq":
            if rs1, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs2, ok := parse_reg(parser); ok {
                    allow(parser, ",");

                    if ref, ok := parse_ref(parser, true); ok {
                        build(&builder, jeq(rs1, rs2, ref));
                        return true;
                    }
                }
            }

        case "jne":
            if rs1, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs2, ok := parse_reg(parser); ok {
                    allow(parser, ",");

                    if ref, ok := parse_ref(parser, true); ok {
                        build(&builder, jne(rs1, rs2, ref));
                        return true;
                    }
                }
            }

        case "jlt":
            if rs1, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs2, ok := parse_reg(parser); ok {
                    allow(parser, ",");

                    if ref, ok := parse_ref(parser, true); ok {
                        build(&builder, jlt(rs1, rs2, ref));
                        return true;
                    }
                }
            }

        case "jge":
            if rs1, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs2, ok := parse_reg(parser); ok {
                    allow(parser, ",");

                    if ref, ok := parse_ref(parser, true); ok {
                        build(&builder, jge(rs1, rs2, ref));
                        return true;
                    }
                }
            }

        case "jltu":
            if rs1, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs2, ok := parse_reg(parser); ok {
                    allow(parser, ",");

                    if ref, ok := parse_ref(parser, true); ok {
                        build(&builder, jltu(rs1, rs2, ref));
                        return true;
                    }
                }
            }

        case "jgeu":
            if rs1, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs2, ok := parse_reg(parser); ok {
                    allow(parser, ",");

                    if ref, ok := parse_ref(parser, true); ok {
                        build(&builder, jgeu(rs1, rs2, ref));
                        return true;
                    }
                }
            }

        case "jgt":
            if rs1, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs2, ok := parse_reg(parser); ok {
                    allow(parser, ",");

                    if ref, ok := parse_ref(parser, true); ok {
                        build(&builder, jgt(rs1, rs2, ref));
                        return true;
                    }
                }
            }

        case "jle":
            if rs1, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs2, ok := parse_reg(parser); ok {
                    allow(parser, ",");

                    if ref, ok := parse_ref(parser, true); ok {
                        build(&builder, jle(rs1, rs2, ref));
                        return true;
                    }
                }
            }

        case "jgtu":
            if rs1, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs2, ok := parse_reg(parser); ok {
                    allow(parser, ",");

                    if ref, ok := parse_ref(parser, true); ok {
                        build(&builder, jgtu(rs1, rs2, ref));
                        return true;
                    }
                }
            }

        case "jleu":
            if rs1, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs2, ok := parse_reg(parser); ok {
                    allow(parser, ",");

                    if ref, ok := parse_ref(parser, true); ok {
                        build(&builder, jleu(rs1, rs2, ref));
                        return true;
                    }
                }
            }

        case "jez":
            if rs, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if ref, ok := parse_ref(parser, true); ok {
                    build(&builder, jez(rs, ref));
                    return true;
                }
            }

        case "jnz":
            if rs, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if ref, ok := parse_ref(parser, true); ok {
                    build(&builder, jnz(rs, ref));
                    return true;
                }
            }

        case "jgez":
            if rs, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if ref, ok := parse_ref(parser, true); ok {
                     build(&builder, jgez(rs, ref));
                     return true;
                }
            }

        case "jltz":
            if rs, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if ref, ok := parse_ref(parser, true); ok {
                     build(&builder, jltz(rs, ref));
                     return true;
                }
            }

        case "jgtz":
            if rs, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if ref, ok := parse_ref(parser, true); ok {
                     build(&builder, jgtz(rs, ref));
                     return true;
                }
            }

        case "jlez":
            if rs, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if ref, ok := parse_ref(parser, true); ok {
                     build(&builder, jlez(rs, ref));
                     return true;
                }
            }

        case "jgezu":
            if rs, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if ref, ok := parse_ref(parser, true); ok {
                     build(&builder, jgezu(rs, ref));
                     return true;
                }
            }

        case "jltzu":
            if rs, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if ref, ok := parse_ref(parser, true); ok {
                     build(&builder, jltzu(rs, ref));
                     return true;
                }
            }

        case "jgtzu":
            if rs, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if ref, ok := parse_ref(parser, true); ok {
                     build(&builder, jgtzu(rs, ref));
                     return true;
                }
            }

        case "jlezu":
            if rs, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if ref, ok := parse_ref(parser, true); ok {
                     build(&builder, jlezu(rs, ref));
                     return true;
                }
            }

        case "addi":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if match(parser, Reg_Name) != nil {
                    if rs1, ok := parse_reg(parser); ok {
                        allow(parser, ",");

                        if im, ok := parse_int(parser); ok {
                            build(&builder, addi(rd, rs1, im));
                            return true;
                        }
                    }
                }
                else if match(parser, Int, Uint, Char) != nil {
                    if im, ok := parse_int(parser); ok {
                        build(&builder, addi(rd, rd, im));
                        return true;
                    }
                }
                else {
                    expect(parser, Reg_Name, Int, Uint, Char); // @error
                }
            }

        case "subi":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if match(parser, Reg_Name) != nil {
                    if rs1, ok := parse_reg(parser); ok {
                        allow(parser, ",");

                        if im, ok := parse_int(parser); ok {
                            build(&builder, subi(rd, rs1, im));
                            return true;
                        }
                    }
                }
                else if match(parser, Int, Uint, Char) != nil {
                    if im, ok := parse_int(parser); ok {
                        build(&builder, subi(rd, rd, im));
                        return true;
                    }
                }
                else {
                    expect(parser, Reg_Name, Int, Uint, Char); // @error
                }
            }

        case "andi":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if match(parser, Reg_Name) != nil {
                    if rs1, ok := parse_reg(parser); ok {
                        allow(parser, ",");

                        if im, ok := parse_int(parser); ok {
                            build(&builder, andi(rd, rs1, im));
                            return true;
                        }
                    }
                }
                else if match(parser, Int, Uint, Char) != nil {
                    if im, ok := parse_int(parser); ok {
                        build(&builder, andi(rd, rd, im));
                        return true;
                    }
                }
                else {
                    expect(parser, Reg_Name, Int, Uint, Char); // @error
                }
            }

        case "ori":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if match(parser, Reg_Name) != nil {
                    if rs1, ok := parse_reg(parser); ok {
                        allow(parser, ",");

                        if im, ok := parse_int(parser); ok {
                            build(&builder, ori(rd, rs1, im));
                            return true;
                        }
                    }
                }
                else if match(parser, Int, Uint, Char) != nil {
                    if im, ok := parse_int(parser); ok {
                        build(&builder, ori(rd, rd, im));
                        return true;
                    }
                }
                else {
                    expect(parser, Reg_Name, Int, Uint, Char); // @error
                }
            }

        case "xori":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if match(parser, Reg_Name) != nil {
                    if rs1, ok := parse_reg(parser); ok {
                        allow(parser, ",");

                        if im, ok := parse_int(parser); ok {
                            build(&builder, xori(rd, rs1, im));
                            return true;
                        }
                    }
                }
                else if match(parser, Int, Uint, Char) != nil {
                    if im, ok := parse_int(parser); ok {
                        build(&builder, xori(rd, rd, im));
                        return true;
                    }
                }
                else {
                    expect(parser, Reg_Name, Int, Uint, Char); // @error
                }
            }

        case "shli":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if match(parser, Reg_Name) != nil {
                    if rs1, ok := parse_reg(parser); ok {
                        allow(parser, ",");

                        if im, ok := parse_uint(parser); ok {
                            build(&builder, shli(rd, rs1, im));
                            return true;
                        }
                    }
                }
                else if match(parser, Uint) != nil {
                    if im, ok := parse_uint(parser); ok {
                        build(&builder, shli(rd, rd, im));
                        return true;
                    }
                }
                else {
                    expect(parser, Reg_Name, Int, Uint, Char); // @error
                }
            }

        case "shri":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if match(parser, Reg_Name) != nil {
                    if rs1, ok := parse_reg(parser); ok {
                        allow(parser, ",");

                        if im, ok := parse_uint(parser); ok {
                            build(&builder, shri(rd, rs1, im));
                            return true;
                        }
                    }
                }
                else if match(parser, Uint) != nil {
                    if im, ok := parse_uint(parser); ok {
                        build(&builder, shri(rd, rd, im));
                        return true;
                    }
                }
                else {
                    expect(parser, Reg_Name, Int, Uint, Char); // @error
                }
            }

        case "shai":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if match(parser, Reg_Name) != nil {
                    if rs1, ok := parse_reg(parser); ok {
                        allow(parser, ",");

                        if im, ok := parse_int(parser); ok {
                            build(&builder, shai(rd, rs1, im));
                            return true;
                        }
                    }
                }
                else if match(parser, Int, Uint, Char) != nil {
                    if im, ok := parse_int(parser); ok {
                        build(&builder, shai(rd, rd, im));
                        return true;
                    }
                }
                else {
                    expect(parser, Reg_Name, Int, Uint, Char); // @error
                }
            }

        case "add":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if match(parser, Reg_Name) != nil {
                    if rs1, ok := parse_reg(parser); ok {
                        allow(parser, ",");

                        if match(parser, Reg_Name) != nil {
                            if rs2, ok := parse_reg(parser); ok {
                                build(&builder, add(rd, rs1, rs2));
                                return true;
                            }
                        }
                        else if match(parser, Int, Uint, Char) != nil {
                            if im, ok := parse_int(parser); ok {
                                build(&builder, add(rd, rs1, im));
                                return true;
                            }
                        }
                        else {
                            build(&builder, add(rd, rd, rs1));
                            return true;
                        }
                    }
                }
                else if match(parser, Int, Uint, Char) != nil {
                    if im, ok := parse_int(parser); ok {
                        build(&builder, add(rd, rd, im));
                        return true;
                    }
                }
                else {
                    expect(parser, Reg_Name, Int, Uint, Char); // @error
                }
            }

        case "sub":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if match(parser, Reg_Name) != nil {
                    if rs1, ok := parse_reg(parser); ok {
                        allow(parser, ",");

                        if match(parser, Reg_Name) != nil {
                            if rs2, ok := parse_reg(parser); ok {
                                build(&builder, sub(rd, rs1, rs2));
                                return true;
                            }
                        }
                        else if match(parser, Int, Uint, Char) != nil {
                            if im, ok := parse_int(parser); ok {
                                build(&builder, sub(rd, rs1, im));
                                return true;
                            }
                        }
                        else {
                            build(&builder, sub(rd, rd, rs1));
                            return true;
                        }
                    }
                }
                else if match(parser, Int, Uint, Char) != nil {
                    if im, ok := parse_int(parser); ok {
                        build(&builder, sub(rd, rd, im));
                        return true;
                    }
                }
                else {
                    expect(parser, Reg_Name, Int, Uint, Char); // @error
                }
            }

        case "mul":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs1, ok := parse_reg(parser); ok {
                    allow(parser, ",");

                    if match(parser, Reg_Name) != nil {
                        if rs2, ok := parse_reg(parser); ok {
                            build(&builder, mul(rd, rs1, rs2));
                            return true;
                        }
                    }
                    else {
                        build(&builder, mul(rd, rd, rs1));
                        return true;
                    }
                }
            }

        case "div":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs1, ok := parse_reg(parser); ok {
                    allow(parser, ",");

                    if match(parser, Reg_Name) != nil {
                        if rs2, ok := parse_reg(parser); ok {
                            build(&builder, div(rd, rs1, rs2));
                            return true;
                        }
                    }
                    else {
                        build(&builder, div(rd, rd, rs1));
                        return true;
                    }
                }
            }

        case "mod":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs1, ok := parse_reg(parser); ok {
                    allow(parser, ",");

                    if match(parser, Reg_Name) != nil {
                        if rs2, ok := parse_reg(parser); ok {
                            build(&builder, mod(rd, rs1, rs2));
                            return true;
                        }
                    }
                    else {
                        build(&builder, mod(rd, rd, rs1));
                        return true;
                    }
                }
            }

        case "mulu":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs1, ok := parse_reg(parser); ok {
                    allow(parser, ",");

                    if match(parser, Reg_Name) != nil {
                        if rs2, ok := parse_reg(parser); ok {
                            build(&builder, mulu(rd, rs1, rs2));
                            return true;
                        }
                    }
                    else {
                        build(&builder, mulu(rd, rd, rs1));
                        return true;
                    }
                }
            }

        case "divu":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs1, ok := parse_reg(parser); ok {
                    allow(parser, ",");

                    if match(parser, Reg_Name) != nil {
                        if rs2, ok := parse_reg(parser); ok {
                            build(&builder, divu(rd, rs1, rs2));
                            return true;
                        }
                    }
                    else {
                        build(&builder, divu(rd, rd, rs1));
                        return true;
                    }
                }
            }

        case "modu":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs1, ok := parse_reg(parser); ok {
                    allow(parser, ",");

                    if match(parser, Reg_Name) != nil {
                        if rs2, ok := parse_reg(parser); ok {
                            build(&builder, modu(rd, rs1, rs2));
                            return true;
                        }
                    }
                    else {
                        build(&builder, modu(rd, rd, rs1));
                        return true;
                    }
                }
            }

        case "addf":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs1, ok := parse_reg(parser); ok {
                    allow(parser, ",");

                    if match(parser, Reg_Name) != nil {
                        if rs2, ok := parse_reg(parser); ok {
                            build(&builder, addf(rd, rs1, rs2));
                            return true;
                        }
                    }
                    else {
                        build(&builder, addf(rd, rd, rs1));
                        return true;
                    }
                }
            }

        case "subf":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs1, ok := parse_reg(parser); ok {
                    allow(parser, ",");

                    if match(parser, Reg_Name) != nil {
                        if rs2, ok := parse_reg(parser); ok {
                            build(&builder, subf(rd, rs1, rs2));
                            return true;
                        }
                    }
                    else {
                        build(&builder, subf(rd, rd, rs1));
                        return true;
                    }
                }
            }

        case "mulf":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs1, ok := parse_reg(parser); ok {
                    allow(parser, ",");

                    if match(parser, Reg_Name) != nil {
                        if rs2, ok := parse_reg(parser); ok {
                            build(&builder, mulf(rd, rs1, rs2));
                            return true;
                        }
                    }
                    else {
                        build(&builder, mulf(rd, rd, rs1));
                        return true;
                    }
                }
            }

        case "divf":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if rs1, ok := parse_reg(parser); ok {
                    allow(parser, ",");

                    if match(parser, Reg_Name) != nil {
                        if rs2, ok := parse_reg(parser); ok {
                            build(&builder, divf(rd, rs1, rs2));
                            return true;
                        }
                    }
                    else {
                        build(&builder, divf(rd, rd, rs1));
                        return true;
                    }
                }
            }

        case "and":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if match(parser, Reg_Name) != nil {
                    if rs1, ok := parse_reg(parser); ok {
                        allow(parser, ",");

                        if match(parser, Reg_Name) != nil {
                            if rs2, ok := parse_reg(parser); ok {
                                build(&builder, and(rd, rs1, rs2));
                                return true;
                            }
                        }
                        else if match(parser, Int, Uint, Char) != nil {
                            if im, ok := parse_int(parser); ok {
                                build(&builder, and(rd, rs1, im));
                                return true;
                            }
                        }
                        else {
                            build(&builder, and(rd, rd, rs1));
                            return true;
                        }
                    }
                }
                else if match(parser, Int, Uint, Char) != nil {
                    if im, ok := parse_int(parser); ok {
                        build(&builder, and(rd, rd, im));
                        return true;
                    }
                }
                else {
                    expect(parser, Reg_Name, Int, Uint, Char); // @error
                }
            }

        case "or":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if match(parser, Reg_Name) != nil {
                    if rs1, ok := parse_reg(parser); ok {
                        allow(parser, ",");

                        if match(parser, Reg_Name) != nil {
                            if rs2, ok := parse_reg(parser); ok {
                                build(&builder, or(rd, rs1, rs2));
                                return true;
                            }
                        }
                        else if match(parser, Int, Uint, Char) != nil {
                            if im, ok := parse_int(parser); ok {
                                build(&builder, or(rd, rs1, im));
                                return true;
                            }
                        }
                        else {
                            build(&builder, or(rd, rd, rs1));
                            return true;
                        }
                    }
                }
                else if match(parser, Int, Uint, Char) != nil {
                    if im, ok := parse_int(parser); ok {
                        build(&builder, or(rd, rd, im));
                        return true;
                    }
                }
                else {
                    expect(parser, Reg_Name, Int, Uint, Char); // @error
                }
            }

        case "xor":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if match(parser, Reg_Name) != nil {
                    if rs1, ok := parse_reg(parser); ok {
                        allow(parser, ",");

                        if match(parser, Reg_Name) != nil {
                            if rs2, ok := parse_reg(parser); ok {
                                build(&builder, xor(rd, rs1, rs2));
                                return true;
                            }
                        }
                        else if match(parser, Int, Uint, Char) != nil {
                            if im, ok := parse_int(parser); ok {
                                build(&builder, xor(rd, rs1, im));
                                return true;
                            }
                        }
                        else {
                            build(&builder, xor(rd, rd, rs1));
                            return true;
                        }
                    }
                }
                else if match(parser, Int, Uint, Char) != nil {
                    if im, ok := parse_int(parser); ok {
                        build(&builder, xor(rd, rd, im));
                        return true;
                    }
                }
                else {
                    expect(parser, Reg_Name, Int, Uint, Char); // @error
                }
            }

        case "shl":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if match(parser, Reg_Name) != nil {
                    if rs1, ok := parse_reg(parser); ok {
                        allow(parser, ",");

                        if match(parser, Reg_Name) != nil {
                            if rs2, ok := parse_reg(parser); ok {
                                build(&builder, shl(rd, rs1, rs2));
                                return true;
                            }
                        }
                        else if match(parser, Int, Uint, Char) != nil {
                            if im, ok := parse_uint(parser); ok {
                                build(&builder, shl(rd, rs1, im));
                                return true;
                            }
                        }
                        else {
                            build(&builder, shl(rd, rd, rs1));
                            return true;
                        }
                    }
                }
                else if match(parser, Uint) != nil {
                    if im, ok := parse_uint(parser); ok {
                        build(&builder, shl(rd, rd, im));
                        return true;
                    }
                }
                else {
                    expect(parser, Reg_Name, Int, Uint, Char); // @error
                }
            }

        case "shr":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if match(parser, Reg_Name) != nil {
                    if rs1, ok := parse_reg(parser); ok {
                        allow(parser, ",");

                        if match(parser, Reg_Name) != nil {
                            if rs2, ok := parse_reg(parser); ok {
                                build(&builder, shr(rd, rs1, rs2));
                                return true;
                            }
                        }
                        else if match(parser, Int, Uint, Char) != nil {
                            if im, ok := parse_uint(parser); ok {
                                build(&builder, shr(rd, rs1, im));
                                return true;
                            }
                        }
                        else {
                            build(&builder, shr(rd, rd, rs1));
                            return true;
                        }
                    }
                }
                else if match(parser, Uint) != nil {
                    if im, ok := parse_uint(parser); ok {
                        build(&builder, shr(rd, rd, im));
                        return true;
                    }
                }
                else {
                    expect(parser, Reg_Name, Int, Uint, Char); // @error
                }
            }

        case "sha":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if match(parser, Reg_Name) != nil {
                    if rs1, ok := parse_reg(parser); ok {
                        allow(parser, ",");

                        if match(parser, Reg_Name) != nil {
                            if rs2, ok := parse_reg(parser); ok {
                                build(&builder, sha(rd, rs1, rs2));
                                return true;
                            }
                        }
                        else if match(parser, Int, Uint, Char) != nil {
                            if im, ok := parse_int(parser); ok {
                                build(&builder, sha(rd, rs1, im));
                                return true;
                            }
                        }
                        else {
                            build(&builder, sha(rd, rd, rs1));
                            return true;
                        }
                    }
                }
                else if match(parser, Int, Uint, Char) != nil {
                    if im, ok := parse_int(parser); ok {
                        build(&builder, sha(rd, rd, im));
                        return true;
                    }
                }
                else {
                    expect(parser, Reg_Name, Int, Uint, Char); // @error
                }
            }

        case "mov":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if match(parser, Reg_Name) != nil {
                    if rs, ok := parse_reg(parser); ok {
                        build(&builder, mov(rd, rs));
                        return true;
                    }
                }
                else if match(parser, Int, Uint, Float, Char) != nil {
                    if im, ok := parse_im(parser); ok {
                        build(&builder, mov(rd, im));
                        return true;
                    }
                }
                else {
                    if ref, ok := parse_ref(parser); ok {
                        build(&builder, movi(rd, ref));
                        return true;
                    }
                }
            }

        case "movi":
            if rd, ok := parse_reg(parser); ok {
                allow(parser, ",");

                if match(parser, Ref_Name) != nil {
                    if ref, ok := parse_ref(parser); ok {
                        build(&builder, movi(rd, ref));
                        return true;
                    }
                }
                else {
                    if im, ok := parse_im(parser); ok {
                        build(&builder, movi(rd, im));
                        return true;
                    }
                }
            }

        case "inc":
            if rd, ok := parse_reg(parser); ok {
                build(&builder, inc(rd));
                return true;
            }

        case "dec":
            if rd, ok := parse_reg(parser); ok {
                build(&builder, dec(rd));
                return true;
            }

        case "call":
            if match(parser, Reg_Name) != nil {
                if rs, ok := parse_reg(parser); ok {
                    build(&builder, call(rs));
                }
            }
            else {
                if im, ok := parse_im(parser); ok {
                    build(&builder, call(im));
                }
            }

        case "tail":
            if match(parser, Reg_Name) != nil {
                if rs, ok := parse_reg(parser); ok {
                    build(&builder, tail(rs));
                }
            }
            else {
                if im, ok := parse_im(parser); ok {
                    build(&builder, tail(im));
                }
            }

        case "ret":
            build(&builder, ret());
            return true;

        case:
            parser_error(parser, "Unimplemented or invalid opcode: %v", op.text);
        }
    }

    return false;
}

parse_reg :: inline proc(using parser: ^Parser) -> (Reg, bool) {
    if token := expect(parser, Reg_Name); token != nil {
        switch token.text {
        case "gp": return GP, true;
        case "bp": return BP, true;
        case "sp": return SP, true;
        case "fp": return FP, true;
        case "x0": return X0, true;
        case "x1": return X1, true;
        case "x2": return X2, true;
        case "x3": return X3, true;
        case "rz": return RZ, true;
        case "ra": return RA, true;
        case "g0": return G0, true;
        case "g1": return G1, true;
        case "g2": return G2, true;
        case "g3": return G3, true;
        case "g4": return G4, true;
        case "g5": return G5, true;
        case "a0": return A0, true;
        case "a1": return A1, true;
        case "a2": return A2, true;
        case "a3": return A3, true;
        case "a4": return A4, true;
        case "a5": return A5, true;
        case "a6": return A6, true;
        case "a7": return A7, true;
        case "s0": return S0, true;
        case "s1": return S1, true;
        case "s2": return S2, true;
        case "s3": return S3, true;
        case "s4": return S4, true;
        case "s5": return S5, true;
        case "s6": return S6, true;
        case "s7": return S7, true;
        case "t0": return T0, true;
        case "t1": return T1, true;
        case "t2": return T2, true;
        case "t3": return T3, true;
        case "t4": return T4, true;
        case "t5": return T5, true;
        case "t6": return T6, true;
        case "t7": return T7, true;

        case: panic("Invalid register got past lexer");
        }
    }

    return Reg{}, false;
}

parse_reg_offset :: inline proc(using parser: ^Parser) -> (Reg, i64, bool) {
    if reg, ok := parse_reg(parser); ok {
        if allow(parser, "[") != nil {
            if im, ok := parse_int(parser); ok {
                if expect(parser, "]") != nil {
                    return reg, im, true;
                }
            }
            else {
                parser_error(parser, "Expected an offset");
            }
        }

        return reg, 0, true;
    }

    return Reg{}, i64{}, false;
}

parse_values :: inline proc(using parser: ^Parser) -> bool {
    if typ := expect(parser, Type_Name); typ != nil {
        if allow(parser, "[") != nil {
            for {
                switch typ.text {
                case "i64", "i32", "i16", "i8":
                    if im, ok := parse_int(parser); ok {
                        switch typ.text {
                        case "i64":
                            value := i64(im);
                            add_bytes(&builder, mem.ptr_to_bytes(&value));
                        case "i32":
                            value := i32(im);
                            add_bytes(&builder, mem.ptr_to_bytes(&value));
                        case "i16":
                            value := i16(im);
                            add_bytes(&builder, mem.ptr_to_bytes(&value));
                        case "i8":
                            value := i8(im);
                            add_bytes(&builder, mem.ptr_to_bytes(&value));
                        }
                    }
                case "u64", "u32", "u16", "u8":
                    if im, ok := parse_uint(parser); ok {
                        switch typ.text {
                        case "u64":
                            value := u64(im);
                            add_bytes(&builder, mem.ptr_to_bytes(&value));
                        case "u32":
                            value := u32(im);
                            add_bytes(&builder, mem.ptr_to_bytes(&value));
                        case "u16":
                            value := u16(im);
                            add_bytes(&builder, mem.ptr_to_bytes(&value));
                        case "u8":
                            value := u8(im);
                            add_bytes(&builder, mem.ptr_to_bytes(&value));
                        }
                    }
                case "f64", "f32":
                    if im, ok := parse_float(parser); ok {
                        switch typ.text {
                        case "f64":
                            value := f64(im);
                            add_bytes(&builder, mem.ptr_to_bytes(&value));
                        case "f32":
                            value := f32(im);
                            add_bytes(&builder, mem.ptr_to_bytes(&value));
                        }
                    }
                }

                if allow(parser, ",") == nil {
                    if expect(parser, "]") != nil {
                        return true;
                    }
                    
                    break;
                }
            }
        }
        else {
            switch typ.text {
            case "i64", "i32", "i16", "i8":
                if im, ok := parse_int(parser); ok {
                    switch typ.text {
                    case "i64":
                        value := i64(im);
                        add_bytes(&builder, mem.ptr_to_bytes(&value));
                    case "i32":
                        value := i32(im);
                        add_bytes(&builder, mem.ptr_to_bytes(&value));
                    case "i16":
                        value := i16(im);
                        add_bytes(&builder, mem.ptr_to_bytes(&value));
                    case "i8":
                        value := i8(im);
                        add_bytes(&builder, mem.ptr_to_bytes(&value));
                    }
                }
            case "u64", "u32", "u16", "u8":
                if im, ok := parse_uint(parser); ok {
                    switch typ.text {
                    case "u64":
                        value := u64(im);
                        add_bytes(&builder, mem.ptr_to_bytes(&value));
                    case "u32":
                        value := u32(im);
                        add_bytes(&builder, mem.ptr_to_bytes(&value));
                    case "u16":
                        value := u16(im);
                        add_bytes(&builder, mem.ptr_to_bytes(&value));
                    case "u8":
                        value := u8(im);
                        add_bytes(&builder, mem.ptr_to_bytes(&value));
                    }
                }
            case "f64", "f32":
                if im, ok := parse_float(parser); ok {
                    switch typ.text {
                    case "f64":
                        value := f64(im);
                        add_bytes(&builder, mem.ptr_to_bytes(&value));
                    case "f32":
                        value := f32(im);
                        add_bytes(&builder, mem.ptr_to_bytes(&value));
                    }
                }
            }

            return true;
        }
    }

    return false;
}

parse_im :: inline proc(using parser: ^Parser) -> (i64, bool) {
    switch token.kind {
    case Int:
        if i, ok := parse_int(parser); ok {
            return i, ok;
        }

    case Uint, Char:
        if u, ok := parse_uint(parser); ok {
            return (^i64)(&u)^, ok;
        }

    case Float:
        if f, ok := parse_float(parser); ok {
            return (^i64)(&f)^, ok;
        }
    }

    return 0, false;
}

parse_int :: inline proc(using parser: ^Parser) -> (i64, bool) {
    if tok := allow(parser, Int, Uint); tok != nil {
        return strconv.parse_i64(tok.text), true;
    }
    else if tok := expect(parser, Char); tok != nil {
        char := tok.text[1];
        return i64(char), true;
    }

    return 0, false;
}

parse_uint :: inline proc(using parser: ^Parser) -> (u64, bool) {
    if tok := allow(parser, Uint); tok != nil {
        return strconv.parse_u64(tok.text), true;
    }
    else if tok := expect(parser, Char); tok != nil {
        char := tok.text[1];
        return u64(char), true;
    }

    return 0, false;
}

parse_float :: inline proc(using parser: ^Parser) -> (f64, bool) {
    if tok := expect(parser, Float); tok != nil {
        return strconv.parse_f64(tok.text), true;
    }

    return 0, false;
}

parse_ref :: inline proc(using parser: ^Parser, rel := false) -> (i64, bool) {
    if tok := allow(parser, "<", ">"); tok != nil {
        if ref := expect(parser, Uint); ref != nil {
            switch tok.text {
            case "<": return add_backward_ref(&builder, ref.text, i64, rel), true;
            case ">": return add_forward_ref(&builder, ref.text, i64, rel), true;
            }
        }
    }
    else {
        if ref := expect(parser, Ref_Name); ref != nil {
            return add_ref(&builder, ref.text, rel), true;
        }
    }

    return 0, false;
}
