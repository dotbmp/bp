/*
 *  @Name:     path
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 28-11-2017 00:10:03 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 05-12-2018 06:04:52 UTC-5
 *  
 *  @Description:
 *  
 */

package path

import "core:strings"
import "core:unicode/utf8"


dir :: proc(path: string, new := false) -> string {
    for i := len(path) - 1; i >= 0; i -= 1 {
        switch path[i] {
        case '/', '\\':
            return new ? strings.new_string(path[:i]) : path[:i];
        }
     }

    return new ? strings.new_string(path) : path;
}

file :: proc(path: string, new := false) -> string {
    end := len(path) - 1;

    for i := end; i >= 0; i -= 1 {
        switch path[i] {
            case '/', '\\':
                if i != end {
                    return new ? strings.new_string(path[i+1:]) : path[i+1:];
                }
                else {
                    return ""; // @note(bpunsky): only a directory could have `/` or `\` at the end, this should never be reached
                }
        }
    }

    return new ? strings.new_string(path) : path;
}

name :: proc(path: string, new := false) -> string {
    dot := len(path);
    end := dot - 1;

    for i := end; i >= 0; i -= 1 {
        switch path[i] {
        case '.':       dot = (dot == end ? i : dot);
        case '/', '\\': return new ? strings.new_string(path[i+1:dot]) : path[i+1:dot];
        }
    }

    return "";
}

ext :: proc(path: string, new := false) -> string {
    for i := len(path)-1; i >= 0; i -= 1 {
        switch path[i] {
        case '/', '\\': return "";
        case '.':       return new ? strings.new_string(path[i+1:]) : path[i+1:];
        }
    }

    return "";
}


// @note(bpunsky): the rel procs always return new memory, unless the result is ""

rel :: proc{rel_between, rel_current};

rel_between :: proc(from, to: string) -> string {
    from, to = full(from), full(to);

    from_is_dir := is_dir(from);
    to_is_dir   := is_dir(to);

    index := 0;
    slash := 0;

    for {
        if index >= len(from) {
            if index >= len(to) || (from_is_dir && index < len(to) && (to[index] == '/' || to[index] == '\\')) {
                slash = index;
            }

            break;
        }
        else if index >= len(to) {
            if index >= len(from) || (to_is_dir && index < len(from) && (from[index] == '/' || from[index] == '\\')) {
                slash = index;
            }

            break;
        }

        lchar, skip := utf8.decode_rune_from_string(from[index:]);
        rchar, _    := utf8.decode_rune_from_string(to[index:]);

        if (lchar == '/' || lchar == '\\') && (rchar == '/' || lchar == '\\') {
            slash = index;
        }
        else if lchar != rchar {
            break;
        }

        index += skip;
    }

    if slash < 1 {
        // @note(bpunsky): there is no common path, use the absolute `to` path (Windows drive letters, for example)
        return to;
    }

    from_slashes := 0;
    to_slashes   := 0;

    if slash < len(from) {
        from = from[slash+1:];
        
        if from_is_dir {
            from_slashes += 1;
        }
    }
    else {
        from = "";
    }

    if slash < len(to) {
        to = to[slash+1:];

        if to_is_dir {
            to_slashes += 1;
        }
    }
    else {
        to = "";
    }

    for char in from {
        if char == '/' || char == '\\' {
            from_slashes += 1;
        }
    }

    for char in to {
        if char == '/' || char == '\\' {
            to_slashes += 1;
        }
    }

    if from_slashes == 0 {
        buffer := make([]byte, 2 + len(to));

        buffer[0] = '.';
        buffer[1] = SEPARATOR;
        copy(buffer[2:], ([]byte)(to));

        return string(buffer);
    }
    else {
        buffer := make([]byte, from_slashes*3 + len(to));

        for i in 0..from_slashes-1 {
            buffer[i*3+0] = '.';
            buffer[i*3+1] = '.';
            buffer[i*3+2] = SEPARATOR;
        }

        copy(buffer[from_slashes*3:], ([]byte)(to));

        return string(buffer);
    }

    return "";
}

import "core:fmt"

rel_current :: proc(to: string) -> string {
    tmp := current();
    defer delete(tmp);

    return rel_between(tmp, to);
}
