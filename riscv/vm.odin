/*
 *  @Name:     vm
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 22-06-2018 17:56:09 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 26-06-2018 14:39:42 UTC-5
 *  
 *  @Description:
 *  
 */

package riscv

import "core:fmt"
import "core:mem"



Hart :: struct {
    running   : bool,
    pc        : u64,
    cycles    : u64,
    registers : [32]u64,
    memory    : []byte,
}

make_hart :: proc(mem_size := 4096) -> Hart {
    return Hart{memory=make([]byte, mem_size)};
}

free_hart :: proc(hart : Hart) {
    free(hart.memory);
}

load_instructions :: proc(using hart : ^Hart, instrs : ...u32) {
    copy(memory, mem.slice_to_bytes(instrs));
}



load :: inline proc(using hart : ^Hart, T : type, addr : u64) -> T {
    return (^T)(&memory[addr])^;
}

store :: inline proc(using hart : ^Hart, T : type, addr : u64, value : T) {
    (^T)(&memory[addr])^ = value;
}



step :: inline proc(using hart : ^Hart) {
    using instr := decode((^u32)(&memory[pc])^);

    next_pc := pc + size_of(u32);

    nulltarget : u64 = ---;
    dst := rd < 32 && rd > 0 ? &registers[rd] : &nulltarget;

    switch mask {
    case LUI:   (^i64)(dst)^ = i64(imm);
    case AUIPC: (^u64)(dst)^ = pc + imm;

    case JAL:
        dst^    = next_pc;
        next_pc = pc + imm;

    case JALR:
        dst^    = next_pc;
        next_pc = (registers[rs1] + imm) & ~u64(1);

    case BEQ:  if (^u64)(&registers[rs1])^ == (^u64)(&registers[rs2])^ do next_pc = pc + imm;
    case BNE:  if (^u64)(&registers[rs1])^ != (^u64)(&registers[rs2])^ do next_pc = pc + imm;
    case BLT:  if (^i64)(&registers[rs1])^ <  (^i64)(&registers[rs2])^ do next_pc = pc + imm;
    case BGE:  if (^i64)(&registers[rs1])^ >= (^i64)(&registers[rs2])^ do next_pc = pc + imm;
    case BLTU: if (^u64)(&registers[rs1])^ <  (^u64)(&registers[rs2])^ do next_pc = pc + imm;
    case BGEU: if (^u64)(&registers[rs1])^ >= (^u64)(&registers[rs2])^ do next_pc = pc + imm;

    case LB:  registers[rd] = sext(u64(load(hart, u8,  registers[rs1] + imm)),  8);
    case LH:  registers[rd] = sext(u64(load(hart, u16, registers[rs1] + imm)), 16);
    case LW:  registers[rd] = sext(u64(load(hart, u32, registers[rs1] + imm)), 32);
    case LD:  registers[rd] = load(hart, u64, registers[rs1] + imm);
    case LBU: registers[rd] = u64(load(hart, u8,  registers[rs1] + imm));
    case LHU: registers[rd] = u64(load(hart, u16, registers[rs1] + imm));
    case LWU: registers[rd] = u64(load(hart, u32, registers[rs1] + imm));
    case SB:  store(hart, u8,  registers[rs1] + imm, u8(registers[rs2]));
    case SH:  store(hart, u16, registers[rs1] + imm, u16(registers[rs2]));
    case SW:  store(hart, u32, registers[rs1] + imm, u32(registers[rs2]));
    case SD:  store(hart, u64, registers[rs1] + imm, u64(registers[rs2]));

    case ADDI:  (^u64)(dst)^ = (^u64)(&registers[rs1])^  +  u64(imm);
    case SLTI:  (^b64)(dst)^ = (^i64)(&registers[rs1])^  <  i64(imm);
    case SLTIU: (^b64)(dst)^ = (^u64)(&registers[rs1])^  <  u64(imm);
    case XORI:  (^u64)(dst)^ = (^u64)(&registers[rs1])^ ~~~ u64(imm);
    case ORI:   (^u64)(dst)^ = (^u64)(&registers[rs1])^  |  u64(imm);
    case ANDI:  (^u64)(dst)^ = (^u64)(&registers[rs1])^  &  u64(imm);

    case ADDIW: (^i64)(dst)^ = i64((^i32)(&registers[rs1])^ +  i32(imm));
    case SLLIW: (^u64)(dst)^ = u64((^u32)(&registers[rs1])^ << u32(imm));
    case SRLIW: (^u64)(dst)^ = u64((^u32)(&registers[rs1])^ >> u32(imm));
    case SRAIW: (^i64)(dst)^ = i64((^i32)(&registers[rs1])^ >> u32(imm));

    case SLLI: (^u64)(dst)^ = (^u64)(&registers[rs1])^ << u64(imm);
    case SRLI: (^u64)(dst)^ = (^u64)(&registers[rs1])^ >> u64(imm);
    case SRAI: (^i64)(dst)^ = (^i64)(&registers[rs1])^ >> u64(imm);

    case ADD:  (^i64)(dst)^ = (^i64)(&registers[rs1])^ +   (^i64)(&registers[rs2])^;
    case SUB:  (^i64)(dst)^ = (^i64)(&registers[rs1])^ -   (^i64)(&registers[rs2])^;
    case SLL:  (^u64)(dst)^ = (^u64)(&registers[rs1])^ <<  (^u64)(&registers[rs2])^;
    case SLT:  (^b64)(dst)^ = (^i64)(&registers[rs1])^ <   (^i64)(&registers[rs2])^;
    case SLTU: (^b64)(dst)^ = (^u64)(&registers[rs1])^ <   (^u64)(&registers[rs2])^;
    case XOR:  (^u64)(dst)^ = (^u64)(&registers[rs1])^ ~~~ (^u64)(&registers[rs2])^;
    case SRL:  (^u64)(dst)^ = (^u64)(&registers[rs1])^ >>  (^u64)(&registers[rs2])^;
    case SRA:  (^i64)(dst)^ = (^i64)(&registers[rs1])^ >>  (^u64)(&registers[rs2])^;
    case OR:   (^u64)(dst)^ = (^u64)(&registers[rs1])^ |   (^u64)(&registers[rs2])^;
    case AND:  (^u64)(dst)^ = (^u64)(&registers[rs1])^ &   (^u64)(&registers[rs2])^;

    case ADDW: (^i64)(dst)^ = i64((^i32)(&registers[rs1])^ +  (^i32)(&registers[rs2])^);
    case SUBW: (^i64)(dst)^ = i64((^i32)(&registers[rs1])^ -  (^i32)(&registers[rs2])^);
    case SLLW: (^u64)(dst)^ = u64((^u32)(&registers[rs1])^ << (^u32)(&registers[rs2])^);
    case SRLW: (^u64)(dst)^ = u64((^u32)(&registers[rs1])^ >> (^u32)(&registers[rs2])^);
    case SRAW: (^i64)(dst)^ = i64((^i32)(&registers[rs1])^ >> (^u32)(&registers[rs2])^);

    case CSRRW:  // @todo(bpunsky): implement
    case CSRRS:  // @todo(bpunsky): implement
    case CSRRC:  // @todo(bpunsky): implement
    case CSRRWI: // @todo(bpunsky): implement
    case CSRRSI: // @todo(bpunsky): implement
    case CSRRCI: // @todo(bpunsky): implement

    case FENCE:   // @todo(bpunsky): implement
    case FENCE_I: // @todo(bpunsky): implement
    case ECALL:   // @todo(bpunsky): implement
    case EBREAK:  // @todo(bpunsky): implement

    case MUL:    (^i64)(dst)^ = (^i64)(&registers[rs1])^ * (^i64)(&registers[rs2])^;
    case MULH:   (^i64)(dst)^ = _mulh(i64(registers[rs1]), i64(registers[rs2]));
    case MULHSU: (^i64)(dst)^ = _mulhsu(i64(registers[rs1]), registers[rs2]);
    case MULHU:  (^u64)(dst)^ = _mulhu(registers[rs1], registers[rs2]);
    case DIV:    (^i64)(dst)^ = (^i64)(&registers[rs1])^ / (^i64)(&registers[rs2])^;
    case DIVU:   (^u64)(dst)^ = (^u64)(&registers[rs1])^ / (^u64)(&registers[rs2])^;
    case REM:    (^i64)(dst)^ = (^i64)(&registers[rs1])^ % (^i64)(&registers[rs2])^;
    case REMU:   (^u64)(dst)^ = (^u64)(&registers[rs1])^ % (^u64)(&registers[rs2])^;

    case MULW:  (^i64)(dst)^ = i64((^i32)(&registers[rs1])^ * (^i32)(&registers[rs2])^);
    case DIVW:  (^i64)(dst)^ = i64((^i32)(&registers[rs1])^ / (^i32)(&registers[rs2])^);
    case DIVUW: (^u64)(dst)^ = u64((^u32)(&registers[rs1])^ / (^u32)(&registers[rs2])^);
    case REMW:  (^i64)(dst)^ = i64((^i32)(&registers[rs1])^ % (^i32)(&registers[rs2])^);
    case REMUW: (^u64)(dst)^ = u64((^u32)(&registers[rs1])^ % (^u32)(&registers[rs2])^);

    case:
        error("ERROR ILLEGAL");
        running = false;
    }

    pc = next_pc;
    cycles += 1;
}



run :: proc(using hart : ^Hart) {
    running = true;

    for running {
        step(hart);
    }
}

debug :: proc(using hart : ^Hart) {
    running = true;

    for running {
        fmt.println();
        print(decode((^u32)(&memory[pc])^));

        step(hart);

        fmt.println();
        fmt.printf("x0: %d\n", registers[x0]);
        fmt.printf("x1: %d\n", registers[x1]);
        fmt.printf("x2: %d\n", registers[x2]);
        fmt.printf("x3: %d\n", registers[x3]);
        fmt.printf("x4: %d\n", registers[x4]);
    }
}
