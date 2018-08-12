/*
 *  @Name:     common
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 21-06-2018 13:18:31 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 02-07-2018 15:14:54 UTC-5
 *  
 *  @Description:
 *  
 */

package fiber

import "core:fmt"



PAGE_SIZE :: 65536;
DOS       :: false;



error :: inline proc(cursor : Cursor, format : string, args : ...any, loc := #caller_location) {
    message := fmt.aprintf(format, ...args);
    fmt.printf_err("(%d,%d): %s (from %s(%d,%d))\n", cursor.lines, cursor.chars, message, loc.file_path, loc.line, loc.column);
}



Runcode :: enum #export {
    STOP,
    RUN,
    DEBUG,
}



Bytecode :: struct {
    registers : [64]u64,
    
    code : []byte,
    data : []byte,
    
    stack_size  : int,
    memory_size : int,
}

destroy_bytecode :: inline proc(bytecode : ^Bytecode) {
    free(bytecode.code);
    free(bytecode.data);
}



Access :: enum {
    None,

    Read,
    Write,
    Exec,
}
