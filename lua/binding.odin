foreign import lua_c "lua53.lib"

// @todo: add luajit support

// @ref: https://www.lua.org/manual/5.3/manual.html#4
// @ref: 


FALSE :: 0;
TRUE  :: 1;


// @region luaconf.h

// @todo: finish porting luaconf.h


MAXINTEGER   :: i64( 0x7fff_ffff_ffff_ffff);
MININTEGER   :: i64(-0x8000_0000_0000_0000);

I_MAXSTACK :: 1000000;

EXTRASPACE :: 1500;

IDSIZE :: 60;

L_BUFFERSIZE :: 0x80 * size_of(rawptr) * size_of(Integer);

numbertointeger :: inline proc(n: Number, p: ^Integer) -> i32 {
    if (n >= cast(Number) MININTEGER) && (n < -(cast(Number) MININTEGER)) {
        p^ = cast(Integer) n;
        return 1;
    }

    return 0;
}


// @endregion


// @region lua.h


VERSION_MAJOR   :: "5";
VERSION_MINOR   :: "3";
VERSION_NUM     :: 503;
VERSION_RELEASE :: "4";

VERSION   :: "Lua " + VERSION_MAJOR + "." + VERSION_MINOR;
RELEASE   :: VERSION + "." + VERSION_RELEASE;
COPYRIGHT :: RELEASE + "  Copyright (C) 1994-2017 Lua.org, PUC-Rio";
AUTHORS   :: "R. Ierusalimschy, L. H. de Figueiredo, W. Celes";

// @note: mark for precompiled code
SIGNATURE :: "\x1bLua"; // <esc>Lua


// @note: option for multiple returns in 'lua_pcall' and 'lua_call'
MULTRET :: -1;


REGISTRYINDEX :: -I_MAXSTACK - 1000;
upvalueindex :: inline proc(i: i32) -> i32 do return REGISTRYINDEX - i;


// @note: thread status
OK         ::  0;
YIELD      ::  1;
ERRRUN     ::  2;
ERRSYNTAX  ::  3;
ERRMEM     ::  4;
ERRGCMM    ::  5;
ERRERR     ::  6;


// @note: opaque type for the state of the entire lua instance
State :: rawptr;


// @note: basic types
TNONE           :: -1;

TNIL            ::  0;
TBOOLEAN        ::  1;
TLIGHTUSERDATA  ::  2;
TNUMBER         ::  3;
TSTRING         ::  4;
TTABLE          ::  5;
TFUNCTION       ::  6;
TUSERDATA       ::  7;
TTHREAD         ::  8;

NUMTAGS         ::  9;


// @note: minimum lua stack available to a c function
MINSTACK :: 20;


// @note: predefined values in the registry
RIDX_MAINTHREAD :: 1;
RIDX_GLOBALS    :: 2;
RIDX_LAST       :: RIDX_GLOBALS;


// @note: lua number types
Number    :: f64; // @todo: arch size
Integer   :: int;
Unsigned  :: uint;


// @note: type for continuation function contexts
KContext  :: uint;


// @note: type for c functions registered with lua
CFunction :: #type proc "c" (L: State) -> i32;

// @note: type for continuation functions
KFunction :: #type proc "c" (L: State, status: int, ctx: KContext) -> i32;

// @note: type for functions that read/write blocks when loading/dumping lua chunks
Reader :: #type proc "c" (L: State, data: rawptr, size: ^int) -> ^u8;
Writer :: #type proc "c" (L: State, p: rawptr, sz: int, ud: rawptr) -> i32;

// @note: type for memory allocation functions
Alloc :: #type proc "c" (ud, ptr: rawptr, osize, nsize: int) -> rawptr;


// lua_ident


// @note: state manipulation
@(link_prefix="lua_")
foreign lua_c {
    newstate  :: proc(f: Alloc, ud: rawptr)        -> State     ---;
    close     :: proc(L: State)                                 ---;
    newthread :: proc(L: State)                    -> State     ---;

    atpanic   :: proc(L: State, panicf: CFunction) -> CFunction ---;

    version   :: proc(L: State)                    -> ^Number   ---;
}


