/*
 *  @Name:     lexer
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 01-06-2018 19:21:27 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 09-08-2018 22:20:09 UTC-5
 *  
 *  @Description:
 *  
 */

package kodo

import "core:fmt"
import "core:os"
import "core:unicode/utf8"

import "cio:kodo/ast"



Lexer :: struct {
    using cursor : ast.Cursor,
    file_path : string,
    text : string,
    skip : int,
}

next_char :: inline proc(using lexer : ^Lexer) -> (res : rune) {
    start += skip;
    chars += 1;

    res, skip = utf8.decode_rune_from_string(text[start:]);

    return;
}

lex_file :: proc(file_name : string) -> []ast.Token {
    if bytes, ok := os.read_entire_file(file_name); ok {
        return lex_text(string(bytes), file_name);
    }

    return nil;
}   

lex_text :: proc(source : string, file_name := "") -> []ast.Token {
    using lexer := Lexer{ast.Cursor{0, 0, 1, 0}, file_name, source, 0};

    token  : ast.Token;
    tokens : [dynamic]ast.Token;

    char := next_char(&lexer);

    loop: for {
        for {
            switch char {
            case ' ', '\t':
                char = next_char(&lexer);
            
                continue;

            case '\r':
                if char = next_char(&lexer); char == '\n' {
                    char = next_char(&lexer);
                }

                lines += 1;
                chars  = 1;

                continue;

            case '\n':
                char = next_char(&lexer);

                lines += 1;
                chars  = 1;

                continue;
            }

            break;
        }

        token.cursor = cursor;

        switch char {
        case '#':
            for {
                switch char = next_char(&lexer); char {
                case 'A'..'Z', 'a'..'z', '0'..'9', '_': continue;
                }

                break;
            }

            switch source[token.start+1:cursor.start] {
            case "uint", "uint8", "uint16", "uint32", "uint64",
                 "int",  "int8",  "int16",  "int32",  "int64",
                 "bool", "bool8", "bool16", "bool32", "bool64",
                 "float32", "float64", "string", "ztring":
                token.kind = ast.Directive;

            case "true", "false":
                token.kind = ast.Bool;

            case:
                error(&lexer, "Invalid directive: %s", source[token.start:cursor.start]);
            }

        case 'A'..'Z', 'a'..'z', '_':
            token.kind = ast.Ident;

            for {
                switch char = next_char(&lexer); char {
                case 'A'..'Z', 'a'..'z', '0'..'9', '_': continue;
                }

                break;
            }

            switch source[token.start:start] {
            case "import", "foreign", "scope",
                 "const", "static", "var",
                 "type", "alias",
                 "proc", "struct", "enum",
                 "if", "else", "for", "switch",
                 "null":
                token.kind = ast.Keyword;

            case "true", "false":
                token.kind = ast.Bool;
            }

        case '0'..'9':
            token.kind = ast.Int;

            for {
                switch char = next_char(&lexer); char {
                case '0'..'9': continue;
                case '.':
                    if token.kind == ast.Float {
                        error(&lexer, "Double radix in float.");
                    }
                    token.kind = ast.Float;
                }

                break;
            }

        case '"', '\'', '`':
            token.kind = ast.String;

            end := char;

            for {
                switch char = next_char(&lexer); char {
                case end:
                    char = next_char(&lexer);

                case utf8.RUNE_ERROR, utf8.RUNE_EOF, '\x00', '\r', '\n':
                    error(&lexer, "Expected '%v', got '%v'.", end, char);

                case: continue;
                }

                break;
            }

        case '\r':
            token.kind = ast.Newline;

            if next_char(&lexer) == '\n' {
                char = next_char(&lexer);
            }

            lines += 1;
            chars  = 1;

        case '\n':
            token.kind = ast.Newline;

            next_char(&lexer);

            lines += 1;
            chars  = 1;

        case ';', ',', '.', '^', ':',
             '+', '-', '*', '/', '%',
             '=', '?', '<', '>', '!',
             '&', '|', '~', '{', '}',
             '[', ']', '(', ')', '$':
            token.kind = ast.Symbol;

            switch char {
            case '.':
                switch char = next_char(&lexer); char {
                case '.':
                    switch char = next_char(&lexer); char {
                    case '.':
                        char = next_char(&lexer);
                    }
                }

            case '+':
                switch char = next_char(&lexer); char {
                case '+', '=':
                    char = next_char(&lexer);
                }

            case '-':
                switch char = next_char(&lexer); char {
                case '-', '>', '=':
                    char = next_char(&lexer);
                }

            case '*', '%', '!':
                switch char = next_char(&lexer); char {
                case '=':
                    char = next_char(&lexer);
                }

            case '/':
                switch char = next_char(&lexer); char {
                case '*':
                    token.kind = ast.Comment;

                    char = next_char(&lexer);

                    for {
                        switch char {
                        case '*':
                            if char = next_char(&lexer); char == '/' {
                                char = next_char(&lexer);
                            }
                            else {
                                continue;
                            }
                        }

                        break;
                    }

                case '/':
                    token.kind = ast.Comment;

                    for {
                        switch char = next_char(&lexer); char {
                        case '\r', '\n':
                        case: continue;
                        }

                        break;
                    }

                case '=':
                    char = next_char(&lexer);
                }

            case '=':
                switch char = next_char(&lexer); char {
                case '>':
                    char = next_char(&lexer);
                }

            case '|':
                switch char = next_char(&lexer); char {
                case '|', '=':
                    char = next_char(&lexer);
                }

            case '&':
                switch char = next_char(&lexer); char {
                case '&', '=':
                    char = next_char(&lexer);
                }

            case '<':
                switch char = next_char(&lexer); char {
                case '<', '-':
                    char = next_char(&lexer);
                }

            case '>':
                switch char = next_char(&lexer); char {
                case '>':
                    char = next_char(&lexer);
                }

            case '~':
                switch char = next_char(&lexer); char {
                case '~':
                    switch char = next_char(&lexer); char {
                    case '=':
                        char = next_char(&lexer);
                    }

                case '=':
                    char = next_char(&lexer);
                }

            case:
                char = next_char(&lexer);
            }


        case utf8.RUNE_ERROR, utf8.RUNE_EOF, '\x00':
            break loop;

        case:
            error(&lexer, "Invalid character in stream: %c {%d}", char, char);
            return nil;
        }

        token.text = source[token.start:cursor.start];
        token.end = cursor.start;

        append(&tokens, token);
    }

    append(&tokens, ast.Token{kind=ast.End});

    return tokens[:];
}



lexer_error :: inline proc(using lexer : ^Lexer, format : string, args : ..any, loc := #caller_location) {
    message := fmt.aprintf(format, ..args);
    defer delete(message);
    
    fmt.printf_err("%s(%d,%d): %s (from %s(%d,%d))\n", file_path, lines, chars, message, loc.file_path, loc.line, loc.column);
}
