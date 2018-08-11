/*
 *  @Name:     strings
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 21-07-2018 16:48:34 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 09-08-2018 21:49:18 UTC-5
 *  
 *  @Description:
 *  
 */

package util

import "core:fmt"
import "core:strconv"
import "core:unicode/utf8"
import "core:unicode/utf16"



escape_string :: proc(str: string) -> string {
    buf := fmt.String_Buffer{};

    for i := 0; i < len(str); {
        char, skip := utf8.decode_rune(cast([]u8) str[i:]);
        i += skip;

        switch char {
        case: 
            if utf8.valid_rune(char) {
                fmt.write_rune(&buf, char);
            }
            else {
                return ""; // @error
            }

        case '"':  fmt.sbprint(&buf, "\\\"");
        case '\'': fmt.sbprint(&buf, "\\'");
        case '\\': fmt.sbprint(&buf, "\\\\");
        case '\a': fmt.sbprint(&buf, "\\a");
        case '\b': fmt.sbprint(&buf, "\\b");
        case '\f': fmt.sbprint(&buf, "\\f");
        case '\n': fmt.sbprint(&buf, "\\n");
        case '\r': fmt.sbprint(&buf, "\\r");
        case '\t': fmt.sbprint(&buf, "\\t");
        case '\v': fmt.sbprint(&buf, "\\v");
        }
    }

    return fmt.to_string(buf);
}

unescape_string :: proc(str: string) -> string {
    buf := fmt.String_Buffer{};

    for i := 0; i < len(str); {
        char, skip := utf8.decode_rune(cast([]u8) str[i:]);
        i += skip;

        switch char {
        case: fmt.write_rune(&buf, char);

        case '"': // @note: do nothing.

        case '\\':
            char, skip = utf8.decode_rune(cast([]u8) str[i:]);
            i += skip;

            switch char {
            case '0': fmt.write_rune(&buf, '\x00');

            case '\\': fmt.write_rune(&buf, '\\');
            case '\'': fmt.write_rune(&buf, '\'');
            case '"':  fmt.write_rune(&buf, '"');

            case 'a': fmt.write_rune(&buf, '\a');
            case 'b': fmt.write_rune(&buf, '\b');
            case 'f': fmt.write_rune(&buf, '\f');
            case 'n': fmt.write_rune(&buf, '\n');
            case 'r': fmt.write_rune(&buf, '\r');
            case 't': fmt.write_rune(&buf, '\t');
            case 'v': fmt.write_rune(&buf, '\v');

            case 'u':
                lo, hi: rune;
                hex := [?]u8{'0', 'x', '0', '0', '0', '0'};

                c0, s0 := utf8.decode_rune(cast([]u8) str[i:]); hex[2] = cast(u8) c0; i += s0;
                c1, s1 := utf8.decode_rune(cast([]u8) str[i:]); hex[3] = cast(u8) c1; i += s1;
                c2, s2 := utf8.decode_rune(cast([]u8) str[i:]); hex[4] = cast(u8) c2; i += s2;
                c3, s3 := utf8.decode_rune(cast([]u8) str[i:]); hex[5] = cast(u8) c3; i += s3;

                lo = cast(rune) strconv.parse_int(cast(string) hex[:]);

                if utf16.is_surrogate(lo) {
                    c0, s0 := utf8.decode_rune(cast([]u8) str[i:]); i += s0;
                    c1, s1 := utf8.decode_rune(cast([]u8) str[i:]); i += s1;

                    if c0 == '\\' && c1 == 'u' {
                        c0, s0 = utf8.decode_rune(cast([]u8) str[i:]); hex[2] = cast(u8) c0; i += s0;
                        c1, s1 = utf8.decode_rune(cast([]u8) str[i:]); hex[3] = cast(u8) c1; i += s1;
                        c2, s2 = utf8.decode_rune(cast([]u8) str[i:]); hex[4] = cast(u8) c2; i += s2;
                        c3, s3 = utf8.decode_rune(cast([]u8) str[i:]); hex[5] = cast(u8) c3; i += s3;                      

                        hi = cast(rune) strconv.parse_u64(string(hex[:]));
                        lo = utf16.decode_surrogate_pair(lo, hi);

                        if lo == utf16.REPLACEMENT_CHAR {
                            return ""; // @error
                        }
                    } else {
                        return ""; // @error
                    }
                }

                fmt.write_rune(&buf, lo);

            case:
                return ""; // @error
            }
        }
    }

    return fmt.to_string(buf);
}
