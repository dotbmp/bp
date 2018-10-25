/*
 *  @Name:     dyncall
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 31-07-2018 10:33:13 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 09-10-2018 16:45:45 UTC-5
 *  
 *  @Description:
 *  
 */

package dyncall

foreign import "dyncall.lib"

import "core:c"
import "core:fmt"
import "core:runtime"



Call_VM :: struct{};
Struct  :: struct{};



SIGCHAR_VOID      :: 'v';
SIGCHAR_BOOL      :: 'B';
SIGCHAR_CHAR      :: 'c';
SIGCHAR_UCHAR     :: 'C';
SIGCHAR_SHORT     :: 's';
SIGCHAR_USHORT    :: 'S';
SIGCHAR_INT       :: 'i';
SIGCHAR_UINT      :: 'I';
SIGCHAR_LONG      :: 'j';
SIGCHAR_ULONG     :: 'J';
SIGCHAR_LONGLONG  :: 'l';
SIGCHAR_ULONGLONG :: 'L';
SIGCHAR_FLOAT     :: 'f';
SIGCHAR_DOUBLE    :: 'd';
SIGCHAR_POINTER   :: 'p';
SIGCHAR_STRING    :: 'Z';
SIGCHAR_STRUCT    :: 'T';
SIGCHAR_ENDARG    :: ')'; /* also works for end struct */

/* callback signatures */

SIGCHAR_CC_PREFIX        :: '_';
SIGCHAR_CC_ELLIPSIS      :: 'e';
SIGCHAR_CC_STDCALL       :: 's';
SIGCHAR_CC_FASTCALL_GNU  :: 'f';
SIGCHAR_CC_FASTCALL_MS   :: 'F';
SIGCHAR_CC_THISCALL_MS   :: '+';



/* Supported Calling Convention Modes */

CALL_C_DEFAULT            ::   0;
CALL_C_ELLIPSIS           :: 100;
CALL_C_ELLIPSIS_VARARGS   :: 101;
CALL_C_X86_CDECL          ::   1;
CALL_C_X86_WIN32_STD      ::   2;
CALL_C_X86_WIN32_FAST_MS  ::   3;
CALL_C_X86_WIN32_FAST_GNU ::   4;
CALL_C_X86_WIN32_THIS_MS  ::   5;
CALL_C_X86_WIN32_THIS_GNU ::   6;
CALL_C_X64_WIN64          ::   7;
CALL_C_X64_SYSV           ::   8;
CALL_C_PPC32_DARWIN       ::   9;
CALL_C_PPC32_OSX          :: CALL_C_PPC32_DARWIN; /* alias */
CALL_C_ARM_ARM_EABI       ::  10;
CALL_C_ARM_THUMB_EABI     ::  11;
CALL_C_ARM_ARMHF          ::  30;
CALL_C_MIPS32_EABI        ::  12;
CALL_C_MIPS32_PSPSDK      :: CALL_C_MIPS32_EABI; /* alias - deprecated. */
CALL_C_PPC32_SYSV         ::  13;
CALL_C_PPC32_LINUX        :: CALL_C_PPC32_SYSV; /* alias */
CALL_C_ARM_ARM            ::  14;
CALL_C_ARM_THUMB          ::  15;
CALL_C_MIPS32_O32         ::  16;
CALL_C_MIPS64_N32         ::  17;
CALL_C_MIPS64_N64         ::  18;
CALL_C_X86_PLAN9          ::  19;
CALL_C_SPARC32            ::  20;
CALL_C_SPARC64            ::  21;
CALL_C_ARM64              ::  22;
CALL_C_PPC64              ::  23;
CALL_C_PPC64_LINUX        :: CALL_C_PPC64; /* alias */
CALL_SYS_DEFAULT          :: 200;
CALL_SYS_X86_INT80H_LINUX :: 201;
CALL_SYS_X86_INT80H_BSD   :: 202;
CALL_SYS_PPC32            :: 210;
CALL_SYS_PPC64            :: 211;

/* Error codes. */

ERROR_NONE             ::  0;
ERROR_UNSUPPORTED_MODE :: -1;



