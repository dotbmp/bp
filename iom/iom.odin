/*
 *  @Name:     iom
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 16-08-2018 22:20:00 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 22-08-2018 13:47:43 UTC-5
 *  
 *  @Description:
 *  
 */

package iom

import "core:fmt"
import "core:mem"
import "core:strings"
import "core:sys/win32"

import "bp:path"



runtime_error :: proc(format: string, args: ..any, loc := #caller_location) {
    fmt.printf_err(format, ..args);
    fmt.println_err();

    panic("This should really be handled some other way.");
}



Proc :: #type proc(core: ^Core);



using Code :: enum {
    STOP = 0,

    RUN,
    DEBUG,
    ERROR,
}

using Error :: enum {
    UNKNOWN = 0,

    INVALID_MEMORY_ACCESS,
    INVALID_FILE_ACCESS,
}



Library :: struct {
    name: string,
    path: string,

    handle: win32.Hmodule,

    procs: map[string]rawptr,
}

load_library :: proc(file_name: string, name := "") -> (Library, bool) {
    if name == "" {
        name = path.name(file_name);
    }

    cname := strings.new_cstring(name);
    defer delete(cname);

    cpath := strings.new_cstring(file_name);
    defer delete(cpath);

    if handle := win32.load_library_a(cpath); handle != nil {
        lib := Library{
            strings.new_string(name),
            strings.new_string(file_name),
            win32.load_library_a(cpath),
            nil,
        };

        return lib, true;
    }

    return Library{}, false;
}

free_library :: proc(lib: ^Library) {
    delete(lib.name);
    delete(lib.path);
    delete(lib.procs);

    win32.free_library(lib.handle);
}

load_procedure :: proc(lib: ^Library, name: string) -> rawptr {
    cname := strings.new_cstring(name);
    defer delete(cname);

    return win32.get_proc_address(lib.handle, cname);
}

load_procedures :: proc(lib: ^Library, names: ..string) -> bool {
    for name in names {
        if ptr := load_procedure(lib, name); ptr != nil {
            lib.procs[name] = ptr;
        }
        else {
            return false;
        }
    }

    return true;
}



Host :: struct {
    code: Code,

    named_procs:   map[string]rawptr,
    foreign_procs: map[string]Proc,

    libs: map[string]Library,

    agents: [dynamic]Agent,
}

make_host :: proc(code := STOP) -> Host {
    host: Host;
    host.code = code;

    return host;
}

add_named_proc :: inline proc(using host: ^Host, name: string, ptr: u64) {
    named_procs[name] = rawptr(uintptr(ptr));
}

get_named_proc :: inline proc(using host: ^Host, name: string) -> u64 {
    return u64(uintptr(named_procs[name]));
}

add_foreign_proc :: inline proc(using host: ^Host, name: string, p: Proc) {
    foreign_procs[name] = p;
}

get_foreign_proc :: inline proc(using host: ^Host, name: string) -> Proc {
    return foreign_procs[name];
}

new_agent :: proc(host: ^Host, code := STOP) -> ^Agent {
    idx := append(&host.agents, Agent{}) - 1;

    agent := &host.agents[idx];
    agent.host = host;
    agent.code = code;
    agent.id = u64(idx);

    return agent;
}

loop_host :: proc(using host: ^Host) -> Code {
    for code != STOP {
        step_host(host);
    }

    return code;
}

step_host :: inline proc(using host: ^Host) -> Code {
    switch code {
    case STOP, ERROR: // do nothing
    case RUN:   run_host(host);
    case DEBUG: debug_host(host);
    case:
        runtime_error("Invalid host code: %v", code);
    }

    return code;
}

run_host :: inline proc(using host: ^Host) {
    running := false;

    for _, i in agents {
        agent := &agents[i];

        step_agent(agent);

        if agent.code != STOP {
            running = true;
        }
    }

    if !running {
        code = STOP;
    }
}

debug_host :: proc(using host: ^Host) {
    for _, i in agents {
        // @todo(bpunsky): debug stuff!
        step_agent(&agents[i]);
    }
}



