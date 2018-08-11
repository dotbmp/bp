/*
 *  @Name:     virtual_windows
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 30-05-2018 21:01:28 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 30-05-2018 21:02:13 UTC-5
 *  
 *  @Description:
 *  
 */

package virtual

foreign import "system:kernel32.lib"



@(default_calling_convention="std")
foreign kernel32 {
    VirtualAlloc        :: proc(address: rawptr, size: int, alloc_type, protect: i32) -> rawptr ---;
    VirtualFree         :: proc(address: rawptr, size: int, free_type: i32)           -> rawptr ---;
    GetLargePageMinimum :: proc() -> uint ---;

    GetSystemInfo       :: proc(system_info : ^System_Info) ---;
    GetNativeSystemInfo :: proc(system_info : ^System_Info) ---;

    GetLastError :: proc() -> u32 ---;
}

System_Info :: struct {
    using _ : struct #raw_union {
        oem_id : u32,
        using _ : struct #raw_union {
            processor_architecture : u16,
            _                      : u16,
        }
    }

    page_size : u32,
    minimum_application_address : rawptr,
    maximum_application_address : rawptr,
    active_processor_mask       : uint,
    number_of_processors        : u32,
    processor_type              : u32,
    allocation_granularity      : u32,
    processor_level             : u16,
    processor_revision          : u16,
}

MEM_COMMIT      :: 0x0000_1000;
MEM_RESERVE     :: 0x0000_2000;
MEM_DECOMMIT    :: 0x0000_4000;
MEM_RELEASE     :: 0x0000_8000;
MEM_RESET       :: 0x0008_0000;
MEM_RESET_UNDO  :: 0x0100_0000;
MEM_LARGE_PAGES :: 0x2000_0000;
MEM_PHYSICAL    :: 0x0040_0000;
MEM_TOP_DOWN    :: 0x0010_0000;
MEM_WRITE_WATCH :: 0x0020_0000;

PAGE_EXECUTE           :: 0x10;
PAGE_EXECUTE_READ      :: 0x20;
PAGE_EXECUTE_READWRITE :: 0x40;
PAGE_EXECUTE_WRITECOPY :: 0x80;
PAGE_NOACCESS          :: 0x01;
PAGE_READONLY          :: 0x02;
PAGE_READWRITE         :: 0x04;
PAGE_WRITECOPY         :: 0x08;

PAGE_TARGETS_INVALID   :: 0x4000_0000;
PAGE_TARGETS_NO_UPDATE :: 0x4000_0000;

PAGE_GUARD        :: 0x100;
PAGE_NOCACHE      :: 0x200;
PAGE_WRITECOMBINE :: 0x400;

PROCESSOR_ARCHITECTURE_AMD64   :: 9;
PROCESSOR_ARCHITECTURE_ARM     :: 5;
PROCESSOR_ARCHITECTURE_IA64    :: 6;
PROCESSOR_ARCHITECTURE_INTEL   :: 0;
PROCESSOR_ARCHITECTURE_UNKNOWN :: 0xffff;

_permissions :: proc(permissions : Permission) -> i32 {
    if (permissions & Guard) == Guard {
        return PAGE_GUARD;
    }
    else {
        if (permissions & Execute) == Execute {
            if (permissions & Read) == Read {
                if (permissions & Write) == Write {
                    return PAGE_EXECUTE_READWRITE;
                }
                else {
                    return PAGE_EXECUTE_READ;
                }
            }
            else if (permissions & Write) == Write {
                return PAGE_EXECUTE_WRITECOPY;
            }
            else {
                return PAGE_EXECUTE;
            }
        }
        else {
            if (permissions & Read) == Read {
                if (permissions & Write) == Write {
                    return PAGE_READWRITE;
                }
                else {
                    return PAGE_READONLY;
                }
            }
            else if (permissions & Write) == Write {
                return PAGE_WRITECOPY;
            }
        }
    }

    return 0;
}

alloc :: inline proc(size : int, address : rawptr = nil, permissions := Read | Write) -> rawptr {
    return VirtualAlloc(address, size, MEM_RESERVE | MEM_COMMIT, _permissions(permissions));
}

free :: inline proc(size : int, address : rawptr) -> rawptr {
    return VirtualFree(address, size, MEM_RELEASE | MEM_DECOMMIT);
}

reserve :: inline proc(size : int, address : rawptr = nil, permissions := Read | Write) -> rawptr {
    return VirtualAlloc(address, size, MEM_RESERVE, _permissions(permissions));
}

commit :: inline proc(size : int, address : rawptr = nil, permissions := Read | Write) -> rawptr {
    return VirtualAlloc(address, size, MEM_COMMIT, _permissions(permissions));
}

unreserve :: inline proc(size : int, address : rawptr) -> rawptr {
    return VirtualFree(address, size, MEM_RELEASE);
}

decommit :: inline proc(size : int, address : rawptr) -> rawptr {
    return VirtualFree(address, size, MEM_DECOMMIT);
}

get_page_size :: proc() -> uint {
    info : System_Info;
    GetSystemInfo(&info);

    return uint(info.page_size);
}
