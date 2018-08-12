foreign import zeromq "libzmq-v120-mt-4_0_4.lib"

import "core:raw.odin"
import "core:strings.odin"

// Defines

HAUS_NUMERO :: 156384712;

// Error codes
ENOTSUP         :: HAUS_NUMERO + 1;
EPROTONOSUPPORT :: HAUS_NUMERO + 2;
ENOBUFFS        :: HAUS_NUMERO + 3;
ENETDOWN        :: HAUS_NUMERO + 4;
EADDRIN_USE     :: HAUS_NUMERO + 5;
EADDRNOT_AVAIL  :: HAUS_NUMERO + 6;
ECONNREFUSED    :: HAUS_NUMERO + 7;
EINPROGRESS     :: HAUS_NUMERO + 8;
ENOTSOCK        :: HAUS_NUMERO + 9;
EMSGSIZE        :: HAUS_NUMERO + 10;
EAFNOSUPPORT    :: HAUS_NUMERO + 11;
ENETUNREACH     :: HAUS_NUMERO + 12;
ECONNABORTED    :: HAUS_NUMERO + 13;
ECONNRESET      :: HAUS_NUMERO + 14;
ENOTCONN        :: HAUS_NUMERO + 15;
ETIMEDOUT       :: HAUS_NUMERO + 16;
EHOSTUNREACH    :: HAUS_NUMERO + 17;
ENETRESET       :: HAUS_NUMERO + 18;
EFSM            :: HAUS_NUMERO + 51;
ENOCOMPATPROTO  :: HAUS_NUMERO + 52;
ETERM           :: HAUS_NUMERO + 53;
EMTHREAD        :: HAUS_NUMERO + 54;

IO_THREADS  :: 1;
MAX_SOCKETS :: 2;

IO_THREADS_DFLT  :: 1;
MAX_SOCKETS_DFLT :: 1023;

// Socket types
PAIR   :: 0;
PUB    :: 1;
SUB    :: 2;
REQ    :: 3;
REP    :: 4;
DEALER :: 5;
ROUTER :: 6;
PULL   :: 7;
PUSH   :: 8;
XPUB   :: 9;
XSUB   :: 10;
STREAM :: 11;

// Socket options
AFFINITY            :: 4;
IDENTITY            :: 5;
SUBSCRIBE           :: 6;
UNSUBSCRIBE         :: 7;
RATE                :: 8;
RECOVERY_IVL        :: 9;
SNDBUF              :: 11;
RCVBUF              :: 12;
RCVMORE             :: 13;
FD                  :: 14;
EVENTS              :: 15;
TYPE                :: 16;
LINGER              :: 17;
RECONNECT_IVL       :: 18;
BACKLOG             :: 19;
RECONNECT_IVL_MAX   :: 21;
MAXMSGSIZE          :: 22;
SNDHWM              :: 23;
RCVHWM              :: 24;
MULTICAST_HOPS      :: 25;
RCVTIMEO            :: 27;
SNDTIMEO            :: 28;
LAST_ENDPOINT       :: 32;
ROUTER_MANDATORY    :: 33;
TCP_KEEPALIVE       :: 34;
TCP_KEEPALIVE_CNT   :: 35;
TCP_KEEPALIVE_IDLE  :: 36;
TCP_KEEPALIVE_INTVL :: 37;
TCP_ACCEPT_FILTER   :: 38;
IMMEDIATE           :: 39;
XPUB_VERBOSE        :: 40;
ROUTER_RAW          :: 41;
IPV6                :: 42;
MECHANISM           :: 43;
PLAIN_SERVER        :: 44;
PLAIN_USERNAME      :: 45;
PLAIN_PASSWORD      :: 46;
CURVE_SERVER        :: 47;
CURVE_PUBLICKEY     :: 48;
CURVE_SECRETKEY     :: 49;
CURVE_SERVERKEY     :: 50;
PROBE_ROUTER        :: 51;
REQ_CORRELATE       :: 52;
REQ_RELAXED         :: 53;
CONFLATE            :: 54;
ZAP_DOMAIN          :: 55;

// Message options
ZMQ_MORE :: 1;

// Send/recieve options
ZMQ_DONTWAIT :: 1;
ZMQ_SNDMORE  :: 2;

// Security mechanisms
ZMQ_NULL  :: 0;
ZMQ_PLAIN :: 1;
ZMQ_CURVE :: 2;

// Socket transport events (tcp and ipc only)
EVENT_CONNECTED       :: 1;
EVENT_CONNECT_DELAYED :: 2;
EVENT_CONNECT_RETRIED :: 4;
EVENT_LISTENING       :: 8;
EVENT_BIND_FAILED     :: 16;
EVENT_ACCEPTED        :: 32;
EVENT_ACCEPT_FAILED   :: 64;
EVENT_CLOSED          :: 128;
EVENT_CLOSE_FAILED    :: 256;
EVENT_DISCONNECTED    :: 512;
EVENT_MONITOR_STOPPED :: 1024;
EVENT_ALL             :: EVENT_CONNECTED       | EVENT_CONNECT_DELAYED |
                         EVENT_CONNECT_RETRIED | EVENT_LISTENING       |
                         EVENT_BIND_FAILED     | EVENT_ACCEPTED        |
                         EVENT_ACCEPT_FAILED   | EVENT_CLOSED          |
                         EVENT_CLOSE_FAILED    | EVENT_DISCONNECTED    |
                         EVENT_MONITOR_STOPPED;