Agent :: struct {
    host: ^Host,
    code: Code,

    id: u64,

    regs: [8]u64,

    cores:  [dynamic]Core,
    memory: []byte,
}

new_core :: proc(agent: ^Agent, code := STOP) -> ^Core {
    idx := append(&agent.cores, Core{}) - 1;

    core := &agent.cores[idx];
    core.agent = agent;
    core.code  = code;
    core.id    = u64(idx);

    return core;
}

get_base_ptr :: proc(agent: ^Agent) -> u64 {
    return u64(uintptr(&agent.memory[0]));
}

agent_reg :: proc(agent: ^Agent, reg: Reg, T: type) -> ^T {
    switch reg {
    case GP: return (^T)(&agent.regs[0]);
    case BP: return (^T)(&agent.regs[1]);
    case SP: return (^T)(&agent.regs[2]);
    case FP: return (^T)(&agent.regs[3]);
    case X0: return (^T)(&agent.regs[4]);
    case X1: return (^T)(&agent.regs[5]);
    case X2: return (^T)(&agent.regs[6]);
    case X3: return (^T)(&agent.regs[7]);
    case:
        runtime_error("Invalid register: %v", reg);
    }

    return nil;
}

step_agent :: inline proc(using agent: ^Agent) -> Code {
    switch code {
    case STOP, ERROR: // do nothing
    case RUN:   run_agent(agent);
    case DEBUG: debug_agent(agent);
    case:
        runtime_error("Invalid agent code: %v", code);
    }

    return code;
}

run_agent :: inline proc(using agent: ^Agent) {
    is_running := false;

    for _, i in cores {
        core := &cores[i];

        step_core(core);

        if core.code != STOP {
            is_running = true;
        }
    }

    if !is_running {
        code = STOP;
    }
}

debug_agent :: proc(using agent: ^Agent) {
    agent_id := fmt.aprint(agent.id);
    defer delete(agent_id);

    fmt.printf("┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐\n");

    fmt.printf("│ AGENT %s", agent_id);
    for in 0..(150-len(agent_id)) {
        fmt.print(" ");
    }
    fmt.printf(" │\n");

    fmt.printf("╞════╤══════════════╤════╤══════════════╤════╤══════════════╤════╤══════════════╤════╤══════════════╤════╤══════════════╤════╤══════════════╤════╤══════════════╡\n");
    fmt.printf("│ gp │% 14d│ bp │% 14d│ sp │% 14d│ fp │% 14d│ x0 │% 14d│ x1 │% 14d│ x2 │% 14d│ x3 │% 14d│\n", agent_reg(agent, GP, i64)^, agent_reg(agent, BP, i64)^, agent_reg(agent, SP, i64)^, agent_reg(agent, FP, i64)^, agent_reg(agent, X0, i64)^, agent_reg(agent, X1, i64)^, agent_reg(agent, X2, i64)^, agent_reg(agent, X3, i64)^);
    fmt.printf("╞════╧══════════════╧════╧══════════════╧════╧══════════════╧════╧══════════════╧════╧══════════════╧════╧══════════════╧════╧══════════════╧════╧══════════════╡\n");

    is_running := false;

    first := true;

    for _, i in cores {
        core := &cores[i];
    
        if core.code != STOP {
            if first {
                first = false;
            }
            else {
                fmt.printf("╞════╧══════════════╧════╧══════════════╧════╧══════════════╧════╧══════════════╧════╧══════════════╧════╧══════════════╧════╧══════════════╧════╧══════════════╡\n");
            }
        }

        step_core(core);

        if core.code != STOP {
            is_running = true;
        }
    }

    fmt.printf("└────┴──────────────┴────┴──────────────┴────┴──────────────┴────┴──────────────┴────┴──────────────┴────┴──────────────┴────┴──────────────┴────┴──────────────┘\n");
    
    if !is_running {
        code = STOP;
    }
    
    fmt.printf("\n");
}



