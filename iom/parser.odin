/*
 *  @Name:     parser
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 21-06-2018 13:58:00 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 06-07-2018 09:58:47 UTC-5
 *  
 *  @Description:
 *  
 */

package fiber

import "core:mem"
import "core:os"
import "core:strconv"



Parser :: struct {
    tokens : []Token,
    token  : ^Token,
    index  : int,

    error_num : int,

    registers : [64]u64,

    code : [dynamic]byte,
    data : [dynamic]byte,

    names : map[string]^Name,

    line_byte_index : int,

    stack_size : int,
    memory_size : int,

    relative : bool,

    op : ^Token,
}

next_token :: proc(using parser : ^Parser) -> ^Token {
    token = &tokens[index];
    index += 1;
    return token;
}

write_instr :: inline proc(using parser : ^Parser, instr : Instr) {
    write_op(parser, encode(instr));
}

write_op :: inline proc(using parser : ^Parser, ops : ...u64) {
    append(&code, ...mem.slice_to_bytes(ops));
}



match :: proc[match_kind, match_text];

match_kind :: inline proc(using parser : ^Parser, kinds : ...Token_Kind) -> bool {
    for kind in kinds {
        if kind == token.kind {
            return true;
        }
    }

    return false;
}

match_text :: inline proc(using parser : ^Parser, texts : ...string) -> bool {
    for text in texts {
        if text == token.text {
            return true;
        }
    }

    return false;
}



allow :: proc[allow_kind, allow_text];

allow_kind :: inline proc(using parser : ^Parser, kinds : ...Token_Kind) -> ^Token {
    for match(parser, ...kinds) {
        tok := token;
        next_token(parser);
        return tok;
    }

    return nil;
}

allow_text :: inline proc(using parser : ^Parser, texts : ...string) -> ^Token {
    for match(parser, ...texts) {
        tok := token;
        next_token(parser);
        return tok;
    }

    return nil;
}



expect :: proc[expect_kind, expect_text];

expect_kind :: inline proc(using parser : ^Parser, kinds : ...Token_Kind, loc := #caller_location) -> ^Token {
    if tok := allow(parser, ...kinds); tok != nil {
        return tok;
    }

    error(cursor=token.cursor, format="Expected %v; got %v", args=[]any{kinds, token.kind}, loc=loc);
    error_num += 1;

    return nil;
}

expect_text :: inline proc(using parser : ^Parser, texts : ...string, loc := #caller_location) -> ^Token {
    if tok := allow(parser, ...texts); tok != nil {
        return tok;
    }

    error(cursor=token.cursor, format="Expected %v; got %v", args=[]any{texts, token.text}, loc=loc);
    error_num += 1;

    return nil;
}



Name :: struct {
    kind : Token_Kind,

    name  : string,
    value : i64,

    usages : [dynamic]Usage,
}

Usage :: struct {
    index    : u64,
    relative : bool,
}

new_name :: inline proc(using parser : ^Parser, name : string, kind := Invalid) -> ^Name {
    if n, ok := names[name]; ok {
        if kind != Invalid {
            if n.kind != Invalid {
                error(token.cursor, "Name already declared: \"%s\"", name);

                return nil;
            }
            else {
                n.kind  = kind;
                n.value = i64(len(code));
            }
        }
        else {
            append(&n.usages, Usage{u64(line_byte_index), relative});
        }

        return n;
    }
    else {
        n := new(Name);

        n.kind = kind;
        n.name = name;

        if kind == Invalid {
            append(&n.usages, Usage{u64(line_byte_index), relative});
        }
        else {
            n.value = i64(len(code));
        }

        names[name] = n;

        return n;
    }
}



