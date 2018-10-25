/*
 *  @Name:     remove
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 28-11-2017 00:10:03 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 17-09-2018 20:49:08 UTC-5
 *  
 *  @Description:
 *  
 */

package remove

import "core:mem"



// remove_unordered requires indices to be in order or it can fuck up big time
remove_unordered :: proc(array: ^[dynamic]$T, indices: ..int) {
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

remove_ordered :: proc(array: ^[dynamic]$T, indices: ..int) {
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

remove_unordered_value :: proc(array: ^[dynamic]$T, values: ..T) {
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

    remove_unordered(array, ..indices[:]);
}

remove_ordered_value :: proc(array: ^[dynamic]$T, values: ..T) {
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

insert :: proc(array: ^[dynamic]$T, index: int, values: ..T) {
    inline assert(array != nil);

    a := (^mem.Raw_Dynamic_Array)(array);
    length := len(values);

    if a.len < index + length {
        reserve(array, index + length - a.len);
    }

    a.len += length;

    copy(array[index + length:], array[index:length]);
    copy(array[index:length], values);
}

prepend :: inline proc(array: ^[dynamic]$T, value: ..T) {
    insert(array, 0, ..value);
}

pop_front :: inline proc(array: ^[dynamic]$T) -> T {
    tmp := array[0];
    inline remove_ordered(array, 0);
    return tmp;
}

pop :: inline proc(array: ^[dynamic]$T) -> T {
    tmp := array[len(array)-1];
    (^mem.Raw_Dynamic_Array)(&array).len -= 1;
    return tmp;
}
