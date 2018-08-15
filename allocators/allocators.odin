/*
 *  @Name:     allocators
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 28-11-2017 00:10:03 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 12-08-2018 23:11:25 UTC-5
 *  
 *  @Description:
 *  
 */

package allocators

import "core:mem"

import "bp:virtual"



round_up_to_multiple :: proc(size, mult : int) -> int {
    div := (size-1) / mult;
    return (div+1) * mult;
}

Virtual_Arena :: struct {
    backing   : mem.Allocator,

    memory    : rawptr,

    index     : int,
    committed : int,
    reserved  : int,

    page_size : int,
}

make_virtual_arena :: inline proc(bytes : int, address : rawptr = nil) -> mem.Allocator {
    page_size := (int)(virtual.get_page_size());

    bytes = round_up_to_multiple(bytes, page_size);

    address = virtual.reserve(bytes,     address, virtual.Read | virtual.Write);

    fmt.println(address);

    address = virtual.commit (page_size, address, virtual.Read | virtual.Write);

    fmt.println(address);

    return mem.Allocator {
        procedure = virtual_allocator_proc,
        data      = new_clone(Virtual_Arena {
            backing   = context.allocator,
            memory    = address,
            index     = 0,
            committed = page_size,
            reserved  = bytes,
            page_size = page_size,
        }),
    };
}

virtual_allocator_proc :: proc(allocator_data : rawptr, mode : mem.Allocator_Mode,
                               size, alignment : int,
                               old_memory : rawptr, old_size : int, flags : u64, location := #caller_location)
-> rawptr {
    using mem.Allocator_Mode;
    allocator := cast(^Virtual_Arena) allocator_data;

    switch mode {
    case Alloc:
        if allocator.index + size > allocator.committed {
            if allocator.index + size > allocator.reserved {
                panic("Virtual arena allocator is out of reserved memory.");
            } else {
                extra := round_up_to_multiple(size, allocator.page_size);

                virtual.commit(extra, mem.ptr_offset((^u8)(allocator.memory), allocator.committed), virtual.Read | virtual.Write);
                
                allocator.committed += extra;
            }
        }
        
        pointer := mem.ptr_offset((^byte)(allocator.memory), allocator.index);

        allocator.index += size;

        return pointer;

    case Free:

    case Free_All:
        virtual.free(allocator.reserved, allocator.memory);

        {
            context = mem.context_from_allocator(allocator.backing);
            free(allocator_data);
        }

    case Resize:
        return virtual_allocator_proc(allocator_data, Alloc, size, alignment, old_memory, old_size, flags);
    }

    return nil;
}



import "core:fmt"

main :: proc() {
    Test :: struct {
        buf : [120000]byte,
        num : int,
    }

    test : ^Test;

    arena := make_virtual_arena(150000);

    fmt.println(((^Virtual_Arena)(arena.data))^);

    {
        context = mem.context_from_allocator(arena);
        //defer free_all();

        test = new(Test);
    }

    fmt.println(test.num);
    test.num = 10101;
    fmt.println(test.num);

    j := cast(^int) virtual.alloc(200);

    fmt.println(virtual.GetLastError(), j);

    j^ = 321;

    fmt.println(j^);

    i := cast(^int) virtual.alloc(size_of(int));

    i^ = 123;

    fmt.println(i^);
}
