/*
 *  @Name:     queue
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 19-07-2018 17:51:16 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 18-10-2018 19:36:22 UTC-5
 *  
 *  @Description:
 *  
 */

package queue

import "core:mem"


Wrap_Mode :: enum int {
    Wrap,
    Assert,
    Silent,
};

Queue :: struct(T: typeid) {
    data: ^T,
    len:  int,
    cap:  int,
    head: int,
    tail: int,
}

make_queue :: inline proc($T: typeid, cap: int) -> Queue(T) {
    return Queue(T){data=(^T)(mem.alloc(cap * size_of(T))), cap=cap};
}

destroy_queue :: inline proc(queue: Queue($T)) {
    free(queue.data);
}

push :: inline proc(queue: ^Queue($T), value: T, mode := Wrap_Mode.Wrap) -> ^T {
    return push_head(queue, value, mode);
}

peek :: inline proc(queue: ^Queue($T)) -> ^T {
    return peek_tail(queue);
}

import "core:runtime"
pop :: proc[runtime.pop, pop_queue];

pop_queue :: inline proc(queue: ^Queue($T)) -> ^T {
    return pop_tail(queue);
}

push_head :: inline proc(queue: ^Queue($T), value: T, mode := Wrap_Mode.Wrap) -> ^T {
    if queue.len == queue.cap do switch mode {
    case Wrap_Mode.Wrap:
        queue.len -= 1; // @note: hacky
        queue.tail = (queue.tail + 1) % queue.cap;

    case Wrap_Mode.Assert:
        assert(false, "Cannot push into a full queue.");
        return nil;
    
    case Wrap_Mode.Silent:
        return nil;
    
    case:
        assert(false, "Invalid case.");
        return nil;
    }

    tmp := mem.ptr_offset(queue.data, queue.head);

    tmp^ = value;
    queue.head = (queue.head + 1) % queue.cap;

    queue.len += 1;

    return tmp;
}

push_tail :: inline proc(queue: ^Queue($T), value: T, mode := Wrap_Mode.Wrap) -> ^T {
    if queue.len == queue.cap do switch mode {
    case Wrap_Mode.Wrap: 
        queue.len -= 1; // @note: hacky
        queue.head = ((queue.cap + queue.head) - 1) % queue.cap;
    
    case Wrap_Mode.Assert:
        assert(false, "Cannot push into a full queue."); 
        return nil;
    
    case Wrap_Mode.Silent: 
        return nil;

    case: 
        assert(false, "Invalid case.");
        return nil;
    }

    tmp := queue.data + queue.tail;

    tmp^ = T;
    queue.tail = ((queue.cap + queue.tail) - 1) % queue.cap;

    queue.len += 1;

    return tmp;
}

peek_tail :: inline proc(queue: ^Queue($T)) -> ^T {
    if queue.len <= 0 do return nil;

    return mem.ptr_offset(queue.data, queue.tail);
}

// pop returns a pointer, which should be deref'd IMMEDIATELY
// unless the user knows FOR SURE that the queue's state can't
// change while the pointer is held.
pop_tail :: inline proc(queue: ^Queue($T)) -> ^T {
    if queue.len <= 0 do return nil;

    tmp := peek(queue);

    queue.tail = (queue.tail + 1) % queue.cap;
    queue.len -= 1;

    return tmp;
}

peek_head :: inline proc(queue: ^Queue($T)) -> ^T {
    if queue.len <= 0 do return nil;

    return mem.ptr_offset(queue.data, queue.head);
}

pop_head :: inline proc(queue: ^Queue($T)) -> ^T {
    if queue.len <= 0 do return nil;

    tmp := peek_head(queue);

    queue.head = ((queue.cap + queue.head) - 1) % queue.cap;
    queue.len -= 1;

    return tmp;
}

get :: inline proc(queue: ^Queue($T), index: int) -> ^T {
    return mem.ptr_offset(queue.data, (queue.cap + queue.tail + index) % queue.cap);
}

/*
peek :: inline proc(queue: ^Queue($T)) -> ^T {
    return queue.data + queue.tail;
}

peek_head :: inline proc(queue: ^Queue($T)) -> ^T {
    return queue.data + queue.head;
}
*/


import "core:fmt";

test_pushpop :: proc() {
    queue := make_queue(int, 8);

    for i in 0..8 do
        push(&queue, i);

    for queue.len > 0 do
        if ptr := pop(&queue); ptr != nil do
            fmt.println(ptr^);

    for i in 0..3 do
        push(&queue, i);

    for queue.len > 0 do
        if ptr := pop(&queue); ptr != nil do
            fmt.println(ptr^);
}

test_wrap :: proc() {
    queue := make_queue(int, 8);

    fmt.println("testing Wrap_Mode.Wrap...");

    for i in 0..8 do
        push(&queue, i, Wrap_Mode.Wrap);

    for queue.len != 0 do
        if ptr := pop(&queue); ptr != nil do
            fmt.println(ptr^);
}

test_silent :: proc() {
    queue := make_queue(int, 8);

    fmt.println("testing Wrap_Mode.Silent...");

    for i in 0..8 do
        push(&queue, i, Wrap_Mode.Silent);

    for queue.len != 0 do
        if ptr := pop(&queue); ptr != nil do
            fmt.println(ptr^);
}

test_assert :: proc() {
    queue := make_queue(int, 8);

    fmt.println("testing Wrap_Mode.Assert...");

    for i in 0..8 do
        push(&queue, i, Wrap_Mode.Assert);

    for queue.len != 0 do
        if ptr := pop(&queue); ptr != nil do
            fmt.println(ptr^);
}

test :: proc() {
    test_pushpop();
    test_wrap();
    test_silent();
    test_assert();
}

main :: proc() do test();