parse_register :: inline proc(using parser : ^Parser) -> Reg {
    if token := expect(parser, Register); token != nil {
        switch token.kind {
        case Register:
            switch token.text {
            case "x0":  return x0;
            case "x1":  return x1;
            case "x2":  return x2;
            case "x3":  return x3;
            case "x4":  return x4;
            case "x5":  return x5;
            case "x6":  return x6;
            case "x7":  return x7;
            case "x8":  return x8;
            case "x9":  return x9;
            case "x10": return x10;
            case "x11": return x11;
            case "x12": return x12;
            case "x13": return x13;
            case "x14": return x14;
            case "x15": return x15;
            case "x16": return x16;
            case "x17": return x17;
            case "x18": return x18;
            case "x19": return x19;
            case "x20": return x20;
            case "x21": return x21;
            case "x22": return x22;
            case "x23": return x23;
            case "x24": return x24;
            case "x25": return x25;
            case "x26": return x26;
            case "x27": return x27;
            case "x28": return x28;
            case "x29": return x29;
            case "x30": return x30;
            case "x31": return x31;
            case "x32": return x32;
            case "x33": return x33;
            case "x34": return x34;
            case "x35": return x35;
            case "x36": return x36;
            case "x37": return x37;
            case "x38": return x38;
            case "x39": return x39;
            case "x40": return x40;
            case "x41": return x41;
            case "x42": return x42;
            case "x43": return x43;
            case "x44": return x44;
            case "x45": return x45;
            case "x46": return x46;
            case "x47": return x47;
            case "x48": return x48;
            case "x49": return x49;
            case "x50": return x50;
            case "x51": return x51;
            case "x52": return x52;
            case "x53": return x53;
            case "x54": return x54;
            case "x55": return x55;
            case "x56": return x56;
            case "x57": return x57;
            case "x58": return x58;
            case "x59": return x59;
            case "x60": return x60;
            case "x61": return x61;
            case "x62": return x62;
            case "x63": return x63;

            case "rz": return rz;
            case "gp": return gp;
            case "sp": return sp;
            case "hp": return hp;
            case "fp": return fp;
            case "ra": return ra;
            case "r0": return r0;
            case "r1": return r1;
            case "a0": return a0;
            case "a1": return a1;
            case "a2": return a2;
            case "a3": return a3;
            case "a4": return a4;
            case "a5": return a5;
            case "a6": return a6;
            case "a7": return a7;
            case "s0": return s0;
            case "s1": return s1;
            case "s2": return s2;
            case "s3": return s3;
            case "s4": return s4;
            case "s5": return s5;
            case "s6": return s6;
            case "s7": return s7;
            case "t0": return t0;
            case "t1": return t1;
            case "t2": return t2;
            case "t3": return t3;
            case "t4": return t4;
            case "t5": return t5;
            case "t6": return t6;
            case "t7": return t7;
            }
        }
    }

    return 0;
}

parse_immediate :: inline proc(using parser : ^Parser) -> i64 {
    if token.kind == Ident {
        if ident := parse_ident(parser, Signed, Unsigned, Float); ident != nil {
            return ident.value;
        }
    }
    else {
        if token := expect(parser, Signed, Unsigned, Float); token != nil {
            switch token.kind {
            case Signed, Unsigned, Float:
                switch token.kind {
                case Signed:   return transmute(i64) (strconv.parse_i64(token.text));
                case Unsigned: return transmute(i64) (strconv.parse_u64(token.text));
                case Float:    return transmute(i64) (strconv.parse_f64(token.text));
                }
            }
        }
    }

    return 0;
}

parse_label :: inline proc(using parser : ^Parser) -> ^Name {
    if label := expect(parser, Label); label != nil {
        name := new_name(parser, label.text[..len(label.text)-1], label.kind);

        return name;
    }

    return nil;
}

/*
parse_const :: inline proc(using parser : ^Parser) -> ^Name {
    if cnst := expect(parser, Const); cnst != nil {
        if imm, ok := parse_immediate(parser); ok {
            if name := new_name(parser, cnst.text[1..], cnst.kind); name != nil {
                name.value = imm;
            
                return name;
            }
        }
    }

    return nil;
}
*/

parse_ident :: inline proc(using parser : ^Parser, kinds : ...Token_Kind) -> ^Name {
    if ident := expect(parser, Ident); ident != nil {
        if name := new_name(parser, ident.text); name != nil {
            if kinds != nil {
                for kind in kinds {
                    if name.kind == kind {
                        return name;
                    }
                }
            }
            else {
                return name;
            }
        }
    }

    return nil;
}

parse_breakpoint :: inline proc(using parser : ^Parser) -> bool {
    if expect(parser, Breakpoint) != nil {
        return true;
    }

    return false;
}



