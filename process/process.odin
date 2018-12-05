/*
 *  @Name:     process
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 21-07-2018 00:40:38 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 07-11-2018 21:36:50 UTC-5
 *  
 *  @Description:
 *  
 */

package process

foreign import "system:kernel32.lib"

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import "core:sys/win32"

foreign kernel32 {
    @(link_name="DuplicateHandle")
    duplicate_handle :: proc "std" (source_process_handle: win32.Handle,
                                    source_handle:         win32.Handle,
                                    target_process_handle: win32.Handle,
                                    target_handle:         ^win32.Handle,
                                    desired_access:        u32,
                                    inherit_handle:        win32.Bool,
                                    options:               u32,
    ) -> win32.Bool ---;

    @(link_name="GetCurrentProcess")
    get_current_process :: proc "std" () -> win32.Handle ---;
}

create :: proc(format := "", args: ..any) -> bool {
    cmd := fmt.aprintf(format, ..args);
    defer delete(cmd);

    ccmd := strings.new_cstring(cmd);
    defer delete(ccmd);

    si := win32.Startup_Info {
        cb          = size_of(win32.Startup_Info),
        //flags       = win32.STARTF_USESTDHANDLES | win32.STARTF_USESHOWWINDOW,
        //show_window = win32.SW_SHOW,
        //stdin       = win32.get_std_handle(win32.STD_INPUT_HANDLE),
        //stdout      = win32.get_std_handle(win32.STD_OUTPUT_HANDLE),
        //stderr      = win32.get_std_handle(win32.STD_ERROR_HANDLE),
        //stdin = win32.Handle(os.stdin),
        //stdout = win32.Handle(os.stdout),
        //stderr = win32.Handle(os.stderr),
    };

    pi: win32.Process_Information;

    exit_code: u32;

    if win32.create_process_a(nil, ccmd, nil, nil, false, 0, nil, nil, &si, &pi) {
        win32.wait_for_single_object(pi.process, win32.INFINITE);
        win32.get_exit_code_process(pi.process, &exit_code);
        win32.close_handle(pi.process);
        win32.close_handle(pi.thread);
    } else {
        // failed to execute
        exit_code = ~u32(0);
    }

    return exit_code == 0;
}

silent :: proc(format := "", args: ..any) -> bool {
    cmd := fmt.aprintf(format, ..args);
    defer delete(cmd);

    ccmd := strings.new_cstring(cmd);
    defer delete(ccmd);

    si := win32.Startup_Info {
        cb          = size_of(win32.Startup_Info),
        flags       = win32.STARTF_USESTDHANDLES | win32.STARTF_USESHOWWINDOW,
        show_window = win32.SW_SHOW,
        stdin       = win32.Handle(os.stdin),
        stdout      = win32.Handle(os.stdout),
        stderr      = win32.Handle(os.stderr),
    };

    pi: win32.Process_Information;

    exit_code: u32;

    if win32.create_process_a(nil, ccmd, nil, nil, false, 0, nil, nil, &si, &pi) {
        win32.wait_for_single_object(pi.process, win32.INFINITE);
        win32.get_exit_code_process(pi.process, &exit_code);
        win32.close_handle(pi.process);
        win32.close_handle(pi.thread);
    } else {
        // failed to execute
        exit_code = ~u32(0);
    }

    return exit_code == 0;
}