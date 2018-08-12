/*
 *  @Name:     fiber
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 25-05-2018 06:47:25 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 06-07-2018 09:56:37 UTC-5
 *  
 *  @Description:
 *  
 */

package fiber

import "core:os"



main :: proc() do debug_file("stack_machine.fbr");



run_text :: proc(source : string) -> bool {
    if bc, ok := parse_text(source); ok {
        defer destroy_bytecode(&bc);
        
        thread := make_thread(&bc);

        run_thread(&thread);

        return true;
    }

    return false;
}

run_file :: proc(filename : string) -> bool {
    if bc, ok := parse_file(filename); ok {
        defer destroy_bytecode(&bc);

        thread := make_thread(&bc);

        run_thread(&thread);

        return true;
    }

    return false;
}



debug_text :: proc(source : string) -> bool {
    if bc, ok := parse_text(source); ok {
        defer destroy_bytecode(&bc);

        thread := make_thread(&bc);

        debug_thread(&thread);

        return true;
    }

    return false;
}

debug_file :: proc(filename : string) -> bool {
    if bc, ok := parse_file(filename); ok {
        defer destroy_bytecode(&bc);

        thread := make_thread(&bc);

        debug_thread(&thread);

        return true;
    }

    return false;
}