// @note: basic stack manipulation
@(link_prefix="lua_")
foreign lua_c {
    absindex   :: proc(L: State, idx: i32)            -> i32 ---;
    gettop     :: proc(L: State)                      -> i32 ---;
    settop     :: proc(L: State, index: i32)                 ---;
    pushvalue  :: proc(L: State, index: i32)                 ---;
    rotate     :: proc(L: State, idx: i32, n: i32)           ---;
    copy       :: proc(L: State, fromidx, toidx: i32)        ---;
    checkstack :: proc(L: State, n: i32)              -> i32 ---; 
    xmove      :: proc(from, to: State, n: i32)              ---;
}

    
// @note: access functions (stack -> c)
@(link_prefix="lua_")
foreign lua_c {
    isnumber                      :: proc(L: State, index: i32) -> i32 ---;
    isstring                      :: proc(L: State, index: i32) -> i32 ---;
    iscfunction                   :: proc(L: State, index: i32) -> i32 ---;
    isinteger                     :: proc(L: State, index: i32) -> i32 ---;
    isuserdata                    :: proc(L: State, index: i32) -> i32 ---;
    @(link_name="lua_type") type_ :: proc(L: State, index: i32) -> i32 ---;
    typename                      :: proc(L: State, tp: i32)    -> ^u8 ---; 

    tonumberx   :: proc(L: State, index: i32, isnum: ^i32) -> Number    ---;
    tointegerx  :: proc(L: State, index: i32, isnum: ^i32) -> Integer   ---;
    toboolean   :: proc(L: State, index: i32)              -> i32       ---;
    tolstring   :: proc(L: State, index: i32, len: ^int)   -> ^u8       ---;
    rawlen      :: proc(L: State, index: i32)              -> int       ---;
    tocfunction :: proc(L: State, index: i32)              -> CFunction ---;
    touserdata  :: proc(L: State, index: i32)              -> rawptr    ---;
    tothread    :: proc(L: State, index: i32)              -> State     ---;
    topointer   :: proc(L: State, index: i32)              -> rawptr    ---;
}


// @note: arithmetic and comparison operators
OPADD  ::  0;
OPSUB  ::  1;
OPMUL  ::  2;
OPMOD  ::  3;
OPPOW  ::  4;
OPDIV  ::  5;
OPIDIV ::  6;
OPBAND ::  7;
OPBOR  ::  8;
OPBXOR ::  9;
OPSHL  :: 10;
OPSHR  :: 11;
OPUNM  :: 12;
OPBNOT :: 13;

foreign lua_c @(link_name="lua_arith") arith :: proc(L: State, op: i32) ---;

OPEQ :: 0;
OPLE :: 1;
OPLT :: 2;

@(link_prefix="lua_")
foreign lua_c {
    rawequal :: proc(L: State, index1, index2: i32)          -> i32 ---;
    compare  :: proc(L: State, index1, index2: i32, op: i32) -> i32 ---;
}