parse_instr :: inline proc(using parser : ^Parser) {
    op = expect(parser, Opname);

    if op == nil {
        return;
    }

    switch op.text {
    case "quit": write_op(parser, quit());
    case "brk":  write_op(parser, brk());

    case "ihi", "ilo", "addi":
        rd := parse_register(parser);
        expect(parser, ",");
        im := parse_immediate(parser);

        switch op.text {
        case "ihi":  write_op(parser, ihi(rd, im));
        case "ilo":  write_op(parser, ilo(rd, im));
        case "addi": write_op(parser, addi(rd, i32(im)));
        }

    case "goto":
        rd := parse_register(parser);

        if allow(parser, ",") != nil {
            switch token.kind {
            case Register:
                rs := parse_register(parser);
                expect(parser, ",");
                im := parse_immediate(parser);

                write_op(parser, goto(rd, rs, i16(im)));

            case Signed, Ident:
                im := parse_immediate(parser);

                write_op(parser, goto(rd, i16(im)));

            case: expect(parser, Register, Signed);
            }
        }
        else {
            write_op(parser, goto(rd));
        }

    case "jump":
        switch token.kind {
        case Register:
            rd := parse_register(parser);
            expect(parser, ",");
            im := parse_immediate(parser);

            write_op(parser, jump(rd, i32(im)));

        case Signed, Ident:
            im := parse_immediate(parser);

            write_op(parser, jump(i32(im)));

        case: expect(parser, Register, Signed);
        }

    case "ld8", "ld16", "ld32", "ld64":
        rd := parse_register(parser);
        expect(parser, ",");

        if allow(parser, "[") != nil {
            rs := parse_register(parser);
            expect(parser, ",");
            im := parse_immediate(parser);
            expect(parser, "]");

            switch op.text {
            case "ld8":  write_op(parser, ld8 (rd, rs, i16(im)));
            case "ld16": write_op(parser, ld16(rd, rs, i16(im)));
            case "ld32": write_op(parser, ld32(rd, rs, i16(im)));
            case "ld64": write_op(parser, ld64(rd, rs, i16(im)));
            }
        }
        else {
            rs := parse_register(parser);

            switch op.text {
            case "ld8":  write_op(parser, ld8 (rd, rs));
            case "ld16": write_op(parser, ld16(rd, rs));
            case "ld32": write_op(parser, ld32(rd, rs));
            case "ld64": write_op(parser, ld64(rd, rs));
            }
        }

    case "sv8", "sv16", "sv32", "sv64":
        if allow(parser, "[") != nil {
            rd := parse_register(parser);
            expect(parser, ",");
            im := parse_immediate(parser);
            expect(parser, "]");
            expect(parser, ",");
            rs := parse_register(parser);

            switch op.text {
            case "sv8":  write_op(parser, sv8 (rd, i16(im), rs));
            case "sv16": write_op(parser, sv16(rd, i16(im), rs));
            case "sv32": write_op(parser, sv32(rd, i16(im), rs));
            case "sv64": write_op(parser, sv64(rd, i16(im), rs));
            }
        }
        else {
            rd := parse_register(parser);
            expect(parser, ",");
            rs := parse_register(parser);

            switch op.text {
            case "sv8":  write_op(parser, sv8 (rd, rs));
            case "sv16": write_op(parser, sv16(rd, rs));
            case "sv32": write_op(parser, sv32(rd, rs));
            case "sv64": write_op(parser, sv64(rd, rs));
            }
        }

    case "add", "sub", "mul", "div", "mod", "mulu", "divu", "modu", "addf", "subf", "mulf", "divf", "shl", "shr", "sha", "and", "or", "xor":
        rd := parse_register(parser);
        expect(parser, ",");
        rs1 := parse_register(parser);

        if allow(parser, ",") != nil {
            rs2 := parse_register(parser);
            
            switch op.text {
            case "add":  write_op(parser, add (rd, rs1, rs2));
            case "sub":  write_op(parser, sub (rd, rs1, rs2));
            case "mul":  write_op(parser, mul (rd, rs1, rs2));
            case "div":  write_op(parser, div (rd, rs1, rs2));
            case "mod":  write_op(parser, mod (rd, rs1, rs2));
            case "mulu": write_op(parser, mulu(rd, rs1, rs2));
            case "divu": write_op(parser, divu(rd, rs1, rs2));
            case "modu": write_op(parser, modu(rd, rs1, rs2));
            case "addf": write_op(parser, addf(rd, rs1, rs2));
            case "subf": write_op(parser, subf(rd, rs1, rs2));
            case "mulf": write_op(parser, mulf(rd, rs1, rs2));
            case "divf": write_op(parser, divf(rd, rs1, rs2));
            case "shl":  write_op(parser, shl (rd, rs1, rs2));
            case "shr":  write_op(parser, shr (rd, rs1, rs2));
            case "sha":  write_op(parser, sha (rd, rs1, rs2));
            case "and":  write_op(parser, and (rd, rs1, rs2));
            case "or":   write_op(parser, or  (rd, rs1, rs2));
            case "xor":  write_op(parser, xor (rd, rs1, rs2));
            }
        }
        else {
            switch op.text {
            case "add":  write_op(parser, add (rd, rs1));
            case "sub":  write_op(parser, sub (rd, rs1));
            case "mul":  write_op(parser, mul (rd, rs1));
            case "div":  write_op(parser, div (rd, rs1));
            case "mod":  write_op(parser, mod (rd, rs1));
            case "mulu": write_op(parser, mulu(rd, rs1));
            case "divu": write_op(parser, divu(rd, rs1));
            case "modu": write_op(parser, modu(rd, rs1));
            case "addf": write_op(parser, addf(rd, rs1));
            case "subf": write_op(parser, subf(rd, rs1));
            case "mulf": write_op(parser, mulf(rd, rs1));
            case "divf": write_op(parser, divf(rd, rs1));
            case "shl":  write_op(parser, shl (rd, rs1));
            case "shr":  write_op(parser, shr (rd, rs1));
            case "sha":  write_op(parser, sha (rd, rs1));
            case "and":  write_op(parser, and (rd, rs1));
            case "or":   write_op(parser, or  (rd, rs1));
            case "xor":  write_op(parser, xor (rd, rs1));
            }
        }

    case "jeq", "jne", "jlt", "jge", "jltu", "jgeu":
        rs1 := parse_register(parser);
        expect(parser, ",");
        rs2 := parse_register(parser);
        expect(parser, ",");
        im := parse_immediate(parser);

        switch op.text {
        case "jeq":  write_op(parser, jeq (rs1, rs2, i16(im)));
        case "jne":  write_op(parser, jne (rs1, rs2, i16(im)));
        case "jlt":  write_op(parser, jlt (rs1, rs2, i16(im)));
        case "jge":  write_op(parser, jge (rs1, rs2, i16(im)));
        case "jltu": write_op(parser, jltu(rs1, rs2, i16(im)));
        case "jgeu": write_op(parser, jgeu(rs1, rs2, i16(im)));
        }

    case "shli", "shri", "shai", "andi", "ori", "xori":
        rd := parse_register(parser);
        expect(parser, ",");
        rs := parse_register(parser);
        expect(parser, ",");
        im := parse_immediate(parser);

        switch op.text {
        case "shli": write_op(parser, shli(rd, rs, i16(im)));
        case "shri": write_op(parser, shri(rd, rs, i16(im)));
        case "shai": write_op(parser, shai(rd, rs, i16(im)));
        case "andi": write_op(parser, andi(rd, rs, i16(im)));
        case "ori":  write_op(parser, ori (rd, rs, i16(im)));
        case "xori": write_op(parser, xori(rd, rs, i16(im)));
        }

    case "nop": write_op(parser, nop());

    case "mov":
        rd := parse_register(parser);
        expect(parser, ",");

        if next := expect(parser, Register, Signed, Unsigned, Float); next != nil {
            switch next.kind {
            case Register:
                rs := parse_register(parser);

                write_op(parser, mov(rd, rs));

            case Signed, Unsigned, Float:
                im := parse_immediate(parser);

                write_op(parser, mov(rd, im));
            }
        }

    case "call", "tail":
        im := parse_immediate(parser);

        switch op.text {
        case "call": write_op(parser, call(im));
        case "tail": write_op(parser, tail(im));
        }

    case "ret": write_op(parser, ret());

    case "push":
        switch token.kind {
        case Register:
            rs := parse_register(parser);

            write_op(parser, push(rs));

        case Signed, Unsigned, Float, Ident:
            im := parse_immediate(parser);

            write_op(parser, push(im));

        case: expect(parser, Register, Signed, Unsigned, Float, Ident);
        }

    case "pop":
        rd := parse_register(parser);

        write_op(parser, pop(rd));

    case:
        error(parser.token, "Invalid instruction.");
    }
}

