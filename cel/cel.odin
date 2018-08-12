/*
 *  @Name:     cel
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 13-02-2018 06:58:01 UTC-5
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 01-08-2018 23:25:17 UTC+1
 *  
 *  @Description:
 *  
 */

package odin_cel;

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import "core:runtime"
import "core:unicode/utf8"

import "shared:CEL"

destroy_value :: proc(value : cel.Value) {
    switch v in value {
    case cel.Array:
        for elem in v {
            destroy_value(elem);
        }

        delete(v);

    case cel.Dict:
        for key, value in v {
            destroy_value(value);
        }

        delete(v);
    }
}

escape_string :: proc(str : string) -> string {
    buf : fmt.String_Buffer;

    for i := 0; i < len(str); {
        char, skip := utf8.decode_rune(([]u8)(str[i..]));
        i += skip;

        switch char {
        case: 
            if utf8.valid_rune(char) {
                fmt.write_rune(&buf, char);
            } else {
                delete(buf);
                return "";
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



// @note(bpunsky): printing `Value` tree to CEL buffer/console/string

INDENT :: "    ";

_buffer_print :: proc(sb : ^fmt.String_Buffer, value : cel.Value, root := true, indent := 0) {
    switch v in value {
    case cel.Dict:
        if !root do fmt.sbprint(sb, "{");

        if !root do indent += 1;
        i := 0;
        for key, val in v {
            //for in 0..indent do fmt.sbprint(sb, INDENT);
            fmt.sbprintf(sb, "%s = ", key);
            _buffer_print(sb, val, false, indent);
            if !root {
                if i != len(v)-1 do fmt.sbprint(sb, ", ");
            } else {
                fmt.sbprintln(sb);
            }
            i += 1;
        }
        if !root do indent -= 1;

        //for in 0..indent do fmt.sbprint(sb, INDENT);
        if !root do fmt.sbprint(sb, "}");

    case cel.Array:
        fmt.sbprint(sb, "[");
        
        indent += 1;        
        for val, i in v {
            //for in 0..indent do fmt.sbprint(sb, INDENT);
            _buffer_print(sb, val, false, indent);
            if i != len(v)-1 do fmt.sbprint(sb, ", ");
            //fmt.sbprintln(sb, ",");
        }
        indent -= 1;

        //for in 0..indent do fmt.sbprint(sb, INDENT);
        fmt.sbprint(sb, "]");

    case bool: fmt.sbprintf(sb, "%v", v);
    case i64:  fmt.sbprintf(sb, "%v", v);
    case f64:  fmt.sbprintf(sb, "%v", v);

    case string:
        str := escape_string(v);
        defer delete(str);

        fmt.sbprintf(sb, "\"%s\"", str);
    
    case cel.Nil_Value: fmt.sbprintf(sb, "nil");
    }
}

to_string :: inline proc(value : cel.Value, root := true) -> string {
    sb := fmt.String_Buffer{};
    _buffer_print(&sb, value, root);
    return fmt.to_string(sb);
}

print_out :: inline proc(value : cel.Value, root := true) {
    str := to_string(value, root);
    defer delete(str);

    fmt.println(str);
}



// @note(bpunsky): clean API, marshalling and unmarshalling

parse :: inline proc(txt : string) -> (^cel.Parser, bool) {
    return cel.create_from_string(txt);
}

parse_file :: inline proc(path : string) -> (^cel.Parser, bool) {
    if bytes, ok := os.read_entire_file(path); ok {
        return parse(cast(string) bytes);
    }

    return nil, false;
}



Raw_Map_Entry :: struct(Value : type) {
    key   : __Map_Key,
    next  : int,
    value : cel.Value,
}

Raw_Map :: struct(Value : type) {
    hashes  : [dynamic]int,
    entries : [dynamic]Raw_Map_Entry(Value),
}



unmarshal :: proc(value : cel.Value, data : any) -> bool {
    type_info := runtime.type_info_base_without_enum(type_info_of(data.typeid));
    type_info  = runtime.type_info_base_without_enum(type_info); // @todo: dirty fucking hack, won't hold up

    switch v in value {
    case cel.Dict:
        switch variant in type_info.variant {
        case runtime.Type_Info_Struct:
            for field, i in variant.names {
                // @todo: stricter type checking and by-order instead of by-name as an option
                a := transmute(any) mem.Raw_Any{rawptr(uintptr(data.data) + uintptr(variant.offsets[i])), variant.types[i].id};
                
                if val, ok := v[field]; ok {
                    if !unmarshal(val, a) do return false; // @error
                } else {
                    type_info := runtime.type_info_base_without_enum(type_info_of(a.typeid));
                    type_info  = runtime.type_info_base_without_enum(type_info); // @todo: dirty fucking hack, won't hold up

                    mem.set(a.data, 0, type_info.size);
                }
            }

            return true; 
        
        case runtime.Type_Info_Map:
            
            return false; // @todo: implement. ask bill about this, maps are a daunting prospect because they're fairly opaque
        case: return false; // @error
        }


    case cel.Array:
        switch variant in type_info.variant {
        case runtime.Type_Info_Array:
            if len(v) > variant.count do return false; // @error

            for i in 0..variant.count-1 {
                a := transmute(any) mem.Raw_Any{rawptr(uintptr(data.data) + uintptr(variant.elem_size * i)), variant.elem.id};
                
                if !unmarshal(v[i], a) do return false; // @error
            }

            return true;

        case runtime.Type_Info_Slice:
            array := cast(^mem.Raw_Slice) data.data;

            if len(v) > array.len do return false; // @error
            array.len = len(v);

            for i in 0..array.len-1 {
                a := transmute(any) mem.Raw_Any{rawptr(uintptr(array.data) + uintptr(variant.elem_size * i)), variant.elem.id};
                if !unmarshal(v[i], a) do return false; // @error
            }

            return true;

        case runtime.Type_Info_Dynamic_Array:
            array := cast(^mem.Raw_Dynamic_Array) data.data;

            if array.cap == 0 {
                array.data      = mem.alloc(len(v)*variant.elem_size);
                array.cap       = len(v);
                array.allocator = context.allocator;
            }

            if len(v) > array.cap do context <- mem.context_from_allocator(array.allocator) do mem.resize(array.data, array.cap, len(v)*variant.elem_size);
            array.len = len(v);

            for i in 0..array.len-1 {
                a := transmute(any) mem.Raw_Any{rawptr(uintptr(array.data) + uintptr(variant.elem_size * i)), variant.elem.id};
                if !unmarshal(v[i], a) do return false; // @error
            }

            return true;

        case: return false; // @error
        }

    case string:
        if _, ok := type_info.variant.(runtime.Type_Info_String); !ok do return false; // @error
        
        tmp := strings.new_string(cast(string) v);
        mem.copy(data.data, &tmp, size_of(string));

        return true;

    case i64:
        if _, ok := type_info.variant.(runtime.Type_Info_Integer); !ok do return false; // @error
        
        switch type_info.size {
        case 8:
            tmp := i64(v);
            mem.copy(data.data, &tmp, type_info.size);

        case 4:
            tmp := i32(v);
            mem.copy(data.data, &tmp, type_info.size);

        case 2:
            tmp := i16(v);
            mem.copy(data.data, &tmp, type_info.size);

        case 1:
            tmp := i8(v);
            mem.copy(data.data, &tmp, type_info.size);

        case: return false; // @error
        }

        return true;

    case f64:
        if _, ok := type_info.variant.(runtime.Type_Info_Float); !ok do return false; // @error

        switch type_info.size {
        case 8:
            tmp := f64(v);
            mem.copy(data.data, &tmp, type_info.size);

        case 4:
            tmp := f32(v);
            mem.copy(data.data, &tmp, type_info.size);

        case: return false; // @error
        }

        return true;

    case bool:
        if _, ok := type_info.variant.(runtime.Type_Info_Boolean); !ok do return false; // @error

        tmp := bool(v);
        mem.copy(data.data, &tmp, type_info.size);

        return true;

    case cel.Nil_Value:
        mem.set(data.data, 0, type_info.size);
    
    case: return false; // @error
    }

    return true;
}

unmarshal_string :: inline proc(txt : string, data : any) -> bool {
    if parser, ok := parse(txt); ok {
        defer cel.destroy(parser);
        return unmarshal(parser.root, data);
    }

    return false;
}

unmarshal_file :: inline proc(path : string, data : any) -> bool {
    if parser, ok := parse_file(path); ok {
        defer cel.destroy(parser);
        return unmarshal(parser.root, data);
    }
    
    return false;
}

marshal :: proc(data : any) -> cel.Value {
    type_info := runtime.type_info_base_without_enum(type_info_of(data.typeid));
    type_info  = runtime.type_info_base_without_enum(type_info);

    value: cel.Value;

    switch v in type_info.variant {
    case runtime.Type_Info_Integer:
        i: i64;

        switch type_info.size {
        /*case 16: i = cast(i64) (cast(^i128) data.data)^;*/
        case 8:  i = cast(i64) (cast(^i64)  data.data)^;
        case 4:  i = cast(i64) (cast(^i32)  data.data)^;
        case 2:  i = cast(i64) (cast(^i16)  data.data)^;
        case 1:  i = cast(i64) (cast(^i8)   data.data)^;
        }

        value = i;

    case runtime.Type_Info_Float:
        f: f64;

        switch type_info.size {
        case 8: f = cast(f64) (cast(^f64) data.data)^;
        case 4: f = cast(f64) (cast(^f32) data.data)^;
        }

        value = f;

    case runtime.Type_Info_String:
        str := (cast(^string) data.data)^;
        // @todo: escape the string
        value = str;

    case runtime.Type_Info_Boolean:
        value = (cast(^bool) data.data)^;

    case runtime.Type_Info_Array:
        array := make([]cel.Value, v.count);

        for i in 0..v.count-1 {
            if tmp := marshal(transmute(any) mem.Raw_Any{rawptr(uintptr(data.data) + uintptr(v.elem_size*i)), v.elem.id}); tmp != nil {
                array[i] = tmp;
            } else {
                return nil; // @error
            }
        }

        value = cast(cel.Array) array;

    case runtime.Type_Info_Slice:
        a := cast(^mem.Raw_Slice) data.data;

        array := make([]cel.Value, a.len);

        for i in 0..a.len-1 {
            if tmp := marshal(transmute(any) mem.Raw_Any{rawptr(uintptr(a.data) + uintptr(v.elem_size*i)), v.elem.id}); tmp != nil {
                array[i] = tmp;
            } else {
                return nil; // @error
            }
        }

        value = cast(cel.Array) array;

    case runtime.Type_Info_Dynamic_Array:
        array := make([dynamic]cel.Value);

        a := cast(^mem.Raw_Dynamic_Array) data.data;

        for i in 0..a.len-1 {
            if tmp := marshal(transmute(any) mem.Raw_Any{rawptr(uintptr(a.data) + uintptr(v.elem_size*i)), v.elem.id}); tmp != nil {
                append(&array, tmp);
            } else {
                return nil; // @error
            }
        }

        value = cast(cel.Array) array[..];

    case runtime.Type_Info_Struct:
        dict := cel.Dict{};

        for ti, i in v.types {
            if tmp := marshal(transmute(any) mem.Raw_Any{rawptr(uintptr(data.data) + uintptr(v.offsets[i])), ti.id}); tmp != nil {
                dict[v.names[i]] = tmp;
            } else {
                return nil; // @error
            }
        }

        value = dict;

    case runtime.Type_Info_Map:
        // @todo: implement. ask bill about this, maps are fucky
        return nil;

    case: return nil; // @error
    }

    return value;
}

marshal_string :: inline proc(data : any) -> (cel : string) {
    if value := marshal(data); value != nil {
        defer destroy_value(value);
        return to_string(value);
    }

    return "";
}

marshal_file :: inline proc(path : string, data : any) -> (ok : bool) {
    if cel := marshal_string(data); cel != "" {
        return os.write_entire_file(path, cast([]u8) cel);
    }

    return false;
}