// @note: push functions
@(link_prefix="lua_")
foreign lua_c {
    pushnil           :: proc(L: State)                                          ---;
    pushnumber        :: proc(L: State, n: Number)                               ---;
    pushinteger       :: proc(L: State, n: Integer)                              ---;
    pushlstring       :: proc(L: State, s: ^u8, len: int)                 -> ^u8 ---;
    pushstring        :: proc(L: State, s: ^u8)                           -> ^u8 ---;
    pushvfstring      :: proc(L: State, fmt: ^u8, #c_vararg args: ...any) -> ^u8 ---;
    pushfstring       :: proc(L: State, fmt: ^u8, #c_vararg args: ...any) -> ^u8 ---;
    pushcclosure      :: proc(L: State, fn: CFunction, n: i32)                   ---;
    pushboolean       :: proc(L: State, b: i32)                                  ---;
    pushlightuserdata :: proc(L: State, p: rawptr)                               ---;
    pushthread        :: proc(L: State)                                   -> i32 ---;
}


// @note: get functions (lua -> stack)
@(link_prefix="lua_")
foreign lua_c {
    getfield     :: proc(L: State, index: i32, k: ^u8)     -> i32    ---;
    gettable     :: proc(L: State, index: i32)             -> i32    ---;
    getglobal    :: proc(L: State, name: ^u8)              -> i32    ---;
    geti         :: proc(L: State, index: i32, i: Integer) -> i32    ---;
    rawget       :: proc(L: State, index: i32)             -> i32    ---;
    rawgeti      :: proc(L: State, index: i32, n: Integer) -> i32    ---;
    rawgetp      :: proc(L: State, index: i32, p: rawptr)  -> i32    ---;

    createtable  :: proc(L: State, narr, nrec: i32)                  ---;
    newuserdata  :: proc(L: State, size: int)              -> rawptr ---;
    getmetatable :: proc(L: State, index: i32)             -> i32    ---;
    getuservalue :: proc(L: State, index: i32)             -> i32    ---;
}


// @note: set functions (stack -> lua)
@(link_prefix="lua_")
foreign lua_c {
    setglobal    :: proc(L: State, name: ^u8)              ---;
    settable     :: proc(L: State, index: i32)             ---;
    setfield     :: proc(L: State, index: i32, k: ^u8)     ---;
    seti         :: proc(L: State, index: i32, n: Integer) ---;
    rawset       :: proc(L: State, index: i32)             ---;
    rawseti      :: proc(L: State, index: i32, i: Integer) ---;                                
    rawsetp      :: proc(L: State, index: i32, p: rawptr)  ---;
    setmetatable :: proc(L: State, index: i32)             ---;
    setuservalue :: proc(L: State, index: i32)             ---;
}


// @note: load and run lua code
foreign lua_c @(link_name="lua_callk") callk :: proc(L: State, nargs, nresults: i32, ctx: KContext, k: KFunction) ---;
call :: inline proc(L: State, nargs, nresults: i32) do callk(L, nargs, nresults, 0, nil);

foreign lua_c @(link_name="lua_pcallk") pcallk :: proc(L: State, nargs, nresults: i32, msgh: i32, ctx: KContext, k: KFunction) -> i32 ---;
pcall :: inline proc(L: State, nargs, nresults: i32, msgh: i32) -> i32 do return pcallk(L, nargs, nresults, msgh, 0, nil);

@(link_prefix="lua_")
foreign lua_c {
    load :: proc(L: State, reader: Reader, data: rawptr, chunk_name, mode: ^u8) -> i32 ---;
    dump :: proc(L: State, writer: Writer, data: rawptr, strip: i32)            -> i32 ---;
}


// @note: coroutine functions
@(link_prefix="lua_")
foreign lua_c {
    yieldk                          :: proc(L: State, nresults: i32, ctx: KContext, k: KFunction) -> i32 ---;
    resume                          :: proc(L: State, from: State, nargs: i32)                    -> i32 ---;
    status                          :: proc(L: State)                                             -> i32 ---;
    isyieldable                     :: proc(L: State, index: i32)                                 -> i32 ---;
    @(link_name="lua_yield") yield_ :: proc(L: State, nresults: i32)                              -> i32 ---;
}


// @note: garbage collection options
GCSTOP       :: 0;
GCRESTART    :: 1;
GCCOLLECT    :: 2;
GCCOUNT      :: 3;
GCCOUNTB     :: 4;
GCSTEP       :: 5;
GCSETPAUSE   :: 6;
GCSETSTEPMUL :: 7;
GCISRUNNING  :: 9;

foreign lua_c @(link_name="lua_gc") gc :: proc(L: State, what, data: i32) -> i32 ---;


// @note: miscellaneous functions
@(link_prefix="lua_")
foreign lua_c {
    error                       :: proc(L: State)                       -> i32   ---;
    next                        :: proc(L: State, index: i32)           -> i32   ---;
    concat                      :: proc(L: State, n: int)                        ---;
    @(link_name="lua_len") len_ :: proc(L: State, index: i32)                    ---;
    stringtonumber              :: proc(L: State, s: ^u8)               -> int   ---;
    getallocf                   :: proc(L: State, ud: ^rawptr)          -> Alloc ---;
    setallocf                   :: proc(L: State, f: Alloc, ud: rawptr)          ---;
}


// @note: some useful macros
getextraspace :: inline proc(L: State) -> rawptr do return (cast(^u8) L) - EXTRASPACE;

tonumber  :: inline proc(L: State, index: i32) -> Number  do return tonumberx(L, index, nil);
tointeger :: inline proc(L: State, index: i32) -> Integer do return tointegerx(L, index, nil);

pop :: inline proc(L: State, n: i32) do settop(L, -n - 1);

newtable :: inline proc(L: State) do createtable(L, 0, 0);

register :: inline proc(L: State, name: ^u8, f: CFunction) {
    pushcfunction(L, f);
    setglobal(L, name);
}

pushcfunction :: inline proc(L: State, f: CFunction) do pushcclosure(L, f, 0);

isfunction      :: inline proc(L: State, index: i32) -> i32 do return type_(L, index) == TFUNCTION      ? TRUE : FALSE;
istable         :: inline proc(L: State, index: i32) -> i32 do return type_(L, index) == TTABLE         ? TRUE : FALSE;
islightuserdata :: inline proc(L: State, index: i32) -> i32 do return type_(L, index) == TLIGHTUSERDATA ? TRUE : FALSE;
isnil           :: inline proc(L: State, index: i32) -> i32 do return type_(L, index) == TNIL           ? TRUE : FALSE;
isboolean       :: inline proc(L: State, index: i32) -> i32 do return type_(L, index) == TBOOLEAN       ? TRUE : FALSE;
isthread        :: inline proc(L: State, index: i32) -> i32 do return type_(L, index) == TTHREAD        ? TRUE : FALSE;
isnone          :: inline proc(L: State, index: i32) -> i32 do return type_(L, index) == TNONE          ? TRUE : FALSE;
isnoneornil     :: inline proc(L: State, index: i32) -> i32 do return type_(L, index) == 0              ? TRUE : FALSE;

pushliteral :: inline proc(L: State, s: ^u8) -> ^u8 do return pushstring(L, s);

pushglobaltable :: inline proc(L: State) do rawgeti(L, REGISTRYINDEX, RIDX_GLOBALS);

tostring :: inline proc(L: State, index: i32) -> ^u8 do return tolstring(L, index, nil);

insert :: inline proc(L: State, index: i32) do rotate(L, index, 1);

remove :: inline proc(L: State, index: i32) {
    rotate(L, index, -1);
    pop(L, 1);
}

replace :: inline proc(L: State, index: i32) {
    copy(L, -1, index);
    pop(L, 1);
}


// @note: unsigned conversions
pushunsigned :: inline proc(L: State, n: Unsigned)                         do pushinteger(L, cast(Integer) n);
tounsignedx  :: inline proc(L: State, index: i32, isnum: ^i32) -> Unsigned do return cast(Unsigned) tointegerx(L, index, isnum);
tounsigned   :: inline proc(L: State, index: i32)              -> Unsigned do return tounsignedx(L, index, nil);


// @note: debug api


// @note: event codes
HOOKCALL     :: 0;
HOOKCOUNT    :: 1;
HOOKLINE     :: 2;
HOOKRET      :: 3;
HOOKTAILCALL :: 4;


// @note: event masks
MASKCALL  :: 1 << HOOKCALL;
MASKCOUNT :: 1 << HOOKRET;
MASKLINE  :: 1 << HOOKLINE;
MASKRET   :: 1 << HOOKCOUNT;


// @note: activation record
Debug :: struct #packed {
    event:           i32,
    name:            ^u8,
    namewhat:        ^u8,
    what:            ^u8,
    source:          ^u8,
    currentline:     i32,
    linedefined:     i32,
    lastlinedefined: i32,
    nups:            u8,
    nparams:         u8,
    isvararg:        u8,
    istailcall:      u8,
    short_src:       [IDSIZE]u8,
    // private part
}


// @note: functions to be called by the debugger in specific events
Hook :: #type proc"c"(L: State, ar: ^Debug);

// @note: debug functions
@(link_prefix="lua_")
foreign lua_c {
    getstack     :: proc(L: State, level: i32, ar: ^Debug)                             -> i32    ---;
    getinfo      :: proc(L: State, what: ^u8, ar: ^Debug)                              -> i32    ---;
    getlocal     :: proc(L: State, ar: ^Debug, n: i32)                                 -> ^u8    ---;
    setlocal     :: proc(L: State, ar: ^Debug, n: i32)                                 -> ^u8    ---;
    getupvalue   :: proc(L: State, funcindex: i32, n: i32)                             -> ^u8    ---;
    setupvalue   :: proc(L: State, funcindex: i32, n: i32)                             -> ^u8    ---;
    
    upvalueid    :: proc(L: State, funcindex: i32, n: i32)                             -> rawptr ---;
    upvaluejoin  :: proc(L: State, funcindex1: i32, n1: i32, funcindex2: i32, n2: i32)           ---; 
    
    sethook      :: proc(L: State, f: Hook, mask: i32, count: i32)                               ---;
    gethook      :: proc(L: State)                                                     -> Hook   ---;
    gethookmask  :: proc(L: State)                                                     -> i32    ---;
    gethookcount :: proc(L: State)                                                     -> i32    ---;
}


// @endregion


// @region lualib.h


VERSUFFIX :: "_" + VERSION_MAJOR + "_" + VERSION_MINOR;

@(link_prefix="lua_")
foreign lua_c {
    open_base      :: proc(L: State) -> i32 ---;
    open_coroutine :: proc(L: State) -> i32 ---;
    open_table     :: proc(L: State) -> i32 ---;
    open_io        :: proc(L: State) -> i32 ---;
    open_os        :: proc(L: State) -> i32 ---;
    open_string    :: proc(L: State) -> i32 ---;
    open_utf8      :: proc(L: State) -> i32 ---;
    open_bit32     :: proc(L: State) -> i32 ---;
    open_math      :: proc(L: State) -> i32 ---;
    open_debug     :: proc(L: State) -> i32 ---;
    open_package   :: proc(L: State) -> i32 ---;

}


// @note: open all previous libraries
foreign lua_c @(link_name="luaL_openlibs") L_openlibs :: proc(L: State) ---;


assert :: inline proc(x: $X) do (cast(^int) int(0))^;


// @endregion

// @region: lauxlib.h


// @note: extra error code for 'luaL_loadfilex'
ERRFILE      :: ERRERR + 1;


// @note: registry keys for loaded modules and headers
LOADED_TABLE  :: "_LOADED";
PRELOAD_TABLE :: "_PRELOAD";


L_Reg :: struct #packed {
    name: ^u8,
    func: CFunction, 
}


