/*
 *  @Name:     lexer
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 21-06-2018 13:14:40 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 22-08-2018 20:01:20 UTC-5
 *  
 *  @Description:
 *  
 */

package iom

import "core:fmt"
import "core:os"
import "core:unicode/utf8"



Cursor :: struct {
    index: int,
    bytes: int,
    lines: int,
    chars: int,
}

using Token_Kind :: enum {
    Invalid,

    Directive,
    Ref_Name,
    Op_Name,
    Reg_Name,
    Type_Name,

    Symbol,
    Newline,
    Comment,

    Int,
    Uint,
    Float,
    String,
    Char,

    End,
}

Token :: struct {
    using cursor: Cursor,

    kind: Token_Kind,
    text: string,
}



Lexer :: struct {
    using cursor: Cursor,
    
    file_name: string,
    source:    string,
    
    skip: int,
}

next_char :: inline proc(using lexer : ^Lexer) -> (res : rune) {
    index += skip;
    chars += 1;

    res, skip = utf8.decode_rune_from_string(source[index:]);

    return;
}

lex :: proc(using lexer: ^Lexer) -> []Token {
    token:  Token;
    tokens: [dynamic]Token;

    char := next_char(lexer);

    loop: for {
        for {
            switch char {
            case ' ', '\t':
                char = next_char(lexer);
                continue;
            }

            break;
        }

        token.cursor = cursor;

        switch char {
        case 'A'..'Z', 'a'..'z', '_':
            token.kind = Ref_Name;

            for {
                switch char = next_char(lexer); char {
                case 'A'..'Z', 'a'..'z', '0'..'9', '_', '.', '-':
                    continue;
                }

                break;
            }

            switch source[token.index:index] {
            case "panic", "nop", "halt",
                 "sys",
                 "goto", "jump",
                 "jeq", "jne", "jlt", "jge", "jgt", "jle", "jltu", "jgeu", "jgtu", "jleu",
                 "jez", "jnz", "jltz", "jgez", "jgtz", "jlez", "jltzu", "jgezu", "jgtzu", "jlezu",
                 "addi",
                 "sv8", "sv16", "sv32", "sv64", "ld8", "ld16", "ld32", "ld64",
                 "add", "addf", "sub", "subu", "subf", "mul", "mulu", "mulf", "div", "divu", "divf", "mod", "modu",
                 "shl", "shr", "sha", "shli", "shri", "shai",
                 "and", "or", "xor", "andi", "ori", "xori",
                 "mov", "movi", "inc", "dec", "call", "tail", "ret":
                token.kind = Op_Name;
            
            case "x0",  "x1",  "x2",  "x3",  "x4",  "x5",  "x6",  "x7",
                 "x8",  "x9",  "x10", "x11", "x12", "x13", "x14", "x15",
                 "x16", "x17", "x18", "x19", "x20", "x21", "x22", "x23",
                 "x24", "x25", "x26", "x27", "x28", "x29", "x30", "x31",
                 "x32", "x33", "x34", "x35", "x36", "x37", "x38", "x39",
                 "x40", "x41", "x42", "x43", "x44", "x45", "x46", "x47",
                 "x48", "x49", "x50", "x51", "x52", "x53", "x54", "x55",
                 "x56", "x57", "x58", "x59", "x60", "x61", "x62", "x63",
                 "rz",  "gp",  "sp",  "hp",  "fp",  "ra",  "r0",  "r1",
                 "a0",  "a1",  "a2",  "a3",  "a4",  "a5",  "a6",  "a7",
                 "s0",  "s1",  "s2",  "s3",  "s4",  "s5",  "s6",  "s7",
                 "t0",  "t1",  "t2",  "t3",  "t4",  "t5",  "t6",  "t7":
                token.kind = Reg_Name;

            case "i64", "i32", "i16", "i8",
                 "u64", "u32", "u16", "u8",
                 "f64", "f32":
                token.kind = Type_Name;
            }
            
        case ',', '[', ']', '<', '>', ':', '@':
            token.kind = Symbol;

            char = next_char(lexer);

        case '+', '-':
            token.kind = Symbol;

            switch char = next_char(lexer); char {
            case '0'..'9':
                token.kind = Int;

                for {
                    switch char = next_char(lexer); char {
                    case '0'..'9':
                        continue;

                    case '.':
                        if token.kind == Float {
                            lexer_error(lexer, "Error: double radix in float");
                        }
                        else {
                            token.kind = Float;
                            continue;
                        }
                    }

                    break;
                }
            }

        case '0'..'9':
            token.kind = Uint;

            for {
                switch char = next_char(lexer); char {
                case '0'..'9':
                    continue;

                case '.':
                    if token.kind == Float {
                        lexer_error(lexer, "Error: double radix in float");
                    }
                    else {
                        token.kind = Float;
                        continue;
                    }
                }

                break;
            }

        case '"':
            token.kind = String;

            for {
                switch char = next_char(lexer); char {
                case '"':
                case: continue;
                }

                char = next_char(lexer);
                break;
            }

        case '\'':
            token.kind = Char;

            char = next_char(lexer);

            if char = next_char(lexer); char == '\'' {
                char = next_char(lexer);
            }
            else {
                lexer_error(lexer, "Expected `'`; got `%v`", char);
            }

        case '#':
            token.kind = Comment;

            for {
                switch char = next_char(lexer); char { 
                case '\r', '\n':
                case: continue;
                }

                break;
            }

        case '\r':
            token.kind = Newline;

            if char = next_char(lexer); char == '\n' {
                char = next_char(lexer);
            }

            lines += 1;
            chars  = 1;
        
        case '\n':
            token.kind = Newline;

            char = next_char(lexer);
           
            lines += 1;
            chars  = 1;

        case utf8.RUNE_ERROR, utf8.RUNE_EOF, '\x00':
            break loop;

        case:
            lexer_error(lexer, "Invalid character in stream: %c {%d}", char, char);
            return nil;
        }

        if token.kind == Invalid {
            lexer_error(lexer, "Invalid token: %s", source[token.index:index]);
        }

        token.bytes = index - token.index; 
        token.text  = source[token.index:index];

        append(&tokens, token);
    }

    append(&tokens, Token{kind=End, cursor=cursor});

    return tokens[:];
}

lex_string :: proc(source: string) -> []Token {
    lexer: Lexer;
    lexer.cursor = Cursor{0, 0, 1, 0};
    lexer.source = source;

    return lex(&lexer);
}

lex_file :: proc(file_name: string) -> []Token {
    lexer: Lexer;
    lexer.cursor    = Cursor{0, 0, 1, 0};
    lexer.file_name = file_name;

    if bytes, ok := os.read_entire_file(file_name); ok {
        lexer.source = string(bytes);
    }
    else {
        lexer_error(&lexer, "Failed to read file: %s", file_name);
        return nil;
    }

    return lex(&lexer);
}



lexer_error :: proc(using lexer: ^Lexer, format: string, args: ..any, loc := #caller_location) {
    caller: string;

    when false {
        caller = fmt.aprintf(" %s(%d:%d)", loc.file_path, loc.line, loc.column);
        defer delete(caller);
    }

    message := fmt.aprintf(format, ..args);
    defer delete(message);

    fmt.printf_err("%s(%d:%d) %s%s\n", file_name, lines, chars, message, caller);
}