@(default_calling_convention="c")
foreign dyncall {
    @(link_name="dcNewCallVM")
    new_call_vm :: proc(size : c.size_t) -> ^Call_VM ---;

    free  :: proc(vm : ^Call_VM) ---;
    reset :: proc(vm : ^Call_VM) ---;

    mode :: proc(vm : ^Call_VM, mode : c.int) ---;

    arg_bool     :: proc(vm : ^Call_VM, value : c.int)      ---;
    arg_char     :: proc(vm : ^Call_VM, value : c.char)     ---;
    arg_short    :: proc(vm : ^Call_VM, value : c.short)    ---;
    arg_int      :: proc(vm : ^Call_VM, value : c.int)      ---;
    arg_long     :: proc(vm : ^Call_VM, value : c.long)     ---;
    arg_longlong :: proc(vm : ^Call_VM, value : c.longlong) ---;
    arg_float    :: proc(vm : ^Call_VM, value : c.float)    ---;
    arg_double   :: proc(vm : ^Call_VM, value : c.double)   ---;
    arg_pointer  :: proc(vm : ^Call_VM, value : rawptr)     ---;

    arg_struct :: proc(vm : ^Call_VM, s : ^Struct, value : rawptr) ---;

    call_void     :: proc(vm : ^Call_VM, funcptr : rawptr)               ---;
    call_bool     :: proc(vm : ^Call_VM, funcptr : rawptr) -> c.bool     ---;
    call_char     :: proc(vm : ^Call_VM, funcptr : rawptr) -> c.char     ---;
    call_short    :: proc(vm : ^Call_VM, funcptr : rawptr) -> c.short    ---;
    call_int      :: proc(vm : ^Call_VM, funcptr : rawptr) -> c.int      ---;
    call_long     :: proc(vm : ^Call_VM, funcptr : rawptr) -> c.long     ---;
    call_longlong :: proc(vm : ^Call_VM, funcptr : rawptr) -> c.longlong ---;
    call_float    :: proc(vm : ^Call_VM, funcptr : rawptr) -> c.float    ---;
    call_double   :: proc(vm : ^Call_VM, funcptr : rawptr) -> c.double   ---;
    call_pointer  :: proc(vm : ^Call_VM, funcptr : rawptr) -> rawptr     ---;
    
    call_struct :: proc(vm : ^Call_VM, funcptr : rawptr, s : ^Struct, return_value : rawptr) ---;

    get_error :: proc(vm : ^Call_VM) -> c.int ---;

    new_struct       :: proc(field_count : c.size_t, alignment : c.int) -> ^Struct ---;
    struct_field     :: proc(s : ^Struct, typ : c.int, alignment : c.int, array_length : c.size_t) ---;
    sub_struct       :: proc(s : ^Struct, field_count : c.size_t, alignment : c.int, array_length : c.size_t) ---;
    close_struct     :: proc(s : ^Struct) ---;
    struct_size      :: proc(s : ^Struct) -> c.size_t ---;
    struct_alignment :: proc(s : ^Struct) -> c.size_t ---;
    free_struct      :: proc(s : ^Struct) ---;

    define_struct :: proc(signature : cstring) -> ^Struct ---;
}