Core :: struct {
    agent: ^Agent,
    code:  Code,
    
    id:     u64,
    time:   u64,
    cycles: u64,
    pc:     u64,
    
    regs: [32]u64,

    scratch: u64,
}

call_foreign_proc :: inline proc(using core: ^Core, name: string) {
    p := get_foreign_proc(agent.host, name);
    p(core);
}

syscall :: inline proc(using core: ^Core, idx: u64) {
    call := syscalls[idx];
    call(core);
}

dst :: proc[dst_, dst__];

dst_ :: inline proc(using core: ^Core, T: type, reg: Reg) -> ^T {
    switch reg {
    case GP: return (^T)(&agent.regs[0]);
    case BP: return (^T)(&agent.regs[1]);
    case SP: return (^T)(&agent.regs[2]);
    case FP: return (^T)(&agent.regs[3]);
    case X0: return (^T)(&agent.regs[4]);
    case X1: return (^T)(&agent.regs[5]);
    case X2: return (^T)(&agent.regs[6]);
    case X3: return (^T)(&agent.regs[7]);

    case RZ: return (^T)(&scratch);
    case RA: return (^T)(&regs[ 1]);
    case G0: return (^T)(&regs[ 2]);
    case G1: return (^T)(&regs[ 3]);
    case G2: return (^T)(&regs[ 4]);
    case G3: return (^T)(&regs[ 5]);
    case G4: return (^T)(&regs[ 6]);
    case G5: return (^T)(&regs[ 7]);
    case A0: return (^T)(&regs[ 8]);
    case A1: return (^T)(&regs[ 9]);
    case A2: return (^T)(&regs[10]);
    case A3: return (^T)(&regs[11]);
    case A4: return (^T)(&regs[12]);
    case A5: return (^T)(&regs[13]);
    case A6: return (^T)(&regs[14]);
    case A7: return (^T)(&regs[15]);
    case S0: return (^T)(&regs[16]);
    case S1: return (^T)(&regs[17]);
    case S2: return (^T)(&regs[18]);
    case S3: return (^T)(&regs[19]);
    case S4: return (^T)(&regs[20]);
    case S5: return (^T)(&regs[21]);
    case S6: return (^T)(&regs[22]);
    case S7: return (^T)(&regs[23]);
    case T0: return (^T)(&regs[24]);
    case T1: return (^T)(&regs[25]);
    case T2: return (^T)(&regs[26]);
    case T3: return (^T)(&regs[27]);
    case T4: return (^T)(&regs[28]);
    case T5: return (^T)(&regs[29]);
    case T6: return (^T)(&regs[30]);
    case T7: return (^T)(&regs[31]);

    case: runtime_error("Invalid register: %v", reg);
    }

    return nil;
}

dst__ :: inline proc(using core: ^Core, reg: Reg) -> ^u64 {
    return dst_(core, u64, reg);
}

src :: proc[src_, src__];

src_ :: inline proc(using core: ^Core, T: type, reg: Reg) -> ^T {
    switch reg {
    case GP: return (^T)(&agent.regs[0]);
    case BP: return (^T)(&agent.regs[1]);
    case SP: return (^T)(&agent.regs[2]);
    case FP: return (^T)(&agent.regs[3]);
    case X0: return (^T)(&agent.regs[4]);
    case X1: return (^T)(&agent.regs[5]);
    case X2: return (^T)(&agent.regs[6]);
    case X3: return (^T)(&agent.regs[7]);

    case RZ: return (^T)(&regs[ 0]);
    case RA: return (^T)(&regs[ 1]);
    case G0: return (^T)(&regs[ 2]);
    case G1: return (^T)(&regs[ 3]);
    case G2: return (^T)(&regs[ 4]);
    case G3: return (^T)(&regs[ 5]);
    case G4: return (^T)(&regs[ 6]);
    case G5: return (^T)(&regs[ 7]);
    case A0: return (^T)(&regs[ 8]);
    case A1: return (^T)(&regs[ 9]);
    case A2: return (^T)(&regs[10]);
    case A3: return (^T)(&regs[11]);
    case A4: return (^T)(&regs[12]);
    case A5: return (^T)(&regs[13]);
    case A6: return (^T)(&regs[14]);
    case A7: return (^T)(&regs[15]);
    case S0: return (^T)(&regs[16]);
    case S1: return (^T)(&regs[17]);
    case S2: return (^T)(&regs[18]);
    case S3: return (^T)(&regs[19]);
    case S4: return (^T)(&regs[20]);
    case S5: return (^T)(&regs[21]);
    case S6: return (^T)(&regs[22]);
    case S7: return (^T)(&regs[23]);
    case T0: return (^T)(&regs[24]);
    case T1: return (^T)(&regs[25]);
    case T2: return (^T)(&regs[26]);
    case T3: return (^T)(&regs[27]);
    case T4: return (^T)(&regs[28]);
    case T5: return (^T)(&regs[29]);
    case T6: return (^T)(&regs[30]);
    case T7: return (^T)(&regs[31]);

    case: runtime_error("Invalid register: %v", reg);
    }

    return nil;
}

