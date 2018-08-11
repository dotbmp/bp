/*
 *  @Name:     ssa
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 21-07-2018 23:20:09 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 21-07-2018 23:45:18 UTC-5
 *  
 *  @Description:
 *  
 */

package ir

import "cio:kodo/ast"

Type :: struct {
    name : string,
    size : int,

    variant : union {
        Type_Struct,
    },
}

Type_Struct :: struct {
    names : []^Name,
    types : []^Type,
}



Instr_Binary :: struct {
    typ : ^Type,
}