field :: proc(s : ^Struct, field : any) {
    ti := runtime.type_info_base_without_enum(type_info_of(field.typeid));

    switch v in ti.variant {
    case Type_Info_Struct:
        for typ, i in v.types {
            field(s, any{v.offsets[i], typ});
        }

    case Type_Info_Proc:
        panic("Procs not implemented yet");

    case Type_Info_Array:
        panic("Arrays not implemented yet");

    case Type_Info_Pointer:
        struct_field(s, SIGCHAR_POINTER, c.size_t(ti.align), 1);

    case Type_Info_Basic:
        typ : i32 = 0;

        switch ti {
        case type_info_of(int):  typ = SIGCHAR_LONGLONG;
        case type_info_of(i64):  typ = SIGCHAR_LONGLONG;
        case type_info_of(i32):  typ = SIGCHAR_INT;
        case type_info_of(i16):  typ = SIGCHAR_SHORT;
        case type_info_of(i8):   typ = SIGCHAR_CHAR;
        case type_info_of(uint): typ = SIGCHAR_ULONGLONG;
        case type_info_of(u64):  typ = SIGCHAR_ULONGLONG;
        case type_info_of(u32):  typ = SIGCHAR_UINT;
        case type_info_of(u16):  typ = SIGCHAR_USHORT;
        case type_info_of(u8):   typ = SIGCHAR_UCHAR;
        case type_info_of(f64):  typ = SIGCHAR_DOUBLE;
        case type_info_of(f32):  typ = SIGCHAR_FLOAT;
        case type_info_of(bool): typ = SIGCHAR_BOOL;
        case type_info_of(b64):  typ = SIGCHAR_LONGLONG;
        case type_info_of(b32):  typ = SIGCHAR_INT;
        case type_info_of(b16):  typ = SIGCHAR_SHORT;
        case type_info_of(b8):   typ = SIGCHAR_BOOL;
        }

        struct_field(s, typ, c.size_t(ti.align), 1);

    case: panic(); // @error(bpunsky)
    }
}

arg :: proc(vm : ^Call_VM, arg : any) {
    ti := runtime.type_info_base_without_enum(type_info_of(arg.typeid));

    switch v in ti.variant {
    case Type_Info_Struct:
    case Type_Info_Proc:
    case Type_Info_Pointer:
    case Type_Info_Basic:

    }
    switch ti {
    case type_info_of(int):
        a := arg.(int);
        arg_longlong(vm, c.longlong(a));

    case type_info_of(i8):
        a := arg.(i8);
        arg_char(vm, c.char(a));
    
    case type_info_of(i16):
        a := arg.(i16);
        arg_short(vm, c.short(a));
    
    case type_info_of(i32):
        a := arg.(i32);
        arg_int(vm, c.int(a));
    
    case type_info_of(i64):
        a := arg.(i64);
        arg_longlong(vm, c.longlong(a));
    
    case type_info_of(uint):
        a := arg.(uint);
        arg_longlong(vm, c.longlong(a));
    
    case type_info_of(u8):
        a := arg.(u8);
        arg_char(vm, c.char(a));

    case type_info_of(u16):
        a := arg.(u16);
        arg_short(vm, c.short(a));
    
    case type_info_of(u32):
        a := arg.(u32);
        arg_int(vm, c.int(a));
    
    case type_info_of(u64):
        a := arg.(u64);
        arg_longlong(vm, c.longlong(a));

    case type_info_of(f32):
        a := arg.(f32);
        arg_float(vm, c.float(a));
    
    case type_info_of(f64):
        a := arg.(f64);
        arg_double(vm, c.double(a));
    
    case type_info_of(bool):
        a := arg.(b8);
        arg_char(vm, c.char(a));
    
    case type_info_of(b8):
        a := arg.(b8);
        arg_char(vm, c.char(a));

    case type_info_of(b16):
        a := arg.(b16);
        arg_short(vm, c.short(a));

    case type_info_of(b32):
        a := arg.(b32);
        arg_int(vm, c.int(a));

    case type_info_of(b64):
        a := arg.(b64);
        arg_longlong(vm, c.longlong(a));

    case: panic(); // @error(bpunsky)
    }
}

call :: proc(vm : ^Call_VM, arg : any) {

}


call_c :: proc(vm : ^Call_VM, ret : any, args : ...any) {
    reset(vm);
    mode(vm, CALL_C_DEFAULT);

    for a in args {
        arg(vm, a);
    }

    call(vm, ret);
}

call_odin :: proc(vm : ^Call_VM, cb : rawptr, args : []any, rets : []any) {
    reset(vm);
    mode(vm, CALL_C_DEFAULT);

    for a in args {
        arg(vm, a);
    }

    context <- Context{} {
        arg_pointer(vm, context.parent);
    }

    call(vm, ret);
}

call_any :: proc(cb : any, args : []any, rets : []any) {
    ti := type_info_base_without_enum(type_info_of(cb.typeid));
    ti.(Type_Info_Proc);

    call_odin(vm, cb.data, )
}
