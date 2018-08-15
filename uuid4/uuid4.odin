/*
 *  @Name:     uuid4
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 13-08-2018 13:08:30 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 13-08-2018 13:36:53 UTC-5
 *  
 *  @Description:
 *  
 */

package uuid4

foreign import "uuid4.lib"

import "core:fmt"



generate :: proc() -> string {
    foreign uuid4 {
        uuid4_generate :: proc "c" (dst: ^byte) -> i32 ---;
    }

    buf := make([]byte, 37);

    uuid4_generate(&buf[0]);

    return string(buf[:len(buf)-1]);
}

main :: proc() {
    for in 0..9 {
        uuid := generate();
        defer delete(uuid);

        fmt.println(uuid);
    }
}