src__ :: inline proc(using core: ^Core, reg: Reg) -> ^u64 {
    return src_(core, u64, reg);
}

write :: inline proc(using core: ^Core, T: type, ptr: u64, val: u64) {
    (^T)(uintptr(ptr))^ = (^T)(&val)^;
}

read :: inline proc(using core: ^Core, T: type, ptr: u64) -> u64 {
    return u64((^T)(uintptr(ptr))^);
}

step_core :: inline proc(using core: ^Core) -> Code {
    switch code {
    case STOP, ERROR: // do nothing
    case RUN:   run_core(core);
    case DEBUG: debug_core(core);
    case:
        runtime_error("Invalid core code: %v", code);
    }

    return code;
}

get_instr :: inline proc(using core: ^Core) -> Instr {
    LOOKAHEAD :: 32; // @error(bpunsky): magic

    if instr, ok := decode(mem.slice_ptr((^byte)(uintptr(pc)), LOOKAHEAD)); ok {
        return instr;
    }
    else {
        panic("Failed to decode instruction"); // @error
        return Instr{};
    }
}

run_core :: inline proc(using core: ^Core) {
    using instr := get_instr(core);

    next_pc := pc + bytes;

    switch op {
    case PANIC: panic("PANIC!");
    case NOP:   // no-op
    case HALT:  code = STOP;

    case SV64: write(core, u64, src(core, rd)^ + u64(im), src(core, rs1)^);
    case SV32: write(core, u32, src(core, rd)^ + u64(im), src(core, rs1)^);
    case SV16: write(core, u16, src(core, rd)^ + u64(im), src(core, rs1)^);
    case SV8:  write(core, u8,  src(core, rd)^ + u64(im), src(core, rs1)^);

    case LD64: src(core, rd)^ = read(core, u64, src(core, rs1)^ + u64(im));
    case LD32: src(core, rd)^ = read(core, u32, src(core, rs1)^ + u64(im));
    case LD16: src(core, rd)^ = read(core, u16, src(core, rs1)^ + u64(im));
    case LD8:  src(core, rd)^ = read(core, u8,  src(core, rs1)^ + u64(im));

    case SYS: syscall(core, u64(im));

    case GOTO:
        dst(core, rd)^ = next_pc;
        next_pc = src(core, rs1)^;

    case JUMP:
        dst(core, rd)^ = next_pc;
        next_pc = pc + u64(im);

    case JEQ:
        if src(core, rs1)^ == src(core, rs2)^ {
            next_pc = pc + u64(im);
        }

    case JNE:
        if src(core, rs1)^ != src(core, rs2)^ {
            next_pc = pc + u64(im);
        }

    case JLT:
        if src(core, i64, rs1)^ < src(core, i64, rs2)^ {
            next_pc = pc + u64(im);
        }
        
    case JGE:
        if src(core, i64, rs1)^ >= src(core, i64, rs2)^ {
            next_pc = pc + u64(im);
        }
        
    case JLTU:
        if src(core, rs1)^ < src(core, rs2)^ {
            next_pc = pc + u64(im);
        }
        
    case JGEU:
        if src(core, rs1)^ <= src(core, rs2)^ {
            next_pc = pc + u64(im);
        }

    case ADDI: dst(core, i64, rd)^ = src(core, i64, rs1)^ +   im;
    case ANDI: dst(core, u64, rd)^ = src(core, u64, rs1)^ &   u64(im);
    case ORI:  dst(core, u64, rd)^ = src(core, u64, rs1)^ |   u64(im);
    case XORI: dst(core, u64, rd)^ = src(core, u64, rs1)^ ~~~ u64(im);
    case SLLI: dst(core, u64, rd)^ = src(core, u64, rs1)^ <<  u64(im);
    case SRLI: dst(core, u64, rd)^ = src(core, u64, rs1)^ >>  u64(im);
    case SRAI: dst(core, i64, rd)^ = src(core, i64, rs1)^ >>  u64(im);

    case ADD: dst(core, i64, rd)^ = src(core, i64, rs1)^ + src(core, i64, rs2)^;
    case SUB: dst(core, i64, rd)^ = src(core, i64, rs1)^ - src(core, i64, rs2)^;
    case MUL: dst(core, i64, rd)^ = src(core, i64, rs1)^ * src(core, i64, rs2)^;
    case DIV: dst(core, i64, rd)^ = src(core, i64, rs1)^ / src(core, i64, rs2)^;
    case MOD: dst(core, i64, rd)^ = src(core, i64, rs1)^ % src(core, i64, rs2)^;

    case MULU: dst(core, u64, rd)^ = src(core, u64, rs1)^ * src(core, u64, rs2)^;
    case DIVU: dst(core, u64, rd)^ = src(core, u64, rs1)^ / src(core, u64, rs2)^;
    case MODU: dst(core, u64, rd)^ = src(core, u64, rs1)^ % src(core, u64, rs2)^;
    
    case ADDF: dst(core, f64, rd)^ = src(core, f64, rs1)^ + src(core, f64, rs2)^;
    case SUBF: dst(core, f64, rd)^ = src(core, f64, rs1)^ + src(core, f64, rs2)^;
    case MULF: dst(core, f64, rd)^ = src(core, f64, rs1)^ * src(core, f64, rs2)^;
    case DIVF: dst(core, f64, rd)^ = src(core, f64, rs1)^ / src(core, f64, rs2)^;

    case AND: dst(core, u64, rd)^ = src(core, u64, rs1)^ &   src(core, u64, rs2)^;
    case OR:  dst(core, u64, rd)^ = src(core, u64, rs1)^ |   src(core, u64, rs2)^;
    case XOR: dst(core, u64, rd)^ = src(core, u64, rs1)^ ~~~ src(core, u64, rs2)^;
    case SLL: dst(core, u64, rd)^ = src(core, u64, rs1)^ <<  src(core, u64, rs2)^;
    case SRL: dst(core, u64, rd)^ = src(core, u64, rs1)^ <<  src(core, u64, rs2)^;
    case SRA: dst(core, i64, rd)^ = src(core, i64, rs1)^ >>  src(core, u64, rs2)^;

    case:
        runtime_error("Invalid instruction");
    }

    pc = next_pc;
}