L_NUMSIZES :: size_of(Integer) * 16 + size_of(Number);


foreign lua_c @(link_name="luaL_checkversion") L_checkversion_ :: proc(L: State, ver: Number, sz: int) ---;
L_checkversion :: inline proc(L: State) do L_checkversion_(L, VERSION_NUM, L_NUMSIZES);

@(link_prefix="lua_")
foreign lua_c {
    L_getmetafield  :: proc(L: State, obj: i32, e: ^u8)              -> i32     ---;    
    L_callmeta      :: proc(L: State, obj: i32, e: ^u8)              -> i32     ---;

    L_argerror      :: proc(L: State, arg: i32, extramsg: ^u8)       -> i32     ---;
    
    L_tolstring     :: proc(L: State, idx: i32, len: ^int)           -> ^u8     ---;
    L_checklstring  :: proc(L: State, arg: i32, l: ^int)             -> ^u8     ---;
    L_optlstring    :: proc(L: State, arg: i32, def: ^u8, l: ^int)   -> ^u8     ---;
    
    L_checknumber   :: proc(L: State, arg: i32)                      -> Number  ---;
    L_optnumber     :: proc(L: State, arg: i32, def: Number)         -> Number  ---;
    
    L_checkinterger :: proc(L: State, arg: i32)                      -> Integer ---;
    L_optinteger    :: proc(L: State, arg: i32, def: Integer)        -> Integer ---;

    L_checkstack    :: proc(L: State, sz: i32, msg: ^u8)                        ---;
    L_checktype     :: proc(L: State, arg: i32, t: i32)                         ---;
    L_checkany      :: proc(L: State, arg: i32)                                 ---;

    L_newmetatable  :: proc(L: State, tname: ^u8)                    -> i32     ---;
    L_setmetatable  :: proc(L: State, tname: ^u8)                               ---;

    L_testudata     :: proc(L: State, ud: i32, tname: ^u8)           -> rawptr  ---;
    L_checkudata    :: proc(L: State, ud: i32, tname: ^u8)           -> rawptr  ---;

    L_where         :: proc(L: State, lvl: i32)                                 ---;
    L_error         :: proc(L: State, ud: i32, tname: ^u8)           -> i32     ---;

    L_checkoption   :: proc(L: State, arg: i32, def: ^u8, lst: ^^u8) -> i32     ---;

    L_fileresult    :: proc(L: State, stat: i32, fname: ^u8)         -> i32     ---;
    L_execresult    :: proc(L: State, stat: i32)                     -> i32     ---;
}