parse_line :: proc(using parser : ^Parser) -> bool {
    line_byte_index = len(code);

    if token.kind == Breakpoint {
        if parse_breakpoint(parser) {
            write_instr(parser, Instr{op=BRK});
        }
    }

    switch token.kind {
    /*
    case Const:
        parse_const(parser);

        return true;
    */

    case Opname:
        parse_instr(parser);

        return true;

    case Label:
        parse_label(parser);

        return true;

    case End:
        break;

    case:
        error(token.cursor, "Error: expected a constant declaration, label or instruction");
    }

    return false;
}



parse_text :: proc(source : string) -> (Bytecode, bool) {
    parser : Parser;
    parser.tokens = lex(source);

    next_token(&parser);

    for {
        if end := allow(&parser, Newline); end != nil {
            for {
                if allow(&parser, Newline) == nil {
                    break;
                }
            }
        }
        
        if !parse_line(&parser) {
            break;
        }
    }

    for _, name in parser.names {
        if name.kind == Label {
            for usage in name.usages {
                instr := decode((^u64)(&parser.code[usage.index])^);

                if usage.relative {
                    instr.im = name.value - i64(usage.index);
                }
                else {
                    instr.im = name.value;
                }

                (^u64)(&parser.code[usage.index])^ = encode(instr);
            }
        }
    }

    bytecode : Bytecode;
    bytecode.registers   = parser.registers;
    bytecode.code        = parser.code[..];
    bytecode.data        = parser.data[..];
    bytecode.stack_size  = parser.stack_size;
    bytecode.memory_size = parser.memory_size;

    return bytecode, true;
}

parse_file :: proc(filename : string) -> (Bytecode, bool) {
    if bytes, ok := os.read_entire_file(filename); ok {
        return parse_text(string(bytes));
    }

    return Bytecode{}, false;
}