debug_core :: proc(using core: ^Core) {
    instr := get_instr(core);

    run_core(core);

    head := fmt.aprintf("│ ");
    istr := instr_to_string(instr);
    tail := fmt.aprintf(" CORE %v │\n", core.id);
    defer {
        delete(tail);
        delete(head);
        delete(istr);
    }

    fmt.print(head);
    fmt.print(istr);
    for in 0..(165-len(head)-len(istr)-len(tail)) {
        fmt.print(" ");
    }
    fmt.print(tail);

    fmt.printf("╞════╤══════════════╤════╤══════════════╤════╤══════════════╤════╤══════════════╤════╤══════════════╤════╤══════════════╤════╤══════════════╤════╤══════════════╡\n");
    fmt.printf("│ rz │% 14d│ ra │% 14d│ g0 │% 14d│ g1 │% 14d│ g2 │% 14d│ g3 │% 14d│ g4 │% 14d│ g5 │% 14d│\n", src(core, i64, RZ)^, src(core, i64, RA)^, src(core, i64, G0)^, src(core, i64, G1)^, src(core, i64, G2)^, src(core, i64, G3)^, src(core, i64, G4)^, src(core, i64, G5)^);
    fmt.printf("│ a0 │% 14d│ a1 │% 14d│ a2 │% 14d│ a3 │% 14d│ a4 │% 14d│ a5 │% 14d│ a6 │% 14d│ a7 │% 14d│\n", src(core, i64, A0)^, src(core, i64, A1)^, src(core, i64, A2)^, src(core, i64, A3)^, src(core, i64, A4)^, src(core, i64, A5)^, src(core, i64, A6)^, src(core, i64, A7)^);
    fmt.printf("│ s0 │% 14d│ s1 │% 14d│ s2 │% 14d│ s3 │% 14d│ s4 │% 14d│ s5 │% 14d│ s6 │% 14d│ s7 │% 14d│\n", src(core, i64, S0)^, src(core, i64, S1)^, src(core, i64, S2)^, src(core, i64, S3)^, src(core, i64, S4)^, src(core, i64, S5)^, src(core, i64, S6)^, src(core, i64, S7)^);
    fmt.printf("│ t0 │% 14d│ t1 │% 14d│ t2 │% 14d│ t3 │% 14d│ t4 │% 14d│ t5 │% 14d│ t6 │% 14d│ t7 │% 14d│\n", src(core, i64, T0)^, src(core, i64, T1)^, src(core, i64, T2)^, src(core, i64, T3)^, src(core, i64, T4)^, src(core, i64, T5)^, src(core, i64, T6)^, src(core, i64, T7)^);
}