POLLIN  :: 1;
POLLOUT :: 2;
POLLERR :: 4;

POLLITEMS_DFLT :: 16;


// Type defs

Msg :: [32]u8;

Event :: struct #packed {
    event: u16,
    value: i32,
}

Poll_Item :: struct #packed {
    socket:  rawptr,
    fd:      i32,
    events:  i16,
    revents: i16,
}

Free_Proc :: #type proc"c"(data, hint: rawptr);

@(link_prefix="zmq_")
foreign zeromq {
    version :: proc(major, minor, patch: ^i32) ---;
        
    @(link_name="zmq_strerror") cstrerror :: proc(errnum: i32) -> ^u8 ---;
    errno :: proc() -> i32 ---; 
    
    ctx_destroy  :: proc(ctx: rawptr)                       -> i32    ---;
    ctx_get      :: proc(ctx: rawptr, option: i32)          -> i32    ---;
    ctx_new      :: proc()                                  -> rawptr ---;
    ctx_set      :: proc(ctx: rawptr, option, opt_val: i32) -> i32    ---;
    ctx_shutdown :: proc(ctx: rawptr)                       -> i32    ---;
    ctx_term     :: proc(ctx: rawptr)                       -> i32    ---;
             
    msg_init      :: proc(msg: ^Msg)                                                        -> i32    ---;
    msg_init_size :: proc(msg: ^Msg, size: int)                                             -> i32    ---;
    msg_init_data :: proc(msg: ^Msg, data: rawptr, size: int, ffn: Free_Proc, hint: rawptr) -> i32    ---;
    msg_send      :: proc(msg: ^Msg, s: rawptr, flags: i32 = 0)                             -> i32    ---;
    msg_recv      :: proc(msg: ^Msg, s: rawptr, flags: i32 = 0)                             -> i32    ---;
    msg_close     :: proc(msg: ^Msg)                                                        -> i32    ---;
    msg_move      :: proc(dest, src: ^Msg)                                                  -> i32    ---;
    msg_copy      :: proc(dest, src: ^Msg)                                                  -> i32    ---;
    msg_data      :: proc(msg: ^Msg)                                                        -> rawptr ---;
    msg_size      :: proc(msg: ^Msg)                                                        -> i32    ---;
    msg_more      :: proc(msg: ^Msg)                                                        -> i32    ---;
    msg_get       :: proc(msg: ^Msg, option: i32)                                           -> i32    ---;
    msg_set       :: proc(msg: ^Msg, option, opt_val: i32)                                  -> i32    ---;
             
    socket          :: proc(ctx: rawptr, kind: int)                                     -> rawptr ---;
    close           :: proc(s: rawptr)                                                  -> i32    ---;
    setsockopt      :: proc(s: rawptr, option: i32, opt_val: rawptr, opt_val_len: int)  -> i32    ---;
    getsockopt      :: proc(s: rawptr, option: i32, opt_val: rawptr, opt_val_len: ^int) -> i32    ---;
        
    @(link_name="zmq_bind")           bind_           :: proc(s: rawptr, addr: ^u8)                             -> i32 ---;
    @(link_name="zmq_connect")        connect_        :: proc(s: rawptr, addr: ^u8)                             -> i32 ---;
    @(link_name="zmq_unbind")         unbind_         :: proc(s: rawptr, addr: ^u8)                             -> i32 ---;
    @(link_name="zmq_disconnect")     disconnect_     :: proc(s: rawptr, addr: ^u8)                             -> i32 ---; 
    @(link_name="zmq_send")           send_           :: proc(s: rawptr, buf: rawptr, len: int, flags: i32 = 0) -> i32 ---;
    @(link_name="zmq_send_const")     send_const_     :: proc(s: rawptr, buf: rawptr, len: int, flags: i32 = 0) -> i32 ---;
    @(link_name="zmq_recv")           recv_           :: proc(s: rawptr, buf: rawptr, len: int, flags: i32 = 0) -> i32 ---;
    @(link_name="zmq_socket_monitor") socket_monitor_ :: proc(s: rawptr, addr: ^u8, events: i32)                -> i32 ---;
            
    sendmsg :: proc(s: rawptr, msg: ^Msg, flags: i32 = 0) -> i32 ---;
    recvmsg :: proc(s: rawptr, msg: ^Msg, flags: i32 = 0) -> i32 ---;
    
    poll  :: proc(items: ^Poll_Item, nitems: i32, timeout: i64) -> i32 ---;
    proxy :: proc(frontend, backend, capture: rawptr)           -> i32 ---;
        
    @(link_name="zmq_z85_encode") z85_encode_ :: proc(dest, data: ^u8, size: int) -> ^u8 ---;
    @(link_name="zmq_z85_decode") z85_decode_ :: proc(dest, str: ^u8)             -> ^u8 ---;
}  

