/*
 *  @Name:     css
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 31-03-2018 22:48:40 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 31-03-2018 23:11:17 UTC-5
 *  
 *  @Description:
 *  
 */

import "core:fmt.odin"



Document :: struct {
    path   : string,
    styles : [dynamic]map[string]map[string]string,
}

Style :: struct {
    selector   : string,
    properties : map[string]string,
}

style :: proc(selector : string, properties : map[string]string = nil) -> ^Style {
    style := new(Style);

    style.selector   = selector;
    style.properties = properties;

    return style;
}