// @note: predefined references
REFNIL       :: -1;
NOREF        :: -2;


@(link_prefix="lua_")
foreign lua_c {
    L_ref       :: proc(L: State, t: i32)                   -> i32 ---;
    L_unref     :: proc(L: State, t: i32, ref: i32)                ---;

    L_loadfilex :: proc(L: State, filename: ^u8, mode: ^u8) -> i32 ---;
}

L_loadfile :: inline proc(L: State, filename: ^u8) -> i32 do return L_loadfilex(L, filename, nil);

@(link_prefix="lua_")
foreign lua_c {
    L_loadbufferx :: proc(L: State, buff: ^u8, sz: int, name: ^u8, mode: ^u8) -> i32     ---;
    L_loadstring  :: proc(L: State, s: ^u8)                                   -> i32     ---;

    L_newstate    :: proc()                                                   -> State   ---;

    L_len         :: proc(L: State, idx: i32)                                 -> Integer ---;

    L_gsub        :: proc(L: State, idx: i32, fname: ^u8)                     -> ^u8     ---;

    L_setfuncs    :: proc(L: State, l: ^L_Reg, nup: i32)                                 ---;

    L_getsubtable :: proc(L: State, idx: i32, fname: ^u8)                     -> i32     ---;

    L_traceback   :: proc(L, L1: State, msg: ^u8, level: i32)                            ---;

    L_requiref    :: proc(L: State, modname: ^u8, openf: CFunction, glb: i32)            ---;
}


