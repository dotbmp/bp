/*
 *  @Name:     remove
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 28-11-2017 00:10:03 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 11-08-2018 10:38:57 UTC-5
 *  
 *  @Description:
 *  
 */

package remove

import "core:mem"



// remove_unordered requires indices to be in order or it can fuck up big time
unordered :: proc(array: ^[dynamic]$T, indices: ..int) {
    assert(array != nil && len(array^) != 0);

    a := cast(^mem.Raw_Dynamic_Array) array;

    for i := len(indices) - 1; i >= 0; i -= 1 {
        index := indices[i];

        if index < 0 || a.len <= 0 || a.len <= index do return;

        if index < a.len - 1 {
            array[index] = array[a.len-1];
        }

        a.len -= 1;
    }
}

ordered :: proc(array: ^[dynamic]$T, indices: ..int) {
    assert(array != nil && len(array^) != 0);

    a := cast(^mem.Raw_Dynamic_Array) array;

    for idx, i in indices {
        index := idx - i;

        if index < 0 || a.len <= 0 || a.len <= index do return;

        if index < a.len - 1 do
            mem.copy(&array[index], &array[index+1], size_of(T) * (a.len - index));
        
        a.len -= 1;
    }
}

unordered_value :: proc(array: ^[dynamic]$T, values: ..T) {
    assert(array != nil && len(array^) != 0);

    indices := make([dynamic]int, 0, len(values));
    defer free(indices);

    for i in 0..len(array)-1 {
        for value in values {
            when T == any {
                if array[i].data == value.data do append(&indices, i);
            } else {
                if array[i] == value do append(&indices, i);
            }
        }
    }

    unordered(array, ..indices[:]);
}

ordered_value :: proc(array: ^[dynamic]$T, values: ..T) {
    assert(array != nil && len(array^) != 0);

    indices := make([dynamic]int, 0, len(values));
    defer free(indices);

    for i in 0..len(array)-1 {
        for value in values {
            when T == any {
                if array[i].data == value.data do append(&indices, i);
            } else {
                if array[i] == value do append(&indices, i);
            }
        }
    }

    ordered(array, ..indices[:]);
}

pop_front :: inline proc(array: ^[dynamic]$T) -> T {
    tmp := array[0];
    ordered(array, 0);
    return tmp;
}

pop :: inline proc(array: ^[dynamic]$T) -> T {
    tmp := array[len(array)-1];
    (^mem.Raw_Dynamic_Array)(&array).len -= 1;
    return tmp;
}