strerror :: inline proc(errnum: i32) -> string {
    tmp := cstrerror(errnum);

    return strings.to_odin_string(tmp);
}
 
bind :: inline proc(s: rawptr, addr: string) -> i32 {
    cstr := strings.new_c_string(addr);
    defer free(cstr);

    return bind_(s, cstr);
}

connect :: inline proc(s: rawptr, addr: string) -> i32 {
    cstr := strings.new_c_string(addr);
    defer free(cstr);

    return connect_(s, cstr);
}

unbind :: inline proc(s: rawptr, addr: string) -> i32 {
    cstr := strings.new_c_string(addr);
    defer free(cstr);

    return unbind_(s, cstr);
}

disconnect :: inline proc(s: rawptr, addr: string) -> i32 {
    cstr := strings.new_c_string(addr);
    defer free(cstr);

    return disconnect_(s, cstr);
}

send :: proc[send_bytes, send_string];

send_bytes :: inline proc(s: rawptr, buf: []u8, flags: i32 = 0) -> i32 {
    return send_(s, &buf[0], len(buf), flags);
}

send_string :: inline proc(s: rawptr, buf: string, flags: i32 = 0) -> i32 {
    return send_(s, &buf[0], len(buf), flags);
}

send_const :: proc[send_const_bytes, send_const_string];

send_const_bytes :: inline proc(s: rawptr, buf: []u8, flags: i32 = 0) -> i32 {
    return send_const_(s, &buf[0], len(buf), flags);
}

send_const_string :: inline proc(s: rawptr, buf: string, flags: i32 = 0) -> i32 {
    return send_const_(s, &buf[0], len(buf), flags);
}

recv :: proc[recv_bytes, recv_string];

// @todo: have recv edit the buf len
recv_bytes :: inline proc(s: rawptr, buf: []u8, flags: i32 = 0) -> i32 {
    return recv_(s, &buf[0], len(buf), flags);
}

recv_string :: inline proc(s: rawptr, buf: string, flags: i32 = 0) -> i32 {
    return recv_(s, &buf[0], len(buf), flags);
}

socket_monitor :: inline proc(s: rawptr, addr: string, events: i32) -> i32 {
    cstr := strings.new_c_string(addr);
    defer free(cstr);

    return socket_monitor_(s, cstr, events);
}

z85_encode :: inline proc(data: []u8) -> string {
    length := cast(int) (cast(f32) len(data) * 1.25);
    buf := cast(^u8) alloc(length + 1);

    (buf + length)^ = 0;

    tmp := z85_encode_(buf, &data[0], len(data));

    return tmp == nil ? "" : transmute(string) raw.String{buf, length};
}

z85_decode :: inline proc(str: string) -> ([]u8, bool) {
    length := cast(int) (cast(f32) len(str) * 0.8);
    buf := make([]u8, length);

    cstr := strings.new_c_string(str);
    defer free(cstr);

    tmp := z85_decode_(&buf[0], cstr);

    if tmp == nil do
        return nil, false;
    else do
        return buf, true;
}


import "core:fmt.odin";
import "core:thread.odin";

client :: proc(thr: ^thread.Thread) -> int {
    fmt.println("Connecting to hello world server...");
    
    ctx := ctx_new();
    defer ctx_destroy(ctx);
    
    s := socket(ctx, REQ);
    defer close(s);

    connect(s, "tcp://localhost:5555");

    for i := 0; i < 10; i += 1 {
        buf := [10]u8{};
        
        fmt.printf("Sending 'hello' (#%d)...\n", i);
        send(s, "Hello");
        
        length := recv(s, buf[..]);
        fmt.printf("Received 'world': ");

        str := cast(string) buf[..length];
        fmt.println(str);
    }

    return 0;
}

server :: proc(thr: ^thread.Thread) -> int {
    ctx := ctx_new();
    defer ctx_destroy(ctx);

    s := socket(ctx, REP);
    defer close(s);

    rc := bind(s, "tcp://*:5555");
    assert(rc == 0);

    for {
        buf := [10]u8{};

        length := recv(s, buf[..]);
        fmt.print("Received 'hello': ");

        str := cast(string) buf[..length];
        fmt.println(str);

        send(s, "World");
    }

    return 0;
}

import "tempo.odin";

test :: proc() {
    server_thread := thread.create(server);
    client_thread := thread.create(client);

    thread.start(server_thread);
    thread.start(client_thread);

    tempo.sleep(tempo.seconds(20));

    fmt.println("Exiting.");
}

main :: proc() {
    test();
}