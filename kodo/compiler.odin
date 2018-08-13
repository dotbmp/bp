/*
 *  @Name:     compiler
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 08-06-2018 18:12:54 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 12-08-2018 22:11:23 UTC-5
 *  
 *  @Description:
 *  
 */

package kodo

import "core:fmt"
import "core:os"

import "bp:kodo/ast"
import "bp:kodo/gen/c"

import "bp:process"

import "bp:path"



error :: proc[lexer_error, parser_error];



FILE_NAME :: "tests/test.kodo";



main :: proc() {
    if module := parse_file(FILE_NAME); module != nil {
        fmt.println("[=--------AST---------=]");
        ast.print(module);
        fmt.println("[=--------------------=]");
        fmt.println();

        dir  := path.dir(FILE_NAME);
        name := path.name(FILE_NAME);
        
        c_file := fmt.aprintf("%s/%s.c", dir, name);
        exe    := fmt.aprintf("%s/%s.exe", dir, name);
        defer delete(c_file);
        defer delete(exe);

        if c.generate_module_file(module, c_file) {
            fmt.println("[=--------MSVC--------=]");
            ok := process.create("cl %s -o %s", c_file, exe);
            fmt.println("[=--------------------=]");
            fmt.println();

            if ok {
                fmt.println("[=--------RUN---------=]");
                ok := process.create("%s", exe);
                fmt.println("[=--------------------=]");
                fmt.println();

                if ok {
                    fmt.println("--> Success!");
                    return;
                }
            }
        }
    }
    
    fmt.println("--> Failure!");
}