/*
 *  @Name:     xml
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 31-03-2018 11:02:18 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 01-04-2018 22:33:30 UTC-5
 *  
 *  @Description:
 *  
 */

import "core:fmt.odin"

// @todo(bpunsky): fix this
import rem "shared:bpunsky/remove.odin"
import "shared:bpunsky/insert.odin"



Element :: struct {
    parent   : ^Element,
    children : [dynamic]^Element,

    tag, body  : string,
    attributes : map[string]string,
}

element :: proc(parent : ^Element, tag : string, body := "", attributes : map[string]string = nil) -> ^Element {
    elem := new(Element);

    elem.tag        = tag;
    elem.body       = body;
    elem.attributes = attributes;

    if parent != nil do append(parent, elem);

    return elem;
}

sbprint :: proc(buf : ^fmt.String_Buffer, elem : ^Element, indent := 0) {
    top := elem.parent == nil && elem.tag == "";
    do_indent := !top && elem.tag != "html";

    for in 0..indent do fmt.sbprint(buf, "  ");

    if !top do fmt.sbprintf(buf, "<%s", elem.tag);

    i := 0;
    for key, value in elem.attributes {
        fmt.sbprintf(buf, " %s", key);

        if value != "" do fmt.sbprintf(buf, "=\"%s\"", value);
        
        if i != len(elem.attributes) - 1 {
            fmt.sbprint(buf, ",");
        }

        i += 1;
    }

    if elem.body == "" && (elem.children == nil || len(elem.children) == 0) {
        if !top do fmt.sbprint(buf, " />");
    } else {
        if !top do fmt.sbprint(buf, ">\n");

        if elem.body != "" {
            for in 0..indent+1 do fmt.sbprint(buf, "  ");
            fmt.sbprintln(buf, elem.body);
        }

        for child in elem.children {
            str := to_string(child, do_indent ? indent + 1 : indent);
            defer free(str);

            fmt.sbprintln(buf, str);
        }
    
        for in 0..indent do fmt.sbprint(buf, "  ");

        if !top do fmt.sbprintf(buf, "</%s>", elem.tag);
    }
}

to_string :: proc(elem : ^Element, indent := 0) -> string {
    buf : fmt.String_Buffer;
    
    sbprint(&buf, elem, indent);

    return fmt.to_string(buf);
}

println :: proc(elem : ^Element, indent := 0) {
    str := to_string(elem, indent);
    defer free(str);

    fmt.println(elem, indent);
}

print :: proc(elem : ^Element, indent := 0) {
    str := to_string(elem, indent);
    defer free(str);

    fmt.print(elem, indent);
}

append :: proc[_global.append, _append];
_append :: proc(parent, child : ^Element) {
    append(&parent.children, child);
    child.parent = parent;
}

insert_before :: proc(elem, other : ^Element) {
    assert(elem.parent != nil);

    insert.before_value(&elem.parent.children, elem, other);
    other.parent = elem;
}

insert_after :: proc(elem, other : ^Element) {
    assert(elem.parent != nil);

    insert.after_value(&elem.parent.children, elem, other);
    other.parent = elem;
}

remove :: proc(parent, child : ^Element) {
    rem.unordered_value(&parent.children, child);
}

find :: proc(elem : ^Element, tag := "", id := "", class := "") -> ^Element {
    for child in elem.children {
        if child == nil do continue;

        match := true;

        if tag != "" && tag != child.tag do match = false;

        if id    != "" do if _id,    ok := child.attributes["id"];    !ok || _id    != id    do match = false;  
        if class != "" do if _class, ok := child.attributes["class"]; !ok || _class != class do match = false;

        if match do return child;

        if found := find(child, tag, id, class); found != nil do return found;
    }

    return nil;
}

find_all :: proc(elem : ^Element, tag := "", id := "", class := "") -> []^Element {
    elems : [dynamic]^Element;

    for child in elem.children {
        if child == nil do continue;

        match := true;

        if tag != "" && tag != child.tag do match = false;

        if id    != "" do if _id,    ok := child.attributes["id"];    !ok || _id    != id    do match = false;  
        if class != "" do if _class, ok := child.attributes["class"]; !ok || _class != class do match = false;

        if match do append(&elems, child);

        append(&elems, ...find_all(child, tag, id, class));
    }

    return elems[..];
}
