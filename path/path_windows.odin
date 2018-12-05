/*
 *  @Name:     path_windows
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 29-05-2018 09:51:15 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 04-12-2018 23:11:21 UTC-5
 *  
 *  @Description:
 *  
 */

package path

foreign import "system:kernel32.lib"

import "core:strings"
import "core:sys/win32"


SEPARATOR :: '\\';
SEPARATOR_STRING :: "\\";


long :: proc(path: string) -> string {
    foreign kernel32 {
        GetLongPathNameA :: proc "std" (short, long : ^byte, len : u32) -> u32 ---;
    }

    c_path := strings.new_cstring(path);
    defer delete(c_path);

    length := GetLongPathNameA(cast(^byte) c_path, nil, 0);

    if length > 0 {
        buf := make([]byte, length-1);

        GetLongPathNameA(cast(^byte) c_path, &buf[0], length);

        return cast(string) buf[:length-1];
    }

    return "";
}

short :: proc(path: string) -> string {
    foreign kernel32 {
        GetShortPathNameA :: proc "std" (long, short : ^byte, len : u32) -> u32 ---;
    }

    c_path := strings.new_cstring(path);
    defer delete(c_path);

    length := GetShortPathNameA(cast(^byte) c_path, nil, 0);

    if length > 0 {
        buf := make([]byte, length-1);

        GetShortPathNameA(cast(^byte) c_path, &buf[0], length);

        return cast(string) buf[:length-1];
    }

    return "";
}

full :: proc(path: string) -> string {
    foreign kernel32 {
        GetFullPathNameA :: proc "std" (filename : ^byte, buffer_length : u32, buffer : ^byte, file_part : ^^byte) -> u32 ---;
    }

    c_path := strings.new_cstring(path);
    defer delete(c_path);

    length := GetFullPathNameA(cast(^byte) c_path, 0, nil, nil);

    if length > 0 {
        buf := make([]byte, length);

        GetFullPathNameA(cast(^byte) c_path, length, &buf[0], nil);

        return cast(string) buf[:length-1];
    }

    return "";
}


current :: proc() -> string {
    foreign kernel32 {
        GetCurrentDirectoryA :: proc "std" (buffer_length : u32, buffer : ^byte) -> u32 ---;
    }

    length := GetCurrentDirectoryA(0, nil);

    if length > 0 {
        buf := make([]byte, length);

        GetCurrentDirectoryA(length, &buf[0]);

        return cast(string) buf[:length-1];
    }

    return "";
}


exists :: proc(path: string) -> bool {
    c_path := strings.new_cstring(path);
    defer delete(c_path);

    attribs := win32.get_file_attributes_a(c_path);

    return i32(attribs) != win32.INVALID_FILE_ATTRIBUTES;
}

is_dir :: proc(path: string) -> bool {
    c_path := strings.new_cstring(path);
    defer delete(c_path);

    attribs := win32.get_file_attributes_a(c_path);

    return (i32(attribs) != win32.INVALID_FILE_ATTRIBUTES) && (attribs & win32.FILE_ATTRIBUTE_DIRECTORY == win32.FILE_ATTRIBUTE_DIRECTORY);
}

is_file :: proc(path: string) -> bool {
    c_path := strings.new_cstring(path);
    defer delete(c_path);

    attribs := win32.get_file_attributes_a(c_path);

    return (i32(attribs) != win32.INVALID_FILE_ATTRIBUTES) && (attribs & win32.FILE_ATTRIBUTE_DIRECTORY != win32.FILE_ATTRIBUTE_DIRECTORY);
}


drive :: proc(path: string, new := false) -> string {
    if len(path) >= 3 {
        letter := path[:1];

        if path[1] == ':' && (path[2] == '\\' || path[2] == '/') {
            return letter;
        }
    }

    return "";
}
