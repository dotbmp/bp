/*
 *  @Name:     lexer
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 21-06-2018 13:14:40 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 06-07-2018 00:05:25 UTC-5
 *  
 *  @Description:
 *  
 */

package fiber

import "core:unicode/utf8"



Cursor :: struct {
    index : int,
    lines : int,
    chars : int,
}

Token_Kind :: enum #export {
    Invalid,

    Label,
    Const,
    Ident,
    Opname,
    Register,
    Newline,
    Symbol,

    Signed,
    Unsigned,
    Float,
    String,

    Breakpoint,

    End,
}

Token :: struct {
    using cursor : Cursor,

    kind : Token_Kind,
    text : string,
}



Lexer :: struct {
    using cursor : Cursor,
    text : string,
    skip : int,
}

next_char :: inline proc(using lexer : ^Lexer) -> (res : rune) {
    index += skip;
    chars += 1;

    res, skip = utf8.decode_rune_from_string(text[index..]);

    return;
}

lex :: proc(source : string) -> []Token {
    using lexer := Lexer{Cursor{0, 1, 0}, source, 0};

    token  : Token;
    tokens : [dynamic]Token;

    char := next_char(&lexer);

    loop: for {
        whitespace: for {
            switch char {
            case ' ', '\t':
                char = next_char(&lexer);
            
                continue;

            case '#':
                for {
                    switch char = next_char(&lexer); char {
                    case '\r':
                        if char = next_char(&lexer); char == '\n' {
                            char = next_char(&lexer);
                        }

                        lines += 1;
                        chars  = 1;

                    case '\n':
                        char = next_char(&lexer);                        

                        lines += 1;
                        chars  = 1;

                    case: continue;
                    }

                    continue whitespace;
                }
            }

            break;
        }

        token.cursor = cursor;

        switch char {
        case 'A'...'Z', 'a'...'z', '_':
            token.kind = Ident;

            for {
                switch char = next_char(&lexer); char {
                case 'A'...'Z', 'a'...'z', '0'...'9', '_':
                    continue;

                case ':':
                    char = next_char(&lexer);

                    token.kind = Label;
                }

                break;
            }

            switch source[token.index..index] {
            case "quit", "brk",
                 "ihi", "ilo",
                 "sx32",
                 "goto", "jump",
                 "jeq", "jne", "jlt", "jge", "jltu", "jgeu",
                 "addi",
                 "sv8", "sv16", "sv32", "sv64", "ld8", "ld16", "ld32", "ld64",
                 "add", "addf", "sub", "subu", "subf", "mul", "mulu", "mulf", "div", "divu", "divf", "mod", "modu",
                 "shl", "shr", "sha", "shli", "shri", "shai",
                 "and", "or", "xor", "andi", "ori", "xori",
                 "fcall",
                 "nop", "mov", "call", "tail", "ret",
                 "push", "pop":
                token.kind = Opname;
            
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
                token.kind = Register;
            }

        case ',', '[', ']':
            token.kind = Symbol;

            char = next_char(&lexer);

        case '$':
            token.kind = Const;

            for {
                switch char = next_char(&lexer); char {
                case 'A'...'Z', 'a'...'z', '0'...'9', '_':
                    continue;
                }

                break;
            }

        case '@':
            token.kind = Breakpoint;

            char = next_char(&lexer);

        case '+', '-':
            token.kind = Signed;

            for {
                switch char = next_char(&lexer); char {
                case '0'...'9':
                    continue;

                case '.':
                    if token.kind == Float {
                        error(lexer.cursor, "Error: double radix in float");
                    }
                    else {
                        token.kind = Float;
                        continue;
                    }
                }

                break;
            }

        case '0'...'9':
            token.kind = Unsigned;

            for {
                switch char = next_char(&lexer); char {
                case '0'...'9':
                    continue;

                case '.':
                    if token.kind == Float {
                        error(lexer.cursor, "Error: double radix in float");
                    }
                    else {
                        token.kind = Float;
                        continue;
                    }
                }

                break;
            }

        case '\r':
            token.kind = Newline;

            if char = next_char(&lexer); char == '\n' {
                char = next_char(&lexer);
            }

            lines += 1;
            chars  = 1;
        
        case '\n':
            token.kind = Newline;

            char = next_char(&lexer);
           
            lines += 1;
            chars  = 1;

        case utf8.RUNE_ERROR, utf8.RUNE_EOF, '\x00':
            break loop;

        case:
            error(cursor, "Invalid character in stream: %c {%d}", char, char);
            return nil;
        }

        token.text = source[token.index..cursor.index];

        append(&tokens, token);
    }

    append(&tokens, Token{kind=End});

    return tokens[..];
}