test :: proc(b: ^Builder) {
    add_spawn(b, "saver");
    // add_spawn(b, "start");

    // add_spawn(b, "test");

    add_label(b, "str");
    strlen := add_bytes(b, ([]byte)("add_proc"));

    add_label(b, "addproc");
    build(b, add(A0, A1));
    build(b, ret());

    add_label(b, "saver");
    build(b, movi(A0, add_ref(b, "str")));
    build(b, movi(A1, i64(strlen)));
    build(b, movi(A2, add_ref(b, "addproc")));
    build(b, sys (SAVE_NAMED_PROC));
    build(b, movi(A0, add_ref(b, "start")));
    build(b, sys (LAUNCH_CORE));
    build(b, movi(A0, add_ref(b, "test")));
    build(b, sys (LAUNCH_CORE));
    build(b, halt());

    add_label(b, "start");
    build(b, nop ()); // delay!
    build(b, movi(A0, add_ref(b, "str")));
    build(b, movi(A1, i64(strlen)));
    build(b, sys (LOAD_NAMED_PROC));
    build(b, mov (T0, A0));
    build(b, movi(A0, 123));
    build(b, movi(A1, 321));
    build(b, call(T0));
    build(b, mov (X0, A0));
    build(b, halt());

    add_label(b, "test");
    add_anon(b, "1");
    build(b, movi(T0, 3));
    build(b, movi(G1, 10));
    add_anon(b, "1");
    build(b, movi(G2, 10));
    build(b, mul (G1, G2));
    build(b, dec (T0));
    build(b, jnz (T0, add_backward_ref(b, "1", i64, true)));
    add_anon(b, "1");
    build(b, halt());
}

main :: proc() {
    host := make_host(RUN);

    //b: Builder;
    //test(&b);

    if b, ok := parse_file("tests/test2.iom"); ok {
        load_agent(&host, &b, DEBUG);
        
        loop_host(&host);
    }
    else {
        fmt.println_err("Parsing failed!");
    }
}
