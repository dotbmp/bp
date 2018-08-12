/*
 *  @Name:     html
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 30-03-2018 19:21:37 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 01-04-2018 22:33:00 UTC-5
 *  
 *  @Description:
 *  
 */

import "core:fmt.odin"

export "xml.odin"



document :: proc(doc_type : string, charset := "utf8", the_title := "") -> ^Element {
    top := element(nil, "", "", nil);

    doct := doctype(top, doc_type);
    html := html(top);
    head := head(html);
    meta(parent=head, charset=charset);
    title(head, the_title);
    body(html);

    return top;
}

html :: proc(parent : ^Element = nil, name := "", id := "", class := "") -> ^Element {
    attributes : map[string]string;

    if name  != "" do attributes["name"]  = name;
    if id    != "" do attributes["id"]    = id;
    if class != "" do attributes["class"] = class;

    return element(parent, "html", "", attributes);
}

doctype :: proc(parent : ^Element = nil, str : string) -> ^Element {
    attributes : map[string]string;

    if str != "" do attributes[str] = "";

    return element(parent, "!doctype", "", attributes);
}

head :: proc(parent : ^Element = nil, name := "", id := "", class := "") -> ^Element {
    attributes : map[string]string;

    if name  != "" do attributes["name"]  = name;
    if id    != "" do attributes["id"]    = id;
    if class != "" do attributes["class"] = class;

    return element(parent, "head", "", attributes);
}

body :: proc(parent : ^Element = nil, name := "", id := "", class := "") -> ^Element {
    attributes : map[string]string;

    if name  != "" do attributes["name"]  = name;
    if id    != "" do attributes["id"]    = id;
    if class != "" do attributes["class"] = class;

    return element(parent, "body", "", attributes);
}

title :: proc(parent : ^Element = nil, body := "", name := "", id := "", class := "", href := "") -> ^Element {
    attributes : map[string]string;

    if name  != "" do attributes["name"]  = name;
    if id    != "" do attributes["id"]    = id;
    if class != "" do attributes["class"] = class;
    if href  != "" do attributes["href"]  = href;

    return element(parent, "title", body, attributes);
}

link :: proc(parent : ^Element = nil, href := "", rel := "") -> ^Element {
    attributes : map[string]string;

    if rel  != "" do attributes["rel"]  = rel;
    if href != "" do attributes["href"] = href;

    return element(parent, "link", "", attributes);
}

meta :: proc(parent : ^Element = nil, body := "", name := "", content := "", charset := "") -> ^Element {
    attributes : map[string]string;

    if name    != "" do attributes["name"]    = name;
    if content != "" do attributes["content"] = content;
    if charset != "" do attributes["charset"] = charset;

    return element(parent, "meta", body, attributes);   
}

h1 :: proc(parent : ^Element = nil, body := "", name := "", id := "", class := "", href := "") -> ^Element {
    attributes : map[string]string;

    if name  != "" do attributes["name"]  = name;
    if id    != "" do attributes["id"]    = id;
    if class != "" do attributes["class"] = class;
    if href  != "" do attributes["href"]  = href;

    return element(parent, "h1", body, attributes);
}

h2 :: proc(parent : ^Element = nil, body := "", name := "", id := "", class := "", href := "") -> ^Element {
    attributes : map[string]string;

    if name  != "" do attributes["name"]  = name;
    if id    != "" do attributes["id"]    = id;
    if class != "" do attributes["class"] = class;
    if href  != "" do attributes["href"]  = href;

    return element(parent, "h2", body, attributes);
}

h3 :: proc(parent : ^Element = nil, body := "", name := "", id := "", class := "", href := "") -> ^Element {
    attributes : map[string]string;

    if name  != "" do attributes["name"]  = name;
    if id    != "" do attributes["id"]    = id;
    if class != "" do attributes["class"] = class;
    if href  != "" do attributes["href"]  = href;

    return element(parent, "h3", body, attributes);
}

h4 :: proc(parent : ^Element = nil, body := "", name := "", id := "", class := "", href := "") -> ^Element {
    attributes : map[string]string;

    if name  != "" do attributes["name"]  = name;
    if id    != "" do attributes["id"]    = id;
    if class != "" do attributes["class"] = class;
    if href  != "" do attributes["href"]  = href;

    return element(parent, "h4", body, attributes);
}

p :: proc(parent : ^Element = nil, body := "", name := "", id := "", class := "", href := "") -> ^Element {
    attributes : map[string]string;

    if name  != "" do attributes["name"]  = name;
    if id    != "" do attributes["id"]    = id;
    if class != "" do attributes["class"] = class;
    if href  != "" do attributes["href"]  = href;

    return element(parent, "p", body, attributes);
}

a :: proc(parent : ^Element = nil, body := "", name := "", id := "", class := "", href := "") -> ^Element {
    attributes : map[string]string;

    if name  != "" do attributes["name"]  = name;
    if id    != "" do attributes["id"]    = id;
    if class != "" do attributes["class"] = class;
    if href  != "" do attributes["href"]  = href;

    return element(parent, "a", body, attributes);
}

div :: proc(parent : ^Element = nil, name := "", id := "", class := "", width := "", height := "") -> ^Element {
    attributes : map[string]string;

    if name   != "" do attributes["name"]   = name;
    if id     != "" do attributes["id"]     = id;
    if class  != "" do attributes["class"]  = class;
    if width  != "" do attributes["width"]  = width;
    if height != "" do attributes["height"] = height;

    return element(parent, "div", "", attributes);
}

hr :: proc(parent : ^Element = nil) -> ^Element {
    return element(parent, "hr", "", nil);
}

// @note(bpunsky): temporary!
style :: proc(parent : ^Element = nil, body : string) -> ^Element {
    return element(parent, "style", body, nil);
}
