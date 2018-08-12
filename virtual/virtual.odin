/*
 *  @Name:     virtual
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 17-05-2018 01:03:39 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 09-08-2018 21:56:17 UTC-5
 *  
 *  @Description:
 *  
 */

package virtual

import "core:mem"



using Permission :: enum {
    None    = 0,
    Guard   = 1 << 0,
    Read    = 1 << 1,
    Write   = 1 << 2,
    Execute = 1 << 3,
}
