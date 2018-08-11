/*
 *  @Name:     riscv
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 27-04-2018 19:08:25 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 26-06-2018 14:28:09 UTC-5
 *  
 *  @Description:
 *  
 */

package riscv

import "core:fmt"
import "core:os"
import "core:mem"
import "core:strconv"



error :: proc(format : string, args : ...any, loc := #caller_location) {
    when false {
        fmt.printf_err("%s(%d,%d): ", loc.file_path, loc.line, loc.column);
        fmt.printf_err(format, ...args);
        fmt.println_err();
    }
    else {
        fmt.printf("%s(%d,%d): ", loc.file_path, loc.line, loc.column);
        fmt.printf(format, ...args);
        fmt.println();   
    }
}



_mulhu :: inline proc(lhs, rhs : u64) -> u64 {
    a0 := u32(lhs);
    a1 := u32(lhs >> 32);

    b0 := u32(rhs);
    b1 := u32(rhs >> 32);

    t := a1*b0 + ((a0*b0) >> 32);
    y1 := t;
    y2 := t >> 32;

    t = a0*b1 + y1;
    y1 = t;

    t = a1*b1 + y2 + (t >> 32);
    y2 = t;
    y3 := t >> 32;

    return (u64(y3) << 32) | u64(y2);
}

_mulh :: inline proc(lhs, rhs : i64) -> i64 {
    res := cast(i64) _mulhu(lhs < 0 ? u64(-lhs) : u64(lhs), rhs < 0 ? u64(-rhs) : u64(rhs));
    
    return (lhs < 0) != (rhs < 0) ? ~res + ((lhs * rhs == 0) ? 1 : 0) : res;
}

_mulhsu :: inline proc(lhs : i64, rhs : u64) -> i64 {
    res := cast(i64) _mulhu(lhs < 0 ? u64(-lhs) : u64(lhs), rhs);

    return lhs < 0 ? ~res + ((lhs * i64(rhs) == 0) ? 1 : 0) : res;
}



sext :: proc[sext64, sext32];
sext64 :: inline proc(x : u64, bits : uint) -> u64 do return u64(i64(x << (64 - bits)) >> (64 - bits));
sext32 :: inline proc(x : u32, bits : uint) -> u32 do return u32(i32(x << (32 - bits)) >> (32 - bits));

hi20 :: proc[hi2064, hi2032];
hi2064 :: inline proc(x : u64) -> u64 do return ((x + 0x800) >> 12) & 0xFFFFFFFFFFFFF;
hi2032 :: inline proc(x : u32) -> u32 do return ((x + 0x800) >> 12) & 0xFFFFFF;

lo12 :: proc[lo1264, lo1232];
lo1264 :: inline proc(x : u64) -> u64 do return sext(x, 12);
lo1232 :: inline proc(x : u32) -> u32 do return sext(x, 12);

bits :: proc[bits64, bits32];
bits64 :: inline proc(x : u64, start, len : uint) -> u64 do return (x >> start) & ((1 << len) - 1);
bits32 :: inline proc(x : u32, start, len : uint) -> u32 do return (x >> start) & ((1 << len) - 1);



main :: proc() {
    hart := make_hart();
    defer free_hart(hart);

    code : [dynamic]byte;

    imm : u64 = 101;

    store(&hart, u32, 200, u32(imm));
    n := load(&hart, u32, 200);

    load_instructions(&hart,
        li(x1, 10),
        li(x2, 9),
        mul(x1, x1, x2),
        sd(x0, 200, x1),
        ld(x4, x0, 200),
    );

    debug(&hart);
}