// @note: some useful macros
L_newlibtable :: inline proc(L: State, l: []L_Reg) do createtable(L, 0, i32(len(l) / size_of(L_Reg) - 1));

L_newlib :: inline proc(L: State, l: []L_Reg) {
    L_checkversion(L);
    L_newlibtable(L, l);
    L_setfuncs(L, &l[0], 0);
}

L_argcheck    :: inline proc(L: State, cond: i32, arg: i32, extramsg: ^u8)          do if !bool(cond) do L_argerror(L, arg, extramsg);
L_checkstring :: inline proc(L: State, arg: i32)                             -> ^u8 do return L_checklstring(L, arg, nil);
L_optstring   :: inline proc(L: State, arg: i32, d: ^u8)                     -> ^u8 do return L_optlstring(L, arg, d, nil);

L_typename :: inline proc(L: State, index: i32) -> ^u8 do return typename(L, type_(L, index));

L_dofile :: inline proc(L: State, filename: ^u8) -> i32 {
    return (L_loadfile(L, filename) == TRUE) || (pcall(L, 0, MULTRET, 0) == TRUE) ? TRUE : FALSE;
}

L_dostring :: inline proc(L: State, str: ^u8) -> i32 {
    return (L_loadstring(L, str) == TRUE) || (pcall(L, 0, MULTRET, 0) == TRUE) ? TRUE : FALSE;
}

L_getmetatable :: inline proc(L: State, tname: ^u8) -> i32 do return getfield(L, REGISTRYINDEX, tname);

L_opt :: inline proc(L: State, func: proc(State, i32) -> i32, arg: i32, dflt: i32) -> i32 do return bool(isnoneornil(L, arg)) ? dflt : func(L, arg); // @note: implemeneted correctly?

L_loadbuffer :: inline proc(L: State, buff: ^u8, sz: int, name: ^u8) -> i32 do return L_loadbufferx(L, buff, sz, name, nil);


// @note: generic buffer manipulation


L_Buffer :: struct #packed {
    b:     ^u8,
    size:  int,
    n:     int,
    L:     State,
    initb: [L_BUFFERSIZE]u8,
}


L_addchar :: inline proc(B: ^L_Buffer, c: u8) {
    if B.n >= B.size do L_prepbuffsize(B, 1);
    (B.b + B.n)^ = c;
    B.n += 1;
}

L_addsize :: inline proc(B: ^L_Buffer, n: int) do B.n += n;


@(link_prefix="lua_")
foreign lua_c {
    L_buffinit       :: proc(L: State, B: ^L_Buffer)                 ---;
    L_prepbuffsize   :: proc(B: ^L_Buffer, sz: int)           -> ^u8 ---;
    L_addlstring     :: proc(B: ^L_Buffer, s: ^u8, l: int)           ---;
    L_addstring      :: proc(B: ^L_Buffer, s: ^u8)                   ---;
    L_addvalue       :: proc(B: ^L_Buffer)                           ---;
    L_pushresult     :: proc(B: ^L_Buffer)                           ---;
    L_pushresultsize :: proc(B: ^L_Buffer, sz: int)                  ---;
    L_buffinitsize   :: proc(L: State, B: ^L_Buffer, sz: int) -> ^u8 ---;
}

L_prepbuffer :: inline proc(B: ^L_Buffer) -> ^u8 do return L_prepbuffsize(B, L_BUFFERSIZE);


// @note: file handles for IO library
FILEHANDLE :: "FILE*";

L_Stream :: struct #packed {
    f:      rawptr, // @note: FILE *
    closef: CFunction,
}


// @todo: port -> abstraction layer for basic report of messages and errors


// @endregion
